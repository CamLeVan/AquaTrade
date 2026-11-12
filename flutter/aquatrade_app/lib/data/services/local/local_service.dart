import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalService {
  static Database? _database;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('aquatrade.db');
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
      CREATE TABLE listings (
        id TEXT PRIMARY KEY,
        title TEXT,
        category TEXT,
        species TEXT,
        province TEXT,
        pricePerFish REAL,
        availableQuantity INTEGER,
        thumbnailUrl TEXT,
        status TEXT,
        sellerName TEXT,
        aiVerified INTEGER,
        qualityLabel TEXT,
        isFavorite INTEGER,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        listingTitle TEXT,
        buyerName TEXT,
        sellerName TEXT,
        unitPriceAtPurchase REAL,
        finalQuantity INTEGER,
        totalPrice REAL,
        shippingAddress TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        category TEXT,
        status TEXT,
        featuredImageUrl TEXT,
        author TEXT,
        viewCount INTEGER
      )
    ''');
  }

  Future<void> saveListings(List<Map<String, dynamic>> maps) async {
    await replaceListings(maps);
  }

  /// Xóa cache cũ rồi ghi lại — chỉ cột có trong schema SQLite.
  Future<void> replaceListings(List<Map<String, dynamic>> maps) async {
    final db = await database;
    if (db == null) return;

    await db.delete('listings');
    if (maps.isEmpty) return;

    final batch = db.batch();
    for (var map in maps) {
      batch.insert(
        'listings',
        {
          'id': map['id'],
          'title': map['title'],
          'category': map['category'],
          'species': map['species'],
          'province': map['province'],
          'pricePerFish': map['pricePerFish'],
          'availableQuantity': map['availableQuantity'],
          'thumbnailUrl': map['thumbnailUrl'],
          'status': map['status'],
          'sellerName': map['sellerName'],
          'aiVerified': map['aiVerified'] == true || map['aiVerified'] == 1 ? 1 : 0,
          'qualityLabel': map['qualityLabel'],
          'isFavorite': map['isFavorite'] == true || map['isFavorite'] == 1 ? 1 : 0,
          'createdAt': map['createdAt'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedListings() async {
    final db = await database;
    if (db == null) return [];
    
    final result = await db.query('listings', orderBy: 'createdAt DESC');
    return result.map((row) {
      final map = Map<String, dynamic>.from(row);
      map['aiVerified'] = map['aiVerified'] == 1;
      map['isFavorite'] = map['isFavorite'] == 1;
      return map;
    }).toList();
  }

  // --- Orders ---
  Future<void> saveOrders(List<Map<String, dynamic>> maps) async {
    await replaceOrders(maps);
  }

  /// Xóa cache cũ rồi ghi lại — tránh giữ đơn stale / thiếu đơn mới sau checkout.
  Future<void> replaceOrders(List<Map<String, dynamic>> maps) async {
    final db = await database;
    if (db == null) return;

    await db.delete('orders');
    if (maps.isEmpty) return;

    final batch = db.batch();
    for (var map in maps) {
      batch.insert(
        'orders',
        {
          'id': map['id'],
          'listingTitle': map['listingTitle'],
          'buyerName': map['buyerName'],
          'sellerName': map['sellerName'],
          'unitPriceAtPurchase': map['unitPriceAtPurchase'],
          'finalQuantity': map['finalQuantity'],
          'totalPrice': map['totalPrice'],
          'shippingAddress': map['shippingAddress'],
          'status': map['status'],
          'createdAt': map['createdAt'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedOrders() async {
    final db = await database;
    if (db == null) return [];
    
    return await db.query('orders', orderBy: 'createdAt DESC');
  }

  // --- Posts ---
  Future<void> savePosts(List<Map<String, dynamic>> maps) async {
    final db = await database;
    if (db == null) return;
    
    final batch = db.batch();
    for (var map in maps) {
      batch.insert('posts', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedPosts() async {
    final db = await database;
    if (db == null) return [];
    
    return await db.query('posts');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
