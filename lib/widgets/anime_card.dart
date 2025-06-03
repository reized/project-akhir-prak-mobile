import 'package:flutter/material.dart';
import '../models/anime_result.dart';

class AnimeCard extends StatelessWidget {
  final AnimeResult result;

  const AnimeCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(result.imageUrl, fit: BoxFit.cover, width: double.infinity, height: 180),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Episode: ${result.episode}'),
                Text('Waktu: ${result.timestamp}'),
                Text('Kemiripan: ${(result.similarity * 100).toStringAsFixed(2)}%'),
                if (result.videoUrl != null)
                  TextButton(
                    onPressed: () {
                      // Buka video jika ada
                      _launchURL(context, result.videoUrl!);
                    },
                    child: Text('Lihat Cuplikan'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur buka video belum diimplementasikan.')),
    );
    // Bisa pakai package url_launcher kalau ingin membuka video
  }
}
