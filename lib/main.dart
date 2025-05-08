import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdfrx_poc/marker.dart';
import 'package:pdfrx_poc/pages/mainPage.dart';
import 'package:pdfrx_poc/text_search_view.dart';
import 'package:pdfrx_poc/thumbnails.dart';
import 'package:url_launcher/url_launcher.dart';

import 'outline_view.dart';

const isWasmEnabled = bool.fromEnvironment('pdfrx.enablePdfiumWasm');

void main() {
  // NOTE:
  // For Pdfium WASM support, see https://github.com/espresso3389/pdfrx/wiki/Enable-Pdfium-WASM-support

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pdfrx example',
      home: MainPage(),
    );
  }
}


