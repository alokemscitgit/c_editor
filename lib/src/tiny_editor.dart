// tiny_mce_editor.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
// The controller class, assumed to be available
import 'tiny_mce_controller.dart'; 
import 'package:universal_html/html.dart' as html;

// Conditional import for stub/web implementation
import 'tiny_mce_stub.dart'
    if (dart.library.html) 'tiny_mce_web.dart' as tinyweb;


class TinyMCEEditor extends StatefulWidget {
  final TinyMCEController controller;
  const TinyMCEEditor({Key? key, required this.controller}) : super(key: key);

  @override
  State<TinyMCEEditor> createState() => _TinyMCEEditorState();
}

class _TinyMCEEditorState extends State<TinyMCEEditor> {
  // 1. Use a unique ID for the HtmlElementView
  final String viewId = 'tinymce_iframe_${DateTime.now().microsecondsSinceEpoch}';
  
  // 2. State to track if the view factory has been registered
  bool _isRegistered = false; 

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Execute registration asynchronously
      _createAndRegisterIframe();
    }
  }

  Future<void> _createAndRegisterIframe() async {
    final htmlContent = await rootBundle.loadString(
      'packages/c_editor/assets/tiny_editor.html', // Ensure this path is correct
    );

    // Call the web-specific function to create and register the iframe
    final iframe = tinyweb.registerTinyMCEIframe(viewId, htmlContent);

    // Attach to controller for communication
    widget.controller.attachWebIframe(iframe as html.IFrameElement);
    
    // 3. Update the state ONLY after the factory has been registered.
    if (mounted) {
      setState(() {
        _isRegistered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // 4. Check the registration state before building HtmlElementView
      if (!_isRegistered) {
        return const Center(child: CircularProgressIndicator());
      }
      
      // Now it's safe to build the HtmlElementView
      // ignore: undefined_prefixed_name
      return SizedBox.expand(
        child: HtmlElementView(viewType: viewId),
      );
    }

    return const Center(child: Text("WebView only works on mobile platforms"));
  }
}