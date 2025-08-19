import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() => runApp(const MaterialApp(home: WebViewExample()));

const String kLocalExamplePage = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Moamalat Payment</title>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js"></script>
  <script src="https://npg.moamalat.net:6006/js/lightbox.js"></script>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      background-color: #f9f9f9;
      padding-top: 100px;
    }
    button {
      padding: 15px 30px;
      font-size: 18px;
      background-color: #007bff;
      color: white;
      border: none;
      border-radius: 8px;
      cursor: pointer;
    }
    button:hover {
      background-color: #0056b3;
    }
  </style>
</head>
<body>
  <h2>Moamalat Lightbox</h2>
  <p>Click the button to initiate payment</p>
  <button onclick="Do()">Pay Now</button>

  <script>
    function Do() {
      callLightbox();
    }

    function callLightbox() {
      var mID = '10765981238'; // Replace with your Merchant ID
      var tID = '34152540';    // Replace with your Terminal ID
      var amount = 100;        // Replace with dynamic amount
      var merchRef = '1234';   // Replace with dynamic reference

      // Merchant secret key in HEX (replace with your real one)
      var merchantKey = "effed1712b370f7d8011092861879bc7";  

      // Parse HEX key into bytes
      var keyBytes = CryptoJS.enc.Hex.parse(merchantKey);

      // Build transaction datetime
      var dt = new Date().YYYYMMDDHHMMSS();

      // String to hash
      var strToHash = 'Amount=' + amount + '000' +
                      '&DateTimeLocalTrxn=' + dt +
                      '&MerchantId=' + mID +
                      '&MerchantReference=' + merchRef +
                      '&TerminalId=' + tID;

      // Generate HMAC-SHA256 secure hash
      var secureHash = CryptoJS.HmacSHA256(strToHash, keyBytes)
                               .toString(CryptoJS.enc.Hex)
                               .toUpperCase();

      console.log("SecureHash:", secureHash);

      // Configure Lightbox
      Lightbox.Checkout.configure = {
        MID: mID,
        TID: tID,
        AmountTrxn: amount + '000',
        MerchantReference: merchRef,
        TrxDateTime: dt,
        SecureHash: secureHash,   // <-- use generated secure hash

        completeCallback: function (data) {
          console.log('Payment complete:', data);
          alert("Payment Successful!");
        },
        errorCallback: function (data) {
          console.error('Payment error:', data);
          alert("Payment Failed.");
        },
        cancelCallback: function () {
          console.warn('Payment cancelled');
          alert("Payment Cancelled.");
        }
      };

      Lightbox.Checkout.showLightbox();
    }

    Object.defineProperty(Date.prototype, 'YYYYMMDDHHMMSS', {
      value: function () {
        function pad2(n) { return (n < 10 ? '0' : '') + n; }
        return this.getFullYear().toString() +
          pad2(this.getMonth() + 1) +
          pad2(this.getDate()) +
          pad2(this.getHours()) +
          pad2(this.getMinutes()) +
          pad2(this.getSeconds());
      }
    });
  </script>
</body>
</html>
''';

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('Loading progress: $progress%');
          },
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(kLocalExamplePage);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moamalat Lightbox Test'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
