// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// #docregion platform_imports
// Import for Android features.
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// #enddocregion platform_imports

void main() => runApp(const MaterialApp(home: WebViewExample()));

const String kLocalExamplePage = '''
<!DOCTYPE html>
<html lang="en">
<head>
<title>Load file or HTML string example</title>
</head>
<body>

<input type="button" onclick="Do()" value="open">
<script src="	https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.5.0/js/bootstrap.bundle.min.js.map"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/4.1.1/crypto-js.min.js" integrity="sha512-E8QSvWZ0eCLGk4km3hxSsNmGWbLtSCSUcewDQPQWZF6pEU8GlT8a5fF32wOl1i8ftdMhssTrF/OhyGWwonTcXA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script src="https://tnpg.moamalat.net:6006/js/lightbox.js"> </script>
 <script>

// use https://npg.moamalat.net:6006/js/lightbox.js in production environment
function Do(){
    callLightbox();
  //   Lightbox.Checkout.showLightbox();
}
function callLightbox() {

    debugger
var mID='10081014649';// use your merchant id here;
var tID='99179395';// use your terminal id here;
var amount=100;
var merchantKey='39636630633731362D663963322D346362642D386531662D633963303432353936373431';//'36323537623434612D656631382D346436652D383930642D393465666365323732363037';// use your key here;
var merchRef='1234';// this will be user as your reference to the transaction you can manage this string by any format

  if (mID === '' || tID === '') {
   
    return;
  }
  //debugger;
  //var dt = new Date().YYYYMMDDHHMMSS();
  var dt = new Date().toGMTString();
  var hmacSHA256 = '';
  
  if(merchantKey)
  {
       merchantKey = hex_to_ascii(merchantKey);
      var strHashData = 'Amount='+amount+'000&DateTimeLocalTrxn='+dt+'&MerchantId='+mID+'&MerchantReference='+merchRef+'&TerminalId='+tID;
      console.log(strHashData);
      hmacSHA256 = CryptoJS.HmacSHA256(strHashData,merchantKey).toString().toUpperCase();
       
      console.log(hmacSHA256);
 }

 
  
  Lightbox.Checkout.configure = {
    MID: mID,
    TID: tID,
    AmountTrxn: amount+'000',
    MerchantReference: merchRef,
    TrxDateTime: dt,
    SecureHash:  hmacSHA256 ,
    completeCallback: function (data) {
      console.log('completed');
      console.log(data);
    },
    errorCallback: function (data) {
      console.log('error');
      console.log(data);
    },
    cancelCallback:function () {
      console.log('cancel');
    }
  };

  Lightbox.Checkout.showLightbox();
}

function hex_to_ascii(str1)
	 {
		var hex  = str1.toString();
		var str = '';
		for (var n = 0; n < hex.length; n += 2) {
			str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
		}
		return str;
	 }
Object.defineProperty(Date.prototype, 'YYYYMMDDHHMMSS', {
    value: function() {
        function pad2(n) {  // always returns a string
            return (n < 10 ? '0' : '') + n;
        }

        return this.getFullYear() +
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

    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadHtmlString(kLocalExamplePage);

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Lightbox example'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
