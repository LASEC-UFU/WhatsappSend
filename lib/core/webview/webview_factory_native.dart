import 'dart:io' show Platform;

import 'app_webview_controller.dart';
import 'desktop_webview_controller.dart';
import 'mobile_webview_controller.dart';

/// Factory nativa (Android e Windows).
AppWebViewController createWebViewController() {
  if (Platform.isWindows) {
    return DesktopWebViewController();
  }
  return MobileWebViewController();
}
