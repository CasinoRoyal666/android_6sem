import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/Shop.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shops.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shops(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        rating REAL NOT NULL,
        category TEXT NOT NULL
      )
    ''');
  }

  // CRUD
  Future<int> insertShop(Shop shop) async {
    final db = await instance.database;
    return await db.insert('shops', shop.toMap());
  }

  Future<List<Shop>> getAllShops() async {
    final db = await instance.database;
    final result = await db.query('shops');
    return result.map((map) => Shop.fromMap(map)).toList();
  }

  Future<Shop?> getShop(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'shops',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Shop.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateShop(Shop shop) async {
    final db = await instance.database;
    return await db.update(
      'shops',
      shop.toMap(),
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  Future<int> deleteShop(int id) async {
    final db = await instance.database;
    return await db.delete(
      'shops',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //sorted
  Future<List<Shop>> getSortedShops(String column, bool ascending) async {
    final db = await instance.database;
    final orderBy = '$column ${ascending ? 'ASC' : 'DESC'}';
    final result = await db.query('shops', orderBy: orderBy);
    return result.map((map) => Shop.fromMap(map)).toList();
  }
}