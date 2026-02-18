import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/gallery_service.dart';

/// Shared image cache to avoid reloading thumbnails.
class PhotoCacheManager {
  static final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 20;

  static Uint8List? get(String id) => _cache[id];

  static void put(String id, Uint8List bytes) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entries
      final keysToRemove = _cache.keys.take(5).toList();
      for (final k in keysToRemove) {
        _cache.remove(k);
      }
    }
    _cache[id] = bytes;
  }

  static bool has(String id) => _cache.containsKey(id);

  /// Preload thumbnails for upcoming assets.
  static Future<void> preload(List<AssetEntity> assets) async {
    for (final asset in assets) {
      if (_cache.containsKey(asset.id)) continue;
      final bytes = await GalleryService.getThumbnail(
        asset,
        width: 1200,
        height: 1200,
      );
      if (bytes != null) {
        put(asset.id, bytes);
      }
    }
  }

  static void clear() => _cache.clear();
}

class PhotoCard extends StatefulWidget {
  final AssetEntity asset;
  final BoxFit fit;

  const PhotoCard({super.key, required this.asset, this.fit = BoxFit.cover});

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant PhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _loading = true;
      _imageBytes = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    // Check cache first
    final cached = PhotoCacheManager.get(widget.asset.id);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _imageBytes = cached;
          _loading = false;
        });
      }
      return;
    }

    final bytes = await GalleryService.getThumbnail(
      widget.asset,
      width: 1200,
      height: 1200,
    );
    if (bytes != null) {
      PhotoCacheManager.put(widget.asset.id, bytes);
    }
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: ClipRRect(
        key: ValueKey(_loading ? 'loading' : widget.asset.id),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  fit: widget.fit,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                )
              : const Center(
                  child: Icon(Icons.broken_image_outlined, size: 48),
                ),
        ),
      ),
    );
  }
}
