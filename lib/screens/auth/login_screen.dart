import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isGoogleLoading = false;
  bool _isSuperAdminLoading = false;
  bool _obscurePassword = true;
  bool _showSuperAdminLogin = false;

  String? _errorMessage;

  // ==========================================
  // GOOGLE SIGN IN
  // ==========================================

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      // AuthGate automatically detects the signed-in user
      // and loads the correct dashboard.
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Error: ${e.code}');
      debugPrint('Message: ${e.message}');

      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'unauthorized-user':
          message = 'This Google account is not registered as an employee.';
          break;

        case 'inactive-user':
          message = 'Your employee account is currently inactive.';
          break;

        case 'invalid-login-method':
          message = 'Please use Super Admin Login.';
          break;

        case 'popup-closed-by-user':
        case 'popup-blocked':
        case 'cancelled-popup-request':
          message = 'Google sign-in was cancelled.';
          break;

        default:
          message =
              e.message ?? 'Unable to sign in with Google. Please try again.';
      }

      setState(() {
        _errorMessage = message;
      });
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint('Stack Trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to sign in with Google. Please try again.';
      });
    } finally {
      // গুরুত্বপূর্ণ: success, error, অথবা popup cancel —
      // সব ক্ষেত্রেই loading বন্ধ হবে
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }
  // ==========================================
  // SUPER ADMIN LOGIN
  // ==========================================

  Future<void> _loginSuperAdmin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email and password.';
      });
      return;
    }

    setState(() {
      _isSuperAdminLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.loginSuperAdmin(email: email, password: password);

      // AuthGate automatically detects the signed-in user.
    } on FirebaseAuthException catch (e) {
      debugPrint('Super Admin Login Error: ${e.code}');
      debugPrint('Message: ${e.message}');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Incorrect email or password.';
      });
    } catch (e, stackTrace) {
      debugPrint('Super Admin Login Error: $e');
      debugPrint('Stack Trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to sign in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSuperAdminLoading = false;
        });
      }
    }
  }

  void _openSuperAdminLogin() {
    setState(() {
      _showSuperAdminLogin = true;
      _errorMessage = null;
    });
  }

  void _backToEmployeeLogin() {
    setState(() {
      _showSuperAdminLogin = false;
      _errorMessage = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuperAdminLogin) {
      return _buildSuperAdminLogin();
    }

    return _buildEmployeeLogin();
  }

  // ==========================================
  // EMPLOYEE LOGIN SCREEN
  // ==========================================

  Widget _buildEmployeeLogin() {
    const sapphireBlue = Color(0xFF155084);
    const kellyGreen = Color(0xFF43C047);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/surokkha_logo.png',
                      width: 190,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Attendance Portal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      color: sapphireBlue,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to manage your attendance',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF172B4D),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Sign in using your Google account',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _isGoogleLoading
                                ? null
                                : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF172B4D),
                              side: const BorderSide(color: Color(0xFFE3E8EF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isGoogleLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: sapphireBlue,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.g_mobiledata_rounded,
                                        size: 30,
                                        color: Color(0xFF4285F4),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Continue with Google',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        const Divider(color: Color(0xFFE3E8EF)),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: _isGoogleLoading
                              ? null
                              : _openSuperAdminLogin,
                          child: Text(
                            'Super Admin Login',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sapphireBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: kellyGreen,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        'Secure Today, Protect Tomorrow',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SUPER ADMIN LOGIN SCREEN
  // ==========================================

  Widget _buildSuperAdminLogin() {
    const sapphireBlue = Color(0xFF155084);

    final isLoading = _isSuperAdminLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          onPressed: isLoading ? null : _backToEmployeeLogin,
          icon: const Icon(Icons.arrow_back_rounded, color: sapphireBlue),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/surokkha_logo.png',
                      width: 170,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Super Admin Portal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: sapphireBlue,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in with your Super Admin credentials',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Admin Login',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF172B4D),
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildField(
                          controller: _emailController,
                          label: 'Email address',
                          icon: Icons.email_outlined,
                          sapphireBlue: sapphireBlue,
                          enabled: !isLoading,
                        ),

                        const SizedBox(height: 16),

                        _buildField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          sapphireBlue: sapphireBlue,
                          obscureText: _obscurePassword,
                          enabled: !isLoading,
                          suffixIcon: IconButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),

                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _loginSuperAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sapphireBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSuperAdminLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // INPUT FIELD
  // ==========================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color sapphireBlue,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF172B4D)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        prefixIcon: Icon(icon, color: sapphireBlue, size: 21),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE6EAF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: sapphireBlue, width: 1.5),
        ),
      ),
    );
  }
}
