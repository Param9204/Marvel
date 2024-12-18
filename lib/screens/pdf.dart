import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Viewer'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: PDFView(
          filePath: filePath,
        ),
      ),
    );
  }
}
