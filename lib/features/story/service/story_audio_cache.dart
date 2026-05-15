import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class StoryAudioCache {
  const StoryAudioCache();

  Future<String> resolve({
    required int storyId,
    required String audioUrl,
  }) async {
    final cached = await _cachedFile(storyId: storyId, audioUrl: audioUrl);
    if (await cached.exists() && await cached.length() > 0) {
      return cached.path;
    }

    await cached.parent.create(recursive: true);
    final temp = File('${cached.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }

    try {
      await Dio().download(
        audioUrl,
        temp.path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      if (await temp.length() == 0) {
        throw StateError('downloaded audio is empty');
      }
      if (await cached.exists()) {
        await cached.delete();
      }
      await temp.rename(cached.path);
      return cached.path;
    } catch (_) {
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }
  }

  Future<File> _cachedFile({
    required int storyId,
    required String audioUrl,
  }) async {
    final base = await getApplicationCacheDirectory();
    final digest = sha1.convert(utf8.encode(audioUrl)).toString();
    final ext = _extensionForUrl(audioUrl);
    return File('${base.path}/story_audio/story-$storyId-$digest$ext');
  }

  String _extensionForUrl(String audioUrl) {
    final path = Uri.tryParse(audioUrl)?.path ?? audioUrl;
    final match = RegExp(r'\.([a-zA-Z0-9]{2,5})$').firstMatch(path);
    if (match == null) {
      return '.mp3';
    }
    return '.${match.group(1)!.toLowerCase()}';
  }
}
