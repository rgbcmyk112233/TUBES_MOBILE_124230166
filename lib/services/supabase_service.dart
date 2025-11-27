import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myfilms_app/models/comment_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static final String supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? 'URL NOT FOUND';
  static final String supabaseAnonKey =
      dotenv.env['SUPABASE_PUBLIC_API_KEY'] ?? 'KEY NOT FOUND';

  Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;

  // -------------------------------------------------------------------
  // !!! PERINGATAN KEAMANAN YANG SANGAT PENTING !!!
  //
  // Anda TIDAK BOLEH menggunakan sha256 untuk password.
  // Ini sangat tidak aman karena:
  // 1. Cepat: Memudahkan "brute force attack".
  // 2. Tidak di-"Salt": Rentan terhadap "rainbow table attack".
  //
  // Cara yang benar adalah menggunakan Supabase Auth bawaan:
  // - Pendaftaran: `supabase.auth.signUp(email: '...', password: '...')`
  // - Login: `supabase.auth.signInWithPassword(email: '...', password: '...')`
  //
  // Supabase akan menangani hashing (bcrypt) dan keamanan secara otomatis.
  // Dengan menggunakan tabel `Users` manual seperti ini, Anda
  // mengabaikan seluruh sistem keamanan Supabase.
  // -------------------------------------------------------------------
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Register user baru
  Future<String?> registerUser({
    required String userName,
    required String userMail,
    required String userPwd,
  }) async {
    try {
      final hashedPassword = hashPassword(userPwd);

      final response = await client
          .from('Users')
          .insert({
            'UserName': userName,
            'UserMail': userMail,
            'UserPwd': hashedPassword,
            'UserDesc': 'Halo! Saya pengguna baru MovieApp',
            'UserPhoto': null,
          })
          .select()
          .single();

      return response['UserId'];
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>?> loginUser({
    required String userMail,
    required String userPwd,
  }) async {
    try {
      final hashedPassword = hashPassword(userPwd);

      final response = await client
          .from('Users')
          .select()
          .eq('UserMail', userMail)
          .eq('UserPwd', hashedPassword)
          .single();

      return response;
    } catch (e) {
      throw Exception('Invalid email or password');
    }
  }

  // Check if email already exists
  Future<bool> checkEmailExists(String userMail) async {
    try {
      final response = await client
          .from('Users')
          .select()
          .eq('UserMail', userMail);

      return response.isNotEmpty;
    } catch (e) {
      // PERBAIKAN: Jangan sembunyikan error. Jika database gagal,
      // lebih baik lemparkan error daripada mengembalikan 'false' (email tidak ada).
      throw Exception('Error checking email: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? userName,
    String? userDesc,
    String? userPhoto,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (userName != null) updateData['UserName'] = userName;
      if (userDesc != null) updateData['UserDesc'] = userDesc;
      if (userPhoto != null) updateData['UserPhoto'] = userPhoto;

      await client.from('Users').update(updateData).eq('UserId', userId);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await client
          .from('Users')
          .select()
          .eq('UserId', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error getting user data: $e');
    }
  }

  // Upload photo to Supabase Storage
  Future<String?> uploadUserPhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$fileName';

      // Upload file ke Supabase Storage
      await client.storage
          .from('user-photos')
          .upload(storagePath, File(filePath));

      // Dapatkan public URL
      final publicUrl = client.storage
          .from('user-photos')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  // Get comments for a movie
  Future<List<Comment>> getComments(String imdbId) async {
    try {
      final response = await client
          .from('Komentar')
          .select()
          .eq('IMDB-ID', imdbId)
          .order('posted', ascending: false);

      return response.map<Comment>((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  // Add new comment
  Future<void> addComment({
    required String imdbId,
    required String userId,
    required String userName,
    required String userComment,
    String? userPhoto,
  }) async {
    try {
      await client.from('Komentar').insert({
        'IMDB-ID': imdbId,
        'UserId': userId,
        'UserName': userName,
        'UserComment': userComment,
        'UserPhoto': userPhoto,
        'posted': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error adding comment: $e');
    }
  }

  // Delete comment (optional)
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      await client
          .from('Komentar')
          .delete()
          .eq('id', commentId)
          // PERBAIKAN: Kolom Anda adalah 'UserId' (PascalCase), bukan 'user_id' (snake_case).
          .eq('UserId', userId);
    } catch (e) {
      throw Exception('Error deleting comment: $e');
    }
  }

  // Get comments by a specific user
  Future<List<Comment>> getCommentsByUser(String userId) async {
    try {
      final response = await client
          .from('Komentar')
          .select()
          .eq('UserId', userId) // Filter berdasarkan UserId
          .order('posted', ascending: false);

      return response.map<Comment>((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching user comments: $e');
    }
  }
}
