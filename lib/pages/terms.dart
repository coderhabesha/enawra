import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Terms extends StatefulWidget {
  @override
  TermsState createState() => TermsState();
}

class TermsState extends State<Terms> {

  @override
  void initState() {
    super.initState();

    // if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://veldteck.github.io/terms',
    );
  }
}
