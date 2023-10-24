import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enawra/screens/view_image.dart';
import 'package:enawra/services/push_notifications_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:enawra/models/post.dart';
import 'package:enawra/pages/profile.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:enawra/widgets/indicators.dart';
import 'package:enawra/widgets/userpost.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<DocumentSnapshot> post = [];

  bool isLoading = false;

  bool hasMore = true;

  int documentLimit = 50;

  DocumentSnapshot? lastDocument;

  ScrollController? _scrollController;

  getPosts() async {
    final firebaseMessaging = PushNotificationsService();
    FirebaseMessaging.instance.requestPermission();

    firebaseMessaging.setNotifications();
    if (!hasMore) {
      print('No New Posts');
    }
    if (isLoading) {
      return CircularProgressIndicator();
    }
    setState(() {
      isLoading = true;
    });
    QuerySnapshot? querySnapshot;

    List<dynamic>? f;

    await followingRef.doc(firebaseAuth.currentUser!.uid).get().then((value) => {
          if (value.exists) {f = value['following'], f!.add(currentUserId())}
        });


    var chunks = [];
    int chunkSize = 10;

    if(f != null && f!.isNotEmpty) {
      for (var i = 0; i < f!.length; i += chunkSize) {
        chunks.add(
            f!.sublist(i, i + chunkSize > f!.length ? f!.length : i + chunkSize));
      }


      if (lastDocument == null && f != null) {
        for (var chunk in chunks) {
          querySnapshot = await postRef
              .where("ownerId", whereIn: chunk)
              .orderBy('timestamp', descending: true)
              .limit(documentLimit)
              .get();

          if (querySnapshot != null) {
            if (querySnapshot.docs.length < documentLimit) {
              hasMore = false;
            }

            lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
            post.addAll(querySnapshot.docs);
          }
        }
      } else if (f != null) {
        for (var chunk in chunks) {
          querySnapshot = await postRef
              .where('ownerId', whereIn: chunk)
              .orderBy('timestamp', descending: true)
              .startAfterDocument(lastDocument!)
              .limit(documentLimit)
              .get();
          if (querySnapshot != null) {
            if (querySnapshot.docs.length < documentLimit) {
              hasMore = false;
            }

            lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
            post.addAll(querySnapshot.docs);
          }
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getPosts();
    _scrollController?.addListener(() {
      double maxScroll = _scrollController!.position.maxScrollExtent;
      double currentScroll = _scrollController!.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.25;
      if (maxScroll - currentScroll <= delta) {
        getPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'enawra',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.profile_circled,
              size: 30.0,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) =>
                      Profile(profileId: firebaseAuth.currentUser!.uid),
                ),
              );
            },
          ),
          SizedBox(width: 20.0),
        ],
      ),
      body: isLoading
          ? circularProgress(context)
          : post.isEmpty ? emptyFeed(context) : ListView.builder(
              controller: _scrollController,
              itemCount: post.length,
              itemBuilder: (context, index) {
                PostModel posts = PostModel.fromJson(post[index].data() as Map<String, dynamic>);
                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: UserPost(post: posts),
                );
              },
            ),
    );
  }

  emptyFeed(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Text(
            'Follow people to add posts to your feed',
            textScaleFactor: 1,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void showInSnackBar(String value, context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
