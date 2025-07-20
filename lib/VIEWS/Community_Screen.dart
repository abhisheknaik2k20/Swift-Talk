import 'dart:io';
import 'package:SwiftTalk/CONTROLLER/Chat_Service.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/Community.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:SwiftTalk/VIEWS/Chat_Screen.dart';
import 'package:SwiftTalk/VIEWS/Status_Preview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppStatusCommunityScreen extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const WhatsAppStatusCommunityScreen({super.key, required this.toggleDrawer});

  @override
  State<WhatsAppStatusCommunityScreen> createState() =>
      _WhatsAppStatusCommunityScreenState();
}

class _WhatsAppStatusCommunityScreenState
    extends State<WhatsAppStatusCommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _communitiesStream;
  UserModel? _currentUser;
  List<File> selectedImages = [];
  final S3UploadService _s3 = S3UploadService();
  final UserRepository _userRepository = UserRepository();
  bool isLoading = false;

  getUserData() async => _currentUser =
      await _userRepository.getCurrentUser() ?? _userRepository.errorUser();

  @override
  void initState() {
    super.initState();
    getUserData();
    _communitiesStream = _firestore
        .collection('communities')
        .orderBy('lastActivity', descending: true)
        .limit(20)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Column(children: [
        SizedBox(
            height: 125,
            child: StreamBuilder(
                stream: _userRepository.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  List<UserModel> users = snapshot.data!;
                  return ListView(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildMyStatusCircle(),
                        ...users.map((user) => _buildStatusCircle(user))
                      ]);
                })),
        Divider(height: 1),
        Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _communitiesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle),
                              child: Icon(Icons.people_outline,
                                  size: 60, color: Color(0xFF128C7E))),
                          SizedBox(height: 20),
                          Text('Join the conversation!',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800])),
                          SizedBox(height: 10),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                  'You\'re not part of any communities yet. Create or join a community to connect with others.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]))),
                          SizedBox(height: 25)
                        ]));
                  }
                  List<Community> communities = snapshot.data!.docs
                      .map((doc) => Community.fromFirestore(doc))
                      .toList();
                  final currentUserUid = _currentUser?.toMap()['uid'];
                  final userCommunities = communities.where((community) {
                    return (community.toMap()['members'] as List)
                        .any((member) => member['uid'] == currentUserUid);
                  }).toList();
                  if (userCommunities.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: Icon(Icons.people_outline,
                                  size: 60, color: Color(0xFF128C7E))),
                          SizedBox(height: 20),
                          Text('Join the conversation!',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800])),
                          SizedBox(height: 10),
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                  'You\'re not part of any communities yet. Create or join a community to connect with others.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[600]))),
                          SizedBox(height: 25)
                        ]));
                  }

                  return ListView(children: [
                    _buildCommunityHeader(),
                    ...userCommunities
                        .map((community) => _buildCommunityItem(community))
                  ]);
                }))
      ]),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal,
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Icon(Icons.group_add, color: Colors.white),
          onPressed: () async {
            if (isLoading) return;
            try {
              setState(() => isLoading = true);
              List<UserModel> allUsers =
                  await _userRepository.getAllUsersOnce();
              if (allUsers.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('No users available to create groups')));
                setState(() => isLoading = false);
                return;
              }
              showDialog(
                context: context,
                builder: (context) => CreateCommunityDialog(
                    users: allUsers,
                    currentUser: _currentUser!,
                    onCommunityCreated: () =>
                        setState(() => isLoading = false)),
              ).then((_) => setState(() => isLoading = false));
            } catch (e) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading users: $e')));
            }
          }));

  Widget _buildMyStatusCircle() => GestureDetector(
      onTap: () async {
        UserModel? user = await _userRepository.getCurrentUser();
        if (user == null) return;
        if (user.statusImages == null || user.statusImages!.isEmpty) {
          try {
            setState(() => isLoading = true);
            FilePickerResult? result = await FilePicker.platform
                .pickFiles(type: FileType.image, allowMultiple: true);
            if (result == null || result.files.isEmpty) {
              setState(() => isLoading = false);
              return;
            }
            final files = result.files
                .where((file) => file.path != null)
                .map((file) => File(file.path!))
                .toList();
            if (files.isEmpty) {
              setState(() => isLoading = false);
              return;
            }
            final urls = await Future.wait(files.map((file) =>
                _s3.uploadFileToS3(
                    reciverId: null,
                    file: file,
                    fileType: "Image",
                    sendNotification: false,
                    isCommunity: false)));
            final validUrls = urls.whereType<String>().toList();
            _userRepository.updateStatusImages(
                _currentUser?.uid ?? '', validUrls);
            setState(() => isLoading = false);
            if (validUrls.isNotEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StatusPreviewScreen(user: user)));
            }
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error uploading images: $e')));
          }
        } else {
          if (user.statusImages!.isNotEmpty) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => StatusPreviewScreen(user: user)));
          }
        }
      },
      child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: [
            Stack(children: [
              CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_currentUser?.photoURL ?? '')),
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(Icons.add, color: Colors.white, size: 16)))
            ]),
            SizedBox(height: 4),
            Text('My Status', style: TextStyle(fontSize: 12))
          ])));

  Widget _buildStatusCircle(UserModel user) {
    if (user.statusImages == null || user.statusImages!.isEmpty) {
      return Container();
    }
    return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => StatusPreviewScreen(user: user)));
        },
        child: Container(
            width: 75,
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(children: [
              Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF25D366), width: 2)),
                  child: CircleAvatar(
                      radius: 28,
                      backgroundImage: user.photoURL.startsWith('http')
                          ? NetworkImage(user.photoURL) as ImageProvider
                          : AssetImage(user.photoURL))),
              SizedBox(height: 4),
              Text(user.name.split(' ')[0],
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center)
            ])));
  }

  Widget _buildCommunityHeader() => Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Text('Communities',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF128C7E))),
        Spacer(),
        TextButton.icon(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF128C7E)),
            label: Text('New', style: TextStyle(color: Color(0xFF128C7E))),
            onPressed: () {})
      ]));

  Widget _buildCommunityItem(Community community) => ListTile(
      leading: CircleAvatar(
          backgroundImage: community.imageUrl.startsWith('http')
              ? NetworkImage(community.imageUrl) as ImageProvider
              : AssetImage("assets/logo.png"),
          radius: 26),
      title:
          Text(community.name, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Row(children: [
        Icon(Icons.people, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
            child: Text(
                '${community.memberCount} members • ${community.description}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13)))
      ]),
      trailing: Text(_getTimeString(community.lastActivity),
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatPage(
              reciever: UserRepository().errorUser(), community: community))));

  String _getTimeString(DateTime? timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr';
    } else {
      return '${difference.inDays} d';
    }
  }
}

class CreateCommunityDialog extends StatefulWidget {
  final List<UserModel> users;
  final UserModel currentUser;
  final Function onCommunityCreated;
  const CreateCommunityDialog(
      {super.key,
      required this.users,
      required this.currentUser,
      required this.onCommunityCreated});

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final S3UploadService _s3 = S3UploadService();
  String _communityImageUrl = "";
  final List<UserModel> _selectedUsers = [];
  File? _selectedImage;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _selectedUsers.add(widget.currentUser);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.image, allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedImage = File(result.files.single.path!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a community name')));
      return;
    }
    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please select at least one member besides yourself')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_selectedImage != null) {
        final imageUrl = await _s3.uploadFileToS3(
            reciverId: null,
            file: _selectedImage!,
            fileType: "Image",
            sendNotification: false,
            isCommunity: false);
        if (imageUrl is String) _communityImageUrl = imageUrl;
      }
      Community community = Community(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: _communityImageUrl,
          memberCount: _selectedUsers.length,
          lastActivity: DateTime.now(),
          createdBy: widget.currentUser.uid,
          createdAt: DateTime.now(),
          members: _selectedUsers);
      DocumentReference docRef =
          await _firestore.collection('communities').add(community.toMap());
      await docRef.update({'id': docRef.id});
      Navigator.of(context).pop();
      widget.onCommunityCreated();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Community created successfully!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating community: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.arrow_back, color: Colors.teal)),
                  SizedBox(width: 16),
                  Text('New Community',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal))
                ]),
                SizedBox(height: 10),
                GestureDetector(
                    onTap: _pickImage,
                    child: Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover)
                                  : null),
                          child: _selectedImage == null
                              ? Icon(Icons.camera_alt,
                                  size: 40, color: Colors.grey[600])
                              : null),
                      CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.teal,
                          child:
                              Icon(Icons.edit, size: 16, color: Colors.white))
                    ])),
                SizedBox(height: 24),
                TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Community name',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2)))),
                SizedBox(height: 10),
                TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2))),
                    maxLines: 1),
                SizedBox(height: 24),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Participants: ${_selectedUsers.length}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800]))),
                SizedBox(height: 8),
                Flexible(
                    child: Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.users.length,
                            itemBuilder: (context, index) {
                              final user = widget.users[index];
                              final bool isCurrentUser =
                                  user.uid == widget.currentUser.uid;
                              final bool isSelected =
                                  _selectedUsers.any((u) => u.uid == user.uid);
                              return ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 0),
                                  leading: CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          user.photoURL.startsWith('http')
                                              ? NetworkImage(user.photoURL)
                                                  as ImageProvider
                                              : AssetImage(user.photoURL)),
                                  title: Text(user.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: isCurrentUser ? Text('You') : null,
                                  trailing: isCurrentUser
                                      ? null
                                      : Checkbox(
                                          value: isSelected,
                                          onChanged: (selected) {
                                            setState(() {
                                              if (selected == true) {
                                                _selectedUsers.add(user);
                                              } else {
                                                _selectedUsers.removeWhere(
                                                    (u) => u.uid == user.uid);
                                              }
                                            });
                                          },
                                          activeColor: Colors.teal));
                            }))),
                SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('CANCEL',
                          style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold))),
                  SizedBox(width: 16),
                  ElevatedButton(
                      onPressed: _isLoading ? null : _createCommunity,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24))),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('CREATE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)))
                ])
              ]))));
}
