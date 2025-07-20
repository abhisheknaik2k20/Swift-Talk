import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/Notification.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:SwiftTalk/VIEWS/Chat_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const NotificationPage({required this.toggleDrawer, super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _notificationRepo = NotificationRepository();
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: _buildNotificationList(context));

  Widget _buildNotificationList(BuildContext context) =>
      StreamBuilder<List<NotificationClass>>(
          stream: _notificationRepo.getNotifications(_currentUser!.uid),
          builder: (context, snapshot) {
            final notification = snapshot.data ?? [];
            return CustomScrollView(slivers: [
              if (notification.isNotEmpty)
                SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                  final document = snapshot.data![index];
                  return _buildNotificationItem(document, context);
                }, childCount: snapshot.data!.length))
              else
                SliverFillRemaining(child: _buildEmptyState())
            ]);
          });

  Widget _buildEmptyState() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_none_outlined,
            size: 120, color: Colors.teal.shade300),
        const SizedBox(height: 16),
        Text('No Notifications',
            style: TextStyle(
                fontSize: 22,
                color: Colors.teal.shade800,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 8),
        Text('You\'re all caught up!',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600))
      ]));

  Widget _buildNotificationItem(
      NotificationClass notification, BuildContext context) {
    final typeIcons = {
      'Image': Icons.image,
      'Video': Icons.video_collection,
      'Audio': Icons.audio_file,
      'PDF': Icons.picture_as_pdf,
      'DOC': Icons.description,
      'DOCX': Icons.description,
      'PPT': Icons.slideshow,
      'PPTX': Icons.slideshow,
      'XLS': Icons.table_chart,
      'XLSX': Icons.table_chart,
      'TXT': Icons.text_snippet,
      'text': Icons.chat
    };
    return Dismissible(
        key: Key(notification.id!),
        background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white)),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) => _notificationRepo.deleteNotification(
            _currentUser!.uid, notification.id!),
        child: ListTile(
            onTap: () async {
              try {
                showCircularProgressBar(context);
                UserModel? receiver =
                    await UserRepository().getUserById(notification.senderId);
                Navigator.of(context).pop();
                if (receiver != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChatPage(reciever: receiver)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Error......")));
                }
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.blue,
                    content: Text(error.toString())));
              }
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(typeIcons[notification.type],
                size: 50, color: Colors.teal),
            title: Text("${notification.type} from ${notification.senderName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(height: 4),
              Text(
                  CustomDateFormat.formatDateTime(
                      notification.timestamp.toDate()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
            ])));
  }
}

showCircularProgressBar(BuildContext context) => showDialog(
    context: context,
    builder: (context) =>
        Center(child: CircularProgressIndicator(color: Colors.teal)));
