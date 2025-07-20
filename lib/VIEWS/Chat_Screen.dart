import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/MODELS/Community.dart';
import 'package:SwiftTalk/MODELS/Message.dart';
import 'package:SwiftTalk/MODELS/Message_Bubble.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:SwiftTalk/VIEWS/Profile.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:SwiftTalk/CONTROLLER/Chat_Service.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhatsAppChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final UserModel reciever;
  final String chatroomID;
  final Community? community;
  const WhatsAppChatAppBar(
      {super.key,
      required this.reciever,
      required this.chatroomID,
      this.community});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final currentUserId = auth.currentUser!.uid;
    if (community == null) {
      final ids = [currentUserId, reciever.uid]..sort();
      final chatRoomId = ids.join("_");
      void viewProfile() => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProfilePage(
                  UserUID: reciever.uid,
                  isMe: false,
                  isCommunity: false,
                  community: null)));
      return AppBar(
          backgroundColor: Colors.teal,
          leadingWidth: 30,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop()),
          title: StreamBuilder<DocumentSnapshot>(
              stream: db.collection('users').doc(reciever.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(reciever.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white));
                }
                final userData = snapshot.data!;
                final isOnline = userData['status'] == 'Online';
                return GestureDetector(
                    onTap: viewProfile,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(
                          backgroundImage: NetworkImage(userData['photoURL'] ??
                              'https://default-avatar-url.com/avatar.jpg'),
                          radius: 20),
                      SizedBox(width: 10),
                      Flexible(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(reciever.name,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis),
                            Text(userData['status'] ?? 'Offline',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isOnline
                                        ? Colors.blue[200]
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis)
                          ]))
                    ]));
              }),
          actions: [
            IconButton(
                icon: Icon(Icons.video_call, color: Colors.white),
                onPressed: () => ChatService.initiateCall(
                    chatRoomId, currentUserId, reciever, context)),
            IconButton(
                icon: Icon(Icons.call, color: Colors.white), onPressed: () {}),
            PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (choice) {
                  if (choice == 'View Contact') viewProfile();
                },
                itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'View Contact', child: Text('View Contact')),
                      PopupMenuItem(value: 'Media', child: Text('Media')),
                      PopupMenuItem(value: 'Search', child: Text('Search'))
                    ])
          ]);
    } else {
      return AppBar(
        backgroundColor: Colors.teal,
        leadingWidth: 30,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
        title: GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfilePage(
                        isCommunity: true,
                        UserUID: reciever.uid,
                        isMe: false,
                        community: community))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                  backgroundImage: community!.imageUrl.isEmpty
                      ? const AssetImage('assets/logo.png') as ImageProvider
                      : NetworkImage(community!.imageUrl) as ImageProvider,
                  radius: 20),
              SizedBox(width: 10),
              Flexible(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Text(community!.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    Text('${community!.members.length} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis)
                  ]))
            ])),
        actions: [
          IconButton(
              icon: Icon(Icons.people, color: Colors.white), onPressed: () {}),
          PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'Community Info', child: Text('Community Info')),
                    PopupMenuItem(value: 'Search', child: Text('Search')),
                    PopupMenuItem(value: 'Media', child: Text('Media')),
                    PopupMenuItem(
                        value: 'Report', child: Text('Report Community'))
                  ])
        ],
      );
    }
  }
}

class ChatPage extends StatelessWidget {
  final UserModel reciever;
  final Community? community;
  const ChatPage({super.key, required this.reciever, this.community});
  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }
    return Scaffold(
        appBar: WhatsAppChatAppBar(
            community: community,
            reciever: reciever,
            chatroomID: ([FirebaseAuth.instance.currentUser!.uid, reciever.uid]
                  ..sort())
                .join("_")),
        body: ChatPageContent(reciever: reciever, community: community));
  }
}

class ChatPageContent extends StatefulWidget {
  final UserModel reciever;
  final Community? community;
  const ChatPageContent({super.key, required this.reciever, this.community});
  @override
  State<ChatPageContent> createState() => _ChatPageContentState();
}

class _ChatPageContentState extends State<ChatPageContent> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  bool startcall = false;
  bool shouldListen = false;
  bool speechEnabled = false;
  late String ChatroomID;
  final _uploadService = S3UploadService();

  @override
  void initState() {
    super.initState();
    ChatroomID = widget.community == null
        ? ([_auth.currentUser!.uid, widget.reciever.uid]..sort()).join("_")
        : widget.community!.id;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    HapticFeedback.selectionClick();
    String textmessage = _messageController.text;
    if (textmessage.isEmpty) {
      return;
    }
    _messageController.clear();
    if (widget.community == null) {
      await _chatService.SendMessage(
          message: Message(
              senderName: _auth.currentUser?.displayName ?? '',
              senderId: _auth.currentUser!.uid,
              senderEmail: _auth.currentUser?.email ?? '',
              receiverId: widget.reciever.uid,
              message: textmessage,
              timestamp: Timestamp.now(),
              type: "text"));
    } else {
      await _chatService.sendCommunityMessage(
          Message(
              senderName: _auth.currentUser?.displayName ?? '',
              senderId: _auth.currentUser!.uid,
              senderEmail: _auth.currentUser?.email ?? '',
              receiverId: widget.community!.id,
              message: textmessage,
              timestamp: Timestamp.now(),
              type: "text"),
          widget.community!);
    }
  }

  Future getImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif']);
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'jpg' ||
          result.files.single.extension?.toLowerCase() == 'jpeg' ||
          result.files.single.extension?.toLowerCase() == 'png' ||
          result.files.single.extension?.toLowerCase() == 'gif') {
        _uploadService.uploadFileToS3(
            community: widget.community,
            isCommunity: widget.community != null,
            reciverId: widget.reciever.uid,
            file: file,
            fileType: 'Image',
            sendNotification: true);
      } else {
        print("Unsupported file type");
      }
    }
  }

  Future getVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['gif', 'mp4', 'mov', 'avi']);
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'mp4' ||
          result.files.single.extension?.toLowerCase() == 'mov' ||
          result.files.single.extension?.toLowerCase() == 'avi') {
        _uploadService.uploadFileToS3(
            community: widget.community,
            isCommunity: widget.community != null,
            reciverId: widget.reciever.uid,
            file: file,
            fileType: 'Video',
            sendNotification: true);
      }
    }
  }

  Future getAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'opus', 'aac']);
    if (result != null) {
      File file = File(result.files.single.path!);
      if (result.files.single.extension?.toLowerCase() == 'mp3' ||
          result.files.single.extension?.toLowerCase() == 'm4a' ||
          result.files.single.extension?.toLowerCase() == 'opus' ||
          result.files.single.extension?.toLowerCase() == 'aac') {
        _uploadService.uploadFileToS3(
            community: widget.community,
            isCommunity: widget.community != null,
            file: file,
            fileType: 'Audio',
            reciverId: widget.reciever.uid,
            sendNotification: true);
      }
    }
  }

  Future getDocs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt'
        ]);
    if (result != null) {
      File file = File(result.files.single.path!);
      print(result.files.single.name);
      final allowedExtensions = [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'txt'
      ];

      if (allowedExtensions
          .contains(result.files.single.extension?.toLowerCase())) {
        _uploadService.uploadFileToS3(
            community: widget.community,
            isCommunity: widget.community != null,
            file: file,
            fileType: result.files.single.extension!.toUpperCase(),
            reciverId: widget.reciever.uid,
            sendNotification: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
            child: WhatsAppMessageList(
                recieverUid: widget.reciever.uid,
                scrollController: _scrollController,
                auth: _auth,
                chatService: _chatService,
                context: context,
                chatroomid: ChatroomID,
                community: widget.community)),
        _buildMessageInput()
      ]);

  Widget _buildMessageInput() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: Colors.grey.shade900,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(
            onPressed: _showAttachmentOptions,
            icon: const Icon(Icons.add, color: Colors.grey, size: 28)),
        Expanded(
            child: Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5)),
                child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10)),
                    style: const TextStyle(color: Colors.black87)))),
        Container(
            margin: const EdgeInsets.only(left: 8),
            child: GestureDetector(
                onTap: sendMessage,
                child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 22,
                    child: Icon(Icons.send, color: Colors.white, size: 22))))
      ]));

  void _showAttachmentOptions() {
    showBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        context: context,
        builder: (context) => _buildAttachmentSheet());
  }

  Widget _buildAttachmentSheet() => Container(
      padding: const EdgeInsets.only(top: 20, left: 4, right: 4),
      height: 325,
      decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildOptionTile(
              icon: Icons.image,
              label: 'Gallery',
              color: Colors.green,
              onTap: getImage),
          _buildOptionTile(
              icon: Icons.video_library,
              label: 'Video',
              color: Colors.purple,
              onTap: getVideo),
          _buildOptionTile(
              icon: Icons.audiotrack,
              label: 'Audio',
              color: Colors.orange,
              onTap: getAudio)
        ]),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildOptionTile(
              icon: Icons.file_present,
              label: 'Document',
              color: Colors.blue,
              onTap: getDocs),
          _buildOptionTile(
              icon: Icons.mic, label: 'Audio', color: Colors.pink, onTap: () {})
        ])
      ]));

  Widget _buildOptionTile(
          {required IconData icon,
          required String label,
          required Color color,
          required VoidCallback onTap}) =>
      InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                radius: 40,
                child: Icon(icon, color: color, size: 40)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20))
          ]));
}

class WhatsAppMessageList extends StatelessWidget {
  final String recieverUid, chatroomid;
  final ScrollController _scrollController;
  final FirebaseAuth _auth;
  final ChatService _chatService;
  final BuildContext context;
  final Community? community;
  const WhatsAppMessageList(
      {super.key,
      required this.recieverUid,
      required ScrollController scrollController,
      required FirebaseAuth auth,
      required ChatService chatService,
      required this.context,
      this.community,
      required this.chatroomid})
      : _scrollController = scrollController,
        _auth = auth,
        _chatService = chatService;

  @override
  Widget build(BuildContext context) {
    Stream<List<dynamic>> messageStream;
    if (community != null) {
      messageStream = _chatService.getCommunityMessages(community!.id);
    } else {
      messageStream =
          _chatService.getMessages(_auth.currentUser!.uid, recieverUid);
    }

    return StreamBuilder<List<dynamic>>(
        stream: messageStream,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                          opacity: value,
                          child: Transform.scale(scale: value, child: child));
                    },
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat, size: 100, color: Colors.teal[300]),
                          const SizedBox(height: 20),
                          Text('No messages yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold)),
                          Text('Start a conversation',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold))
                        ])));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut);
            }
          });
          return ListView.builder(
              controller: _scrollController,
              itemCount: snapshot.data!.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return AnimatedMessageItem(
                    index: index,
                    child: GestureDetector(
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          DocumentSnapshot? document =
                              snapshot.data![index] is DocumentSnapshot
                                  ? snapshot.data![index]
                                  : null;
                          if (document != null) showEditBox(document);
                        },
                        child: snapshot.data![index].runtimeType == FileMessage
                            ? FileMessageBubble(
                                message: snapshot.data![index],
                                chatRoomID: chatroomid)
                            : MessageBubble(
                                message: snapshot.data![index],
                                chatRoomID: chatroomid)));
              });
        });
  }

  void showEditBox(DocumentSnapshot document) async {
    TextEditingController textController = TextEditingController();
    await showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Edit Message',
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation1, animation2) => Container(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation =
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
          return ScaleTransition(
              scale:
                  Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
              child: FadeTransition(
                  opacity: animation,
                  child: AlertDialog(
                      backgroundColor: Colors.grey.shade900,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Enter The New Message',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      actions: <Widget>[
                        TextFormField(
                            controller: textController,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.teal,
                            decoration: InputDecoration(
                                hintText: ' Enter Message Here',
                                hintStyle:
                                    TextStyle(color: Colors.grey.shade400),
                                focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white))),
                            autofocus: true),
                        const SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedButton(
                                onPressed: () async {
                                  if (textController.text.isNotEmpty) {
                                    Navigator.of(context).pop();
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('chat_Rooms')
                                          .doc(chatroomid)
                                          .collection('messages')
                                          .doc(document.id)
                                          .update({
                                        'message': textController.text,
                                        'type': 'text',
                                        'edit': true
                                      });
                                    } catch (e) {
                                      print(e);
                                    }
                                  }
                                },
                                child: Text('Done',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.teal.shade500)),
                              )
                            ])
                      ])));
        });
  }
}

class AnimatedMessageItem extends StatelessWidget {
  final Widget child;
  final int index;
  const AnimatedMessageItem(
      {super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation:
          ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1),
      builder: (context, child) {
        return FadeTransition(
            opacity:
                Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
              parent: ModalRoute.of(context)?.animation ??
                  const AlwaysStoppedAnimation(1),
              curve: Interval(
                  0.1 * (index % 10) / 10, // Stagger based on index
                  1.0,
                  curve: Curves.easeOut),
            )),
            child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: ModalRoute.of(context)?.animation ??
                            const AlwaysStoppedAnimation(1),
                        curve: Interval(
                            0.1 * (index % 10) / 10, // Stagger based on index
                            1.0,
                            curve: Curves.easeOut))),
                child: this.child));
      },
      child: child);
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const AnimatedButton(
      {super.key, required this.child, required this.onPressed});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: ElevatedButton(
                  onPressed: widget.onPressed,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: widget.child))));
}
