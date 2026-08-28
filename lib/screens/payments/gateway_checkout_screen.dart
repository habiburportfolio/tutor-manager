import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../utils/theme.dart';

/// Displays a payment gateway's hosted checkout page (SSLCommerz / bKash /
/// Nagad) inside an in-app WebView, and detects success/fail/cancel by
/// watching the URL for the configured callback markers.
class GatewayCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String gatewayName;

  const GatewayCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.gatewayName,
  });

  @override
  State<GatewayCheckoutScreen> createState() => _GatewayCheckoutScreenState();
}

class _GatewayCheckoutScreenState extends State<GatewayCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (_resolved) return NavigationDecision.navigate;
            if (url.contains('/payment/success') ||
                url.contains('status=success') ||
                url.contains('status=completed')) {
              _resolved = true;
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment/fail') ||
                url.contains('/payment/cancel') ||
                url.contains('status=fail') ||
                url.contains('status=cancel')) {
              _resolved = true;
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gatewayName} Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: kPrimary),
            ),
        ],
      ),
    );
  }
}
