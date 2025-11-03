import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  // Hash password menggunakan SHA-256
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
      return false;
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
}
