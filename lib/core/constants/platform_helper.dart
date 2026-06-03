// Canonical conditional import pattern for cross-platform code.
// Web uses stubs, native uses dart:io.
export 'platform_stub.dart'
    if (dart.library.io) 'platform_native.dart';
