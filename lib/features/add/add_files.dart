part of 'add_screen.dart';

/// PDF and photos: pick and remove. Nothing is uploaded or parsed.
extension _AddFiles on _AddScreenState {
  Future<void> _pickPdf() async {
    if (_picking || _saving || _rec != _Rec.idle || _pdf != null) return;
    _set(() => _picking = true);
    FocusScope.of(context).unfocus();
    try {
      final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
      if (f == null || f.path == null || !mounted) return;
      if (p.extension(f.name).toLowerCase() != '.pdf') {
        showToast(context, 'اختار ملف PDF بس');
        return;
      }
      final bytes = await File(f.path!).length();
      _set(() {
        _pdf = f;
        _pdfBytes = bytes;
      });
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نفتح الملف');
    } finally {
      _set(() => _picking = false);
    }
  }

  void _removePdf() {
    if (_saving) return;
    _set(() => _pdf = null);
  }

  Future<void> _pickImages() async {
    if (_picking || _saving || _rec != _Rec.idle) return;
    _set(() => _picking = true);
    FocusScope.of(context).unfocus();
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (!mounted) return;
      final usable = picked.where((f) => f.path != null);
      _set(() => _images = [..._images, ...usable]);
    } catch (_) {
      if (mounted) showToast(context, 'معرفناش نفتح الصور');
    } finally {
      _set(() => _picking = false);
    }
  }

  void _removeImage(PlatformFile image) {
    if (_saving) return;
    _set(() => _images = [..._images]..remove(image));
  }
}
