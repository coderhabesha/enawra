import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enawra/screens/view_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';
import 'package:enawra/components/chat_bubble.dart';
import 'package:enawra/models/enum/message_type.dart';
import 'package:enawra/models/message.dart';
import 'package:enawra/models/user.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:enawra/view_models/conversation/conversation_view_model.dart';
import 'package:enawra/view_models/user/user_view_model.dart';
import 'package:enawra/widgets/indicators.dart';
import 'package:timeago/timeago.dart' as timeago;

class Conversation extends StatefulWidget {
  final String userId;
  final String chatId;

  const Conversation({@required this.userId, @required this.chatId});

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  TextEditingController messageController = TextEditingController();

  bool isFirst = false;
  String chatId;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      focusNode.unfocus();
    });
    if (widget.chatId == null) {
      isFirst = true;
    } else {
      chatId = widget.chatId;
    }

    messageController.addListener(() {
      if (focusNode.hasFocus && messageController.text.isNotEmpty) {
        setTyping(true);
      } else if (!focusNode.hasFocus ||
          (focusNode.hasFocus && messageController.text.isEmpty)) {
        setTyping(false);
      }
    });
  }

  setTyping(typing) {
    UserViewModel viewModel =
        Provider.of<UserViewModel>(context, listen: false);
    viewModel.setUser();
    var user = Provider.of<UserViewModel>(context, listen: false).user;
    Provider.of<ConversationViewModel>(context, listen: false)
        .setUserTyping(chatId, user, typing);
  }

  @override
  Widget build(BuildContext context) {
    UserViewModel viewModel =
        UserViewModel(); // Provider.of<UserViewModel>(context, listen: false);
    viewModel.setUser();

    var user = Provider.of<UserViewModel>(context, listen: true).user;
    return Consumer<ConversationViewModel>(
        builder: (BuildContext context, viewModel, Widget child) {
      if (isFirst) {
        setUpFirstChat(viewModel);
      }

      return Scaffold(
        key: viewModel.scaffoldKey,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.keyboard_backspace,
            ),
          ),
          elevation: 0.0,
          titleSpacing: 0,
          title: buildName(),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Flexible(
                child: StreamBuilder(
                  stream: messageListStream(chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List messages = snapshot.data.docs;
                      if (messages.isNotEmpty) {
                        viewModel.setReadCount(chatId, user, messages.length);
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        itemCount: messages.length,
                        reverse: true,
                        itemBuilder: (BuildContext context, int index) {
                          Message message = Message.fromJson(
                              messages.reversed.toList()[index].data());
                          return ChatBubble(
                              message: '${message.content}',
                              firstName: '${user.displayName}',
                              time: message?.time,
                              isMe: message?.senderUid == user?.uid,
                              type: message?.type);
                        },
                      );
                    } else {
                      return Center(child: circularProgress(context));
                    }
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  elevation: 10.0,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 100.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.photo_on_rectangle,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () => showPhotoOptions(viewModel, user),
                        ),
                        Flexible(
                          child: TextField(
                            controller: messageController,
                            focusNode: focusNode,
                            style: TextStyle(
                              fontSize: 15.0,
                              color:
                                  Theme.of(context).textTheme.headline6.color,
                            ),
                            autofocus: true,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10.0),
                              enabledBorder: InputBorder.none,
                              border: InputBorder.none,
                              hintText: "Type your message",
                              hintStyle: TextStyle(
                                color:
                                    Theme.of(context).textTheme.headline6.color,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Feather.send,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () {
                            if (messageController.text.trim().isNotEmpty) {
                              sendMessage(viewModel, user);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  _buildOnlineText(
    var user,
    bool typing,
  ) {
    if (user.isOnline) {
      if (typing) {
        return "typing...";
      } else {
        return "online";
      }
    } else {
      return 'last seen ${timeago.format(user.lastSeen.toDate())}';
    }
  }

  buildName() {
    return StreamBuilder(
      stream: usersRef.doc('${widget.userId}').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot documentSnapshot = snapshot.data;
          UserModel user = UserModel.fromJson(documentSnapshot.data());
          return InkWell(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Hero(
                    tag: user.email,
                    child: CircleAvatar(
                      radius: 25.0,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider('${user.photoUrl}')
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(children: [
                        Text(
                          '${user.firstName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                          ),
                        ),
                        new Spacer(),
                        IconButton(
                          icon: Icon(Feather.more_horizontal),
                          onPressed: () => handleReport(context),
                        ),
                      ]),
                      // StreamBuilder(
                      //   stream: chatRef.doc('$chatId').snapshots(),
                      //   builder: (context, snapshot) {
                      //     if (snapshot.hasData) {
                      //       DocumentSnapshot snap = snapshot.data;
                      //       Map data = snap.data() ?? {};
                      //       Map usersTyping = data['typing'] ?? {};
                      //       return Text(
                      //         _buildOnlineText(
                      //           user,
                      //           usersTyping[widget.userId] ?? false,
                      //         ),
                      //         style: TextStyle(
                      //           fontWeight: FontWeight.w400,
                      //           fontSize: 11,
                      //         ),
                      //       );
                      //     } else {
                      //       return SizedBox();
                      //     }
                      //   },
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {},
          );
        } else {
          return Center(child: CircularProgressIndicator());
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

  blockUser() async {
    await blockedRef.doc(currentUserId()).set(
        {"block": FieldValue.arrayUnion(<String>[])}, SetOptions(merge: true));
  }

  showPhotoOptions(ConversationViewModel viewModel, var user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text("Camera"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 0, isImage: true);
              },
            ),
            ListTile(
              title: Text("Gallery"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 1, isImage: true);
              },
            ),
          ],
        );
      },
    );
  }

  setUpFirstChat(ConversationViewModel viewModel) async {
    if (isFirst) {
      print("Sending the first message");
      String id = await viewModel.sendFirstMessage(widget.userId);
      setState(() {
        isFirst = false;
        chatId = id;
      });
    }
  }

  sendMessage(ConversationViewModel viewModel, var user,
      {bool isImage = false, int imageType}) async {
    String msg;
    if (isImage) {
      msg = await viewModel.pickImage(
        source: imageType,
        context: context,
        chatId: chatId,
      );
    } else {
      msg = messageController.text.trim();
      messageController.clear();
    }

    Message message = Message(
      content: '$msg',
      senderUid: user?.uid,
      type: isImage ? MessageType.IMAGE : MessageType.TEXT,
      time: Timestamp.now(),
    );

    if (msg.isNotEmpty) {
      viewModel.sendMessage(
        chatId,
        message,
      );
    }
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef
        .doc(documentId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
  }
}
