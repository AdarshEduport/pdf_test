// Line class to store line information
import 'dart:ui';

import 'package:flutter/material.dart';

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

  bool isEmpty() {
    return start == Offset.zero && end == Offset.zero;
  }

  factory Line.empty() {
    return Line(
      start: Offset.zero,
      end: Offset.zero,
      color: Colors.transparent,
      width: 0.0,
    );
  }

  // Efficient serialization: [start.dx, start.dy, end.dx, end.dy, color.value, width]
  List<dynamic> toJson() => [
    start.dx,
    start.dy,
    end.dx,
    end.dy,
    color.value,
    width,
  ];

  factory Line.fromJson(List<dynamic> json) {
    return Line(
      start: Offset(json[0] as double, json[1] as double),
      end: Offset(json[2] as double, json[3] as double),
      color: Color(json[4] as int),
      width: json[5] as double,
    );
  }

  // For batch conversion
  static List<List<dynamic>> toJsonList(List<Line> lines) => lines.map((l) => l.toJson()).toList();
  static List<Line> fromJsonList(List<dynamic> jsonList) =>
      jsonList.map((e) => Line.fromJson(List<dynamic>.from(e))).toList();
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