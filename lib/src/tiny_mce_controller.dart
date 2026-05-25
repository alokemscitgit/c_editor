import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' as html;

// Controller to communicate with TinyMCE editor
class TinyMCEController {
  WebViewController? _mobileController;
  html.IFrameElement? _webIFrame;

  final StreamController<String> _onMessage = StreamController.broadcast();
  Stream<String> get onMessage => _onMessage.stream;

  bool get isWeb => kIsWeb;

  /// Attach mobile WebViewController
  void attachMobile(WebViewController controller) {
    _mobileController = controller;
  }

  /// Attach web iframe
  void attachWebIframe(html.IFrameElement iframe) {
    _webIFrame = iframe;
    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data == null) return;
      try {
        final parsed = (data is String) ? jsonDecode(data) : data;
        _onMessage.add(jsonEncode(parsed));
      } catch (e) {
        _onMessage.add(data.toString());
      }
    });
  }

  /// Run JS in mobile WebView and get result
  Future<String?> _runJsMobile(String js) async {
    if (_mobileController == null) return null;
    try {
      final result = await _mobileController!.runJavaScriptReturningResult(js);
      if (result == null) return null;
      final r = result.toString();
      if (r.length >= 2 && r.startsWith('"') && r.endsWith('"')) {
        return jsonDecode(r)?.toString();
      }
      return r;
    } catch (_) {
      return null;
    }
  }

  /// Get editor content
  Future<String?> getContent() async {
    if (kIsWeb) {
      final request = jsonEncode({'type': 'getContent'});
      _webIFrame?.contentWindow?.postMessage(request, '*');
      try {
        final event = await onMessage
            .map((s) => jsonDecode(s))
            .firstWhere((m) => m['type'] == 'getContentResult')
            .timeout(Duration(seconds: 3));
        return event['content']?.toString() ?? '';
      } catch (_) {
        return null;
      }
    } else {
      final res = await _runJsMobile("getEditorContent();");
      return res;
    }
  }

  /// Set editor content
  Future<void> setContent(String htmlContent) async {
    final escaped = jsonEncode(htmlContent);
    if (kIsWeb) {
      final req = jsonEncode({'type': 'setContent', 'content': htmlContent});
      _webIFrame?.contentWindow?.postMessage(req, '*');
    } else {
      await _mobileController?.runJavaScript("setEditorContent($escaped);");
    }
  }

  /// Toggle dark mode
  Future<void> toggleDark(bool dark) async {
    if (kIsWeb) {
      final req = jsonEncode({'type': 'toggleDark', 'dark': dark});
      _webIFrame?.contentWindow?.postMessage(req, '*');
    } else {
      await _mobileController?.runJavaScript("toggleDark(${dark ? 'true' : 'false'});");
    }
  }

  void dispose() {
    _onMessage.close();
  }
}
