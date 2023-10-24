import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:enawra/models/user.dart';
import 'package:enawra/screens/view_image.dart';
import 'package:enawra/services/services.dart';
import 'package:enawra/utils/firebase.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

class PostService extends Service {
  String? postId = Uuid().v4();
  String? location;
  Position? position;
  Placemark? placemark;

//uploads profile picture to the users collection
  uploadProfilePicture(File image, User user) async {
    String link = await uploadImage(profilePic, image);
    var ref = usersRef.doc(user.uid);
    ref.update({
      "photoUrl": link,
    });
  }

//uploads post to the post collection
  uploadPost(File image, String description) async {
    String link = "";

    String loc = await getLocation();

    if (image != null) {
      link = await uploadImage(posts, image);
    }

    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    var ref = postRef.doc();
    ref.set({
      "id": ref.id,
      "postId": ref.id,
      "firstName": user!.firstName,
      "lastName": user!.lastName,
      "ownerId": firebaseAuth.currentUser!.uid,
      "mediaUrl": link,
      "description": description ?? "",
      "location": loc ?? "enawra",
      "timestamp": Timestamp.now(),
      "state": usersRef.doc(firebaseAuth.currentUser!.uid)
    }).catchError((e) {
      print(e);
    });
  }

  Future<String> getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    print(permission);
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission rPermission = await Geolocator.requestPermission();
      print(rPermission);
      await getLocation();
    } else {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position!.latitude, position!.longitude);
      placemark = placemarks[0];
      location = " ${placemarks[0].locality}, ${placemarks[0].country}";
    }

    return location!;
  }

  //uploads story to the story collection
  uploadStory(File image, String description) async {
    String link = await uploadImage(posts, image);
    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    var ref = storyRef.doc();
    ref.set({
      "id": ref.id,
      "postId": ref.id,
      "firstName": user!.firstName,
      "lastName": user!.lastName,
      "ownerId": firebaseAuth.currentUser!.uid,
      "mediaUrl": link,
      "description": description ?? "",
      "timestamp": Timestamp.now(),
    }).catchError((e) {
      print(e);
    });
  }

//upload a comment
  uploadComment(String currentUserId, String comment, String postId,
      String ownerId, String mediaUrl) async {
    if (comment.trim().isEmpty) {
      return;
    }

    DocumentSnapshot doc = await usersRef.doc(currentUserId).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    await commentRef.doc(postId).collection("comments").add({
      "firstName": user!.firstName,
      "lastName": user!.lastName,
      "comment": comment,
      "timestamp": Timestamp.now(),
      "userDp": user!.photoUrl,
      "userId": user!.id,
    });
    bool isNotMe = ownerId != currentUserId;

    if (isNotMe) {
      addCommentToNotification("comment", comment, user!.firstName!,
          user!.lastName!, user!.id!, postId, mediaUrl, ownerId, user!.photoUrl!);
    }
  }

//add the comment to notification collection
  addCommentToNotification(
      String type,
      String commentData,
      String firstName,
      String lastName,
      String userId,
      String postId,
      String mediaUrl,
      String ownerId,
      String userDp) async {
    await notificationRef.doc(ownerId).collection('notifications').add({
      "type": type,
      "commentData": commentData,
      "firstName": firstName,
      "lastName": lastName,
      "userId": userId,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

//add the likes to the notfication collection
  addLikesToNotification(String type, String firstName, String lastName, String userId,
      String postId, String mediaUrl, String ownerId, String userDp) async {
    await notificationRef
        .doc(ownerId)
        .collection('notifications')
        .doc(postId)
        .set({
      "type": type,
      "firstName": firstName,
      "lastName": lastName,
      "userId": firebaseAuth.currentUser!.uid,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

  //remove likes from notification
  removeLikeFromNotification(
      String ownerId, String postId, String currentUser) async {
    bool isNotMe = currentUser != ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUser).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(ownerId)
          .collection('notifications')
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }
}
