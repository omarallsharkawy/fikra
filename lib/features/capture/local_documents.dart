import 'package:file_picker/file_picker.dart';

import '../../data/files/file_opener.dart';
import '../../data/product/models.dart';

class LocalDocument {
  const LocalDocument(this.path, this.name);
  final String path, name;
}

abstract interface class LocalDocuments {
  Future<LocalDocument?> pickPdf();
  Future<void> open(LocalDocument document);
}

class DeviceLocalDocuments implements LocalDocuments {
  DeviceLocalDocuments(this.opener);
  final FileOpener opener;
  @override
  Future<LocalDocument?> pickPdf() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result.isEmpty) return null;
    final file = result.first;
    if (file.path == null) throw const ProductFailure(FailureKind.unavailable);
    return LocalDocument(file.path!, file.name);
  }

  @override
  Future<void> open(LocalDocument document) async {
    if (!await opener(document.path)) throw const ProductFailure(FailureKind.unavailable);
  }
}
