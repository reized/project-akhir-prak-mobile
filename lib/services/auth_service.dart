import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Import for utf8
import 'package:crypto/crypto.dart'; // Import for sha256
import '../models/user_model.dart';
import 'database_helper.dart';
import 'bookmark_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserKey = 'current_user';

  User? _currentUser;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  AuthService._internal();

  factory AuthService() => _instance;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  // Add the hashing method here
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final username = prefs.getString(_currentUserKey);

    if (isLoggedIn && username != null) {
      _currentUser = await _dbHelper.getUserByUsername(username);
    }
  }

  Future<AuthResult> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return AuthResult(
          success: false, message: 'Username dan password tidak boleh kosong');
    }
    // loginUser in DatabaseHelper expects raw password and hashes it for comparison
    final user = await _dbHelper.loginUser(username, password);

    if (user != null) {
      _currentUser = user;
      await _saveLoginState(true, username);
      return AuthResult(success: true, message: 'Login berhasil');
    } else {
      return AuthResult(
          success: false, message: 'Username atau password salah');
    }
  }

  Future<AuthResult> register(String username, String password,
      {String? email}) async {
    if (username.isEmpty || password.isEmpty) {
      return AuthResult(
          success: false, message: 'Username dan password tidak boleh kosong');
    }

    if (password.length < 6) {
      return AuthResult(success: false, message: 'Password minimal 6 karakter');
    }
    if (username.trim().length < 3) {
        return AuthResult(success: false, message: 'Username minimal 3 karakter');
    }

    // registerUser in DatabaseHelper expects raw password and hashes it
    final success =
        await _dbHelper.registerUser(username, password, email: email);

    if (success) {
      return AuthResult(success: true, message: 'Registrasi berhasil');
    } else {
      return AuthResult(success: false, message: 'Username sudah digunakan');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _saveLoginState(false, null);
  }

  Future<void> _saveLoginState(bool isLoggedIn, String? username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    if (username != null) {
      await prefs.setString(_currentUserKey, username);
    } else {
      await prefs.remove(_currentUserKey);
    }
  }

  Future<AuthResult> updateUserDetails({
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult(success: false, message: 'User tidak login');
    }

    String? newHashedPasswordOpt; // Changed variable name to avoid conflict

    if (newPassword != null && newPassword.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        return AuthResult(success: false, message: 'Password saat ini diperlukan untuk mengubah password');
      }
      if (newPassword.length < 6) {
        return AuthResult(success: false, message: 'Password baru minimal 6 karakter');
      }
      // verifyPassword in DatabaseHelper expects raw password
      final passwordVerified = await _dbHelper.verifyPassword(_currentUser!.id!, currentPassword);
      if (!passwordVerified) {
        return AuthResult(success: false, message: 'Password saat ini salah');
      }
      newHashedPasswordOpt = _hashPassword(newPassword); // Use the local _hashPassword
    }

    User updatedUser = _currentUser!.copyWith(
      email: newEmail ?? _currentUser!.email,
      password: newHashedPasswordOpt ?? _currentUser!.password,
    );

    // updateUser in DatabaseHelper expects a User object where password is pre-hashed
    final success = await _dbHelper.updateUser(updatedUser);
    if (success) {
      _currentUser = updatedUser;
      return AuthResult(success: true, message: 'Data berhasil diperbarui');
    } else {
      return AuthResult(success: false, message: 'Gagal memperbarui data');
    }
  }

  Future<AuthResult> deleteCurrentUserAccount(String password) async {
    if (_currentUser == null) {
      return AuthResult(success: false, message: 'User tidak login');
    }
    if (password.isEmpty) {
      return AuthResult(success: false, message: 'Password diperlukan untuk menghapus akun');
    }

    // verifyPassword in DatabaseHelper expects raw password
    final passwordVerified = await _dbHelper.verifyPassword(_currentUser!.id!, password);
    if (!passwordVerified) {
      return AuthResult(success: false, message: 'Password salah');
    }

    final bookmarkService = BookmarkService();
    await bookmarkService.clearAllBookmarks();

    final success = await _dbHelper.deleteUser(_currentUser!.id!);
    if (success) {
      await clearUserData();
      await logout();
      return AuthResult(success: true, message: 'Akun berhasil dihapus');
    } else {
      return AuthResult(success: false, message: 'Gagal menghapus akun');
    }
  }

  String getUserSpecificKey(String baseKey) {
    if (_currentUser != null) {
      return '${baseKey}_${_currentUser!.username}';
    }
    print("Warning: getUserSpecificKey called with no current user for baseKey: $baseKey");
    return '${baseKey}_guest';
  }

  Future<void> clearUserData() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final username = _currentUser!.username;

    final keys = prefs.getKeys();
    final userKeys = keys.where((key) => key.endsWith('_$username')).toList();

    for (String key in userKeys) {
      print('Removing user specific key: $key');
      await prefs.remove(key);
    }
  }

  Future<void> migrateOldBookmarks() async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final oldBookmarksKey = 'bookmarked_anime';
    final oldDetailedBookmarksKey = 'detailed_bookmarks';

    final oldBookmarks = prefs.getStringList(oldBookmarksKey);
    final oldDetailedBookmarks = prefs.getStringList(oldDetailedBookmarksKey);

    if (oldBookmarks != null && oldBookmarks.isNotEmpty) {
      final newBookmarkKey = getUserSpecificKey('bookmarked_anime');
      final newDetailedBookmarkKey = getUserSpecificKey('detailed_bookmarks');

      if (prefs.getStringList(newBookmarkKey) == null) {
        await prefs.setStringList(newBookmarkKey, oldBookmarks);
        print('Migrated bookmarked_anime for user: ${_currentUser!.username}');
      }
      if (oldDetailedBookmarks != null && oldDetailedBookmarks.isNotEmpty) {
         if (prefs.getStringList(newDetailedBookmarkKey) == null) {
            await prefs.setStringList(newDetailedBookmarkKey, oldDetailedBookmarks);
            print('Migrated detailed_bookmarks for user: ${_currentUser!.username}');
         }
      }
      await prefs.remove(oldBookmarksKey);
      await prefs.remove(oldDetailedBookmarksKey);
      print('Removed old global bookmark keys after migration attempt.');
    }
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}