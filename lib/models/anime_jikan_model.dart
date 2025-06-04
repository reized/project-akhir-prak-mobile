class Anime {
  final int malId;
  final String title;
  final String imageUrl;
  final String? synopsis;
  final int? episodes;
  final double? score;
  final int? rank;
  final int? popularity;
  final List<String> genres;
  final List<String> studios;
  final List<StreamingLink> streamingLinks;

  Anime({
    required this.malId,
    required this.title,
    required this.imageUrl,
    this.synopsis,
    this.episodes,
    this.score,
    this.rank,
    this.popularity,
    this.genres = const [],
    this.studios = const [],
    this.streamingLinks = const [],
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    List<String> genres = [];
    if (json['genres'] != null) {
      genres = List<String>.from(json['genres'].map((x) => x['name']));
    } else if (json['genres_array'] != null) { 
      genres = List<String>.from(json['genres_array'].map((x) => x['name']));
    }

    List<String> studios = [];
    if (json['studios'] != null) {
      studios = List<String>.from(json['studios'].map((x) => x['name']));
    }

    List<StreamingLink> streamingLinks = [];
    if (json['streaming'] != null) {
      streamingLinks = List<StreamingLink>.from(
          json['streaming'].map((x) => StreamingLink.fromJson(x)));
    }

    return Anime(
      malId: json['mal_id'],
      title: json['title'] ?? 'Unknown Title',
      imageUrl: json['images']?['jpg']?['image_url'] ?? '',
      synopsis: json['synopsis'],
      episodes: json['episodes'],
      score: (json['score'] as num?)?.toDouble(),
      rank: json['rank'],
      popularity: json['popularity'],
      genres: genres,
      studios: studios,
      streamingLinks: streamingLinks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mal_id': malId,
      'title': title,
      'image_url': imageUrl, 
      'synopsis': synopsis,
      'episodes': episodes,
      'score': score,
      'rank': rank,
      'popularity': popularity,
      'genres': genres,
      'studios': studios,
      'streamingLinks': streamingLinks.map((e) => e.toJson()).toList(),
    };
  }

  factory Anime.fromLocalStorageJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'],
      title: json['title'],
      imageUrl: json['image_url'],
      synopsis: json['synopsis'],
      episodes: json['episodes'],
      score: json['score'],
      rank: json['rank'],
      popularity: json['popularity'],
      genres: List<String>.from(json['genres'] ?? []),
      studios: List<String>.from(json['studios'] ?? []),
      streamingLinks: List<StreamingLink>.from((json['streamingLinks'] ?? [])
          .map((x) => StreamingLink.fromJson(x))),
    );
  }
}

class StreamingLink {
  final String name;
  final String url;

  StreamingLink({required this.name, required this.url});

  factory StreamingLink.fromJson(Map<String, dynamic> json) {
    return StreamingLink(
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}

class Genre {
  final int malId;
  final String name;

  Genre({required this.malId, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      malId: json['mal_id'],
      name: json['name'],
    );
  }
}