import 'package:SwiftTalk/CONTROLLER/Login_Logic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isDisposed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animationController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        try {
          _animationController.forward();
        } catch (e) {
          print('Animation forward error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLoginSignup() {
    if (mounted) {
      setState(() {
        isLogin = !isLogin;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildLogo(colors),
                      const SizedBox(height: 24),
                      _buildHeader(colors),
                      const SizedBox(height: 16),
                      Expanded(
                          child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                  position: _slideAnimation,
                                  child: ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: SingleChildScrollView(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                            if (!isLogin)
                                              _buildTextField(
                                                  controller: _nameController,
                                                  hint: 'Full Name',
                                                  icon: Icons.person),
                                            if (!isLogin)
                                              const SizedBox(height: 16),
                                            if (!isLogin) _buildPhoneField(),
                                            if (!isLogin)
                                              const SizedBox(height: 16),
                                            _buildTextField(
                                                controller: _emailController,
                                                hint: 'Email',
                                                icon: Icons.email),
                                            const SizedBox(height: 16),
                                            _buildTextField(
                                                controller: _passwordController,
                                                hint: 'Password',
                                                icon: Icons.lock,
                                                isPassword: true),
                                            const SizedBox(height: 24),
                                            _buildActionButton(colors),
                                            if (isLogin)
                                              _buildForgotPassword(colors),
                                            _buildToggleButton(colors),
                                            const SizedBox(height: 24),
                                            if (isLogin)
                                              Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _buildGoogleLogin(colors)
                                                  ])
                                          ]))))))
                    ]))));
  }

  Widget _buildHeader(ColorScheme colors) => FadeTransition(
      opacity: _fadeAnimation,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(isLogin ? 'Welcome Back!' : 'Create Account',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface)),
        const SizedBox(height: 8),
        Text(
            isLogin
                ? 'Enter your email address and password to get access your account'
                : 'Please enter valid information to access your account.',
            style: TextStyle(
                fontSize: 14, color: colors.onSurface.withOpacity(0.7)))
      ]));

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool isPassword = false,
      String? Function(String?)? validator}) {
    return Builder(builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Container(
          decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isFocused
                      ? Colors.teal
                      : colors.onSurface.withOpacity(0.1))),
          child: TextFormField(
              cursorColor: Colors.teal,
              controller: controller,
              obscureText: isPassword && _obscureText,
              validator: validator,
              style: TextStyle(color: colors.onSurface),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onTap: () => setState(() => _isFocused = true),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      TextStyle(color: colors.onSurface.withOpacity(0.5)),
                  prefixIcon:
                      Icon(icon, color: colors.onSurface.withOpacity(0.5)),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: _isFocused
                                  ? Colors.teal
                                  : colors.onSurface.withOpacity(0.5)),
                          onPressed: () {
                            if (mounted) {
                              setState(() => _obscureText = !_obscureText);
                            }
                          })
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  errorStyle: TextStyle(color: Colors.red)),
              onChanged: (_) => setState(() => _isFocused = false)));
    });
  }

  Widget _buildPhoneField() {
    return Builder(builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Container(
          decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.onSurface.withOpacity(0.1))),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(Icons.phone,
                    color: colors.onSurface.withOpacity(0.5))),
            Expanded(
                child: TextField(
                    controller: _phoneController,
                    style: TextStyle(color: colors.onSurface),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        hintText: 'Enter Phone',
                        hintStyle:
                            TextStyle(color: colors.onSurface.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16))))
          ]));
    });
  }

  Widget _buildForgotPassword(ColorScheme colors) => Align(
      alignment: Alignment.center,
      child: TextButton(
          onPressed: () {},
          child: Text('Forgot Password?',
              style:
                  TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))));

  Widget _buildLogo(ColorScheme colors) => ScaleTransition(
      scale: _scaleAnimation,
      child: CircleAvatar(
          radius: 40, backgroundImage: AssetImage('assets/logo.png')));

  Widget _buildActionButton(ColorScheme colors) {
    final authLoadingProvider =
        Provider.of<AuthLoadingProvider>(context, listen: false);
    AuthManager(loadingProvider: authLoadingProvider);
    return ElevatedButton(
        onPressed: () async {
          if (isLogin &&
              _emailController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty) {
            AuthManager(loadingProvider: authLoadingProvider).emailpassLogin(
                _emailController.text, _passwordController.text, context);
          }
          if (_emailController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty &&
              _phoneController.text.isNotEmpty &&
              _nameController.text.isNotEmpty) {
            AuthManager(loadingProvider: authLoadingProvider).emailpassSignup(
                _nameController.text,
                _phoneController.text,
                _emailController.text,
                _passwordController.text,
                context);
          }
        },
        style: ElevatedButton.styleFrom(
            foregroundColor: colors.onPrimary,
            backgroundColor: Colors.teal,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(isLogin ? 'Login' : 'Create',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
        ]));
  }

  Widget _buildGoogleLogin(ColorScheme colors) {
    final authLoadingProvider =
        Provider.of<AuthLoadingProvider>(context, listen: false);
    AuthManager(loadingProvider: authLoadingProvider);
    return GestureDetector(
        onTap: () => AuthManager(loadingProvider: authLoadingProvider)
            .implementGoogleSignIn(context),
        child: Image.asset('assets/google.png', width: 175));
  }

  Widget _buildToggleButton(ColorScheme colors) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(
          isLogin ? 'Don\'t have an account?' : 'Already have an account?',
          style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
        ),
        TextButton(
            onPressed: _toggleLoginSignup,
            child: Text(isLogin ? 'Create account' : 'Login',
                style:
                    TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)))
      ]);
}
