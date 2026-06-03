import 'dart:io';

/// Native implementation — uses dart:io Platform.
class PlatformHelper {
  PlatformHelper._();
  static bool get isWeb => false;
  static bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  static bool get isMobile =>
      Platform.isAndroid || Platform.isIOS;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get supportsEqualizer => Platform.isAndroid;
}
