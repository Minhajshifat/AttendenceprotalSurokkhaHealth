import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'models/app_user.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/agent/agent_dashboad.dart';
import 'screens/auth/login_screen.dart';
import 'screens/teamlead/team_lead_dashboard.dart';
import 'services/user_service.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/office/office_employee_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SurokkhaAttendanceApp());
}

class SurokkhaAttendanceApp extends StatelessWidget {
  const SurokkhaAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surokkha Attendance',
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          return const LoginScreen();
        }

        return UserDashboardLoader(firebaseUser: firebaseUser);
      },
    );
  }
}

class UserDashboardLoader extends StatefulWidget {
  final User firebaseUser;

  const UserDashboardLoader({super.key, required this.firebaseUser});

  @override
  State<UserDashboardLoader> createState() => _UserDashboardLoaderState();
}

class _UserDashboardLoaderState extends State<UserDashboardLoader> {
  final UserService _userService = UserService();

  bool _loading = true;
  String? _error;
  dynamic _appUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final firebaseUser = widget.firebaseUser;

      AppUser? user;

      // ==========================================
      // 1. FIRST TRY FIREBASE UID
      // Super Admin-এর জন্য
      // ==========================================

      user = await _userService.getUser(firebaseUser.uid);

      // ==========================================
      // 2. IF NOT FOUND, TRY GOOGLE EMAIL
      // Employee-এর জন্য
      // ==========================================

      if (user == null && firebaseUser.email != null) {
        user = await _userService.getUserByEmail(firebaseUser.email!);
      }

      if (!mounted) return;

      // ==========================================
      // 3. UNAUTHORIZED ACCOUNT
      // ==========================================

      if (user == null) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'This Google account is not authorized.';
        });

        return;
      }

      // ==========================================
      // 4. INACTIVE EMPLOYEE
      // ==========================================

      if (!user.isActive || user.accountStatus != 'active') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Your employee account is inactive.';
        });

        return;
      }

      // ==========================================
      // 5. SUCCESS
      // ==========================================

      setState(() {
        _appUser = user;
        _loading = false;
      });
    } catch (e) {
      debugPrint('User loading error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load user profile.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _LoadingScreen();
    }

    if (_error != null) {
      return _ErrorScreen(message: _error!);
    }

    switch (_appUser.role) {
      case 'agent':
        return AgentDashboard(user: _appUser);

      case 'team_lead':
        return TeamLeadDashboard(user: _appUser);

      case 'admin':
        return AdminDashboard(user: _appUser);
      case 'super_admin':
        return SuperAdminDashboard(user: _appUser);
      case 'office_employee':
        return OfficeEmployeeDashboard(user: _appUser);

      default:
        return _ErrorScreen(message: 'Unknown user role: ${_appUser.role}');
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FC),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF155084))),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
