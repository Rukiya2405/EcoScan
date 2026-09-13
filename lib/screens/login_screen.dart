import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;

  static const Color primaryGreen =
      Color(0xFF2E7D32);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final String email =
          _emailController.text.trim();

      final String password =
          _passwordController.text;

      debugPrint('==============================');
      debugPrint('ECOSCAN LOGIN');
      debugPrint('Email: $email');
      debugPrint('Attempting Firebase login...');
      debugPrint('==============================');

      final UserCredential credential =
          await FirebaseAuth.instance
              .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      debugPrint('==============================');
      debugPrint('LOGIN SUCCESSFUL');
      debugPrint('User: ${user?.email}');
      debugPrint('UID: ${user?.uid}');
      debugPrint('==============================');

      if (!mounted) {
        return;
      }

      if (user != null) {
        /*
         * IMPORTANT:
         *
         * We explicitly navigate to HomeScreen here.
         *
         * This prevents the situation where Firebase login
         * succeeds but the LoginScreen remains visible.
         */

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('==============================');
      debugPrint('LOGIN ERROR');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('==============================');

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
        case 'wrong-password':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message = 'No account exists with this email.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'No internet connection. Please check your connection.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password authentication is not enabled in Firebase.';
          break;

        default:
          message =
              e.message ?? 'Login failed. Please try again.';
      }

      _showError(message);
    } catch (e) {
      debugPrint('==============================');
      debugPrint('UNKNOWN LOGIN ERROR');
      debugPrint('$e');
      debugPrint('==============================');

      if (!mounted) {
        return;
      }

      _showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // CREATE ACCOUNT
  // ============================================================

  void _openRegisterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<void> _forgotPassword() async {
    final String email =
        _emailController.text.trim();

    if (email.isEmpty) {
      _showError(
        'Enter your email address first.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password reset email sent.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.message ??
            'Could not send password reset email.',
      );
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // EMAIL VALIDATOR
  // ============================================================

  String? _emailValidator(String? value) {
    final String email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email.';
    }

    if (!email.contains('@')) {
      return 'Please enter a valid email.';
    }

    return null;
  }

  // ============================================================
  // PASSWORD VALIDATOR
  // ============================================================

  String? _passwordValidator(String? value) {
    final String password =
        value ?? '';

    if (password.isEmpty) {
      return 'Please enter your password.';
    }

    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F8F5),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  // ==================================================
                  // LOGO
                  // ==================================================

                  Container(
                    width: 90,
                    height: 90,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      size: 48,
                      color: primaryGreen,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // TITLE
                  // ==================================================

                  const Text(
                    'Welcome to EcoScan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sign in to continue your\n'
                    'waste management journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // EMAIL LABEL
                  // ==================================================

                  const Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    validator:
                        _emailValidator,
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your email',
                      prefixIcon:
                          const Icon(
                        Icons.email_outlined,
                        color: primaryGreen,
                      ),
                      filled: true,
                      fillColor:
                          Colors.white,
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            const BorderSide(
                          color: primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // PASSWORD LABEL
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _forgotPassword,
                        child:
                            const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color:
                                primaryGreen,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // PASSWORD
                  // ==================================================

                  TextFormField(
                    controller:
                        _passwordController,
                    obscureText:
                        _hidePassword,
                    textInputAction:
                        TextInputAction.done,
                    validator:
                        _passwordValidator,
                    onFieldSubmitted:
                        (_) => _login(),
                    decoration:
                        InputDecoration(
                      hintText:
                          'Enter your password',

                      prefixIcon:
                          const Icon(
                        Icons.lock_outline_rounded,
                        color: primaryGreen,
                      ),

                      suffixIcon:
                          IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword =
                                !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons
                                  .visibility_outlined
                              : Icons
                                  .visibility_off_outlined,
                        ),
                      ),

                      filled: true,
                      fillColor:
                          Colors.white,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            BorderSide.none,
                      ),

                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            BorderSide(
                          color:
                              Colors.grey.shade200,
                        ),
                      ),

                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                        borderSide:
                            const BorderSide(
                          color: primaryGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // LOGIN BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child:
                        ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _login,
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            primaryGreen,
                        foregroundColor:
                            Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade400,
                        elevation: 2,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CREATE ACCOUNT
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _openRegisterScreen,
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 13,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // SECURITY
                  // ==================================================

                  const Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .verified_user_outlined,
                        size: 16,
                        color: primaryGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Secure Firebase authentication',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
