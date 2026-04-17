import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  Future<String> uploadIssueMedia(File file, String userId) async {
    final compressed = await _compressImage(file);
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'issues/$userId/${_uuid.v4()}.$ext';

    await _supabase.storage.from('media').upload(path, compressed ?? file);
    return _supabase.storage.from('media').getPublicUrl(path);
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final compressed = await _compressImage(file, maxDimension: 400);
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'avatars/$userId.$ext';

    await _supabase.storage.from('media').upload(path, compressed ?? file,
        fileOptions: const FileOptions(upsert: true));
    return _supabase.storage.from('media').getPublicUrl(path);
  }

  Future<String> uploadAuthorityProof(File file, String authorityId) async {
    final compressed = await _compressImage(file);
    final ext = file.path.split('.').last.toLowerCase();
    final path = 'authority_proof/$authorityId/${_uuid.v4()}.$ext';

    await _supabase.storage.from('media').upload(path, compressed ?? file);
    return _supabase.storage.from('media').getPublicUrl(path);
  }

  Future<File?> _compressImage(File file, {int maxDimension = 1200}) async {
    final targetPath = file.path.replaceFirst(
        RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false),
        '_compressed.jpg');
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: maxDimension,
      minHeight: maxDimension,
      keepExif: false,
    );
    return result != null ? File(result.path) : null;
  }
}
