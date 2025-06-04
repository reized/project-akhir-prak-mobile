
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/anime_jikan_model.dart';
import '../widgets/jikan_anime_card.dart';

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

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final List<String> detailedBookmarksJson = prefs.getStringList('detailed_bookmarks') ?? [];
    
    List<Anime> loadedBookmarks = [];
    for (String jsonString in detailedBookmarksJson) {
      try {
        loadedBookmarks.add(Anime.fromLocalStorageJson(json.decode(jsonString)));
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
    List<String> bookmarks = prefs.getStringList('bookmarked_anime') ?? [];
    bookmarks.remove(malId.toString());
    await prefs.setStringList('bookmarked_anime', bookmarks);

    List<String> detailedBookmarks = prefs.getStringList('detailed_bookmarks') ?? [];
    detailedBookmarks.removeWhere((item) {
      final Map<String, dynamic> itemJson = json.decode(item);
      return itemJson['mal_id'] == malId;
    });
    await prefs.setStringList('detailed_bookmarks', detailedBookmarks);

    setState(() {
      _bookmarkedAnime.removeWhere((anime) => anime.malId == malId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dihapus dari Bookmark!')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Bookmark'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedAnime.isEmpty
              ? const Center(child: Text('Belum ada anime yang di-bookmark.'))
              : ListView.builder(
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
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: JikanAnimeCard(anime: anime), 
                    );
                  },
                ),
    );
  }
}