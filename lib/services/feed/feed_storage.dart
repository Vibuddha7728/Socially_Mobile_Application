// feed_storage.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadImage({
    required File postImage,
    required String userId,
  }) async {
    try {
      final filePath =
          'feed-images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('media')
          .upload(
            filePath,
            postImage,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      return _supabase.storage.from('media').getPublicUrl(filePath);
    } catch (e) {
      print('Feed image upload error: $e');
      return '';
    }
  }

  Future<void> deleteImage({required String imageUrl}) async {
    try {
      final filePath = imageUrl.split('/media/').last;
      await _supabase.storage.from('media').remove([filePath]);
    } catch (e) {
      print('Feed image delete error: $e');
    }
  }
}
