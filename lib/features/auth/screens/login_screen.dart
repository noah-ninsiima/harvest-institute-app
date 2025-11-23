import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuthException
import 'package:cloud_functions/cloud_functions.dart'; // For calling setUserRole
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

  // TEMPORARY DEBUG FUNCTION
  Future<void> _showRoleFixDialog() async {
    final uidController = TextEditingController();
    String selectedRole = 'student';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug: Set User Role'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: uidController,
                decoration: const InputDecoration(labelText: 'User UID'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'instructor', child: Text('Instructor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedRole = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = uidController.text.trim();
              if (uid.isEmpty) return;

              try {
                final callable = FirebaseFunctions.instance.httpsCallable('setUserRole');
                await callable.call({'uid': uid, 'role': selectedRole});
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Role updated! User must re-login.')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Set Role'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Use theme values
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Dark Navy
    final accentColor = theme.colorScheme.secondary; // Teal
    final textColor = theme.colorScheme.onPrimary; // Light text

    return Scaffold(
      // Background color is handled by theme (dark navy)
      appBar: AppBar(
        title: Text(_isSigningUp ? 'Sign Up' : 'Login'),
        backgroundColor: Colors.transparent, // Make app bar transparent to blend
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // LOGO SECTION
              Container(
                margin: const EdgeInsets.only(bottom: 48.0),
                child: Column(
                  children: [
                    // Replace this Icon with your Image asset when you have one
                    // Image.asset('assets/images/harvest_logo.png', height: 100),
                    Icon(
                      Icons.school_rounded, // Placeholder icon
                      size: 80,
                      color: accentColor, // Use theme accent color (Teal)
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "HARVEST",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: accentColor,
                        letterSpacing: 4.0, // Increased letter spacing for modern look
                      ),
                    ),
                    Text(
                      "INSTITUTE",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor.withOpacity(0.7),
                        letterSpacing: 6.0,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tagline / Welcome Text
              Text(
                _isSigningUp ? 'Join the Harvest' : 'Welcome Back',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Raising skilled laborers for the End-Time Harvest",
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),

              // Input Fields
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 24.0),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _handleEmailAuth,
                          child: Text(_isSigningUp ? 'Create Account' : 'Sign In'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSigningUp = !_isSigningUp;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isSigningUp
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Sign Up',
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text("OR", style: TextStyle(color: textColor.withOpacity(0.5))),
                            ),
                            Expanded(child: Divider(color: textColor.withOpacity(0.2))),
                          ],
                        ),
                        const SizedBox(height: 24),

                        OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: textColor.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        // DEBUG TOOL - REMOVE IN PRODUCTION
                        TextButton(
                          onPressed: _showRoleFixDialog,
                          child: Text(
                            "Debug: Fix User Roles",
                            style: TextStyle(color: Colors.orange.withOpacity(0.5), fontSize: 12),
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
