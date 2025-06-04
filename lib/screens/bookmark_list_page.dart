import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/anime_jikan_model.dart';
import '../widgets/jikan_anime_card.dart';
import '../services/auth_service.dart';

class BookmarkListPage extends StatefulWidget {
  const BookmarkListPage({super.key});

  @override
  State<BookmarkListPage> createState() => _BookmarkListPageState();
}

class _BookmarkListPageState extends State<BookmarkListPage> {
  List<Anime> _bookmarkedAnime = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  String _getUserSpecificKey(String baseKey) {
    final authService = AuthService();
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      return '${baseKey}_${currentUser.username}';
    }
    return baseKey; // Fallback jika tidak ada user
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');
    final List<String> detailedBookmarksJson =
        prefs.getStringList(userDetailedBookmarkKey) ?? [];

    List<Anime> loadedBookmarks = [];
    for (String jsonString in detailedBookmarksJson) {
      try {
        loadedBookmarks
            .add(Anime.fromLocalStorageJson(json.decode(jsonString)));
      } catch (e) {
        print('Error parsing bookmark: $e');
      }
    }

    setState(() {
      _bookmarkedAnime = loadedBookmarks;
      _isLoading = false;
    });
  }

  void _removeBookmark(int malId) async {
    final prefs = await SharedPreferences.getInstance();
    final userBookmarkKey = _getUserSpecificKey('bookmarked_anime');
    final userDetailedBookmarkKey = _getUserSpecificKey('detailed_bookmarks');

    List<String> bookmarks = prefs.getStringList(userBookmarkKey) ?? [];
    bookmarks.remove(malId.toString());
    await prefs.setStringList(userBookmarkKey, bookmarks);

    List<String> detailedBookmarks =
        prefs.getStringList(userDetailedBookmarkKey) ?? [];
    detailedBookmarks.removeWhere((item) {
      final Map<String, dynamic> itemJson = json.decode(item);
      return itemJson['mal_id'] == malId;
    });
    await prefs.setStringList(userDetailedBookmarkKey, detailedBookmarks);

    setState(() {
      _bookmarkedAnime.removeWhere((anime) => anime.malId == malId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dihapus dari Bookmark!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmark ${currentUser?.username ?? ""}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedAnime.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada anime yang di-bookmark.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mulai bookmark anime favorit Anda!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Geser ke kiri untuk menghapus bookmark',
                              style: TextStyle(
                                color: Colors.deepPurple[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _bookmarkedAnime.length,
                        itemBuilder: (context, index) {
                          final anime = _bookmarkedAnime[index];
                          return Dismissible(
                            key: Key(anime.malId.toString()),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _removeBookmark(anime.malId);
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: JikanAnimeCard(anime: anime),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
