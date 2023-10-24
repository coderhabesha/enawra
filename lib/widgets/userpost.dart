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
import 'package:ionicons/ionicons.dart';
// import 'package:flutter_icons/flutter_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserPost extends StatelessWidget {
  final PostModel? post;

  UserPost({this.post});
  final DateTime timestamp = DateTime.now();

  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  final PostService services = PostService();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: () {},
      borderRadius: BorderRadius.circular(10.0),
      child: OpenContainer(
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return Comments(post: post);
        },
        closedElevation: 0.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        onClosed: (v) {},
        closedColor: Theme.of(context).cardColor,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return Stack(
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0.0),
                      topRight: Radius.circular(0.0),
                    ),
                    child: post!.mediaUrl!.isNotEmpty ? CustomImage(
                      imageUrl: post!.mediaUrl!,
                      height: 300.0,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ) : null,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        post!.mediaUrl!.isEmpty ? Visibility(
                          visible: post!.description != null &&
                              post!.description.toString().isNotEmpty,
                          child: Padding(
                            padding: currentUserId() != post!.ownerId ? const EdgeInsets.only(left: 5.0, top: 40.0) : const EdgeInsets.only(left: 5.0, top: 5.0) ,
                            child: Text(
                              '${post?.description ?? ""}',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.caption!.color,
                                  fontSize: 15.0,
                                ),
                              maxLines: 2,
                            ),
                          ),
                        ) : Container(),
                        Padding(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Row(
                            children: [
                              buildLikeButton(),
                              InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () {
                                  Navigator.of(context).push(
                                    CupertinoPageRoute(
                                      builder: (_) => Comments(post: post),
                                    ),
                                  );
                                },
                                child: Icon(
                                  CupertinoIcons.chat_bubble,
                                  size: 25.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: StreamBuilder(
                                  stream: likesRef
                                      .where('postId', isEqualTo: post!.postId)
                                      .snapshots(),
                                  builder: (context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    if (snapshot.hasData) {
                                      QuerySnapshot snap = snapshot.data!;
                                      List<DocumentSnapshot> docs = snap.docs;
                                      return buildLikesCount(
                                          context, docs?.length ?? 0);
                                    } else {
                                      return buildLikesCount(context, 0);
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 5.0),
                            StreamBuilder(
                              stream: commentRef
                                  .doc(post!.postId)
                                  .collection("comments")
                                  .snapshots(),
                              builder: (context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasData) {
                                  QuerySnapshot snap = snapshot.data!;
                                  List<DocumentSnapshot> docs = snap.docs;
                                  return buildCommentsCount(
                                      context, docs?.length ?? 0);
                                } else {
                                  return buildCommentsCount(context, 0);
                                }
                              },
                            ),
                          ],
                        ),
                        post!.mediaUrl!.isNotEmpty ? Visibility(
                          visible: post!.description != null &&
                              post!.description.toString().isNotEmpty,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0, top: 3.0),
                            child: Text(
                              '${post?.description ?? ""}',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.caption!.color,
                                fontSize: 15.0,
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ) : Container(),
                        SizedBox(height: 3.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, top: 3.0, bottom: 3.0),
                          child: Text(timeago.format(post!.timestamp!.toDate()),
                              style: TextStyle(fontSize: 10.0)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              buildUser(context),
            ],
          );
        },
      ),
    );
  }

  buildLikeButton() {
    return StreamBuilder(
      stream: likesRef
          .where('postId', isEqualTo: post!.postId)
          .where('userId', isEqualTo: currentUserId())
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> docs = snapshot?.data?.docs ?? [];
          return IconButton(
            onPressed: () {
              if (docs.isEmpty) {
                likesRef.add({
                  'userId': currentUserId(),
                  'postId': post!.postId,
                  'dateCreated': Timestamp.now(),
                });
                addLikesToNotification();
              } else {
                likesRef.doc(docs[0].id).delete();
                services.removeLikeFromNotification(
                    post!.ownerId!, post!.postId!, currentUserId());
              }
            },
            icon: docs.isEmpty
                ? Icon(
                    CupertinoIcons.heart,
                  )
                : Icon(
                    CupertinoIcons.heart_fill,
                    color: Colors.red,
                  ),
          );
        }
        return Container();
      },
    );
  }

  addLikesToNotification() async {
    bool isNotMe = currentUserId() != post!.ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUserId()).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      services.addLikesToNotification("like", user!.firstName!, user!.lastName!, currentUserId(),
          post!.postId!, post!.mediaUrl!, post!.ownerId!, user!.photoUrl!);
    }
  }

  buildLikesCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 7.0),
      child: Text(
        '$count likes',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10.0,
        ),
      ),
    );
  }

  buildCommentsCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 0.5),
      child: Text(
        '-   $count comments',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  buildUser(BuildContext context) {
    bool isMe = currentUserId() == post!.ownerId;
    return StreamBuilder(
      stream: usersRef.doc(post!.ownerId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot snap = snapshot.data as DocumentSnapshot<Object?>;
          UserModel user = UserModel.fromJson(snap.data() as Map<String, dynamic>);
          return Visibility(
            visible: !isMe,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.white60,
                  borderRadius: BorderRadius.zero
                ),
                child: GestureDetector(
                  onTap: () => showProfile(context, profileId: user?.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        user.photoUrl!.isNotEmpty
                            ? CircleAvatar(
                                radius: 14.0,
                                backgroundColor: Color(0xff4D4D4D),
                                backgroundImage: CachedNetworkImageProvider(
                                    user.photoUrl ?? ""),
                              )
                            : CircleAvatar(
                                radius: 14.0,
                                backgroundColor: Color(0xff4D4D4D),
                              ),
                        SizedBox(width: 5.0),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${post?.firstName ?? ""}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff4D4D4D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${post?.location ?? 'enawra'}',
                              style: TextStyle(
                                fontSize: 10.0,
                                color: Color(0xff4D4D4D),
                              ),
                            ),
                          ],
                        ),
                        new Spacer(),
                        IconButton(
                          icon: Icon(Ionicons.close_outline),
                          onPressed: () => handleReport(context),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  handleReport(BuildContext parentContext) {
    //shows a simple dialog box
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0)),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  reportPost();
                },
                child: Text('Report Post'),
              ),
              Divider(),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  blockUser();
                },
                child: Text('Block User'),
              ),
              Divider(),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        });
  }

  reportPost() async {
    await postRef
        .doc(post!.postId)
        .update({"report": FieldValue.arrayUnion(<String>[currentUserId()])});
  }

  blockUser() async {
    await blockedRef
        .doc(currentUserId())
        .set({"block": FieldValue.arrayUnion(<String>[post!.ownerId!])}, SetOptions(merge: true));
  }

  showProfile(BuildContext context, {String? profileId}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => Profile(profileId: profileId),
      ),
    );
  }
}
