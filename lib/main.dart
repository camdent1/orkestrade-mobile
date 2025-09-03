import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/supabase_service.dart';
import 'services/location_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Start webhook server for geofence events
  await LocationService.startWebhookServer(port: 8080);
  
  runApp(const OrkestradeApp());
}

class OrkestradeApp extends StatelessWidget {
  const OrkestradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orkestrade Mobile',
      theme: ThemeData(
        primaryColor: const Color(0xFFFFAC86), // atomic-tangerine
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFAC86),
          secondary: const Color(0xFF0E2536), // prussian-blue
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E2536),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}