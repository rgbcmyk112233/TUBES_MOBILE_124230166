import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/session_service.dart';
import '../sqlite/user_model.dart';
import '../sqlite/database_helper.dart'; // Pastikan import ini ada
import '../models/login_log_model.dart'; // Import model log
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final SessionService _sessionService = SessionService();
  // Tambahkan instance DatabaseHelper (sesuaikan dengan nama class Anda)
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _checkingSession = true;

  // Warna Tema (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _inputColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFFFC107);
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _supabaseService.initialize();
    await _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final session = await _sessionService.getCurrentSession();
      if (session != null && session.isValid) {
        final user = User.fromSession(session);
        _navigateToHome(user);
        return;
      }
    } catch (e) {
      print('Error checking session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingSession = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userData = await _supabaseService.loginUser(
          userMail: _emailController.text.trim(),
          userPwd: _passwordController.text.trim(),
        );

        if (userData != null) {
          final user = User.fromJson(userData);

          // 1. Simpan Session
          await _sessionService.saveSession(user.toSession());

          // 2. SIMPAN LOG LOGIN KE SQLITE (Fitur Baru)
          try {
            await _dbHelper.insertLoginLog(
              LoginLog(
                username: user.userName,
                loginTime: DateTime.now().toIso8601String(),
              ),
            );
          } catch (e) {
            print("Gagal menyimpan log login: $e");
            // Kita biarkan login tetap lanjut meski log gagal disimpan
          }

          if (mounted) _navigateToHome(user);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email atau password salah',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _accentColor),
              const SizedBox(height: 16),
              Text(
                'Memeriksa session...',
                style: TextStyle(color: _subTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.movie_filter_rounded,
                    size: 80,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue exploring movies',
                  style: TextStyle(fontSize: 16, color: _subTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Masukkan email';
                    if (!value.contains('@'))
                      return 'Masukkan email yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Masukkan password';
                    if (value.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.black,
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
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: _subTextColor),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
