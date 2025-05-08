import 'package:flutter/material.dart';
import '../models/Shop.dart';
import '../database/databaseHelper.dart';
import '../database/FileHelper.dart';
import 'dart:io';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({Key? key, required this.shopId}) : super(key: key);

  @override
  _ShopDetailScreenState createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Shop shop;
  bool isLoading = true;
  Map<String, Shop?> loadedShops = {};
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    loadShop();
  }

  Future loadShop() async {
    setState(() => isLoading = true);
    shop = (await DatabaseHelper.instance.getShop(widget.shopId))!;
    setState(() => isLoading = false);
  }

  Future<void> saveToDirectory(String type) async {
    try {
      switch (type) {
        case 'temporary':
          await FileHelper.saveToTemporary(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'documents':
          await FileHelper.saveToDocuments(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'support':
          await FileHelper.saveToSupport(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'cache':
          await FileHelper.saveToCache(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'library':
          if (Platform.isAndroid) {
            setState(() {
              statusMessage = 'Library доступен только на iOS.';
            });
            return; // Важно: выйти из функции после установки сообщения
          } else {
            await FileHelper.saveToLibrary(shop);
            setState(() {
              statusMessage = 'Магазин сохранен в ${type}';
            });
          }
          break;
        case 'downloads':
          await FileHelper.saveToDownloads(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'external':
          await FileHelper.saveToExternalStorage(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'externalStorageDirectories':
          await FileHelper.saveToExternalStorageDirectories(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'externalCacheDirectories':
          await FileHelper.saveToExternalCacheDirectories(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
        case 'iosLibrary':
          await FileHelper.saveToLibrary(shop);
          setState(() {
            statusMessage = 'Магазин сохранен в ${type}';
          });
          break;
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Ошибка сохранения: $e';
      });
    }
  }

  Future<void> loadFromDirectory(String type) async {
    try {
      final loadedShop = await FileHelper.readFromDirectory(type);
      setState(() {
        loadedShops[type] = loadedShop;
        statusMessage = loadedShop != null
            ? 'Магазин загружен из ${type}'
            : 'Файл в ${type} не найден';
      });
    } catch (e) {
      setState(() {
        loadedShops[type] = null;
        statusMessage = 'Ошибка чтения из ${type}: $e';
      });
    }
  }

  Widget _buildDirectoryButton(String type, String label) {
    // Проверка только для Android-специфичных директорий
    bool isAndroidOnly = ['external', 'externalStorageDirectories', 'externalCacheDirectories'].contains(type);



    if (isAndroidOnly && Platform.isIOS) {
      return SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () => saveToDirectory(type),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: Size(0, 36),
      ),
    );
  }

  Widget _buildLoadButton(String type, String label) {
    // Проверка только для Android-специфичных директорий
    bool isAndroidOnly = ['external', 'externalStorageDirectories', 'externalCacheDirectories'].contains(type);

    if (isAndroidOnly && Platform.isIOS) {
      return SizedBox.shrink(); // Не показываем Android-специфичные кнопки на iOS
    }

    return ElevatedButton(
      onPressed: () => loadFromDirectory(type),
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: Size(0, 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading ? Text('Загрузка...') : Text(shop.name),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category),
                        SizedBox(width: 8),
                        Text(
                          'Категория: ${shop.category}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star),
                        SizedBox(width: 8),
                        Text(
                          'Рейтинг: ${shop.rating}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Адрес: ${shop.address}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Операции с файловой системой',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('Сохранить магазин в:'),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDirectoryButton('temporary', 'Temporary'),
                        _buildDirectoryButton('documents', 'Documents'),
                        _buildDirectoryButton('support', 'Support'),
                        _buildDirectoryButton('cache', 'Cache'),
                        _buildDirectoryButton('library', 'Library'),
                        _buildDirectoryButton('downloads', 'Downloads'),
                        _buildDirectoryButton('external', 'External'),
                        _buildDirectoryButton('externalStorageDirectories', 'Ext. Storage Dirs'),
                        _buildDirectoryButton('externalCacheDirectories', 'Ext. Cache Dirs'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text('Загрузить магазин из:'),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildLoadButton('temporary', 'Temporary'),
                        _buildLoadButton('documents', 'Documents'),
                        _buildLoadButton('support', 'Support'),
                        _buildLoadButton('cache', 'Cache'),
                        _buildLoadButton('library', 'Library'),
                        _buildLoadButton('downloads', 'Downloads'),
                        _buildLoadButton('external', 'External'),
                        _buildLoadButton('externalStorageDirectories', 'Ext. Storage Dirs'),
                        _buildLoadButton('externalCacheDirectories', 'Ext. Cache Dirs'),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      statusMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...loadedShops.entries.map((entry) {
              if (entry.value == null) return SizedBox.shrink();

              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Загружено из ${entry.key}:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Название: ${entry.value!.name}'),
                      Text('Категория: ${entry.value!.category}'),
                      Text('Рейтинг: ${entry.value!.rating}'),
                      Text('Адрес: ${entry.value!.address}'),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}