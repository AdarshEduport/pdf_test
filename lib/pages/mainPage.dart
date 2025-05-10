
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx_poc/extensions.dart';
import 'package:pdfrx_poc/line.dart';
import 'package:pdfrx_poc/marker.dart';
import 'package:pdfrx_poc/pages/color_picker.dart';
import 'package:pdfrx_poc/pages/toolbar.dart';
import 'package:pdfrx_poc/selection.dart';

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

  
  bool _isDrawingLine = false;
  bool _isCurrentlyDrawing = false;
  Offset? _lineStart;
  Offset? _lineEnd;
  int? _drawingPageNumber;
  Color heighlightColor = Colors.yellow;
  double heighlightOpacity = 1.0;
  double heighlightThickness = 5;
  bool isEditing = false;
  bool _isEraser = false;
  Color bgColor = const Color(0xff1A1F38);
  Color editingColor = Colors.lightBlueAccent;
  final test ={"1":[{"color":4294961979,"rects":[{"left":162.4559326171875,"top":224.15679931640625,"right":193.25234985351562,"bottom":239.20709228515625}]}]};
  final testLine = 
  {2: [[247.49084191694294, 117.86064761262105, 318.1760331439749, 116.25416599382493, 4294961979, 5.0], [250.7038051545353, 117.86064761262105, 317.21214417269715, 115.290277022547, 4294961979, 5.0], [252.31028677333148, 117.86064761262105, 313.3565882875863, 115.290277022547, 4294961979, 5.0], [249.7709653595836, 114.95566114460632, 311.1119538726655, 113.21959543197192, 4294961979, 5.0], [247.84200345665653, 114.95566114460632, 307.8327186376895, 117.46331161841158, 4294961979, 5.0]]};

  List<PdfTextRanges>? textSelections;
  final _markers = <int, List<Marker>>{};
  final _saveMarkers = <int, List<SavedMarker>>{};// markers to be saved
  final _storedMarkers = <int, List<SavedMarker>>{};//already staored mrkers
  // Line drawing state variables
  final _lines = <int, List<Line>>{};
  int? _pageNumber;
  Offset? _offsetInPage;
  bool canHightlight = false;
 FocusNode _focusNode = FocusNode();
  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _storedMarkers.addAll(SavedMarkersJsonExtension.fromJson(jsonEncode(test)));
    _lines.addAll(SavedMarkersJsonExtension.fromJsonLine(testLine));
    
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
    return Scaffold(
      bottomNavigationBar: HighlightControlsBar(
        onDrawTap: () {
      
         
          setState(() {
            isEditing =true;
            _isDrawingLine = !_isDrawingLine;
           
          });
        
        },
    
        isEditing: isEditing,
        isEraser: _isEraser,
        heighlightColor: heighlightColor,
        heighlightOpacity: heighlightOpacity,
        heighlightThickness: heighlightThickness,
        editingColor: editingColor,
        bgColor: bgColor,
        onHighlightTap: () {
             saveLines();
             return;
          _addCurrentSelectionToMarkers(Colors.yellow);
          _focusNode.unfocus();
        },
        onColorTap: () {
          ColorPickerBottomSheet.show(
            context: context,
            onColorSelected: (color, opacity) {
              setState(() {
                heighlightColor = color;
                heighlightOpacity = opacity;
                _isEraser = false;
              });
            },
            initialColor: heighlightColor,
            initialOpacity: heighlightOpacity,
          );
        },
        onThicknessTap: () {
          ColorPickerBottomSheet.showThicknessSheet(
            context: context,
            lineColor: heighlightColor,
            onThicknessSelected: (double thickness) {
              setState(() {
                heighlightThickness = thickness;
                _isEraser = false;
              });
            },
          );
        },
        onEraserTap: () {
          setState(() {
            _isEraser = !_isEraser;
          });
        },
         highLightEnabled: canHightlight,
    
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
                        
                        perPageSelectableRegionInjector: (context, child, page, pageRect) {
                          return SelectionArea(selectionControls:CustomTextSelectionControls(),focusNode: _focusNode, child: child,);
                        },
                      
                        // scrollByMouseWheel: isHorizontalLayout,
                        pageAnchor: PdfPageAnchor.top,
                        pageAnchorEnd: PdfPageAnchor.bottom,
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

                        viewerOverlayBuilder: (context, size, handleLinkTap) {
                         
                          return [

                            PdfViewerScrollThumb(
                              controller: controller,
                              orientation: ScrollbarOrientation.right,
                              thumbSize: const Size(40, 25),
                              thumbBuilder: (context, thumbSize, pageNumber, controller) => Container(
                          
                                decoration: BoxDecoration(
                                  color: bgColor.withOpacity(.7),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                margin: EdgeInsets.only(
                            
                                  right: 5,
                                  top: 5,
                                  
                                ),
                                child:Center(
                                        child: Text(
                                          pageNumber.toString(),
                                          
                                          style: const TextStyle(color: Colors.white,fontSize: 8),
                                        ),
                                      ),
                              ),
                            ),
                            Visibility(
                              visible: _isDrawingLine && isEditing || _isEraser,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onLongPressStart: (details) {
                                  // Start drawing a line on long press

                                  final posInDoc = controller
                                      .globalToDocument(details.globalPosition);
                                  if (posInDoc == null) return;

                                  final pageIndex = controller
                                      .layout.pageLayouts
                                      .indexWhere((pageRect) =>
                                          pageRect.contains(posInDoc));
                                  if (pageIndex < 0) return;

                                  final pageOffset = posInDoc -
                                      controller.layout.pageLayouts[pageIndex]
                                          .topLeft;

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

                                  final pageIndex = controller
                                      .layout.pageLayouts
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
                                  if (_isEraser) {
                                    // Handle erasing mode
                                    final posInDoc =
                                        controller.globalToDocument(
                                            details.globalPosition);
                                    if (posInDoc == null) return;

                                    final pageIndex = controller
                                        .layout.pageLayouts
                                        .indexWhere(
                                      (pageRect) => pageRect.contains(posInDoc),
                                    );
                                    if (pageIndex < 0) return;

                                    final pageOffset = posInDoc -
                                        controller.layout.pageLayouts[pageIndex]
                                            .topLeft;

                                    // Check if the tap is near any line on the page
                                    final pageLines = _lines[pageIndex + 1];
                                    if (pageLines != null) {
                                      final lineToRemove = pageLines.firstWhere(
                                        (line) =>
                                            _isPointNearLine(pageOffset, line),
                                        orElse: () => Line.empty(),
                                      );

                                      if (!lineToRemove.isEmpty()) {
                                        setState(() {
                                          pageLines.remove(lineToRemove);
                                          if (pageLines.isEmpty) {
                                            _lines.remove(pageIndex + 1);
                                          }
                                        });
                                      }
                                    }
                                  }
                                  // Handle regular taps (like for link handling)
                                  final posInDoc = controller
                                      .globalToDocument(details.globalPosition);
                                  if (posInDoc == null) return;

                                  final pageIndex = controller
                                      .layout.pageLayouts
                                      .indexWhere((pageRect) =>
                                          pageRect.contains(posInDoc));
                                  if (pageIndex < 0) return;

                                  _offsetInPage = posInDoc -
                                      controller.layout.pageLayouts[pageIndex]
                                          .topLeft;
                                  _pageNumber = pageIndex + 1;

                                  

                                  setState(() {});
                                },
                                child: SizedBox(
                                  height: size.height,
                                  width: size.width,
                                ),
                              ),
                            ),
                          ];
                        },

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
                          _paintMarkers,
                          _paintLines,
                          _paintStoredMarkers
                        ],

                        onDocumentChanged: (document) async {
                          if (document == null) {
                            textSearcher.value?.dispose();
                            textSearcher.value = null;
                            outline.value = null;
                            textSelections = null;
                            // _lines.clear();
                          }
                        },

                        onViewerReady: (document, controller) async {
                          outline.value = await document.loadOutline();
                          textSearcher.value = PdfTextSearcher(controller)
                            ..addListener(_update);
                        },

                        onTextSelectionChange: (selections) {
                          textSelections = selections;
                        
                            activateHighlight(selections.isNotEmpty);
                          
                          // _addCurrentSelectionToMarkers(Colors.green);
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

  void activateHighlight(bool status){
if(status!=canHightlight){
  setState(() {
    canHightlight = status;
  });
}
  }

 void _paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = _markers[page.pageNumber];
    if (markers == null) {
      return;
    }
    for (final marker in markers) {
      final paint = Paint()
        ..color = marker.color.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (final range in marker.ranges.ranges) {
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );
        if (f != null) {
          final rect =f.bounds.toRectInPageRect(page: page, pageRect: pageRect);
          canvas.drawRect(
            rect,
            paint,
          );
          _saveMarkers.putIfAbsent(page.pageNumber, () => []).add(SavedMarker(marker.color, [rect]));
        }
      }
    }
  }

   void saveMarkers()async{
     

     _markers.forEach((pageNumber, markers) {
     
      for (final marker in markers) {
      final paint = Paint()
        ..color = marker.color.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (final range in marker.ranges.ranges) {

       
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );
        if (f != null) {
          // 
          final  page = controller.pages[pageNumber];
          // final rect =f.bounds.toRectInPageRect(page:page , pageRect: controller.calcRectForRectInsidePage(pageNumber: pageNumber, rect: rect));
         
          
        }
      }
    }
    });
    if (controller.isReady && _saveMarkers.isNotEmpty) {
    log("Markers to be saved: ${_saveMarkers.toJson()}");
    
    }
  }

  void saveLines(){
   
   final lines =  _lines.map((page, lines) {
      return MapEntry(
        page,
        lines.map((e) => e.toJson()).toList(),
      );
    });

    log("Lines  $lines");
  }


  void _paintStoredMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = _storedMarkers[page.pageNumber];
    if (markers == null) {
      return;
    }
    for (final marker in markers) {
      final paint = Paint()
        ..color = Colors.yellow.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (final rect in marker.rects) {
       
      
          canvas.drawRect(
            rect,
            paint,
          );
        
      }
    }
  }

 

  void _addCurrentSelectionToMarkers(Color color) {
    if (controller.isReady && textSelections != null) {
      for (final selectedText in textSelections!) {
        _markers.putIfAbsent(selectedText.pageNumber, () => []).add(Marker(color, selectedText));
      }
      canHightlight=false;
      
      setState(() {});
    }
  }


  bool _isPointNearLine(Offset point, Line line, {double tolerance = 10.0}) {
    final lineVector = line.end - line.start;
    final pointVector = point - line.start;

    final lineLengthSquared =
        lineVector.dx * lineVector.dx + lineVector.dy * lineVector.dy;

    if (lineLengthSquared == 0.0) {
      // Line is a point
      return (point - line.start).distance <= tolerance;
    }

    final t =
        (pointVector.dx * lineVector.dx + pointVector.dy * lineVector.dy) /
            lineLengthSquared;

    if (t < 0.0 || t > 1.0) {
      // Point is outside the line segment
      return false;
    }

    final projection = Offset(
      line.start.dx + t * lineVector.dx,
      line.start.dy + t * lineVector.dy,
    );
    return (point - projection).distance <= tolerance;
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


  



  Future<void> navigateToUrl(Uri url) async {}


}





