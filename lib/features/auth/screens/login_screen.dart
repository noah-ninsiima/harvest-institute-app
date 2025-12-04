import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../widgets/role_check_wrapper.dart'; // Import RoleCheckWrapper

class LoginScreen extends ConsumerStatefulWidget {
  final String? message;

  const LoginScreen({super.key, this.message});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Cleared default credentials
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  
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

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).signInWithMoodle(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // State changes are handled by ref.listen in build()
    } catch (e) {
      // Exceptions from the async call itself (if not caught in controller)
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener for Auth State changes
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          debugPrint("Login Successful, Navigating...");
          // Replaced direct StudentDashboard navigation with RoleCheckWrapper to handle roles
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RoleCheckWrapper()),
          );
        },
        error: (error, stack) {
          debugPrint("Login Failed: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
          setState(() {
            _errorMessage = error.toString();
          });
        },
        loading: () {
          // Optional: You can handle loading state here if needed
        },
      );
    });

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onPrimary;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

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
                  labelText: 'Username or Email',
                  prefixIcon: Icon(Icons.person_outline),
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
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleSignIn,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign In'),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
