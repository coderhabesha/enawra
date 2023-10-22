import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  String id;
  String postId;
  String ownerId;
  String firstName;
  String lastName;
  String location;
  String description;
  String mediaUrl;
  Timestamp timestamp;
  

  PostModel({
    this.id,
    this.postId,
    this.ownerId,
    this.location,
    this.description,
    this.mediaUrl,
    this.firstName,
    this.lastName,
    this.timestamp,
  });
  PostModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    postId = json['postId'];
    ownerId = json['ownerId'];
    location = json['location'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    description = json['description'];
    mediaUrl = json['mediaUrl'];
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['postId'] = this.postId;
    data['ownerId'] = this.ownerId;
    data['location'] = this.location;
    data['description'] = this.description;
    data['mediaUrl'] = this.mediaUrl;

    data['timestamp'] = this.timestamp;
    data['firstName'] = this.firstName;
    data['lastName'] = this.lastName;
    return data;
  }
}
