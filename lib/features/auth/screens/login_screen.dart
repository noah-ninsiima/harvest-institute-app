import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';
import '../widgets/role_check_wrapper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'register_screen.dart'; // Import RegisterScreen

class LoginScreen extends StatefulWidget {
  final String? message;

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RoleCheckWrapper()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      _navigateToRoleCheckWrapper();
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found': msg = 'No user found for that email.'; break;
        case 'wrong-password': msg = 'Wrong password provided.'; break;
        case 'invalid-email': msg = 'The email address is invalid.'; break;
        case 'user-disabled': msg = 'This user account has been disabled.'; break;
        default: msg = e.message ?? 'An unknown authentication error occurred.';
      }
      setState(() {
        _errorMessage = msg;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      _navigateToRoleCheckWrapper();
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
      if (mounted) setState(() => _isLoading = false);
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
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
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
                    Icon(
                      Icons.school_rounded,
                      size: 80,
                      color: accentColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "HARVEST",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: accentColor,
                        letterSpacing: 4.0,
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
              
              Text(
                'Welcome Back',
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
                          onPressed: _handleSignIn,
                          child: const Text('Sign In'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Navigate to RegisterScreen for sign-up
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Don\'t have an account? Sign Up'),
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
                        // DEBUG TOOL
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
