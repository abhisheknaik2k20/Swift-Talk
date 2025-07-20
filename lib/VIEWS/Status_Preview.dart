import 'package:SwiftTalk/CONTROLLER/Native_Implement.dart';
import 'package:SwiftTalk/CONTROLLER/User_Repository.dart';
import 'package:flutter/material.dart';
import 'package:SwiftTalk/MODELS/User.dart';

class StatusPreviewScreen extends StatefulWidget {
  final UserModel user;
  const StatusPreviewScreen({super.key, required this.user});

  @override
  State<StatusPreviewScreen> createState() => _StatusPreviewScreenState();
}

class _StatusPreviewScreenState extends State<StatusPreviewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  final UserRepository _userRepository = UserRepository();
  late List<String> _statusImages;
  bool _isDeleting = false;
  @override
  void initState() {
    super.initState();
    _statusImages =
        widget.user.statusImages?.map((status) => status.imageUrl).toList() ??
            [];
    _pageController = PageController();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 5));
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        if (_currentIndex + 1 < _statusImages.length) {
          setState(() {
            _currentIndex += 1;
            _pageController.animateToPage(_currentIndex,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
          _animationController.forward();
        } else {
          if (!_isDeleting) {
            Navigator.of(context).pop();
          }
        }
      }
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrentImage() async {
    if (_statusImages.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _statusImages.length) {
      return;
    }
    setState(() => _isDeleting = true);
    _animationController.stop();
    final String imageToDelete = _statusImages[_currentIndex];
    final int currentIndexBackup = _currentIndex;
    final success =
        await _userRepository.deleteUserStatusImageByUrl(imageToDelete);
    if (success) {
      if (mounted) {
        setState(() {
          _statusImages.removeAt(currentIndexBackup);
          if (_statusImages.isEmpty) {
            _isDeleting = false;
            Navigator.of(context).pop();
            return;
          }
          if (currentIndexBackup >= _statusImages.length) {
            _currentIndex = _statusImages.length - 1;
          } else {
            _currentIndex = currentIndexBackup;
            if (_currentIndex >= _statusImages.length) {
              _currentIndex = _statusImages.length - 1;
            }
          }
          _pageController.jumpToPage(_currentIndex);
          _animationController.reset();
          _animationController.forward();
          _isDeleting = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete status image')));
        setState(() => _isDeleting = false);
        _animationController.forward();
      }
    }
  }

  void _handleTapZone(TapDownDetails details) {
    if (_isDeleting) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    if (tapX < screenWidth / 4) {
      if (_currentIndex > 0) {
        setState(() {
          _currentIndex -= 1;
          _pageController.animateToPage(_currentIndex,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          _animationController.reset();
          _animationController.forward();
        });
      }
    } else if (tapX > 3 * screenWidth / 4) {
      if (_currentIndex + 1 < _statusImages.length) {
        setState(() {
          _currentIndex += 1;
          _pageController.animateToPage(_currentIndex,
              duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          _animationController.reset();
          _animationController.forward();
        });
      } else if (!_isDeleting) {
        Navigator.of(context).pop();
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        GestureDetector(
            onTapDown: _handleTapZone,
            child: PageView.builder(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _statusImages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final String imageUrl = _statusImages[index];
                  return Stack(alignment: Alignment.center, children: [
                    if (imageUrl.startsWith('http'))
                      CustomCachedNetworkImage(
                          imageUrl: imageUrl,
                          imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.fitHeight))),
                          placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.teal)),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.red)))
                    else
                      Image.asset(imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          frameBuilder: (BuildContext context, Widget child,
                              int? frame, bool wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                child: child);
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.error, color: Colors.red)))
                  ]);
                })),
        SafeArea(
            child: SizedBox(
                height: 2,
                child: Row(
                    children: List.generate(
                        _statusImages.length,
                        (index) => Expanded(
                            child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: index < _currentIndex
                                        ? Colors.white
                                        : index == _currentIndex
                                            ? Colors.grey.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.2)),
                                child: index == _currentIndex
                                    ? AnimatedBuilder(
                                        animation: _animationController,
                                        builder: (context, child) {
                                          return FractionallySizedBox(
                                              widthFactor:
                                                  _animationController.value,
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                  color: Colors.white));
                                        })
                                    : null)))))),
        SafeArea(
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  CircleAvatar(
                      backgroundImage: widget.user.photoURL.startsWith('http')
                          ? NetworkImage(widget.user.photoURL) as ImageProvider
                          : AssetImage(widget.user.photoURL),
                      radius: 20),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(widget.user.name,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16))),
                  GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {}, // Empty to just block propagation
                      child: IconButton(
                        icon: Icon(
                            _isDeleting ? Icons.hourglass_top : Icons.delete,
                            color: Colors.white),
                        onPressed: _isDeleting
                            ? null
                            : () {
                                print("DELETE TAPPED");
                                _deleteCurrentImage();
                              },
                      )),
                  GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          }))
                ]))),
        if (_isDeleting)
          Center(
              child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Deleting...', style: TextStyle(color: Colors.white))
                  ])))
      ]));
}
