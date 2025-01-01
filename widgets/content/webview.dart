import 'package:flutter/material.dart';

import 'package:webviewx_plus/webviewx_plus.dart';

class WebView extends StatefulWidget {
  const WebView({
    super.key,
    this.width,
    this.height,
    required this.url,
    required this.currentLanguage,
  });

  final double? width;
  final double? height;
  final String url;
  final String currentLanguage;

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  WebViewXController? _webviewController;
  late String _themeUrl;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _updateThemeUrl();
  }

  void _updateThemeUrl() {
    try {
      Uri uri = Uri.parse(widget.url);
      List<String> pathSegments = uri.pathSegments.toList();

      int languageIndex = pathSegments
          .indexWhere((segment) => ['en', 'es', 'pt'].contains(segment));
      if (languageIndex != -1) {
        pathSegments[languageIndex] = widget.currentLanguage;
      }

      uri = uri.replace(pathSegments: pathSegments);
      final Map<String, dynamic> queryParams = Map.from(uri.queryParameters);
      queryParams['theme'] = 'light';
      _themeUrl = uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      _errorMessage = 'Error al procesar la URL: $e';
      debugPrint(_errorMessage);
    }
  }

  @override
  void didUpdateWidget(WebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.currentLanguage != widget.currentLanguage) {
      _updateThemeUrl();
      _reloadWebView();
    }
  }

  void _reloadWebView() {
    // Agregar verificación de nulidad
    if (_errorMessage == null && _webviewController != null) {
      _webviewController!.loadContent(
        _themeUrl,
        sourceType: SourceType.url,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width ?? constraints.maxWidth;
        final height = widget.height ?? 400.0;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              WebViewX(
                key: ValueKey(_themeUrl),
                initialContent: _themeUrl,
                initialSourceType: SourceType.url,
                width: width,
                height: height,
                onWebViewCreated: _handleWebViewCreated,
                onWebResourceError: _handleWebViewError,
                javascriptMode: JavascriptMode.unrestricted,
                ignoreAllGestures: false,
                webSpecificParams: const WebSpecificParams(
                  webAllowFullscreenContent: true,
                  printDebugInfo: false,
                ),
                mobileSpecificParams: const MobileSpecificParams(
                  debuggingEnabled: false,
                  gestureNavigationEnabled: false,
                  androidEnableHybridComposition: true,
                ),
              ),
              if (_isLoading)
                const Positioned.fill(
                  child: WebViewAware(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleWebViewCreated(WebViewXController controller) {
    _webviewController = controller;
    if (mounted) {
      Future.microtask(() {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  void _handleWebViewError(WebResourceError error) {
    if (mounted) {
      Future.microtask(() {
        setState(() {
          _errorMessage = error.description;
        });
      });
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: widget.height ?? 400,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _updateThemeUrl();
                  });
                  _reloadWebView();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _webviewController?.dispose();
    super.dispose();
  }
}