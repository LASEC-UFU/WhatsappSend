import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart' as win;

import 'app_webview_controller.dart';

/// Implementação para Windows Desktop usando `webview_windows` (WebView2/Edge).
class DesktopWebViewController implements AppWebViewController {
  final _controller = win.WebviewController();
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    await _controller.initialize();
    _initialized = true;
  }

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> loadUrl(String url) => _controller.loadUrl(url);

  @override
  Future<String> executeJavaScript(String script) async {
    final result = await _controller.executeScript(script);
    return result?.toString() ?? '';
  }

  @override
  Widget buildWidget() => win.Webview(_controller);

  @override
  void dispose() => _controller.dispose();
}
