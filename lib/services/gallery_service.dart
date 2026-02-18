import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  /// Request permission and return true if granted.
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps == PermissionState.limited;
  }

  /// Load all images from device gallery, sorted by date descending.
  static Future<List<AssetEntity>> loadAllImages({
    int page = 0,
    int pageSize = 50,
  }) async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    // Use the "Recent" / all-photos album (first one)
    final AssetPathEntity recentAlbum = albums.first;
    final List<AssetEntity> assets = await recentAlbum.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return assets;
  }

  /// Get total count of images in gallery.
  static Future<int> getTotalImageCount() async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isEmpty) return 0;
    return await albums.first.assetCountAsync;
  }

  /// Load thumbnail bytes for an asset.
  static Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 800,
    int height = 800,
  }) async {
    return await asset.thumbnailDataWithSize(ThumbnailSize(width, height));
  }

  /// Delete a list of assets. Returns deleted IDs.
  static Future<List<String>> deleteAssets(List<AssetEntity> assets) async {
    final List<String> result = await PhotoManager.editor.deleteWithIds(
      assets.map((a) => a.id).toList(),
    );
    return result;
  }
}
