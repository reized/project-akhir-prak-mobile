import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'whatnime.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register user
  Future<bool> registerUser(String username, String password,
      {String? email}) async {
    try {
      final db = await database;

      final existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (existing.isNotEmpty) {
        return false; 
      }

      final user = User(
        username: username,
        password: _hashPassword(password),
        email: email,
      );

      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Login user
  Future<User?> loginUser(String username, String password) async {
    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);

      final maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, hashedPassword],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error logging in user: $e');
      return null;
    }
  }

  // Get user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await database;
      final maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
  
  // Verify user's current password
  Future<bool> verifyPassword(int userId, String password) async {
    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);
      final maps = await db.query(
        'users',
        columns: ['id'],
        where: 'id = ? AND password = ?',
        whereArgs: [userId, hashedPassword],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

  // Update user (can update email and/or password)
  Future<bool> updateUser(User user) async {
    try {
      final db = await database;
      // Ensure the password in the user object is hashed if it's being changed
      // The AuthService should handle providing the correctly hashed password in the User object
      final result = await db.update(
        'users',
        user.toMap(), // User object should contain new email and/or new hashed password
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}