import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MoNoteProApp()); // ← const هنا آمن لأن MoNoteProApp stateless وكل حاجة داخلها const أو لا تحتاج const
}

class MoNoteProApp extends StatelessWidget {
  const MoNoteProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoNote Pro',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),

        cardTheme: const CardThemeData(  // ← CardThemeData يدعم const تمامًا
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),

      home: const SplashScreen(), // ← غيرناه لاسم أوضح، وconst آمن هنا
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // نستخدم Future.delayed خارج const لأنه عملية async
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenPlaceholder()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [  // ← const هنا آمن لأن كل الأطفال const
            Icon(
              Icons.note_alt_rounded,
              size: 100,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 24),
            Text(
              'MoNote Pro',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your smart notes in the cloud',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Text(
          'Login Screen Coming Soon...\n(We will implement Auth next)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}