import 'dart:convert';
import 'dart:ui';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx_poc/line.dart';

class Marker {
  Marker(this.color, this.rect);
  
  final Color color;
  final PdfRect rect;
  
  List<dynamic> toJson() {
    return [
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
      color.value,
    ];
  }
  

  factory Marker.fromJson(List<dynamic> json) {
    return Marker(
      Color(json[4] as int),
      PdfRect(
         json[0] as double,
        json[1] as double,
         json[2] as double,
      json[3] as double,
      ),
    );
  }
  
}






// Extension methods for the _savedMarkers map
extension SavedMarkersJsonExtension on Map<int, List<Marker>> {
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
  static Map<int, List<Marker>> fromJson(Map<String, List<List<num>>> json) {

    
    final result = <int, List<Marker>>{};
    json.forEach((keyStr, value) {
      final key = int.parse(keyStr);
      final markersList = (value as List).map((markerJson) {
        return Marker.fromJson(markerJson );
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