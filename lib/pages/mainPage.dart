import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx_poc/pages/color_picker.dart';
import 'package:pdfrx_poc/pages/toolbar.dart';

Color bgColor = const Color(0xff1A1F38);

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final documentRef = ValueNotifier<PdfDocumentRef?>(null);
  final controller = PdfViewerController();
  final showLeftPane = ValueNotifier<bool>(false);
  final outline = ValueNotifier<List<PdfOutlineNode>?>(null);
  final textSearcher = ValueNotifier<PdfTextSearcher?>(null);

  // Line drawing state variables
  final _lines = <int, List<Line>>{};
  bool _isDrawingLine = false;
  bool _isCurrentlyDrawing = false;
  Offset? _lineStart;
  Offset? _lineEnd;
  int? _drawingPageNumber;
  Color heighlightColor = Colors.yellow;
  double heighlightOpacity = 1.0;
  double heighlightThickness = 5;
  bool isHighlightMode = false;
  bool isEditing = false;
  Color bgColor = const Color(0xff1A1F38);
  Color editingColor = Colors.lightBlueAccent;

  List<PdfTextRanges>? textSelections;
  int? _pageNumber;
  Offset? _offsetInPage;

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    documentRef.value = PdfDocumentRefUri(
      Uri.parse(
          'https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf'),
      passwordProvider: () {},
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    textSearcher.value?.dispose();
    textSearcher.dispose();
    showLeftPane.dispose();
    outline.dispose();
    documentRef.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const visualDensity = VisualDensity.compact;
    return Scaffold(
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).padding.bottom + 70,
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  IconButton(
                    visualDensity: visualDensity,
                    icon: Icon(
                      Icons.border_color_rounded,
                      size: 22,
                      color: isHighlightMode ? editingColor : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isHighlightMode = !isHighlightMode;
                        isEditing = true;
                        _isDrawingLine!=_isDrawingLine;
                      });
                    },
                  ),
                  const Text(
                    'Highlight',
                    style: TextStyle(fontSize: 8, color: Colors.white),
                  ),
                ],
              ),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: isHighlightMode
                      ? Row(
                          key: const ValueKey('highlightControls'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Container(
                                height: 24,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                width: 1.3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      ColorPickerBottomSheet.show(
                                          context: context,
                                          onColorSelected: (color, opacity) {
                                            setState(() {
                                              heighlightColor = color;
                                              heighlightOpacity = opacity;
                                            });
                                          },
                                          initialColor: heighlightColor,
                                          initialOpacity: heighlightOpacity);
                                    },
                                    child: Container(
                                      height: 22,
                                      width: 22,
                                      decoration: BoxDecoration(
                                        color: heighlightColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(.9),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Color',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                       ColorPickerBottomSheet.showThicknessSheet(context: context, lineColor: heighlightColor, onThicknessSelected: (double thickness) {
                                        setState(() {
                                          heighlightThickness = thickness;
                                        });

                                       });
                                    },
                                    child: Icon(
                                      Icons.line_weight,
                                      size: 22,
                                      color: heighlightColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Line Thickness',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.white),
                                  ),
                                ],
                              )
                            ])
                      : const SizedBox.shrink(key: ValueKey('empty')))
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
            valueListenable: documentRef,
            builder: (context, docRef, child) {
              if (docRef == null) {
                return const Center(
                  child: Text(
                    'No document loaded',
                    style: TextStyle(fontSize: 20),
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: PdfViewer(
                      docRef,
                      controller: controller,
                      params: PdfViewerParams(
                        layoutPages: _layoutPages[_layoutTypeIndex],
                        // scrollByMouseWheel: isHorizontalLayout,
                        pageAnchor: isHorizontalLayout
                            ? PdfPageAnchor.left
                            : PdfPageAnchor.top,
                        pageAnchorEnd: isHorizontalLayout
                            ? PdfPageAnchor.right
                            : PdfPageAnchor.bottom,
                        enableTextSelection: true,
                        useAlternativeFitScaleAsMinScale: false,
                        maxScale: 8,
                        pageOverlaysBuilder: (context, pageRect, page) {
                          return [
                            // Draw existing lines on this page
                            if (_lines.containsKey(page.pageNumber))
                              ..._lines[page.pageNumber]!
                                  .map((line) => GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        child: CustomPaint(
                                          painter: LinePainter(
                                            opacity: .4,
                                            startPoint: line.start *
                                                controller.currentZoom,
                                            endPoint: line.end *
                                                controller.currentZoom,
                                            color: line.color,
                                            strokeWidth: line.width *
                                                controller.currentZoom,
                                          ),
                                        ),
                                      )),

                            // Draw active line being drawn
                            if (_isDrawingLine &&
                                _drawingPageNumber == page.pageNumber &&
                                _lineStart != null &&
                                _lineEnd != null)
                              GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                child: CustomPaint(
                                  painter: LinePainter(
                                    opacity: .4,
                                    startPoint:
                                        _lineStart! * controller.currentZoom,
                                    endPoint:
                                        _lineEnd! * controller.currentZoom,
                                    color: heighlightColor,
                                    strokeWidth: 3.0 * controller.currentZoom,
                                  ),
                                ),
                              ),
                          ];
                        },

                        onViewSizeChanged: (viewSize, oldViewSize, controller) {
                          if (oldViewSize != null) {
                            //
                            // Calculate the matrix to keep the center position during device
                            // screen rotation
                            //
                            // The most important thing here is that the transformation matrix
                            // is not changed on the view change.
                            final centerPosition =
                                controller.value.calcPosition(oldViewSize);
                            final newMatrix =
                                controller.calcMatrixFor(centerPosition);
                            // Don't change the matrix in sync; the callback might be called
                            // during widget-tree's build process.
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () => controller.goTo(newMatrix),
                            );
                          }
                        },

                        viewerOverlayBuilder: (context, size, handleLinkTap) =>
                            [
                          Visibility(
                            visible: _isDrawingLine,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onLongPressStart: (details) {
                                // Start drawing a line on long press
                                final posInDoc = controller
                                    .globalToDocument(details.globalPosition);
                                if (posInDoc == null) return;

                                final pageIndex = controller.layout.pageLayouts
                                    .indexWhere((pageRect) =>
                                        pageRect.contains(posInDoc));
                                if (pageIndex < 0) return;

                                final pageOffset = posInDoc -
                                    controller
                                        .layout.pageLayouts[pageIndex].topLeft;

                                setState(() {
                                  _lineStart = pageOffset;
                                  _lineEnd =
                                      pageOffset; // Initialize end with start
                                  _drawingPageNumber = pageIndex + 1;
                                  _isCurrentlyDrawing =
                                      true; // Flag to track active drawing
                                });
                              },
                              onLongPressMoveUpdate: (details) {
                                // Only update if we're in drawing mode
                                if (!_isCurrentlyDrawing) return;

                                // Update the end point of the line
                                final posInDoc = controller
                                    .globalToDocument(details.globalPosition);
                                if (posInDoc == null) return;

                                final pageIndex = controller.layout.pageLayouts
                                    .indexWhere((pageRect) =>
                                        pageRect.contains(posInDoc));

                                // Only update if we're still on the same page
                                if (pageIndex + 1 == _drawingPageNumber) {
                                  final pageOffset = posInDoc -
                                      controller.layout.pageLayouts[pageIndex]
                                          .topLeft;

                                  setState(() {
                                    _lineEnd = pageOffset;
                                  });
                                }
                              },
                              onLongPressEnd: (details) {
                                // Finalize the line
                                if (_isCurrentlyDrawing &&
                                    _lineStart != null &&
                                    _lineEnd != null &&
                                    _drawingPageNumber != null) {
                                  // Add the line to the collection
                                  _lines
                                      .putIfAbsent(
                                          _drawingPageNumber!, () => [])
                                      .add(Line(
                                        start: _lineStart!,
                                        end: _lineEnd!,
                                        color: heighlightColor,
                                        width: heighlightThickness,
                                      ));

                                  // Reset temporary drawing state
                                  setState(() {
                                    _lineStart = null;
                                    _lineEnd = null;
                                    _isCurrentlyDrawing = false;
                                  });
                                }
                              },
                              onTapDown: (details) {
                                // Handle regular taps (like for link handling)
                                final posInDoc = controller
                                    .globalToDocument(details.globalPosition);
                                if (posInDoc == null) return;

                                final pageIndex = controller.layout.pageLayouts
                                    .indexWhere((pageRect) =>
                                        pageRect.contains(posInDoc));
                                if (pageIndex < 0) return;

                                _offsetInPage = posInDoc -
                                    controller
                                        .layout.pageLayouts[pageIndex].topLeft;
                                _pageNumber = pageIndex + 1;

                                // Call the link handling function if it exists
                                if (handleLinkTap != null) {}

                                setState(() {});
                              },
                              child: SizedBox(
                                height: size.height,
                                width: size.width,
                              ),
                            ),
                          ),
                        ],

                        loadingBannerBuilder:
                            (context, bytesDownloaded, totalBytes) => Center(
                          child: CircularProgressIndicator(
                            value: totalBytes != null
                                ? bytesDownloaded / totalBytes
                                : null,
                            backgroundColor: Colors.grey,
                          ),
                        ),

                        linkHandlerParams: PdfLinkHandlerParams(
                          onLinkTap: (link) {
                            if (link.url != null) {
                              navigateToUrl(link.url!);
                            } else if (link.dest != null) {
                              controller.goToDest(link.dest);
                            }
                          },
                        ),

                        pagePaintCallbacks: [
                          if (textSearcher.value != null)
                            textSearcher.value!.pageTextMatchPaintCallback,
                          // _paintMarkers,
                          _paintLines,
                        ],

                        onDocumentChanged: (document) async {
                          if (document == null) {
                            textSearcher.value?.dispose();
                            textSearcher.value = null;
                            outline.value = null;
                            textSelections = null;
                            _lines.clear();
                          }
                        },

                        onViewerReady: (document, controller) async {
                          outline.value = await document.loadOutline();
                          textSearcher.value = PdfTextSearcher(controller)
                            ..addListener(_update);
                        },

                        onTextSelectionChange: (selections) {
                          textSelections = selections;
                        },
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  void _paintLines(Canvas canvas, Rect pageRect, PdfPage page) {
    final lines = _lines[page.pageNumber];
    if (lines == null) {
      return;
    }

    for (final line in lines) {
      final paint = Paint()
        ..color = line.color.withOpacity(.2)
        ..strokeWidth = line.width * pageRect.width / page.width
        ..style = PaintingStyle.stroke;

      final startPoint = Offset(
          pageRect.left + line.start.dx * pageRect.width / page.width,
          pageRect.top + line.start.dy * pageRect.height / page.height);

      final endPoint = Offset(
          pageRect.left + line.end.dx * pageRect.width / page.width,
          pageRect.top + line.end.dy * pageRect.height / page.height);

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  int _layoutTypeIndex = 0;

  /// Change the layout logic; see [_layoutPages] for the logics
  void _changeLayoutType() {
    setState(() {
      _layoutTypeIndex = (_layoutTypeIndex + 1) % _layoutPages.length;
    });
  }

  bool get isHorizontalLayout => _layoutTypeIndex == 1;

  /// Page reading order; true to L-to-R that is commonly used by books like manga or such
  var isRightToLeftReadingOrder = false;

  /// Use the first page as cover page
  var needCoverPage = true;

  late final List<PdfPageLayoutFunction?> _layoutPages = [
    // The default layout
    null,
    // Horizontal layout
    (pages, params) {
      final height = pages.fold(0.0, (prev, page) => max(prev, page.height)) +
          params.margin * 2;
      final pageLayouts = <Rect>[];
      double x = params.margin;
      for (var page in pages) {
        pageLayouts.add(
          Rect.fromLTWH(
            x,
            (height - page.height) / 2, // center vertically
            page.width,
            page.height,
          ),
        );
        x += page.width + params.margin;
      }
      return PdfPageLayout(
        pageLayouts: pageLayouts,
        documentSize: Size(x, height),
      );
    },
    // Facing pages layout
    (pages, params) {
      final width = pages.fold(0.0, (prev, page) => max(prev, page.width));

      final pageLayouts = <Rect>[];
      final offset = needCoverPage ? 1 : 0;
      double y = params.margin;
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final pos = i + offset;
        final isLeft =
            isRightToLeftReadingOrder ? (pos & 1) == 1 : (pos & 1) == 0;

        final otherSide = (pos ^ 1) - offset;
        final h = 0 <= otherSide && otherSide < pages.length
            ? max(page.height, pages[otherSide].height)
            : page.height;

        pageLayouts.add(
          Rect.fromLTWH(
            isLeft
                ? width + params.margin - page.width
                : params.margin * 2 + width,
            y + (h - page.height) / 2,
            page.width,
            page.height,
          ),
        );
        if (pos & 1 == 1 || i + 1 == pages.length) {
          y += h + params.margin;
        }
      }
      return PdfPageLayout(
        pageLayouts: pageLayouts,
        documentSize: Size(
          (params.margin + width) * 2 + params.margin,
          y,
        ),
      );
    },
  ];

  Future<void> navigateToUrl(Uri url) async {}

  Future<void> openUri() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        controller.text =
            'https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/PDF32000_2008.pdf';
        return AlertDialog(
          title: const Text('Open URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb)
                const Text(
                  'Note: The URL must be CORS-enabled.',
                  style: TextStyle(color: Colors.red),
                ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    final uri = Uri.parse(result);
    documentRef.value = PdfDocumentRefUri(
      uri,
      passwordProvider: () {},
    );
  }

  static String? _fileName(String? path) {
    if (path == null) return null;
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }
}

// Line class to store line information
class Line {
  final Offset start;
  final Offset end;
  final Color color;
  final double width;

  Line(
      {required this.start,
      required this.end,
      required this.color,
      required this.width});
}

// Custom painter for drawing lines
class LinePainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;
  final double opacity;
  final double strokeWidth;

  LinePainter({
    required this.startPoint,
    required this.opacity,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
