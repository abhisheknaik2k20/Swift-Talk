import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:SwiftTalk/MODELS/User.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/VIEWS/Chat_Screen.dart';

class MessagesPage extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const MessagesPage({required this.toggleDrawer, super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final _userRepository = UserRepository();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() => _isSearchVisible
      ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'Search users',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearchVisible = false);
                      }),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none))))
      : SizedBox.shrink();

  Widget _buildChatList() => Expanded(
      child: StreamBuilder<List<UserModel>>(
          stream: _userRepository.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Something went wrong',
                      style: TextStyle(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: Colors.teal));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("No Users Found"));
            }

            final users = snapshot.data ?? [];
            return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) =>
                    _buildChatListItem(users[index]));
          }));

  Widget _buildChatListItem(UserModel userData) => ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              userData.photoURL != '' ? NetworkImage(userData.photoURL) : null,
          child: userData.photoURL == ''
              ? Icon(Icons.account_circle, color: Colors.teal, size: 60)
              : null),
      title: Text(userData.username,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      subtitle: Text(userData.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600)),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChatPage(reciever: userData))));

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Column(children: [_buildSearchBar(), _buildChatList()]),
      floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.teal,
          child: Icon(Icons.message, color: Colors.white)));
}
