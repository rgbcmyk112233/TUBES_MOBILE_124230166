import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../sqlite/user_model.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'services/session_service.dart';
// Import Database Helper dan Model Log
import '../sqlite/database_helper.dart';
import '../models/login_log_model.dart';

class AboutPage extends StatefulWidget {
  final User user;

  const AboutPage({Key? key, required this.user}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _selectedImagePath;
  String _lastLoginText =
      "Memuat data login..."; // Variabel untuk menyimpan text log

  // Warna Tema Konsisten (Dark Mode)
  final Color _bgColor = const Color(0xFF121212);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _inputColor = const Color(0xFF2C2C2C);
  final Color _accentColor = const Color(0xFFFFC107);
  final Color _textColor = const Color(0xFFE0E0E0);
  final Color _subTextColor = const Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.userName;
    _descController.text = widget.user.userDesc;
    _initializeSupabase();
    _loadLastLogin(); // Panggil fungsi load log
  }

  Future<void> _initializeSupabase() async {
    await _supabaseService.initialize();
  }

  // --- AMBIL DATA LOG LOGIN TERAKHIR ---
  Future<void> _loadLastLogin() async {
    try {
      final log = await _dbHelper.getLastLogin(widget.user.userName);
      if (log != null) {
        // Parsing waktu ISO8601 ke format yang enak dibaca
        final dateTime = DateTime.parse(log.loginTime).toLocal();
        final dateStr = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
        final timeStr =
            "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

        if (mounted) {
          setState(() {
            _lastLoginText = "Last Login: $dateStr at $timeStr";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lastLoginText = "First time login / No log found.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastLoginText = "Failed to load log info.";
        });
      }
    }
  }

  // ... (Fungsi _showImagePickerOptions, _pickImage, _saveProfile, _showLogoutDialog, _logout, _buildProfileImage, _getProfileImage, _shouldShowPlaceholder, _buildInputLabel tetap SAMA seperti sebelumnya) ...
  // Silakan copy paste method-method tersebut dari kode sebelumnya jika perlu,
  // karena tidak ada perubahan logika di sana.
  // Saya akan langsung ke bagian build() untuk menunjukkan penempatan Log.

  // --- LOGIKA PILIH GAMBAR (KAMERA / GALERI) ---
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text(
                  'Ambil Foto (Kamera)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl;
      if (_selectedImagePath != null) {
        photoUrl = await _supabaseService.uploadUserPhoto(
          userId: widget.user.userId,
          filePath: _selectedImagePath!,
        );
      }

      await _supabaseService.updateUserProfile(
        userId: widget.user.userId,
        userName: _nameController.text.trim(),
        userDesc: _descController.text.trim(),
        userPhoto: photoUrl,
      );

      final updatedUser = User(
        userId: widget.user.userId,
        userName: _nameController.text.trim(),
        userMail: widget.user.userMail,
        userDesc: _descController.text.trim(),
        userPhoto: photoUrl ?? widget.user.userPhoto,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile berhasil diupdate',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green[800],
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: updatedUser)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, size: 40, color: Colors.red),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: _subTextColor),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textColor,
                          side: BorderSide(color: Colors.grey[700]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    final SessionService sessionService = SessionService();
    await sessionService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _showImagePickerOptions : null,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 2),
              color: _bgColor,
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: _inputColor,
              backgroundImage: _getProfileImage(),
              child: _shouldShowPlaceholder()
                  ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                  : null,
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bgColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImagePath != null) {
      return FileImage(File(_selectedImagePath!));
    } else if (widget.user.userPhoto != null &&
        widget.user.userPhoto!.isNotEmpty) {
      return NetworkImage(widget.user.userPhoto!);
    }
    return null;
  }

  bool _shouldShowPlaceholder() {
    return _selectedImagePath == null &&
        (widget.user.userPhoto == null || widget.user.userPhoto!.isEmpty);
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _accentColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(child: _buildProfileImage()),
                  const SizedBox(height: 30),

                  if (!_isEditing) ...[
                    Text(
                      _nameController.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.user.userMail,
                      style: TextStyle(fontSize: 16, color: _subTextColor),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "About Me",
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            _descController.text.isNotEmpty
                                ? _descController.text
                                : "No description available.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: _textColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isEditing) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Username'),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: _textColor),
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: Icon(Icons.person, color: _accentColor),
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
                        ),
                        const SizedBox(height: 20),
                        _buildInputLabel('Bio / Description'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          style: TextStyle(color: _textColor),
                          decoration: InputDecoration(
                            hintText: 'Tell us about yourself...',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Icon(
                                Icons.description,
                                color: _accentColor,
                              ),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _nameController.text = widget.user.userName;
                                _descController.text = widget.user.userDesc;
                                _selectedImagePath = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textColor,
                              side: BorderSide(color: Colors.grey[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 30),

                  if (!_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _cardColor,
                              foregroundColor: _accentColor,
                              side: BorderSide(color: _accentColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showLogoutDialog,
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              foregroundColor: Colors.red[400],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // --- FITUR BARU: LOG LOGIN DI BAGIAN PALING BAWAH ---
                  const SizedBox(height: 40),
                  Divider(color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _lastLoginText, // Menampilkan data dari SQLite
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
