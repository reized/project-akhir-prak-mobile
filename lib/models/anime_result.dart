class AnimeResult {
  final String title;
  final String imageUrl;
  final String? videoUrl;
  final int? episode;
  final double similarity;
  final double timestamp;

  AnimeResult({
    required this.title,
    required this.imageUrl,
    required this.similarity,
    required this.timestamp,
    this.videoUrl,
    this.episode,
  });

  factory AnimeResult.fromJson(Map<String, dynamic> json) {
    return AnimeResult(
      title: json['filename'] ?? 'Unknown',
      imageUrl: json['image'] ?? '',
      videoUrl: json['video'],
      episode: json['episode'],
      similarity: (json['similarity'] as num).toDouble(),
      timestamp: (json['from'] as num).toDouble(),
    );
  }
}
