import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:enawra/components/custom_card.dart';
import 'package:enawra/components/custom_image.dart';
import 'package:enawra/models/post.dart';
import 'package:enawra/models/user.dart';
import 'package:enawra/pages/profile.dart';
import 'package:enawra/screens/comment.dart';
import 'package:enawra/screens/view_image.dart';
import 'package:enawra/services/post_service.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Privacy extends StatefulWidget {
  @override
  PrivacyState createState() => PrivacyState();
}

class PrivacyState extends State<Privacy> {

  @override
  void initState() {
    super.initState();

    // if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://veldteck.github.io/privacy policy',
    );
  }
}