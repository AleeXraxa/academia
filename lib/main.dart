import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:academia/app/core/constants/app_constants.dart';
import 'package:academia/app/routes/app_pages.dart';
import 'package:academia/app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:academia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Fallback for platforms not yet present in firebase_options.dart.
    await Firebase.initializeApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appTitle,
      theme: AppTheme.light(),
      initialRoute: AppPages.initial,
      getPages: AppPages.pages,
    );
  }
}
