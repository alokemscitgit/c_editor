// tiny_mce_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
// New recommended import for platformViewRegistry
import 'dart:ui_web' as ui_web;


// This function creates the iframe, registers it with Flutter Web, and returns the element.
IFrameElement registerTinyMCEIframe(String viewId, String htmlContent) {
  final iframe = IFrameElement()
    ..srcdoc = htmlContent
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%';

  // Register the view factory using the new recommended API (ui_web)
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) => iframe,
  );

  return iframe;
}