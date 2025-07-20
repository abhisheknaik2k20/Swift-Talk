import 'package:SwiftTalk/CONTROLLER/Call_Provider.dart';
import 'package:SwiftTalk/VIEWS/Community_Screen.dart';
import 'package:SwiftTalk/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/VIEWS/Call_Screen.dart';
import 'package:SwiftTalk/VIEWS/NotificationPage.dart';
import 'package:SwiftTalk/VIEWS/Profile.dart';
import 'package:SwiftTalk/VIEWS/Chat_Bot.dart';
import 'package:SwiftTalk/VIEWS/First_Screen.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class BlackScreen extends StatefulWidget {
  const BlackScreen({super.key});
  @override
  State<BlackScreen> createState() => _BlackScreenState();
}

class _BlackScreenState extends State<BlackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance.collection('users');

  void _toggleDrawer() => _scaffoldKey.currentState!.isDrawerOpen
      ? _scaffoldKey.currentState!.closeDrawer()
      : _scaffoldKey.currentState!.openDrawer();

  void _hideDrawer() => _scaffoldKey.currentState!.isDrawerOpen
      ? _scaffoldKey.currentState!.closeDrawer()
      : null;

  void _navigateTo(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => page));

  Widget _buildDrawerHeader() {
    return StreamBuilder<DocumentSnapshot>(
        stream: _db.doc(_auth.currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
          String profileUrl;
          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            profileUrl =
                userData?['photoURL'] ?? _auth.currentUser?.photoURL ?? '';
          } else {
            profileUrl = _auth.currentUser?.photoURL ?? '';
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                profileUrl.isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(profileUrl), radius: 45)
                    : const CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        radius: 45,
                        child: Icon(Icons.account_circle,
                            size: 65, color: Colors.white)),
                const SizedBox(height: 15),
                Text(_auth.currentUser?.displayName ?? 'Unknown User',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 22),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text(_auth.currentUser?.email ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                    overflow: TextOverflow.ellipsis)
              ]);
        });
  }

  Widget _buildDrawerItem(
          {required IconData icon,
          required String title,
          required VoidCallback onTap,
          Color? iconColor = Colors.grey,
          bool showTrailing = false}) =>
      ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Icon(icon, color: iconColor),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: showTrailing
              ? const Icon(Icons.arrow_forward_ios, size: 16)
              : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)));

  Widget _buildThemeToggle() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: themeProvider.isDarkMode ? Colors.grey : Colors.amber),
            const SizedBox(width: 16),
            Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: const TextStyle(fontWeight: FontWeight.w500))
          ]),
          Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
              activeColor: Colors.teal),
        ]));
  }

  Widget _buildDrawerContent() => Container(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: SafeArea(
          child: Column(children: [
        const SizedBox(height: 30),
        _buildDrawerHeader(),
        const SizedBox(height: 15),
        _buildDrawerItem(
            icon: Icons.home_rounded,
            title: 'Home',
            onTap: () => _hideDrawer(),
            showTrailing: true),
        _buildDrawerItem(
            icon: Icons.account_circle_rounded,
            title: 'Profile',
            onTap: () => _navigateTo(
                ProfilePage(UserUID: _auth.currentUser!.uid, isMe: true)),
            showTrailing: true),
        _buildDrawerItem(
            icon: Icons.computer_rounded,
            title: 'WEB-Login',
            onTap: () {},
            showTrailing: true),
        const Divider(indent: 20, endIndent: 20),
        _buildThemeToggle(),
        const Divider(indent: 20, endIndent: 20),
        _buildDrawerItem(
            icon: Icons.logout,
            title: "Logout",
            onTap: () async => _auth.signOut()),
        const Spacer(),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Terms of Service | Privacy Policy',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                textAlign: TextAlign.center))
      ])));

  @override
  Widget build(BuildContext context) {
    final callStatusProvider = context.watch<CallStatusProvider>();
    Widget mainContent = callStatusProvider.isCallActive
        ? const CallScreen()
        : HomePage(toggleDrawer: _toggleDrawer);
    return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
            width: MediaQuery.of(context).size.width * 0.75,
            child: _buildDrawerContent()),
        body: mainContent);
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleDrawer;
  const HomePage({required this.toggleDrawer, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> valueNotifier = ValueNotifier(1.0);
  final _auth = FirebaseAuth.instance;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _appBarAnimation;
  int _selectedIndex = 0;
  int _previousIndex = 0;
  late List<Map<dynamic, dynamic>> _pagesInfo = [];
  final _navItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
    const BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Status'),
    const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_active), label: 'Notifications'),
    const BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'BOT')
  ];
  double _navBarVal = 1.0;
  bool _showNavBar = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializePagesInfo();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animationController.value = 1.0;
    _appBarAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeApp();
  }

  void _initializePagesInfo() => _pagesInfo = [
        {
          'APPBARINFO': {
            'title': 'CHATS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE': MessagesPage(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': 'STATUS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE':
              WhatsAppStatusCommunityScreen(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': 'NOTIFICATIONS',
            'IconButtons': {
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: Colors.white)),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.white))
            }
          },
          'PAGE': NotificationPage(toggleDrawer: widget.toggleDrawer)
        },
        {
          'APPBARINFO': {
            'title': Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const CircleAvatar(
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.smart_toy_outlined, color: Colors.teal)),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('CHATBOT',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('Online',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[200],
                                fontWeight: FontWeight.bold))
                      ])
                ])
          },
          'PAGE': ChatGPTScreen(valueNotifier: valueNotifier)
        }
      ];

  Future<void> _initializeApp() async {
    await _reloadUser();
    _pageController.addListener(_handlePageChange);
  }

  void _handlePageChange() {
    if (!mounted) return;
    final page = _pageController.page;
    if (page == null) return;
    final distanceToChatBot = (page - 3).abs();
    if (distanceToChatBot <= 1) {
      final animationValue = distanceToChatBot.clamp(0.0, 1.0);
      setState(() {
        _navBarVal = animationValue;
        valueNotifier.value = 1 - animationValue;
        _showNavBar = animationValue > 0.1;
      });
    } else {
      setState(() {
        _navBarVal = 1.0;
        _showNavBar = true;
      });
    }

    final newIndex = page.round();
    if (newIndex != _selectedIndex) {
      _previousIndex = _selectedIndex;
      setState(() => _selectedIndex = newIndex);
      if (!_isAnimating) {
        _isAnimating = true;
        _animationController
            .forward(from: 0.0)
            .then((_) => _isAnimating = false);
      }
    }
  }

  Future<void> _reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.reload();
      await user.getIdToken();
    } catch (_) {}
  }

  void _navigateToPage(int index) {
    if (_selectedIndex == index) return;
    _previousIndex = _selectedIndex;
    _isAnimating = true;
    _animationController.forward(from: 0.0).then((_) => _isAnimating = false);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    valueNotifier.dispose();
    _pageController.removeListener(_handlePageChange);
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTitleWidget(dynamic titleContent) {
    if (titleContent is String) {
      return Text(titleContent,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20));
    } else {
      return titleContent;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    final currentAppBarInfo = _pagesInfo[_selectedIndex]['APPBARINFO'];
    final previousAppBarInfo = _pagesInfo[_previousIndex]['APPBARINFO'];
    final isChatBotPage = _selectedIndex == 3;
    final chatBotPageOffset = _pageController.hasClients &&
            _pageController.page != null
        ? 1.0 - math.min(1.0, math.max(0.0, (3 - _pageController.page!).abs()))
        : (isChatBotPage ? 1.0 : 0.0);
    final animationValue = _isAnimating ? _appBarAnimation.value : 1.0;
    return PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AnimatedBuilder(
            animation: _appBarAnimation,
            builder: (context, child) => AppBar(
                backgroundColor: Colors.teal.shade500,
                elevation: 4 * animationValue,
                toolbarHeight: 50,
                leadingWidth: 56 * (1 - chatBotPageOffset),
                leading: chatBotPageOffset >= 0.99
                    ? null
                    : SizedBox(
                        width: 56 * (1 - chatBotPageOffset),
                        child: Opacity(
                            opacity: 1 - chatBotPageOffset,
                            child: IconButton(
                                icon: Icon(Icons.menu, color: Colors.white),
                                onPressed: widget.toggleDrawer))),
                titleSpacing: 0,
                title: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.only(left: chatBotPageOffset * 16),
                    child: Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        child:
                            Stack(alignment: Alignment.centerLeft, children: [
                          Opacity(
                              opacity: 1 - animationValue,
                              child: Transform.translate(
                                  offset: Offset(-20 * animationValue, 0),
                                  child: _buildTitleWidget(
                                      previousAppBarInfo['title']))),
                          Opacity(
                              opacity: animationValue,
                              child: Transform.translate(
                                  offset: Offset(20 * (1 - animationValue), 0),
                                  child: _buildTitleWidget(
                                      currentAppBarInfo['title'])))
                        ]))),
                actions: currentAppBarInfo.containsKey('IconButtons')
                    ? List<Widget>.from(
                        (currentAppBarInfo['IconButtons'] as Set<IconButton>)
                            .map((button) => Opacity(
                                // Use 1.0 opacity when app is first loaded
                                opacity: _isAnimating ? animationValue : 1.0,
                                child: button)))
                    : [])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: _buildAppBar(),
      body: PageView.builder(
          controller: _pageController,
          itemCount: _pagesInfo.length,
          itemBuilder: (context, index) => AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double page = _pageController.position.haveDimensions
                    ? _pageController.page ?? index.toDouble()
                    : index.toDouble();
                double pageOffset = index - page;
                double gauss =
                    math.exp(-(math.pow(pageOffset.abs() - 0.5, 2) / 0.08));
                return Transform.translate(
                    offset: Offset(0, 30 * pageOffset.abs() * gauss),
                    child: Transform.rotate(
                        angle: pageOffset * 0.05,
                        child: Transform.scale(
                            scale: 1.0 - 0.1 * pageOffset.abs(),
                            child: Opacity(
                                opacity: 1.0 - 0.3 * pageOffset.abs(),
                                child: child))));
              },
              child: _pagesInfo[index]['PAGE'])),
      bottomNavigationBar: _showNavBar
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 72 * _navBarVal,
              color: Colors.grey.shade900,
              child: ClipRect(
                  child: OverflowBox(
                      maxHeight: 72,
                      minHeight: 0,
                      alignment: Alignment.center,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent),
                        child: BottomNavigationBar(
                            currentIndex: _selectedIndex,
                            onTap: _navigateToPage,
                            backgroundColor: Colors.grey.shade900,
                            unselectedItemColor: Colors.grey,
                            selectedItemColor: Colors.white,
                            showSelectedLabels: true,
                            showUnselectedLabels: true,
                            type: BottomNavigationBarType.fixed,
                            selectedFontSize: 12,
                            unselectedFontSize: 12,
                            iconSize: 24,
                            elevation: 0,
                            items: _navItems),
                      ))))
          : const SizedBox.shrink());
}
