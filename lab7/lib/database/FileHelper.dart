import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/Shop.dart';

class FileHelper {
  static Future<File> saveToTemporary(Shop shop) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/shop_temp.json');
    return file.writeAsString(shop.toJson());
  }

  static Future<File> saveToDocuments(Shop shop) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/shop_docs.json');
    return file.writeAsString(shop.toJson());
  }

  static Future<File> saveToSupport(Shop shop) async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/shop_support.json');
    return file.writeAsString(shop.toJson());
  }

  static Future<File> saveToCache(Shop shop) async {
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/shop_cache.json');
    return file.writeAsString(shop.toJson());
  }

  static Future<File> saveToLibrary(Shop shop) async {
    try {
      if (Platform.isIOS) {
        final directory = await getLibraryDirectory();
        final file = File('${directory.path}/shop_library.json');
        return file.writeAsString(shop.toJson());
      } else {
        throw Exception('Library directory is only available on iOS');
      }
    } catch (e) {
      print('Error saving to library directory: $e');
      return saveToDocuments(shop);
    }
  }

  static Future<File> saveToDownloads(Shop shop) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/shop_downloads.json');
        return file.writeAsString(shop.toJson());
      } else {
        throw Exception('Downloads directory not available');
      }
    } catch (e) {
      print('Error saving to downloads directory: $e');
      return saveToDocuments(shop);
    }
  }

  // Platform-specific storage operations
  static Future<File> saveToExternalStorage(Shop shop) async {
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final file = File('${directory.path}/shop_external.json');
          return file.writeAsString(shop.toJson());
        } else {
          throw Exception('External storage not available');
        }
      } else {
        throw Exception('External storage is only available on Android');
      }
    } catch (e) {
      print('Error saving to external storage: $e');
      return saveToDocuments(shop);
    }
  }

  // Save to external storage directories (Android only)
  static Future<File> saveToExternalStorageDirectories(Shop shop) async {
    try {
      if (Platform.isAndroid) {
        final directories = await getExternalStorageDirectories();
        if (directories != null && directories.isNotEmpty) {
          final file = File('${directories[0].path}/shop_ext_storage_dirs.json');
          return file.writeAsString(shop.toJson());
        } else {
          throw Exception('External storage directories not available');
        }
      } else {
        throw Exception('External storage directories are only available on Android');
      }
    } catch (e) {
      print('Error saving to external storage directories: $e');
      return saveToDocuments(shop);
    }
  }

  static Future<File> saveToExternalCacheDirectories(Shop shop) async {
    try {
      if (Platform.isAndroid) {
        final directories = await getExternalCacheDirectories();
        if (directories != null && directories.isNotEmpty) {
          final file = File('${directories[0].path}/shop_ext_cache_dirs.json');
          return file.writeAsString(shop.toJson());
        } else {
          throw Exception('External cache directories not available');
        }
      } else {
        throw Exception('External cache directories are only available on Android');
      }
    } catch (e) {
      print('Error saving to external cache directories: $e');
      return saveToDocuments(shop);
    }
  }

  // Read shop from various directories with error handling
  static Future<Shop?> readFromDirectory(String directoryType) async {
    try {
      late File file;

      switch (directoryType) {
        case 'temporary':
          final directory = await getTemporaryDirectory();
          file = File('${directory.path}/shop_temp.json');
          break;
        case 'documents':
          final directory = await getApplicationDocumentsDirectory();
          file = File('${directory.path}/shop_docs.json');
          break;
        case 'support':
          final directory = await getApplicationSupportDirectory();
          file = File('${directory.path}/shop_support.json');
          break;
        case 'cache':
          final directory = await getApplicationCacheDirectory();
          file = File('${directory.path}/shop_cache.json');
          break;
        case 'library':
          if (Platform.isIOS) {
            final directory = await getLibraryDirectory();
            file = File('${directory.path}/shop_library.json');
          } else {
            throw Exception('Library directory is only available on iOS');
          }
          break;
        case 'downloads':
          final directory = await getDownloadsDirectory();
          if (directory == null) throw Exception('Downloads directory not available');
          file = File('${directory.path}/shop_downloads.json');
          break;
        case 'external':
          if (Platform.isAndroid) {
            final directory = await getExternalStorageDirectory();
            if (directory == null) throw Exception('External storage not available');
            file = File('${directory.path}/shop_external.json');
          } else {
            throw Exception('External storage is only available on Android');
          }
          break;
        case 'externalStorageDirectories':
          if (Platform.isAndroid) {
            final directories = await getExternalStorageDirectories();
            if (directories == null || directories.isEmpty)
              throw Exception('External storage directories not available');
            file = File('${directories[0].path}/shop_ext_storage_dirs.json');
          } else {
            throw Exception('External storage directories are only available on Android');
          }
          break;
        case 'externalCacheDirectories':
          if (Platform.isAndroid) {
            final directories = await getExternalCacheDirectories();
            if (directories == null || directories.isEmpty)
              throw Exception('External cache directories not available');
            file = File('${directories[0].path}/shop_ext_cache_dirs.json');
          } else {
            throw Exception('External cache directories are only available on Android');
          }
          break;
        default:
          throw Exception('Unknown directory type');
      }

      if (await file.exists()) {
        final contents = await file.readAsString();
        return Shop.fromJson(contents);
      } else {
        return null;
      }
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }
}