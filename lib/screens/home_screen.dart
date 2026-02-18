import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/gallery_service.dart';
import '../widgets/photo_card.dart';
import '../widgets/swipe_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<AssetEntity> _photos = [];
  final List<AssetEntity> _toDelete = [];
  int _keptCount = 0;
  int _totalPhotos = 0;
  int _swipedCount = 0;
  bool _loading = true;
  bool _permissionDenied = false;
  bool _done = false;
  double _swipeProgress = 0.0;
  int _currentPage = 0;
  bool _loadingMore = false;
  static const int _pageSize = 50;

  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final hasPermission = await GalleryService.requestPermission();
    if (!hasPermission) {
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }
    await _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final total = await GalleryService.getTotalImageCount();
    final photos = await GalleryService.loadAllImages(
      page: _currentPage,
      pageSize: _pageSize,
    );
    setState(() {
      _totalPhotos = total;
      _swipedCount = 0;
      _photos = photos;
      _loading = false;
      _done = photos.isEmpty;
    });
  }

  Future<void> _loadMorePhotos() async {
    if (_loadingMore) return;
    _loadingMore = true;
    _currentPage++;
    final morePhotos = await GalleryService.loadAllImages(
      page: _currentPage,
      pageSize: _pageSize,
    );
    if (morePhotos.isEmpty) {
      setState(() => _done = true);
    } else {
      setState(() => _photos = morePhotos);
    }
    _loadingMore = false;
  }

  Future<void> _confirmAndDelete() async {
    if (_toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Photos'),
        content: Text(
          'Move ${_toDelete.length} photo${_toDelete.length > 1 ? 's' : ''} to trash?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GalleryService.deleteAssets(_toDelete);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_toDelete.length} photo(s) deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      _toDelete.clear();
    }
  }

  void _restart() {
    setState(() {
      _toDelete.clear();
      _keptCount = 0;
      _currentPage = 0;
      _loading = true;
      _done = false;
    });
    _loadPhotos();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _permissionDenied
            ? _buildPermissionDenied()
            : _done
            ? _buildDone()
            : _buildSwiper(cs),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 16),
          Text('Loading photos...'),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gallery Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Please grant photo library access to start cleaning your gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => PhotoManager.openSetting(),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'All Done!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Kept $_keptCount  •  Marked ${_toDelete.length} for deletion',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            if (_toDelete.isNotEmpty)
              FilledButton.icon(
                onPressed: _confirmAndDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text('Delete ${_toDelete.length} Photos'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start Over'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwiper(ColorScheme cs) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Swipe Cleaner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(_totalPhotos - _swipedCount).clamp(0, _totalPhotos)} photos remaining',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (_toDelete.isNotEmpty)
                FilledButton.tonal(
                  onPressed: _confirmAndDelete,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'Delete ${_toDelete.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatChip(
                icon: Icons.favorite_rounded,
                label: '$_keptCount',
                color: Colors.green,
              ),
              const SizedBox(width: 24),
              _StatChip(
                icon: Icons.delete_rounded,
                label: '${_toDelete.length}',
                color: Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Swiper
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _photos.length,
              numberOfCardsDisplayed: _photos.length >= 3 ? 3 : _photos.length,
              backCardOffset: const Offset(0, -30),
              scale: 0.92,
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
                vertical: false,
              ),
              onSwipe: _onSwipe,
              onSwipeDirectionChange: (horizontalDirection, verticalDirection) {
                setState(() {
                  if (horizontalDirection == CardSwiperDirection.right) {
                    _swipeProgress = 0.5;
                  } else if (horizontalDirection == CardSwiperDirection.left) {
                    _swipeProgress = -0.5;
                  } else {
                    _swipeProgress = 0.0;
                  }
                });
              },
              onEnd: () {
                // Load more or show done
                if (!_loadingMore) {
                  _loadMorePhotos();
                }
              },
              cardBuilder:
                  (context, index, percentThresholdX, percentThresholdY) {
                    if (index >= _photos.length) return const SizedBox.shrink();
                    final progress = percentThresholdX / 100.0;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoCard(
                          key: ValueKey(_photos[index].id),
                          asset: _photos[index],
                        ),
                        SwipeOverlay(swipeProgress: progress),
                      ],
                    );
                  },
            ),
          ),
        ),

        // Bottom hints
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionHint(
                icon: Icons.delete_rounded,
                label: 'Delete',
                color: Colors.red.shade400,
                onTap: () => _swiperController.swipe(CardSwiperDirection.left),
              ),
              _ActionHint(
                icon: Icons.favorite_rounded,
                label: 'Keep',
                color: Colors.green.shade400,
                onTap: () => _swiperController.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
        ),

        // Swipe instruction
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            '← swipe left to delete  •  swipe right to keep →',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    HapticFeedback.lightImpact();

    if (previousIndex < _photos.length) {
      if (direction == CardSwiperDirection.left) {
        // Delete
        _toDelete.add(_photos[previousIndex]);
      } else if (direction == CardSwiperDirection.right) {
        // Keep
        _keptCount++;
      }
      _swipedCount++;
    }

    setState(() {
      _swipeProgress = 0.0;
    });

    return true;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color.shade400),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color.shade400,
          ),
        ),
      ],
    );
  }
}

class _ActionHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionHint({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
