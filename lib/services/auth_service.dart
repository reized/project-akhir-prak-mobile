import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

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
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}
