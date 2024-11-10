import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/activity_monitoring_screen.dart';
import 'screens/activity_prioritization_screen.dart';
import 'screens/daily_routines_screen.dart';
import 'screens/integration_screen.dart';
import 'screens/notification_setup_screen.dart';
import 'screens/user_management_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,  // Added for DailyRoutines view
    DeviceOrientation.landscapeRight, // Added for DailyRoutines view
  ]);

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore persistence for offline support
     FirebaseFirestore.instance.settings =
    const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

    runApp(MyApp());
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app. Please try again.'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  // Enhanced color scheme with additional colors for task priorities and categories
  static final ColorScheme lightColorScheme = ColorScheme(
    primary: Color(0xFF6750A4),
    primaryContainer: Color(0xFFEADDFF),
    secondary: Color(0xFF625B71),
    secondaryContainer: Color(0xFFE8DEF8),
    surface: Colors.white,
    background: Color(0xFFFFFBFE),
    error: Color(0xFFB3261E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1C1B1F),
    onBackground: Color(0xFF1C1B1F),
    onError: Colors.white,
    brightness: Brightness.light,
  );

  static final ColorScheme darkColorScheme = ColorScheme(
    primary: Color(0xFFD0BCFF),
    primaryContainer: Color(0xFF4F378B),
    secondary: Color(0xFFCCC2DC),
    secondaryContainer: Color(0xFF4A4458),
    surface: Color(0xFF1C1B1F),
    background: Color(0xFF1C1B1F),
    error: Color(0xFFF2B8B5),
    onPrimary: Color(0xFF381E72),
    onSecondary: Color(0xFF332D41),
    onSurface: Color(0xFFE6E1E5),
    onBackground: Color(0xFFE6E1E5),
    onError: Color(0xFF601410),
    brightness: Brightness.dark,
  );

  // Custom theme extension for task-specific colors
  static final taskColors = {
    'priority': {
      'critical': Colors.red[700],
      'high': Colors.orange[700],
      'medium': Colors.yellow[700],
      'low': Colors.green[700],
    },
    'category': {
      'work': Colors.blue[100],
      'personal': Colors.purple[100],
      'health': Colors.teal[100],
      'education': Colors.indigo[100],
      'other': Colors.grey[100],
    },
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: lightColorScheme.surface,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: darkColorScheme.onBackground,
          displayColor: darkColorScheme.onBackground,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: darkColorScheme.surface,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Something went wrong. Please try again later.'),
              ),
            );
          }

          if (snapshot.hasData) {
            return HomeScreen();
          }

          return LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/activityPrioritization': (context) => ActivityPrioritizationScreen(),
        '/dailyRoutines': (context) => DailyRoutinesScreen(),  // Added route
        '/notificationSetup': (context) => NotificationSetupScreen(),
        '/userManagement': (context) => UserManagementScreen(),
        '/integration': (context) => IntegrationScreen(),
        '/activityMonitoring': (context) => ActivityMonitoringScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes
        if (settings.name?.startsWith('/task/') ?? false) {
          final taskId = settings.name?.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ActivityPrioritizationScreen(),
            settings: RouteSettings(arguments: taskId),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('Page Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Page not found'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}