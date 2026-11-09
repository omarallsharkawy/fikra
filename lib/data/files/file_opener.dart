import 'package:open_filex/open_filex.dart';

/// Opens the file at the given path in another app; false if it couldn't.
typedef FileOpener = Future<bool> Function(String path);

Future<bool> openWithSystem(String path) async {
  try {
    return (await OpenFilex.open(path)).type == ResultType.done;
  } catch (_) {
    return false;
  }
}
