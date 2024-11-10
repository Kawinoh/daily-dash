import 'package:dailydash/screens/activity_prioritization_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TabController _tabController;
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _name = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    setState(() {
      _email = '';
      _password = '';
      _confirmPassword = '';
      _name = '';
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
      _rememberMe = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final formKey = _tabController.index == 0 ? _loginFormKey : _registerFormKey;
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      formKey.currentState!.save();
      User? user;

      if (_tabController.index == 0) {
        user = await _authService.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } else {
        user = await _authService.registerWithEmailAndPassword(
          email: _email,
          password: _password,
          name: _name,
        );
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityPrioritizationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: size.height * 0.02,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.02),
                    _buildAnimatedLogo(),
                    SizedBox(height: size.height * 0.04),
                    _buildGlassmorphicCard(size),
                    SizedBox(height: size.height * 0.02),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        // Implement terms of service
                      },
                      child: Text(
                        'Terms of Service',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      duration: Duration(seconds: 1),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Hero(
            tag: 'app_logo',
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.schedule,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassmorphicCard(Size size) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: size.height * 0.7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(size.width * 0.06),
              color: Colors.white.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  SizedBox(height: size.height * 0.02),
                  _buildTabs(),
                  SizedBox(height: size.height * 0.03),
                  _buildTabContent(size),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ).createShader(bounds),
          child: Text(
            'Welcome',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please sign in to continue',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.black.withOpacity(0.1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        tabs: [
          Tab(child: _buildTabLabel('LOGIN', Icons.login)),
          Tab(child: _buildTabLabel('REGISTER', Icons.person_add)),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildTabContent(Size size) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: _tabController.index == 0
              ? size.height * 0.35  // Reduced height since we removed social login
              : size.height * 0.45, // Reduced height since we removed social login
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(child: _buildLoginForm()),
            SingleChildScrollView(child: _buildRegisterForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmailField(),
          SizedBox(height: 16),
          _buildPasswordField(),
          SizedBox(height: 8),
          _buildRememberMeAndForgotPassword(),
          SizedBox(height: 24),
          _buildAnimatedSubmitButton('Login'),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameField(),
          SizedBox(height: 16),
          _buildEmailField(),
          SizedBox(height: 16),
          _buildPasswordField(),
          SizedBox(height: 16),
          _buildConfirmPasswordField(),
          SizedBox(height: 24),
          _buildAnimatedSubmitButton('Register'),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      style: GoogleFonts.poppins(),
      decoration: _modernInputDecoration(
        'Full Name',
        Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
      onChanged: (value) => _name = value,
      onSaved: (value) => _name = value!,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      style: GoogleFonts.poppins(),
      decoration: _modernInputDecoration(
        'Email',
        Icons.email_outlined,
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      onChanged: (value) => _email = value,
      onSaved: (value) => _email = value!,
      textInputAction: TextInputAction.next,
      enabled: !_isLoading,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      style: GoogleFonts.poppins(),
      decoration: _modernInputDecoration(
        'Password',
        Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white.withOpacity(0.8),
          ),
          onPressed: _isLoading ? null : () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (_tabController.index == 1 && value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
      onChanged: (value) => _password = value,
      onSaved: (value) => _password = value!,
      textInputAction: _tabController.index == 0 ? TextInputAction.done : TextInputAction.next,
      enabled: !_isLoading,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
        style: GoogleFonts.poppins(),
    decoration: _modernInputDecoration(
    'Confirm Password',
    Icons.lock_outline,
    suffixIcon: IconButton(
    icon: Icon(
    _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    color: Colors.white.withOpacity(0.8),
    ),
    onPressed: _isLoading ? null : () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
    ),
    ),
    obscureText: !_isConfirmPasswordVisible,
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please confirm your password';
    }
    if (value != _password) {
    return 'Passwords do not match';
    }
    return null;
    },
    onChanged: (value) => _confirmPassword = value,
    onSaved: (value) => _confirmPassword = value!,
      textInputAction: TextInputAction.done,
      enabled: !_isLoading,
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _rememberMe = value!),
                fillColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Colors.transparent;
                }),
                checkColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.8)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Remember me',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: _isLoading ? null : () {
            // Implement forgot password functionality
          },
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSubmitButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(
      String label,
      IconData icon, {
        Widget? suffixIcon,
      }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.8),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.8),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.red.withOpacity(0.8),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.1),
      errorStyle: GoogleFonts.poppins(
        color: Colors.red.shade300,
      ),
    );
  }
}