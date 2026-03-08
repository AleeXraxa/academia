import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:academia/app/core/constants/app_constants.dart';
import 'package:academia/app/routes/app_pages.dart';
import 'package:academia/app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:academia/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
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
