import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/anime_jikan_model.dart'; 
import '../screens/anime_detail_page.dart';

class JikanAnimeCard extends StatelessWidget {
  final Anime anime;
  final bool compactMode;

  const JikanAnimeCard({
    super.key,
    required this.anime,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    const double nonCompactCardHeight = 330.0;
    const double compactCardWidth = 140.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailPage(animeId: anime.malId),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip
            .antiAlias, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: compactMode
            ? const EdgeInsets.symmetric(
                horizontal: 8) 
            : const EdgeInsets.symmetric(
                horizontal: 8, vertical: 8), 

        child: compactMode
            ? SizedBox(
                // Untuk Carousel
                width: compactCardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: anime.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error, color: Colors.grey)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3, 
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          anime.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(
                // Untuk Grid (non-compact)
                height: nonCompactCardHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: CachedNetworkImage(
                        imageUrl: anime.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(
                              child:
                                  Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                    Expanded(
              
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          
                          children: [
                            Text(
                              anime.title,
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                          
                            if (anime.score != null)
                              Text(
                                'Rating: ${anime.score!.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                            if (anime.episodes != null && anime.episodes! > 0)
                              Text(
                                'Episodes: ${anime.episodes}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[700]),
                              ),
                            if (anime.genres.isNotEmpty)
                              Text(
                                'Genre: ${anime.genres.take(2).join(', ')}...', 
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
