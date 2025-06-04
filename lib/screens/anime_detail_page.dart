import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/anime_jikan_model.dart';
import '../services/jikan_api.dart';

class AnimeDetailPage extends StatefulWidget {
  final int animeId;

  const AnimeDetailPage({super.key, required this.animeId});

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late Future<Anime> _animeDetailsFuture;
  bool _isBookmarked = false;
  Anime? _anime; // To store the fetched anime object

  @override
  void initState() {
    super.initState();
    _animeDetailsFuture = JikanApi.getAnimeDetails(widget.animeId);
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarked_anime') ?? [];
    setState(() {
      _isBookmarked = bookmarks.contains(widget.animeId.toString());
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> bookmarks = prefs.getStringList('bookmarked_anime') ?? [];

    if (_isBookmarked) {
      bookmarks.remove(widget.animeId.toString());
      if (_anime != null) {
        // Also remove from detailed bookmark list if exists
        List<String> detailedBookmarks = prefs.getStringList('detailed_bookmarks') ?? [];
        detailedBookmarks.removeWhere((item) {
          final Map<String, dynamic> itemJson = json.decode(item);
          return itemJson['mal_id'] == _anime!.malId;
        });
        await prefs.setStringList('detailed_bookmarks', detailedBookmarks);
      }
    } else {
      bookmarks.add(widget.animeId.toString());
      if (_anime != null) {
        // Add detailed info for displaying in profile page
        List<String> detailedBookmarks = prefs.getStringList('detailed_bookmarks') ?? [];
        detailedBookmarks.add(json.encode(_anime!.toJson()));
        await prefs.setStringList('detailed_bookmarks', detailedBookmarks);
      }
    }
    await prefs.setStringList('bookmarked_anime', bookmarks);
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Ditambahkan ke Bookmark!' : 'Dihapus dari Bookmark!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Anime'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: FutureBuilder<Anime>(
        future: _animeDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Anime tidak ditemukan.'));
          }

          _anime = snapshot.data; // Store the fetched anime
          final anime = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: anime.imageUrl,
                      width: 200,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  anime.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                if (anime.synopsis != null && anime.synopsis!.isNotEmpty)
                  Text(
                    anime.synopsis!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: 15),
                _buildInfoRow('Episodes', anime.episodes?.toString() ?? 'N/A'),
                _buildInfoRow('Score', anime.score?.toStringAsFixed(2) ?? 'N/A'),
                _buildInfoRow('Rank', anime.rank?.toString() ?? 'N/A'),
                _buildInfoRow('Popularity', anime.popularity?.toString() ?? 'N/A'),
                _buildInfoRow('Genres', anime.genres.join(', ') ),
                _buildInfoRow('Studios', anime.studios.join(', ') ),
                const SizedBox(height: 20),
                Text(
                  'Tonton Sekarang:',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                if (anime.streamingLinks.isNotEmpty)
                  Column(
                    children: anime.streamingLinks.map((link) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL(link.url),
                          icon: const Icon(Icons.play_circle_filled),
                          label: Text('Tonton di ${link.name}'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        _launchURL('https://www.youtube.com/results?search_query=${anime.title} anime'),
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Cari di YouTube'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}