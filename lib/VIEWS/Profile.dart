import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/CONTROLLER/Chat_Service.dart';
import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:SwiftTalk/MODELS/Community.dart';

class ProfilePage extends StatefulWidget {
  final String? UserUID;
  final bool isMe;
  final bool isCommunity;
  final Community? community;
  const ProfilePage(
      {this.isMe = false,
      super.key,
      this.UserUID,
      this.isCommunity = false,
      this.community})
      : assert((UserUID != null && !isCommunity) ||
            (community != null && isCommunity));

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  String? formattedDateTime;
  UserModel? user;
  Community? community;
  List<File> mediaFiles = [];
  bool isLoadingMedia = true;
  bool isJoined = false;
  final _auth = FirebaseAuth.instance;
  String? chatroomId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late bool isDarkMode;
  late ThemeData theme;

  @override
  bool get wantKeepAlive => true;
  Color get primaryColor => isDarkMode ? Color(0xFF128C7E) : Color(0xFF075E54);
  Color get accentColor => isDarkMode ? Color(0xFF25D366) : Color(0xFF25D366);
  Color get cardColor => isDarkMode ? Colors.grey.shade900 : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtitleColor =>
      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
  Color get dividerColor => isDarkMode
      ? Colors.grey.shade700.withOpacity(0.3)
      : Colors.grey.withOpacity(0.3);
  Color get iconColor =>
      isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
  Color get placeholderColor =>
      isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400;

  void getDetails() async {
    try {
      if (widget.isCommunity) {
        setState(() {
          community = widget.community;

          if (community?.createdAt != null) {
            formattedDateTime =
                CustomDateFormat.formatDateTime(community!.createdAt);
          } else {
            formattedDateTime = 'Not available';
          }
          isJoined = community!.members
              .any((member) => member.uid == _auth.currentUser?.uid);
        });
        if (isJoined) {
          chatroomId = "community_${community!.id}";
          loadSharedMedia(chatroomId!);
        }
      } else {
        UserModel? local = await UserRepository().getUserById(widget.UserUID!);
        setState(() {
          user = local;
          if (user?.status is Timestamp) {
            Timestamp timestamp = user?.createdAt as Timestamp;
            formattedDateTime =
                CustomDateFormat.formatDateTime(timestamp.toDate());
          } else if (user?.status is String) {
            formattedDateTime = user?.status;
          } else {
            formattedDateTime = 'Not available';
          }
        });

        if (!widget.isMe) {
          List<String> ids = [widget.UserUID!, _auth.currentUser?.uid ?? ""];
          ids.sort();
          chatroomId = ids.join("_");
          loadSharedMedia(chatroomId!);
        }
      }

      _animationController.forward();
    } catch (e) {
      print('Error fetching details: $e');
      setState(() => formattedDateTime = 'Error loading date');
    }
  }

  Future<void> toggleJoinCommunity() async {}

  Future<void> loadSharedMedia(String chatRoomID) async {
    setState(() => isLoadingMedia = true);
    try {
      List<File> files = [];
      List<String> mediaTypes = [
        'Image',
        'Video',
        'PDF',
        'DOC',
        'DOCX',
        'PPT',
        'PPTX',
        'XLS',
        'XLSX',
        'TXT'
      ];
      for (String type in mediaTypes) {
        Directory? appDir;
        if (Platform.isAndroid) {
          try {
            appDir = await getExternalStorageDirectory();
            if (appDir != null) {
              String mediaPath = "${appDir.path}/$chatRoomID/$type";
              print("Checking for media in: $mediaPath");
              Directory mediaDir = Directory(mediaPath);
              if (await mediaDir.exists()) {
                print("Directory exists: $mediaPath");
                List<FileSystemEntity> entities =
                    await mediaDir.list().toList();
                print("Found ${entities.length} items in $mediaPath");
                for (var entity in entities) {
                  if (entity is File) {
                    print("Added file: ${entity.path}");
                    files.add(entity);
                  }
                }
              } else {
                print("Directory does not exist: $mediaPath");
              }
            }
          } catch (e) {
            print("Failed to get media files from Android: $e");
          }
        } else {
          try {
            appDir = await getApplicationDocumentsDirectory();
            String mediaPath = "${appDir.path}/$chatRoomID/$type";
            print("Checking for media in: $mediaPath");
            Directory mediaDir = Directory(mediaPath);
            if (await mediaDir.exists()) {
              print("Directory exists: $mediaPath");
              List<FileSystemEntity> entities = await mediaDir.list().toList();
              print("Found ${entities.length} items in $mediaPath");
              for (var entity in entities) {
                if (entity is File) {
                  print("Added file: ${entity.path}");
                  files.add(entity);
                }
              }
            } else {
              print("Directory does not exist: $mediaPath");
            }
          } catch (e) {
            print("Failed to get media files from iOS: $e");
          }
        }
      }

      if (files.isEmpty) {
        try {
          Directory? appDir = Platform.isAndroid
              ? await getExternalStorageDirectory()
              : await getApplicationDocumentsDirectory();
          if (appDir != null) {
            print("Checking parent directory: ${appDir.path}/$chatRoomID");
            Directory parentDir = Directory("${appDir.path}/$chatRoomID");
            if (await parentDir.exists()) {
              await _recursiveFindMedia(parentDir, files);
            }
          }
        } catch (e) {
          print("Failed to search parent directory: $e");
        }
      }

      setState(() {
        mediaFiles = files;
        isLoadingMedia = false;
      });
      print("Found total ${mediaFiles.length} media files");
    } catch (e) {
      print("Error loading shared media: $e");
      setState(() => isLoadingMedia = false);
    }
  }

  Future<void> _recursiveFindMedia(Directory dir, List<File> files,
      {int depth = 0}) async {
    if (depth > 3) return;
    try {
      List<FileSystemEntity> entities = await dir.list().toList();
      print("Searching in ${dir.path}, found ${entities.length} items");
      for (var entity in entities) {
        if (entity is File) {
          String ext = path.extension(entity.path).toLowerCase();
          if ([
            '.jpg',
            '.jpeg',
            '.png',
            '.gif',
            '.mp4',
            '.mov',
            '.avi',
            '.pdf',
            '.doc',
            '.docx',
            '.ppt',
            '.pptx',
            '.xls',
            '.xlsx',
            '.txt'
          ].contains(ext)) {
            print("Found media file: ${entity.path}");
            files.add(entity);
          }
        } else if (entity is Directory) {
          await _recursiveFindMedia(entity, files, depth: depth + 1);
        }
      }
    } catch (e) {
      print("Error in recursive search: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.0, 0.5, curve: Curves.easeOut)));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2, 0.7, curve: Curves.easeOut)));
    community = widget.community;
    getDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildHeroImage(String? imageUrl) => Hero(
      tag: widget.isCommunity
          ? 'community-${community?.id}'
          : 'profile-${widget.UserUID}',
      child: CustomCachedNetworkImage(
          imageUrl: imageUrl ?? '', fit: BoxFit.cover));
  Widget _buildMediaThumbnail(File file) {
    final fileExt = path.extension(file.path).toLowerCase();
    final isImage =
        ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(fileExt);
    final isVideo = ['.mp4', '.mov', '.avi', '.mkv'].contains(fileExt);
    final isPdf = ['.pdf'].contains(fileExt);
    final isDoc = ['.doc', '.docx'].contains(fileExt);
    final isPpt = ['.ppt', '.pptx'].contains(fileExt);
    final isExcel = ['.xls', '.xlsx'].contains(fileExt);
    final isTxt = ['.txt'].contains(fileExt);
    return Container(
        decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ]),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (isImage)
            Image.file(file, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
              print("Error loading image: $error");
              return Center(
                  child: Icon(Icons.broken_image, color: placeholderColor));
            })
          else if (isVideo)
            Container(
                color: isDarkMode ? Colors.grey.shade900 : Colors.black,
                child: Center(
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40)))
          else if (isPdf)
            Container(
                color: isDarkMode ? Colors.red.shade900 : Colors.red.shade50,
                child: Center(
                    child: Icon(Icons.picture_as_pdf,
                        color: Colors.red, size: 40)))
          else if (isDoc)
            Container(
                color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                child: Center(
                    child:
                        Icon(Icons.description, color: Colors.blue, size: 40)))
          else if (isPpt)
            Container(
                color:
                    isDarkMode ? Colors.orange.shade900 : Colors.orange.shade50,
                child: Center(
                    child:
                        Icon(Icons.slideshow, color: Colors.orange, size: 40)))
          else if (isExcel)
            Container(
                color:
                    isDarkMode ? Colors.green.shade900 : Colors.green.shade50,
                child: Center(
                    child:
                        Icon(Icons.table_chart, color: Colors.green, size: 40)))
          else if (isTxt)
            Container(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                child: Center(
                    child: Icon(Icons.article,
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        size: 40)))
          else
            Container(
                color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
                child: Center(
                    child: Icon(Icons.insert_drive_file,
                        color: Colors.blue, size: 40))),
          if (!isImage)
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    color: Colors.black.withOpacity(0.6),
                    child: Text(
                        Uri.decodeComponent(path
                            .basename(file.path)
                            .replaceFirst(RegExp(r'^\d+_'), '')),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)))
        ]));
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primaryColor,
                letterSpacing: 0.2)),
        if (trailing != null) trailing
      ]));

  Widget _buildAnimatedSection(Widget child, {double delay = 0.0}) =>
      FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(position: _slideAnimation, child: child));
  Widget _buildMembersList() {
    if (community == null || community!.members.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child:
                  Text("No members", style: TextStyle(color: subtitleColor))));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader("Members (${community!.memberCount})",
          trailing: widget.isMe
              ? TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Invite members")));
                  },
                  icon: Icon(Icons.person_add, size: 16, color: primaryColor),
                  label: Text("INVITE", style: TextStyle(color: primaryColor)),
                )
              : null),
      ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount:
              community!.members.length > 5 ? 5 : community!.members.length,
          itemBuilder: (context, index) {
            final member = community!.members[index];
            final isAdmin = member.uid == community!.createdBy;
            return ListTile(
                leading: CircleAvatar(
                    backgroundImage: member.photoURL.isNotEmpty
                        ? NetworkImage(member.photoURL)
                        : null,
                    child: member.photoURL.isEmpty
                        ? Text(member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : "?")
                        : null),
                title: Text(member.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textColor)),
                subtitle: Text(isAdmin ? "Admin" : "Member",
                    style: TextStyle(
                        color: isAdmin ? primaryColor : subtitleColor)),
                trailing: widget.isMe &&
                        !isAdmin &&
                        _auth.currentUser?.uid == community!.createdBy
                    ? IconButton(
                        icon: Icon(Icons.more_vert, color: iconColor),
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                  color: cardColor,
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                            leading: Icon(
                                                Icons.remove_circle_outline,
                                                color: Colors.red),
                                            title: Text("Remove from community",
                                                style: TextStyle(
                                                    color: textColor)),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "Member removal not implemented")));
                                            }),
                                        ListTile(
                                            leading: Icon(
                                                Icons.admin_panel_settings,
                                                color: primaryColor),
                                            title: Text("Make admin",
                                                style: TextStyle(
                                                    color: textColor)),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          "Admin promotion not implemented")));
                                            })
                                      ])));
                        })
                    : null);
          }),
      if (community!.members.length > 5)
        Center(
            child: TextButton(
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        maxChildSize: 0.9,
                        minChildSize: 0.5,
                        expand: false,
                        builder: (context, scrollController) => Container(
                            color: cardColor,
                            child: Column(children: [
                              Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                      "All Members (${community!.memberCount})",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textColor))),
                              Divider(color: dividerColor),
                              Expanded(
                                  child: ListView.builder(
                                      controller: scrollController,
                                      itemCount: community!.members.length,
                                      itemBuilder: (context, index) {
                                        final member =
                                            community!.members[index];
                                        final isAdmin =
                                            member.uid == community!.createdBy;
                                        return ListTile(
                                            leading: CircleAvatar(
                                                backgroundImage:
                                                    member.photoURL.isNotEmpty
                                                        ? NetworkImage(
                                                            member.photoURL)
                                                        : null,
                                                child: member.photoURL.isEmpty
                                                    ? Text(member.name.isNotEmpty
                                                        ? member.name[0]
                                                            .toUpperCase()
                                                        : "?")
                                                    : null),
                                            title: Text(member.name,
                                                style: TextStyle(
                                                    color: textColor)),
                                            subtitle: Text(
                                                isAdmin ? "Admin" : "Member",
                                                style: TextStyle(
                                                    color: isAdmin
                                                        ? primaryColor
                                                        : subtitleColor)));
                                      }))
                            ])))),
                child: Text("View All Members",
                    style: TextStyle(color: primaryColor))))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    theme = Theme.of(context);
    final callStatusProvider = context.watch<CallStatusProvider>();
    if (callStatusProvider.isCallActive) {
      return const CallScreen();
    }
    if (!widget.isCommunity && user == null) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    if (widget.isCommunity && community == null) {
      return Scaffold(
          body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }
    if (widget.isCommunity) {
      return Scaffold(
          body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
            SliverAppBar(
                expandedHeight: 230,
                backgroundColor: Colors.transparent,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Container(
                        decoration: BoxDecoration(color: Colors.black26),
                        child: community?.imageUrl != null &&
                                community!.imageUrl.isNotEmpty
                            ? ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent
                                      ],
                                      stops: [
                                        0.7,
                                        1.0
                                      ]).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: CustomCachedNetworkImage(
                                    imageUrl: community!.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: primaryColor))),
                                    errorWidget: (context, url, error) =>
                                        Image.asset('assets/logo.png',
                                            fit: BoxFit.cover)))
                            : Image.asset('assets/logo.png',
                                fit: BoxFit.cover))),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop()),
                actions: [
                  if (widget.isMe) // Community admin
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Select community image"),
                              backgroundColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[900],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))));
                          try {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                    type: FileType.image, allowMultiple: false);
                            if (result != null &&
                                result.files.single.path != null) {
                              File imageFile = File(result.files.single.path!);
                              String? imageURL = await S3UploadService()
                                  .uploadFileToS3(
                                      isCommunity: true,
                                      reciverId: community!.id,
                                      file: imageFile,
                                      fileType: "Image",
                                      sendNotification: false);
                              await FirebaseFirestore.instance
                                  .collection('communities')
                                  .doc(community!.id)
                                  .update({'imageUrl': imageURL ?? ''});
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Error picking image: $e'),
                                backgroundColor: Colors.red));
                          }
                        }),
                  PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'share') {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share community')));
                        } else if (value == 'leave') {
                          toggleJoinCommunity();
                        } else if (value == 'report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Report community')));
                        } else if (value == 'delete') {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                      backgroundColor: cardColor,
                                      title: Text("Delete Community?"),
                                      content: Text(
                                          "This action cannot be undone. All messages and shared media will be permanently deleted."),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text("CANCEL")),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Community deletion not implemented')));
                                            },
                                            child: Text("DELETE",
                                                style: TextStyle(
                                                    color: Colors.red)))
                                      ]));
                        }
                      },
                      itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'share', child: Text('Share community')),
                            if (!widget.isMe)
                              const PopupMenuItem(
                                  value: 'leave',
                                  child: Text('Leave community')),
                            if (!widget.isMe)
                              const PopupMenuItem(
                                  value: 'report',
                                  child: Text('Report community')),
                            if (widget.isMe)
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete community',
                                      style: TextStyle(color: Colors.red)))
                          ])
                ]),
            SliverToBoxAdapter(
                child: _buildAnimatedSection(Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 1,
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(community?.name ?? "Community",
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                            letterSpacing: 0.2))),
                                if (widget.isMe)
                                  const Icon(Icons.verified,
                                      color: Color(0xFF25D366), size: 20)
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                Icon(Icons.people, size: 22, color: iconColor),
                                const SizedBox(width: 12),
                                Text("${community?.memberCount ?? 0} members",
                                    style: TextStyle(
                                        fontSize: 18, color: textColor))
                              ]),
                              const SizedBox(height: 16),
                              Row(children: [
                                Icon(Icons.date_range,
                                    size: 22, color: iconColor),
                                const SizedBox(width: 12),
                                Text(
                                    "Created ${formattedDateTime ?? 'recently'}",
                                    style: TextStyle(
                                        fontSize: 16, color: subtitleColor))
                              ]),
                              if (!widget.isMe && !isJoined)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16.0),
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8))),
                                            onPressed: toggleJoinCommunity,
                                            child: Text('JOIN COMMUNITY',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))))),
                              const SizedBox(height: 16),
                              if (community?.description != null &&
                                  community!.description.isNotEmpty)
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Description",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: primaryColor)),
                                      const SizedBox(height: 8),
                                      Text(community!.description,
                                          style: TextStyle(
                                              fontSize: 16, color: textColor))
                                    ])
                            ]))))),
            SliverToBoxAdapter(
                child: _buildAnimatedSection(
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: _buildMembersList()),
                    delay: 0.2)),
            if (isJoined)
              SliverToBoxAdapter(
                  child: _buildAnimatedSection(
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader("Shared Media"),
                                const SizedBox(height: 12),
                                isLoadingMedia
                                    ? Center(
                                        child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: CircularProgressIndicator(
                                                color: primaryColor)))
                                    : mediaFiles.isEmpty
                                        ? Center(
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 32.0),
                                                child: Text(
                                                    "No media files shared yet",
                                                    style: TextStyle(
                                                        color: subtitleColor))))
                                        : Container(
                                            height: 120,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 16.0),
                                            child: ListView.builder(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount: mediaFiles.length,
                                                itemBuilder: (context, index) {
                                                  return GestureDetector(
                                                      onTap: () =>
                                                          OpenFile.open(
                                                              mediaFiles[index]
                                                                  .path),
                                                      child: Container(
                                                          width: 120,
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 8.0),
                                                          child:
                                                              _buildMediaThumbnail(
                                                                  mediaFiles[
                                                                      index])));
                                                }))
                              ])),
                      delay: 0.4)),
            if (isJoined)
              SliverToBoxAdapter(
                  child: _buildAnimatedSection(
                      Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(children: [
                            SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    onPressed: () {},
                                    icon: Icon(Icons.message,
                                        color: Colors.white),
                                    label: Text('MESSAGE',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)))),
                            if (!widget.isMe) // Not admin
                              Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: BorderSide(
                                                  color: Colors.red
                                                      .withOpacity(0.5)),
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          onPressed: toggleJoinCommunity,
                                          icon: Icon(Icons.exit_to_app,
                                              color: Colors.red),
                                          label: Text('LEAVE COMMUNITY',
                                              style: TextStyle(fontWeight: FontWeight.bold)))))
                          ])),
                      delay: 0.6))
          ]));
    }

    return Scaffold(
        body:
            CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
      SliverAppBar(
          expandedHeight: 230,
          backgroundColor: Colors.transparent,
          pinned: true,
          stretch: true,
          flexibleSpace: FlexibleSpaceBar(
              stretchModes: [StretchMode.zoomBackground],
              background: _buildHeroImage(user?.photoURL)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop()),
          actions: [
            if (widget.isMe)
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Select profile picture"),
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[900],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                    try {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                              type: FileType.image, allowMultiple: false);
                      if (result != null && result.files.single.path != null) {
                        File imageFile = File(result.files.single.path!);
                        String? imageURL = await S3UploadService()
                            .uploadFileToS3(
                                isCommunity: false,
                                reciverId: _auth.currentUser!.uid,
                                file: imageFile,
                                fileType: "Image",
                                sendNotification: false);
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_auth.currentUser!.uid)
                            .update({'photoURL': imageURL ?? ''});
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error picking image: $e'),
                          backgroundColor: Colors.red));
                    }
                  }),
            if (!widget.isMe)
              PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'report') {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Report user')));
                    } else if (value == 'block') {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Block user')));
                    }
                  },
                  itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'report', child: Text('Report')),
                        const PopupMenuItem(
                            value: 'block', child: Text('Block')),
                      ])
          ]),
      SliverToBoxAdapter(
          child: _buildAnimatedSection(Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 1,
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(user?.name ?? "User",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: 0.2))),
                          const Icon(Icons.verified,
                              color: Color(0xFF25D366), size: 20)
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Icon(Icons.date_range, size: 22, color: iconColor),
                          const SizedBox(width: 12),
                          Text("Joined ${formattedDateTime ?? 'recently'}",
                              style:
                                  TextStyle(fontSize: 16, color: subtitleColor))
                        ]),
                        Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("About",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Text(
                                      user!.description ??
                                          "Hey there, I'm using SwiftTalk",
                                      style: TextStyle(
                                          fontSize: 16, color: textColor))
                                ]))
                      ]))))),
      if (!widget.isMe && chatroomId != null)
        SliverToBoxAdapter(
            child: _buildAnimatedSection(
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader("Shared Media"),
                          const SizedBox(height: 12),
                          isLoadingMedia
                              ? Center(
                                  child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: CircularProgressIndicator(
                                          color: primaryColor)))
                              : mediaFiles.isEmpty
                                  ? Center(
                                      child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 32.0),
                                          child: Text(
                                              "No media files shared yet",
                                              style: TextStyle(
                                                  color: subtitleColor))))
                                  : Container(
                                      height: 120,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: mediaFiles.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                                onTap: () => OpenFile.open(
                                                    mediaFiles[index].path),
                                                child: Container(
                                                    width: 120,
                                                    margin:
                                                        const EdgeInsets.only(
                                                            right: 8.0),
                                                    child: _buildMediaThumbnail(
                                                        mediaFiles[index])));
                                          }))
                        ])),
                delay: 0.4)),
      if (!widget.isMe)
        SliverToBoxAdapter(
            child: _buildAnimatedSection(
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(children: [
                      Expanded(
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {},
                              icon: Icon(Icons.message),
                              label: Text('MESSAGE',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              onPressed: () {},
                              icon: Icon(Icons.call),
                              label: Text('CALL',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))))
                    ])),
                delay: 0.6)),
      if (widget.isMe)
        SliverToBoxAdapter(
            child: _buildAnimatedSection(
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Settings"),
                    Card(
                        margin: const EdgeInsets.all(8.0),
                        elevation: 1,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          ListTile(
                              leading:
                                  Icon(Icons.account_circle, color: iconColor),
                              title: Text("Account",
                                  style: TextStyle(color: textColor)),
                              trailing:
                                  Icon(Icons.chevron_right, color: iconColor),
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Account settings not implemented')))),
                          Divider(color: dividerColor, height: 1),
                          ListTile(
                              leading: Icon(Icons.lock, color: iconColor),
                              title: Text("Privacy",
                                  style: TextStyle(color: textColor)),
                              trailing:
                                  Icon(Icons.chevron_right, color: iconColor),
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Privacy settings not implemented')))),
                          Divider(color: dividerColor, height: 1),
                          ListTile(
                              leading:
                                  Icon(Icons.notifications, color: iconColor),
                              title: Text("Notifications",
                                  style: TextStyle(color: textColor)),
                              trailing:
                                  Icon(Icons.chevron_right, color: iconColor),
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Notification settings not implemented')))),
                          Divider(color: dividerColor, height: 1),
                          ListTile(
                              leading:
                                  Icon(Icons.help_outline, color: iconColor),
                              title: Text("Help",
                                  style: TextStyle(color: textColor)),
                              trailing:
                                  Icon(Icons.chevron_right, color: iconColor),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Help section not implemented')));
                              })
                        ]))
                  ])),
          delay: 0.8,
        ))
    ]));
  }
}
