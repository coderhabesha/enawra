import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_icons/flutter_icons.dart';
import 'package:enawra/chats/conversation.dart';
import 'package:enawra/models/user.dart';
import 'package:enawra/pages/profile.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:enawra/widgets/indicators.dart';
import 'package:ionicons/ionicons.dart';

class SearchPosts extends StatefulWidget {
  @override
  _SearchPostsState createState() => _SearchPostsState();
}

class _SearchPostsState extends State<SearchPosts> {
  User? user;
  TextEditingController searchController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> users = [];
  List<DocumentSnapshot> filteredUsers = [];
  bool loading = true;

  currentUserId() {
    return firebaseAuth.currentUser!.uid;
  }

  getUsers() async {
    QuerySnapshot snap = await usersRef.get();
    List<DocumentSnapshot> doc = snap.docs;
    users = doc;
    filteredUsers = doc;
    setState(() {
      loading = false;
    });
  }

  search(String query) {
    if (query == "") {
      filteredUsers = users;
    } else {
      List userSearch = users.where((userSnap) {
        Map user = userSnap.data() as Map<String, dynamic>;
        String firstName = user['firstName'];
        return firstName.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        filteredUsers = userSearch as List<DocumentSnapshot<Object?>>;
      });
    }
  }

  removeFromList(index) {
    filteredUsers.removeAt(index);
  }

  @override
  void initState() {
    getUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildSearch(),
      ),
      body: buildUsers(),
    );
  }

  buildSearch() {
    return Row(
      children: [
        Container(
          height: 35.0,
          width: MediaQuery.of(context).size.width - 100,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Center(
              child: TextFormField(
                controller: searchController,
                textAlignVertical: TextAlignVertical.center,
                maxLength: 10,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                ],
                textCapitalization: TextCapitalization.sentences,
                onChanged: (query) {
                  search(query);
                },
                decoration: InputDecoration(
                  suffixIcon: GestureDetector(
                    onTap: () {
                      searchController.clear();
                    },
                    child: Icon(Ionicons.close_outline, size: 12.0, color: Colors.black),
                  ),
                  contentPadding: EdgeInsets.only(bottom: 10.0, left: 10.0),
                  border: InputBorder.none,
                  counterText: '',
                  hintText: 'Search names...',
                  hintStyle: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  buildUsers() {
    if (!loading) {
      if (filteredUsers.isEmpty) {
        return Center(
          child: Text("No User Found",
              style: TextStyle(fontWeight: FontWeight.bold)),
        );
      } else {
        return ListView.builder(
          itemCount: filteredUsers.length,
          itemBuilder: (BuildContext context, int index) {
            DocumentSnapshot doc = filteredUsers[index];
            UserModel user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
            if (doc.id == currentUserId()) {
              Timer(Duration(milliseconds: 500), () {
                setState(() {
                  removeFromList(index);
                });
              });
            }
            return Column(
              children: [
                ListTile(
                  onTap: () => showProfile(context, profileId: user.id!),
                  contentPadding: EdgeInsets.symmetric(horizontal: 25.0),
                  leading: CircleAvatar(
                    radius: 35.0,
                    backgroundImage: user.photoUrl!.isNotEmpty ?
                    NetworkImage(user.photoUrl!) : null,
                  ),
                  title: Text(user.firstName!,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => Conversation(
                            userId: doc.id,
                            chatId: null,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 30.0,
                      width: 62.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            'Message',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(),
              ],
            );
          },
        );
      }
    } else {
      return Center(
        child: circularProgress(context),
      );
    }
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