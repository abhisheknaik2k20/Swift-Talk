import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/NotificationService.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:math';
import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Map<String, List> mediaConfig = {
  'Video': [
    Icons.video_collection_sharp,
    Colors.blue,
    'Video',
    Colors.blue.shade100
  ],
  'Audio': [Icons.audiotrack, Colors.orange, 'Audio', Colors.yellow.shade100],
  'PDF': [
    Icons.picture_as_pdf,
    Colors.red,
    'PDF Document',
    Colors.red.shade100
  ],
  'DOC': [
    Icons.description,
    Colors.indigo,
    'Word Document',
    Colors.indigo.shade100
  ],
  'DOCX': [
    Icons.description,
    Colors.indigo,
    'Word Document',
    Colors.indigo.shade100
  ],
  'PPT': [
    Icons.slideshow,
    Colors.deepOrange,
    'PowerPoint Presentation',
    Colors.deepOrange.shade100
  ],
  'PPTX': [
    Icons.slideshow,
    Colors.deepOrange,
    'PowerPoint Presentation',
    Colors.deepOrange.shade100
  ],
  'XLS': [
    Icons.table_chart,
    Colors.green,
    'Excel Spreadsheet',
    Colors.lightGreen.shade100
  ],
  'XLSX': [
    Icons.table_chart,
    Colors.green,
    'Excel Spreadsheet',
    Colors.lightGreen.shade100
  ],
  'TXT': [Icons.notes, Colors.grey, 'Text File', Colors.grey.shade200],
};

class MessageBubble extends StatelessWidget {
  final Message message;
  final String chatRoomID;
  const MessageBubble(
      {required this.chatRoomID, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isCurrentUser =
        message.senderId == FirebaseAuth.instance.currentUser!.uid;
    final String formattedTime =
        CustomDateFormat.formatDateTime((message.timestamp).toDate());

    // Theme-adaptive colors
    final bubbleColorUser =
        isDarkMode ? Colors.teal.shade800 : Colors.teal.shade100;
    final bubbleColorOther = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor =
        isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.shade300;
    final highlightColor =
        isDarkMode ? Colors.teal.shade400 : Colors.teal.shade800;
    final timeColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final deletedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;

    return GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBottomSheetDetails(message, isCurrentUser, context);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5),
                      decoration: BoxDecoration(
                          color: isCurrentUser
                              ? bubbleColorUser
                              : bubbleColorOther,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: shadowColor,
                                blurRadius: 2,
                                offset: const Offset(1, 1))
                          ]),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(message.senderName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: highlightColor,
                                          fontSize: 12))),
                            _getMessageContent(message, isDarkMode,
                                deletedTextColor, textColor),
                            const SizedBox(height: 4),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Text(formattedTime,
                                    style: TextStyle(
                                        fontSize: 12, color: timeColor)))
                          ]))
                ])));
  }

  Widget _getMessageContent(Message message, bool isDarkMode,
      Color deletedTextColor, Color textColor) {
    switch (message.type) {
      case "deleted":
        return Text(message.message,
            style: TextStyle(fontSize: 16, color: deletedTextColor));
      case _:
        return Text(message.message,
            style: TextStyle(fontSize: 16, color: textColor));
    }
  }

  void _showBottomSheetDetails(
      Message message, bool isCurrentUser, BuildContext context) {
    final firebase = FirebaseFirestore.instance
        .collection('chat_Rooms')
        .doc(([message.senderId, message.receiverId]..sort()).join("_"))
        .collection("messages");

    // Get theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomSheetBgColor =
        isDarkMode ? const Color(0xFF1F2C34) : Colors.grey.shade100;
    final dividerColor =
        isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final infoRowBgColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final infoLabelColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700;
    final infoValueColor = isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
                color: bottomSheetBgColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              _whatsappInfoRow(Icons.person, "From", message.senderName,
                  infoRowBgColor, infoLabelColor, infoValueColor),
              _whatsappInfoRow(
                  Icons.access_time,
                  "Sent",
                  CustomDateFormat.formatDateTime(message.timestamp.toDate()),
                  infoRowBgColor,
                  infoLabelColor,
                  infoValueColor),
              const SizedBox(height: 24),
              message.type != 'deleted'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          _whatsappActionButton(
                            Icons.reply,
                            "Reply",
                            () => Navigator.pop(context),
                            Colors.blue[700]!,
                          ),
                          _whatsappActionButton(Icons.content_copy, "Copy", () {
                            Clipboard.setData(
                                ClipboardData(text: message.message));
                            Navigator.pop(context);
                          }, Colors.orange[700]!),
                          if (isCurrentUser)
                            _whatsappActionButton(Icons.delete, "Delete",
                                () async {
                              try {
                                await firebase.doc(message.id).update({
                                  "message": "This message was deleted",
                                  'type': 'deleted'
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Message deleted successfully')));
                              } catch (e) {
                                Navigator.pop(context);
                              }
                            }, Colors.red[700]!)
                        ])
                  : SizedBox.shrink(),
              const SizedBox(height: 16)
            ])));
  }

  Widget _whatsappActionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ]));
  }

  Widget _whatsappInfoRow(IconData icon, String title, String value,
          Color bgColor, Color labelColor, Color valueColor) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, color: valueColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(color: labelColor, fontSize: 14)),
                  Text(value,
                      style: TextStyle(color: valueColor, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                ]))
          ]));
}

class FileMessageBubble extends StatelessWidget {
  final FileMessage message;
  final String chatRoomID;
  const FileMessageBubble(
      {required this.chatRoomID, required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isCurrentUser =
        message.senderId == FirebaseAuth.instance.currentUser!.uid;
    final String formattedTime =
        CustomDateFormat.formatDateTime((message.timestamp).toDate());

    // Theme-adaptive colors
    final bubbleColorUser =
        isDarkMode ? Colors.teal.shade800 : Colors.teal.shade100;
    final bubbleColorOther = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor =
        isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.shade300;
    final highlightColor =
        isDarkMode ? Colors.teal.shade400 : Colors.teal.shade800;
    final timeColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return GestureDetector(
        onTap: () => _handleMediaTap(message, context),
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showBottomSheetDetails(message, isCurrentUser, context);
        },
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5),
                      decoration: BoxDecoration(
                          color: isCurrentUser
                              ? bubbleColorUser
                              : bubbleColorOther,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: shadowColor,
                                blurRadius: 2,
                                offset: const Offset(1, 1))
                          ]),
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(message.senderName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: highlightColor,
                                        fontSize: 12)),
                              ),
                            _getMessageContent(message, isDarkMode),
                            const SizedBox(height: 4),
                            Text(message.filename,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 4),
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Text(formattedTime,
                                    style: TextStyle(
                                        fontSize: 10, color: timeColor)))
                          ]))
                ])));
  }

  Widget _whatsappActionButton(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return InkWell(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ]));
  }

  void _showBottomSheetDetails(
      FileMessage message, bool isCurrentUser, BuildContext context) {
    final firebase = FirebaseFirestore.instance
        .collection('chat_Rooms')
        .doc(([message.senderId, message.receiverId]..sort()).join("_"))
        .collection("messages");
    String formattedSize = _formatFileSize(message.fileSize);

    // Get theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomSheetBgColor =
        isDarkMode ? const Color(0xFF1F2C34) : Colors.grey.shade100;
    final dividerColor =
        isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final infoRowBgColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final infoLabelColor =
        isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700;
    final infoValueColor = isDarkMode ? Colors.white : Colors.black;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
                color: bottomSheetBgColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              _whatsappInfoRow(Icons.person, "From", message.senderName,
                  infoRowBgColor, infoLabelColor, infoValueColor),
              _whatsappInfoRow(
                  Icons.access_time,
                  "Sent",
                  CustomDateFormat.formatDateTime(message.timestamp.toDate()),
                  infoRowBgColor,
                  infoLabelColor,
                  infoValueColor),
              _whatsappInfoRow(
                  Icons.insert_drive_file,
                  "File",
                  message.filename,
                  infoRowBgColor,
                  infoLabelColor,
                  infoValueColor),
              _whatsappInfoRow(Icons.data_usage, "Size", formattedSize,
                  infoRowBgColor, infoLabelColor, infoValueColor),
              const SizedBox(height: 24),
              message.type != 'deleted'
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                          _whatsappActionButton(Icons.reply, "Reply",
                              () => Navigator.pop(context), Colors.blue[700]!),
                          _whatsappActionButton(Icons.download, "Download",
                              () async {
                            Navigator.of(context).pop();
                            await NotificationService().downloadFile(
                                message,
                                ([message.senderId, message.receiverId]..sort())
                                    .join("_"));
                          }, Colors.green[700]!),
                          if (isCurrentUser)
                            _whatsappActionButton(Icons.delete, "Delete",
                                () async {
                              try {
                                await firebase.doc(message.id).update({
                                  "message": "This file was deleted",
                                  'type': 'deleted'
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('File deleted successfully')));
                              } catch (e) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        'Error deleting file: ${e.toString()}')));
                              }
                            }, Colors.red[700]!)
                        ])
                  : SizedBox.shrink(),
              const SizedBox(height: 16)
            ])));
  }

  Widget _whatsappInfoRow(IconData icon, String title, String value,
          Color bgColor, Color labelColor, Color valueColor) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, color: valueColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(color: labelColor, fontSize: 14)),
                  Text(value,
                      style: TextStyle(color: valueColor, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                ]))
          ]));

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _getMessageContent(FileMessage message, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black;

    switch (message.type) {
      case 'Image':
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 175,
              height: 175,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(10)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomCachedNetworkImage(imageUrl: message.message)))
        ]);
      case 'Video':
      case 'Audio':
      case 'PDF':
      case 'DOC':
      case 'DOCX':
      case 'PPT':
      case 'PPTX':
      case 'XLS':
      case 'XLSX':
      case 'TXT':
        final config = mediaConfig[message.type]!;
        final bgColor = isDarkMode ? config[3].withOpacity(0.7) : config[3];

        return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(config[0], color: config[1], size: 50),
                  const SizedBox(height: 10)
                ]));
      default:
        return Text(message.message,
            style: TextStyle(fontSize: 16, color: textColor));
    }
  }

  void _handleMediaTap(FileMessage message, BuildContext context) async {
    try {
      final fileName = path.basename(Uri.parse(message.message).path);
      String? localFilePath;
      if (Platform.isAndroid) {
        final appDir = await getExternalStorageDirectory();
        final fileDir =
            Directory("${appDir?.path}/$chatRoomID/${message.type}");
        localFilePath = path.join(fileDir.path, fileName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        localFilePath = path.join(appDir.path, fileName);
      }
      final localFile = File(localFilePath);
      if (await localFile.exists()) {
        debugPrint('File exists locally, opening: $localFilePath');
        await OpenFile.open(localFilePath);
      } else {
        debugPrint('File not found locally, starting download');
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) =>
                Center(child: CircularProgressIndicator(color: Colors.teal)));
        final downloadedPath =
            await NotificationService().downloadFile(message, chatRoomID);
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (downloadedPath != null) {
          await OpenFile.open(downloadedPath);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to download file')));
        }
      }
    } catch (error) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      debugPrint('Error handling media tap: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: ${error.toString()}')));
    }
  }
}
