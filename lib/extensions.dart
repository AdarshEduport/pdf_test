import 'dart:convert';

import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx/src/pdfium/pdfrx_pdfium.dart';
import 'package:pdfrx_poc/marker.dart';

/// Extension methods to support JSON serialization and deserialization for PdfPageText,
/// PdfTextRanges, and related classes.

// Extension for PdfPageText
extension PdfPageTextJsonExtension on PdfPageText {
  /// Converts the PdfPageText to a JSON-serializable Map
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'fullText': fullText,
      'fragments': fragments.map((fragment) => _fragmentToJson(fragment)).toList(),
    };
  }

  /// Helper method to convert a PdfPageTextFragment to JSON
  Map<String, dynamic> _fragmentToJson(PdfPageTextFragment fragment) {
    return {
      'index': fragment.index,
      'length': fragment.length,
      'text': fragment.text,
      'bounds': _rectToJson(fragment.bounds),
    };
  }

  /// Helper method to convert a PdfRect to JSON
  Map<String, dynamic> _rectToJson(PdfRect rect) {
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }
}

// Extension for PdfTextRanges
extension PdfTextRangesJsonExtension on PdfTextRanges {
  /// Converts the PdfTextRanges to a JSON-serializable Map
  Map<String, dynamic> toJson() {
    return {
      'pageText': (pageText).toJson(), // Using the extension method above
      'ranges': ranges.map((range) => _rangeToJson(range)).toList(),
    };
  }

  /// Helper method to convert a PdfTextRange to JSON
  Map<String, dynamic> _rangeToJson(PdfTextRange range) {
    return {
      'start': range.start,
      'end': range.end,
    };
  }
}

// Factory class for creating objects from JSON
class PdfTextJsonFactory {
  /// Creates a PdfPageText from JSON. 
  /// Note: This requires a concrete implementation class to be provided.
  static PdfPageText createPdfPageTextFromJson(
    Map<String, dynamic> json, 
    PdfPageTextFactory factory
  ) {
    final pageNumber = json['pageNumber'] as int;
    final fullText = json['fullText'] as String;
    final fragmentsJson = json['fragments'] as List<dynamic>;
    
    // Create an instance using the provided factory
    final pageText = factory.createPdfPageText(
      pageNumber: pageNumber,
      fullText: fullText,
      fragments: [], // Will be populated after creation
    );
    
    // Populate fragments using the factory
    final fragments = fragmentsJson.map((fragJson) {
      final Map<String, dynamic> fragmentMap = fragJson as Map<String, dynamic>;
      final rect = _rectFromJson(fragmentMap['bounds'] as Map<String, dynamic>);
      
      return factory.createPdfPageTextFragment(
        pageText: pageText,
        index: fragmentMap['index'] as int,
        length: fragmentMap['length'] as int,
        bounds: rect,
      );
    }).toList();
    
    // Set fragments on the page text (requires a mechanism to update the list)
    factory.setFragmentsOnPageText(pageText, fragments);
    
    return pageText;
  }
  
  /// Creates PdfTextRanges from JSON
  static PdfTextRanges createPdfTextRangesFromJson(
    Map<String, dynamic> json,
    PdfPageText pageText,
    PdfTextRangeFactory factory
  ) {
    final rangesJson = json['ranges'] as List<dynamic>;
    
    final ranges = rangesJson.map((rangeJson) {
      final Map<String, dynamic> rangeMap = rangeJson as Map<String, dynamic>;
      
      return factory.createPdfTextRange(
        start: rangeMap['start'] as int,
        end: rangeMap['end'] as int,
      );
    }).toList();
    
    return PdfTextRanges(
      pageText: pageText,
      ranges: ranges,
    );
  }
  
  /// Helper method to convert JSON to PdfRect
  static PdfRect _rectFromJson(Map<String, dynamic> json) {
    return PdfRect(
      json['left'] as double,
      json['top'] as double,
      json['right'] as double,
      json['bottom'] as double,
    );
  }
}

/// Factory interface for creating PdfPageText implementations
abstract class PdfPageTextFactory {
  /// Creates a concrete PdfPageText implementation
  PdfPageText createPdfPageText({
    required int pageNumber,
    required String fullText,
    required List<PdfPageTextFragment> fragments,
  });
  
  /// Creates a concrete PdfPageTextFragment implementation
  PdfPageTextFragment createPdfPageTextFragment({
    required PdfPageText pageText,
    required int index,
    required int length,
    required PdfRect bounds,
  });
  
  /// Sets fragments on an existing PdfPageText instance
  void setFragmentsOnPageText(PdfPageText pageText, List<PdfPageTextFragment> fragments);
}

/// Factory interface for creating PdfTextRange implementations
abstract class PdfTextRangeFactory {
  /// Creates a concrete PdfTextRange implementation
  PdfTextRange createPdfTextRange({
    required int start,
    required int end,
  });
}

/// Example implementation of PdfPageTextFactory for PdfPageTextPdfium
class PdfPageTextPdfiumFactory implements PdfPageTextFactory {
  @override
  PdfPageText createPdfPageText({
    required int pageNumber,
    required String fullText,
    required List<PdfPageTextFragment> fragments,
  }) {
    return PdfPageTextPdfium(
      pageNumber: pageNumber,
      fullText: fullText,
      fragments: fragments,
    );
  }
  
  @override
  PdfPageTextFragment createPdfPageTextFragment({
    required PdfPageText pageText,
    required int index,
    required int length,
    required PdfRect bounds,
  }) {
    // Note: This is a simplified implementation - you'll need to adapt it
    // to match your actual PdfPageTextFragmentPdfium constructor
    return PdfPageTextFragmentPdfium(
      pageText as PdfPageTextPdfium,
      index,
      length,
      bounds,
      [], // Character rects would need to be populated from somewhere
    );
  }
  
  @override
  void setFragmentsOnPageText(PdfPageText pageText, List<PdfPageTextFragment> fragments) {
    // This assumes PdfPageTextPdfium has mutable fragments
    // If not, you'll need to create a new instance with the fragments
    final pdfiumPageText = pageText as PdfPageTextPdfium;
    pdfiumPageText.fragments.clear();
    pdfiumPageText.fragments.addAll(fragments);
  }
}

/// Example implementation for creating a TextRange
class DefaultPdfTextRangeFactory implements PdfTextRangeFactory {
  @override
  PdfTextRange createPdfTextRange({
    required int start,
    required int end,
  }) {
    return PdfTextRange(start: start, end: end);
  }
}



extension MarkersMapJsonExtension on Map<int, List<Marker>> {
  /// Convert Map<int, List<Marker>> to JSON-serializable Map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{};
    
    // Convert each key (int) to a string and serialize the list of markers
    forEach((key, markersList) {
      result[key.toString()] = markersList.map((marker) => marker.toJson()).toList();
    });
    
    return result;
  }
}

/// Class for handling Map<int, List<Marker>> serialization and deserialization
class MarkersMapJsonConverter {
  /// Convert Map<int, List<Marker>> to JSON string
  static String encode(Map<int, List<Marker>> markers) {
    return jsonEncode(markers.toJson());
  }
  
  /// Create Map<int, List<Marker>> from JSON string
  static Map<int, List<Marker>> decode(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return createFromJson(json);
  }
  
  /// Create Map<int, List<Marker>> from JSON map
  static Map<int, List<Marker>> createFromJson(Map<String, dynamic> json) {
    final result = <int, List<Marker>>{};
    
    json.forEach((keyStr, value) {
      // Convert string key back to int
      final key = int.parse(keyStr);
      
      // Convert each marker in the list
      final markersList = (value as List<dynamic>).map((markerJson) {
        return Marker.fromJson(markerJson as Map<String, dynamic>);
      }).toList();
      
      result[key] = markersList;
    });
    
    return result;
  }
}