import './firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'services/sync_service.dart';
import 'providers/app_provider.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SyncService().monitorConnectivity();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const CashbookApp(),
    ),
  );
}

class CashbookApp extends StatelessWidget {
  const CashbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naya Khata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AppProvider>(
        builder: (context, provider, child) {
          // If already onboarded, show Dashboard, else show SplashScreen which redirects to Auth
          return SplashScreen();
        },
      ),
    );
  }
}
