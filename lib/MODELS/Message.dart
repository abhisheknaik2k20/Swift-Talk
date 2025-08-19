import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageAnalysis {
  final String sentiment;
  final double sentimentConfidence;
  final bool isSpam;
  final double spamConfidence;
  final bool isGrammatical;
  final double grammaticalConfidence;
  final Map<String, double> sentimentScores;
  final Map<String, double> spamScores;
  final Map<String, double> grammaticalScores;

  const MessageAnalysis({
    required this.sentiment,
    required this.sentimentConfidence,
    required this.isSpam,
    required this.spamConfidence,
    required this.isGrammatical,
    required this.grammaticalConfidence,
    required this.sentimentScores,
    required this.spamScores,
    required this.grammaticalScores,
  });

  factory MessageAnalysis.fromMap(Map<String, dynamic> map) {
    return MessageAnalysis(
      sentiment: map['sentiment'] ?? 'neutral',
      sentimentConfidence: (map['sentimentConfidence'] ?? 0.0).toDouble(),
      isSpam: map['isSpam'] ?? false,
      spamConfidence: (map['spamConfidence'] ?? 0.0).toDouble(),
      isGrammatical: map['isGrammatical'] ?? true,
      grammaticalConfidence: (map['grammaticalConfidence'] ?? 0.0).toDouble(),
      sentimentScores: Map<String, double>.from(map['sentimentScores'] ?? {}),
      spamScores: Map<String, double>.from(map['spamScores'] ?? {}),
      grammaticalScores:
          Map<String, double>.from(map['grammaticalScores'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentiment': sentiment,
      'sentimentConfidence': sentimentConfidence,
      'isSpam': isSpam,
      'spamConfidence': spamConfidence,
      'isGrammatical': isGrammatical,
      'grammaticalConfidence': grammaticalConfidence,
      'sentimentScores': sentimentScores,
      'spamScores': spamScores,
      'grammaticalScores': grammaticalScores,
    };
  }
}

class Message {
  String? id;
  final String senderName;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final String type;
  final MessageAnalysis? analysis;

  Message(
      {this.id,
      required this.senderName,
      required this.senderId,
      required this.senderEmail,
      required this.receiverId,
      required this.message,
      required this.timestamp,
      required this.type,
      this.analysis});

  factory Message.fromMap(Map<String, dynamic> map, String docId) {
    return Message(
        id: docId,
        senderName: map['senderName'] ?? '',
        senderId: map['senderId'] ?? '',
        senderEmail: map['senderEmail'] ?? '',
        receiverId: map['reciverId'] ?? '',
        message: map['message'] ?? '',
        timestamp: map['timestamp'],
        type: map['type'] ?? 'text',
        analysis: map['analysis'] != null
            ? MessageAnalysis.fromMap(
                Map<String, dynamic>.from(map['analysis']))
            : null);
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
