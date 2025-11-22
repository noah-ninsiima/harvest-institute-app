import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuthException
import '../../../services/auth_service.dart'; // Corrected relative path
import '../widgets/role_check_wrapper.dart'; // Corrected relative path
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // For Google Icon

class LoginScreen extends StatefulWidget {
  final String? message; // Optional message, e.g., for unknown roles

  const LoginScreen({super.key, this.message});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSigningUp = false; // To switch between login and signup UI

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      _errorMessage = widget.message;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleCheckWrapper() {
    if (mounted) {
      // Replaces the entire navigation stack, ensuring user cannot go back to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleCheckWrapper()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _handleEmailAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear any previous error message
    });

    try {
      if (_isSigningUp) {
        await _authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      _navigateToRoleCheckWrapper(); // On success, navigate via RoleCheckWrapper
    } on FirebaseAuthException catch (e) {
      String msg;
      if (_isSigningUp) {
        switch (e.code) {
          case 'weak-password': msg = 'The password provided is too weak.'; break;
          case 'email-already-in-use': msg = 'An account already exists for that email.'; break;
          case 'invalid-email': msg = 'The email address is invalid.'; break;
          default: msg = e.message ?? 'An unknown error occurred during sign-up.';
        }
      } else { // Signing In
        switch (e.code) {
          case 'user-not-found': msg = 'No user found for that email.'; break;
          case 'wrong-password': msg = 'Wrong password provided for that user.'; break;
          case 'invalid-email': msg = 'The email address is invalid.'; break;
          default: msg = e.message ?? 'An unknown authentication error occurred.';
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      _navigateToRoleCheckWrapper(); // On success, navigate via RoleCheckWrapper
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Error: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = e.message ?? 'Google Sign-In failed.';
      });
    } catch (e) {
      debugPrint('General Google Sign-In Error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred during Google Sign-In.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSigningUp ? 'Sign Up' : 'Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _handleEmailAuth,
                          child: Text(_isSigningUp ? 'Sign Up' : 'Sign In'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSigningUp = !_isSigningUp; // Toggle between sign-up and sign-in modes
                              _errorMessage = null; // Clear error message on mode switch
                            });
                          },
                          child: Text(
                            _isSigningUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Sign Up',
                          ),
                        ),
                        const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20),
                        ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                          label: const Text('Sign In with Google', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Google brand color
                            minimumSize: const Size(double.infinity, 45), // Make button full width
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
