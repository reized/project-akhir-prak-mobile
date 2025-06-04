import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/anime_jikan_model.dart';
import 'auth_service.dart';

class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  
  BookmarkService._internal();
  
  factory BookmarkService() => _instance;

  String _getUserSpecificKey(String baseKey) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      return '${baseKey}_${currentUser.username}';
    }
    throw Exception('User tidak login');
  }

  // Cek apakah anime sudah di-bookmark
  Future<bool> isBookmarked(int animeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
      final bookmarks = prefs.getStringList(userBookmarkKey) ?? [];
      return bookmarks.contains(animeId.toString());
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  // Tambah anime ke bookmark
  Future<bool> addBookmark(Anime anime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
      final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
      
      // Tambah ID anime ke list bookmark
      List<String> bookmarks = prefs.getStringList(userBookmarkKey) ?? [];
      if (!bookmarks.contains(anime.malId.toString())) {
        bookmarks.add(anime.malId.toString());
        await prefs.setStringList(userBookmarkKey, bookmarks);
      }
      
      // Tambah detail anime untuk ditampilkan
      List<String> detailedBookmarks = prefs.getStringList(userDetailedBookmarkKey) ?? [];
      
      // Cek apakah sudah ada, jika tidak tambahkan
      bool alreadyExists = detailedBookmarks.any((item) {
        final Map<String, dynamic> itemJson = json.decode(item);
        return itemJson['mal_id'] == anime.malId;
      });
      
      if (!alreadyExists) {
        detailedBookmarks.add(json.encode(anime.toJson()));
        await prefs.setStringList(userDetailedBookmarkKey, detailedBookmarks);
      }
      
      return true;
    } catch (e) {
      print('Error adding bookmark: $e');
      return false;
    }
  }

  // Hapus anime dari bookmark
  Future<bool> removeBookmark(int animeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
      final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
      
      // Hapus ID dari list bookmark
      List<String> bookmarks = prefs.getStringList(userBookmarkKey) ?? [];
      bookmarks.remove(animeId.toString());
      await prefs.setStringList(userBookmarkKey, bookmarks);
      
      // Hapus detail anime
      List<String> detailedBookmarks = prefs.getStringList(userDetailedBookmarkKey) ?? [];
      detailedBookmarks.removeWhere((item) {
        final Map<String, dynamic> itemJson = json.decode(item);
        return itemJson['mal_id'] == animeId;
      });
      await prefs.setStringList(userDetailedBookmarkKey, detailedBookmarks);
      
      return true;
    } catch (e) {
      print('Error removing bookmark: $e');
      return false;
    }
  }

  // Toggle bookmark status
  Future<bool> toggleBookmark(Anime anime) async {
    final isCurrentlyBookmarked = await isBookmarked(anime.malId);
    
    if (isCurrentlyBookmarked) {
      return await removeBookmark(anime.malId);
    } else {
      return await addBookmark(anime);
    }
  }

  // Dapatkan semua bookmark user
  Future<List<Anime>> getAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
      final List<String> detailedBookmarksJson = prefs.getStringList(userDetailedBookmarkKey) ?? [];
      
      List<Anime> loadedBookmarks = [];
      for (String jsonString in detailedBookmarksJson) {
        try {
          loadedBookmarks.add(Anime.fromLocalStorageJson(json.decode(jsonString)));
        } catch (e) {
          print('Error parsing bookmark: $e');
        }
      }
      
      return loadedBookmarks;
    } catch (e) {
      print('Error loading bookmarks: $e');
      return [];
    }
  }

  // Dapatkan jumlah bookmark
  Future<int> getBookmarkCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
      final bookmarks = prefs.getStringList(userBookmarkKey) ?? [];
      return bookmarks.length;
    } catch (e) {
      print('Error getting bookmark count: $e');
      return 0;
    }
  }

  // Hapus semua bookmark user
  Future<bool> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
      final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
      
      await prefs.remove(userBookmarkKey);
      await prefs.remove(userDetailedBookmarkKey);
      
      return true;
    } catch (e) {
      print('Error clearing bookmarks: $e');
      return false;
    }
  }

  // Migrasi bookmark lama ke sistem baru (untuk user yang sudah ada)
  Future<void> migrateOldBookmarks() async {
    try {
      final authService = AuthService();
      if (authService.currentUser == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Cek apakah ada bookmark lama
      final oldBookmarks = prefs.getStringList('bookmarked_anime');
      final oldDetailedBookmarks = prefs.getStringList('detailed_bookmarks');
      
      if (oldBookmarks != null && oldBookmarks.isNotEmpty) {
        // Pindahkan ke sistem baru
        final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
        final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
        
        // Cek apakah user sudah punya bookmark baru
        final existingBookmarks = prefs.getStringList(userBookmarkKey);
        
        if (existingBookmarks == null || existingBookmarks.isEmpty) {
          await prefs.setStringList(userBookmarkKey, oldBookmarks);
          
          if (oldDetailedBookmarks != null && oldDetailedBookmarks.isNotEmpty) {
            await prefs.setStringList(userDetailedBookmarkKey, oldDetailedBookmarks);
          }
        }
        
        // Hapus data lama setelah migrasi
        await prefs.remove('bookmarked_anime');
        await prefs.remove('detailed_bookmarks');
        
        print('Bookmark migration completed for user: ${authService.currentUser!.username}');
      }
    } catch (e) {
      print('Error during bookmark migration: $e');
    }
  }
}