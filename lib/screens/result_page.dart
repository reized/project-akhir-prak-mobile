import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/anime_result.dart';

class ResultScreen extends StatelessWidget {
  final List<AnimeResult> results;

  const ResultScreen({super.key, required this.results});

  Future<void> _launchVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Tidak bisa membuka video.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Pencarian')),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: Column(
              children: [
                Image.network(result.imageUrl),
                ListTile(
                  title: Text(result.title),
                  subtitle: Text('Kemiripan: ${(result.similarity * 100).toStringAsFixed(2)}%'),
                ),
                if (result.videoUrl != null)
                  TextButton.icon(
                    onPressed: () => _launchVideo(result.videoUrl!),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Lihat Cuplikan'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
