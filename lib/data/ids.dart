import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Random v4 id for every row and attachment file.
String newId() => _uuid.v4();
