import 'package:uuid/uuid.dart';

/// Makes a new primary key. Injected so tests can use predictable ids.
typedef IdGenerator = String Function();

const _uuid = Uuid();

/// Random UUID v4 keys, generated on the device so data can sync later
/// (PRD 3).
String newUuid() => _uuid.v4();
