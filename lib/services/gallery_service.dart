import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

class GalleryService {
  /// Request permission and return true if granted.
  static Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps == PermissionState.limited;
  }

  /// Return all albums that contain images.
  static Future<List<AssetPathEntity>> getAlbums() async {
    return await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );
  }

  /// Load images from [album] (or the first album if null), paged.
  static Future<List<AssetEntity>> loadAllImages({
    required AssetPathEntity album,
    int page = 0,
    int pageSize = 50,
  }) async {
    return await album.getAssetListPaged(page: page, size: pageSize);
  }

  /// Get total image count for [album].
  static Future<int> getTotalImageCount(AssetPathEntity album) async {
    return await album.assetCountAsync;
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
