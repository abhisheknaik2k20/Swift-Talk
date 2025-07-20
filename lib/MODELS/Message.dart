import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String? id;
  final String senderName;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String type;

  Message(
      {this.id,
      required this.senderName,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.type});

  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
        id: docId,
        senderName: map['senderName'] ?? '',
        senderId: map['senderId'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverId: map['reciverId'] ?? '',
        message: map['message'] ?? '',
        timestamp: map['timestamp'],
        type: map['type'] ?? 'text');
  }

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'reciverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'type': type
    };
  }

  Message copyWith(
      {String? id,
      String? senderName,
      String? senderId,
      String? senderEmail,
      String? receiverId,
      String? message,
      Timestamp? timestamp,
      String? type}) {
    return Message(
        id: id ?? this.id,
        senderName: senderName ?? this.senderName,
        senderId: senderId ?? this.senderId,
        senderEmail: senderEmail ?? this.senderEmail,
        receiverId: receiverId ?? this.receiverId,
        message: message ?? this.message,
        timestamp: timestamp ?? this.timestamp,
        type: type ?? this.type);
  }
}

class FileMessage extends Message {
  final String filename;
  int fileSize;

  FileMessage(
      {super.id,
      required super.senderName,
      required super.senderId,
      required super.senderEmail,
      required super.receiverId,
      required super.message,
      required super.timestamp,
      required this.filename,
      required super.type,
      this.fileSize = 0});

  factory FileMessage.fromMap(Map<String, dynamic> map, String docId) {
    return FileMessage(
        id: docId,
        senderName: map['senderName'] ?? '',
        senderId: map['senderId'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverId: map['reciverId'] ?? '',
        message: map['message'] ?? '',
        timestamp: map['timestamp'],
        filename: map['filename'] ?? '',
        type: map['type'],
        fileSize: map['fileSize'] ?? 0);
  }

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {...baseMap, 'filename': filename, 'fileSize': fileSize};
  }
}

class ChatBotMessage {
  final String text;
  final bool isUser;
  final File? imageFile;
  ChatBotMessage({required this.text, required this.isUser, this.imageFile});
}
