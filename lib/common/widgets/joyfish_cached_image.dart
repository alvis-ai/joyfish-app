import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class JoyfishCachedImage extends StatefulWidget {
  const JoyfishCachedImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorBuilder,
  });

  final String imageUrl;
  final BoxFit? fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext context, Object error, StackTrace? stack)?
      errorBuilder;

  @override
  State<JoyfishCachedImage> createState() => _JoyfishCachedImageState();
}

class _JoyfishCachedImageState extends State<JoyfishCachedImage> {
  late Future<String> _imagePathFuture;

  @override
  void initState() {
    super.initState();
    _imagePathFuture = JoyfishImageCache.resolve(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant JoyfishCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imagePathFuture = JoyfishImageCache.resolve(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _imagePathFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(
            File(snapshot.data!),
            fit: widget.fit,
            errorBuilder: widget.errorBuilder,
          );
        }

        if (snapshot.hasError) {
          final builder = widget.errorBuilder;
          if (builder != null) {
            return builder(context, snapshot.error!, snapshot.stackTrace);
          }
          return const SizedBox.shrink();
        }

        return widget.placeholder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}

class JoyfishImageCache {
  JoyfishImageCache._();

  static Future<String> resolve(String imageUrl) async {
    final file = await _cachedFile(imageUrl);
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }

    await file.parent.create(recursive: true);
    final temp = File('${file.path}.download');
    if (await temp.exists()) {
      await temp.delete();
    }

    try {
      await Dio().download(
        imageUrl,
        temp.path,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      if (await temp.length() == 0) {
        throw StateError('downloaded image is empty');
      }
      if (await file.exists()) {
        await file.delete();
      }
      await temp.rename(file.path);
      return file.path;
    } catch (_) {
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }
  }

  static Future<File> _cachedFile(String imageUrl) async {
    final dir = await getApplicationCacheDirectory();
    final hash = sha1.convert(utf8.encode(imageUrl)).toString();
    final extension = _extensionForUrl(imageUrl);
    return File('${dir.path}/story_images/$hash$extension');
  }

  static String _extensionForUrl(String imageUrl) {
    final path = Uri.tryParse(imageUrl)?.path.toLowerCase() ?? '';
    final dotIndex = path.lastIndexOf('.');
    final slashIndex = path.lastIndexOf('/');
    final extension = dotIndex > slashIndex ? path.substring(dotIndex) : '';
    switch (extension) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.webp':
      case '.gif':
        return extension;
      default:
        return '.img';
    }
  }
}
