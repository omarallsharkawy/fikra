import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

/// Tests replace this boundary without initializing PDFium or doing file I/O.
typedef PdfDocumentLoader = Future<PdfDocument> Function(String path);

final pdfDocumentLoaderProvider = Provider<PdfDocumentLoader>((ref) => _loadDocument);

Future<PdfDocument> _loadDocument(String path) async {
  // Check readability without copying the file into a Dart byte buffer.
  final file = await File(path).open();
  await file.close();
  await pdfrxFlutterInitialize();
  final document = await PdfDocument.openFile(path, passwordProvider: () async => null, useProgressiveLoading: true);
  // Also reject encrypted documents that happen to accept an empty password.
  if (document.isEncrypted || document.pages.isEmpty) {
    await document.dispose();
    throw const FormatException('Unsupported PDF document');
  }
  return document;
}

/// Owns the native document, including when a user leaves before loading ends.
final pdfDocumentProvider = FutureProvider.autoDispose.family<PdfDocument, String>((ref, path) async {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  final document = await ref.watch(pdfDocumentLoaderProvider)(path);
  if (disposed) {
    await _disposeDocument(document);
    throw StateError('PDF viewer disposed while loading');
  }
  ref.onDispose(() => _disposeDocument(document));
  return document;
}, retry: (_, _) => null);

Future<void> _disposeDocument(PdfDocument document) async {
  try {
    await document.dispose();
  } catch (_) {
    // A failed native cleanup must not become an unhandled asynchronous error.
  }
}
