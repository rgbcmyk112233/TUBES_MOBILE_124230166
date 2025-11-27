import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../sqlite/user_model.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../services/notification_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Warna Tema Konsisten (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _inputColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFFFC107); // Amber/Gold
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _initializeSupabase();
    _requestNotificationPermission();
  }

  Future<void> _initializeSupabase() async {
    await _supabaseService.initialize();
  }

  Future<void> _requestNotificationPermission() async {
    await _notificationService.requestPermissions();
  }

  // --- DIALOG SUKSES (DARK THEME) ---
  void _showSuccessDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _cardColor, // Background Dialog Gelap
          elevation: 10,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: _textColor, // Teks putih/abu
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Welcome, '),
                    TextSpan(
                      text: user.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accentColor, // Nama user Gold
                      ),
                    ),
                    const TextSpan(
                      text:
                          '! 🎉\n\nYour account has been created successfully.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'You can now explore movies and chat with AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _subTextColor),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(user: user),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Exploring',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        );
      },
    );
  }

  // --- DIALOG ERROR (DARK THEME) ---
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: _cardColor,
          elevation: 10,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Registration Failed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textColor, height: 1.5),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final dialogContext = context;

      try {
        final emailExists = await _supabaseService.checkEmailExists(
          _emailController.text.trim(),
        );

        if (emailExists) {
          if (!mounted) return;
          _showErrorDialog(
            dialogContext,
            'Email ${_emailController.text.trim()} is already registered.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final userId = await _supabaseService.registerUser(
          userName: _usernameController.text.trim(),
          userMail: _emailController.text.trim(),
          userPwd: _passwordController.text.trim(),
        );

        if (userId != null) {
          final userData = await _supabaseService.loginUser(
            userMail: _emailController.text.trim(),
            userPwd: _passwordController.text.trim(),
          );

          if (userData != null) {
            final user = User.fromJson(userData);

            await _notificationService.showWelcomeNotification(user.userName);

            if (!mounted) return;
            _showSuccessDialog(dialogContext, user);
          } else {
            throw Exception('Auto-login failed.');
          }
        }
      } catch (e) {
        if (!mounted) return;
        _showErrorDialog(dialogContext, 'An error occurred: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: _textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Please fill in the form to continue',
                  style: TextStyle(fontSize: 16, color: _subTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: _subTextColor),
                    prefixIcon: Icon(Icons.person_outline, color: _accentColor),
                    filled: true,
                    fillColor: _inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter username';
                    if (value.length < 3) return 'Min 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: _subTextColor),
                    prefixIcon: Icon(Icons.email_outlined, color: _accentColor),
                    filled: true,
                    fillColor: _inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter email';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: _subTextColor),
                    prefixIcon: Icon(Icons.lock_outline, color: _accentColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: _inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter password';
                    if (value.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: _textColor),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: _subTextColor),
                    prefixIcon: Icon(Icons.lock_outline, color: _accentColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: _inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Confirm password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black, // Text hitam kontras
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: _accentColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'SIGN UP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: _subTextColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
