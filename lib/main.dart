// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/services/seed_service.dart'; 
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // We continue to run the app, but some features might not work.
    // In a real app, you might want to show an error screen.
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvest Institute App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(), 
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SeedService _seedService = SeedService();
  String _seedStatus = 'Ready to seed';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Institute App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                      _seedStatus = 'Seeding in progress...';
                    });
                    
                    try {
                      await _seedService.seedDatabase();
                      setState(() {
                        _seedStatus = 'Seeding complete!';
                      });
                    } catch (e) {
                       setState(() {
                        _seedStatus = 'Error: $e';
                      });
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Seed Database (Admin Only!)'),
                ),
              const SizedBox(height: 20),
              Text(
                _seedStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              // Navigation to Login
              OutlinedButton(
                onPressed: () {
                   // Navigate to Login Screen
                   // Since we don't have named routes set up in this minimal main.dart, 
                   // we'll use a direct MaterialPageRoute if the file exists.
                   // I'll assume the import path from previous turns.
                   try {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                         builder: (context) => const LoginScreenPlaceholder(), // Using a placeholder for now to avoid import errors if files moved
                       ),
                     );
                   } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Navigation failed: $e")));
                   }
                },
                child: const Text('Go to Login Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder to avoid compilation errors if the real LoginScreen isn't imported correctly yet.
// In a real scenario, we'd import the actual screen.
class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: const Center(child: Text("Login Screen Placeholder")),
    );
  }
}
