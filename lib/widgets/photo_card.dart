import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/gallery_service.dart';

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

  Future<void> _loadImage() async {
    final bytes = await GalleryService.getThumbnail(
      widget.asset,
      width: 1200,
      height: 1200,
    );
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
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
              )
            : const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      ),
    );
  }
}
