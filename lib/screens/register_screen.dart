import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final TextEditingController
      _nameController =
      TextEditingController();

  final TextEditingController
      _emailController =
      TextEditingController();

  final TextEditingController
      _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color primaryGreen =
      Color(0xFF2E7D32);

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    if (_isLoading) {
      return;
    }

    final String name =
        _nameController.text.trim();

    final String email =
        _emailController.text.trim();

    final String password =
        _passwordController.text;

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (name.isEmpty) {
      _showMessage(
        'Please enter your full name.',
      );
      return;
    }

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please enter a password.',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must be at least 6 characters.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        '================================',
      );
      debugPrint(
        'ECOSCAN REGISTRATION',
      );
      debugPrint(
        'Email: $email',
      );
      debugPrint(
        'Creating Firebase account...',
      );
      debugPrint(
        '================================',
      );

      // ========================================================
      // CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      final UserCredential credential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user =
          credential.user;

      if (user == null) {
        throw Exception(
          'User account could not be created.',
        );
      }

      debugPrint(
        'Firebase account created.',
      );

      // ========================================================
      // SAVE DISPLAY NAME
      // ========================================================

      await user.updateDisplayName(
        name,
      );

      // Refresh Firebase user data.
      await user.reload();

      // ========================================================
      // CREATE FIRESTORE USER PROFILE
      // ========================================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': name,
        'email': email,
        'ecoPoints': 0,
        'totalScans': 0,
        'totalRecycled': 0,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'Firestore profile created.',
      );

      debugPrint(
        '================================',
      );
      debugPrint(
        'REGISTRATION SUCCESSFUL',
      );
      debugPrint(
        'User: ${user.email}',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      /*
       * IMPORTANT:
       *
       * createUserWithEmailAndPassword()
       * automatically signs the new user in.
       *
       * Therefore Firebase authentication changes:
       *
       * null -> User
       *
       * AuthGate in main.dart will detect
       * that change and display HomeScreen.
       *
       * We replace this RegisterScreen with
       * HomeScreen so there is no old login
       * screen underneath it.
       */

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '================================',
      );
      debugPrint(
        'REGISTRATION ERROR',
      );
      debugPrint(
        'Code: ${e.code}',
      );
      debugPrint(
        'Message: ${e.message}',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account already exists with this email.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'Please choose a stronger password.';
          break;

        case 'operation-not-allowed':
          message =
              'Email/password registration is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message =
              'No internet connection. Please check your connection.';
          break;

        default:
          message =
              e.message ??
              'Registration failed. Please try again.';
      }

      _showMessage(message);
    } catch (e) {
      debugPrint(
        '================================',
      );
      debugPrint(
        'UNKNOWN REGISTRATION ERROR',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
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
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F8F5),

      appBar: AppBar(
        backgroundColor:
            primaryGreen,
        foregroundColor:
            Colors.white,

        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(25),

          child: Column(
            children: [

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // ICON
              // ==================================================

              const Icon(
                Icons
                    .person_add_alt_1,
                color:
                    primaryGreen,
                size: 70,
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Join EcoScan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Create an account and start making an impact.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.grey,
                  fontSize: 15,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // NAME
              // ==================================================

              TextField(
                controller:
                    _nameController,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    InputDecoration(
                  labelText:
                      'Full Name',

                  prefixIcon:
                      const Icon(
                    Icons
                        .person_outline,
                    color:
                        primaryGreen,
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey
                              .shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // EMAIL
              // ==================================================

              TextField(
                controller:
                    _emailController,

                keyboardType:
                    TextInputType
                        .emailAddress,

                textInputAction:
                    TextInputAction.next,

                decoration:
                    InputDecoration(
                  labelText:
                      'Email',

                  prefixIcon:
                      const Icon(
                    Icons
                        .email_outlined,
                    color:
                        primaryGreen,
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey
                              .shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // PASSWORD
              // ==================================================

              TextField(
                controller:
                    _passwordController,

                obscureText:
                    _obscurePassword,

                textInputAction:
                    TextInputAction.done,

                onSubmitted:
                    (_) => _register(),

                decoration:
                    InputDecoration(
                  labelText:
                      'Password',

                  prefixIcon:
                      const Icon(
                    Icons
                        .lock_outline,
                    color:
                        primaryGreen,
                  ),

                  suffixIcon:
                      IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },

                    icon: Icon(
                      _obscurePassword
                          ? Icons
                              .visibility
                          : Icons
                              .visibility_off,
                    ),
                  ),

                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          Colors.grey
                              .shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    borderSide:
                        const BorderSide(
                      color:
                          primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // CREATE ACCOUNT BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 55,

                child:
                    ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _register,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        primaryGreen,
                    foregroundColor:
                        Colors.white,

                    disabledBackgroundColor:
                        Colors.grey
                            .shade400,

                    elevation: 2,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),
                  ),

                  child:
                      _isLoading
                          ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                                  CircularProgressIndicator(
                                color:
                                    Colors.white,
                                strokeWidth:
                                    3,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style:
                                  TextStyle(
                                fontSize:
                                    17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // BACK TO LOGIN
              // ==================================================

              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },

                child:
                    const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color:
                        primaryGreen,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // SECURITY
              // ==================================================

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: [
                  Icon(
                    Icons
                        .verified_user_outlined,
                    size: 16,
                    color:
                        primaryGreen,
                  ),

                  SizedBox(
                    width: 6,
                  ),

                  Text(
                    'Secure Firebase authentication',
                    style:
                        TextStyle(
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
    );
  }
}
