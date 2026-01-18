import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReelStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadVideo({required File videoFile}) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final String filePath = 'reels/$fileName';

      await _supabase.storage.from('media').upload(
            filePath,
            videoFile,
            fileOptions: const FileOptions(contentType: 'video/mp4'),
          );

      return _supabase.storage.from('media').getPublicUrl(filePath);
    } catch (e) {
      print('Upload error: $e');
      return '';
    }
  }

  Future<void> deleteVideo({required String videoUrl}) async {
    try {
      // URL එකෙන් file path එක වෙන් කරගැනීම (reels/filename.mp4)
      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;
      
      // 'media/reels/filename.mp4' ආකාරයට ඇත්නම් අවසන් කොටස් දෙක ලබා ගැනීම
      final String filePath = "${pathSegments[pathSegments.length - 2]}/${pathSegments.last}";

      await _supabase.storage.from('media').remove([filePath]);
      print('Video deleted from Supabase');
    } catch (e) {
      print('Delete error: $e');
    }
  }
}