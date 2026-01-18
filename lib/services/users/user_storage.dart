// user_profile_storage_service.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadImage({
    required File profileImage,
    required String userEmail,
  }) async {
    try {
      final filePath =
          'user-images/$userEmail/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('media')
          .upload(
            filePath,
            profileImage,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return _supabase.storage.from('media').getPublicUrl(filePath);
    } catch (e) {
      print('Profile upload error: $e');
      return '';
    }
  }
}
