import 'dart:convert';
import 'dart:ui';

import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx_poc/extensions.dart';
import 'package:pdfrx_poc/line.dart';

class Marker {
  Marker(this.color, this.ranges);
  
  final Color color;
  final PdfTextRanges ranges;
  
  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'ranges': ranges.toJson(),
    };
  }
  
  factory Marker.fromJson(Map<String, dynamic> json) {
    // Extract ranges object from the JSON
    final rangesJson = json['ranges'] as Map<String, dynamic>;
    
    // Extract page text from ranges JSON
    final pageTextJson = rangesJson['pageText'] as Map<String, dynamic>;
    
    // Create factories for creating concrete implementations
    final pageTextFactory = PdfPageTextPdfiumFactory();
    final textRangeFactory = DefaultPdfTextRangeFactory();
    
    // Create page text from JSON
    final pageText = PdfTextJsonFactory.createPdfPageTextFromJson(
      pageTextJson,
      pageTextFactory
    );
    
    // Create text ranges from JSON
    final textRanges = PdfTextJsonFactory.createPdfTextRangesFromJson(
      rangesJson,
      pageText,
      textRangeFactory
    );
    
    // Create and return Marker instance
    return Marker(
      Color(json['color'] as int),
      textRanges,
    );
  }
}


class SavedMarker {
  SavedMarker(this.color, this.rects);
  
  final Color color;
  final List<Rect> rects;
  
  // Convert a SavedMarker object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      'color': color.value, // Store color as integer value
      'rects': rects.map((rect) => {
        'left': rect.left,
        'top': rect.top,
        'right': rect.right,
        'bottom': rect.bottom,
      }).toList(),
    };
  }
  
  // Create a SavedMarker from a JSON-compatible Map
  factory SavedMarker.fromJson(Map<String, dynamic> json) {
    // Parse color from integer value
    final color = Color(json['color'] as int);
    
    // Parse list of rectangles
    final rectsList = (json['rects'] as List).map((rectJson) {
      return Rect.fromLTRB(
        rectJson['left'] as double,
        rectJson['top'] as double,
        rectJson['right'] as double,
        rectJson['bottom'] as double,
      );
    }).toList();
    
    return SavedMarker(color, rectsList);
  }
}

// Extension methods for the _savedMarkers map
extension SavedMarkersJsonExtension on Map<int, List<SavedMarker>> {
  // Convert _savedMarkers to JSON string
  String toJson() {
    final jsonMap = map((key, markersList) {
      return MapEntry(
        key.toString(), // Convert int key to string
        markersList.map((marker) => marker.toJson()).toList(),
      );
    });
    
    return jsonEncode(jsonMap);
  }
  
  // Load _savedMarkers from JSON string
  static Map<int, List<SavedMarker>> fromJson(String jsonString) {
    final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
    
    final result = <int, List<SavedMarker>>{};
    decodedMap.forEach((keyStr, value) {
      final key = int.parse(keyStr);
      final markersList = (value as List).map((markerJson) {
        return SavedMarker.fromJson(markerJson as Map<String, dynamic>);
      }).toList();
      
      result[key] = markersList;
    });
    
    return result;
  }

  static Map<int, List<Line>> fromJsonLine(Map<int, dynamic> json) {
    
    
    final result = <int, List<Line>>{};
    json.forEach((key, value) {
     
      final markersList = (value as List).map((markerJson) {
        return Line.fromJson(markerJson );
      }).toList();
      
      result[key] = markersList;
    });
    
    return result;
  }
}