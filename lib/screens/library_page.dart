import 'package:flutter/material.dart';
import '../services/jikan_api.dart';
import '../models/anime_jikan_model.dart';
import '../widgets/jikan_anime_card.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Anime> _searchResults = [];
  bool _isSearching = false;

  late Future<List<Anime>> _seasonAnimeFuture;
  late Future<List<Anime>> _topRatedAnimeFuture;
  late Future<List<Anime>> _topAnimeFuture;
  late Future<List<Genre>> _genresFuture;

  final List<Anime> _allAnime = [];
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchInitialData() {
    _seasonAnimeFuture = JikanApi.getSeasonNowAnime();
    _topRatedAnimeFuture = JikanApi.getTopAnime(type: 'bypopularity');
    _topAnimeFuture = JikanApi.getTopAnime(type: 'favorite');
    _genresFuture = JikanApi.getGenres();
    _loadAllAnime();
  }

  Future<void> _loadAllAnime() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newAnime = await JikanApi.getAllAnime(
        page: _currentPage,
        limit: 20,
        genreId: _selectedGenreId,
      );
      if (newAnime.isEmpty) {
        _hasMore = false;
      } else {
        _allAnime.addAll(newAnime);
        _currentPage++;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more anime: $e')),
      );
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadAllAnime();
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await JikanApi.searchAnime(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search anime: $e')),
      );
    }
  }

  void _applyGenreFilter(int? genreId) {
    setState(() {
      _selectedGenreId = genreId;
      _allAnime.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
    });
    _loadAllAnime();
  }

  Future<void> _refreshData() async {
    setState(() {
      _allAnime.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoadingMore = false;
      _searchController.clear();
      _isSearching = false;
      _searchResults = [];
    });

    // Reload semua data
    _seasonAnimeFuture = JikanApi.getSeasonNowAnime();
    _topRatedAnimeFuture = JikanApi.getTopAnime(type: 'bypopularity');
    _topAnimeFuture = JikanApi.getTopAnime(type: 'favorite');
    _genresFuture = JikanApi.getGenres();
    await _loadAllAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Cari Anime...',
                    hintText: 'Misal: Naruto, Attack on Titan',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                if (_isSearching)
                  _buildSearchResults()
                else ...[
                  // Current Season Anime Carousel
                  _buildSectionHeader('Sedang Tayang Musim Ini'),
                  _buildAnimeCarousel(_seasonAnimeFuture),
                  const SizedBox(height: 20),

                  // Top Rated Anime Carousel
                  _buildSectionHeader('Rating Teratas'),
                  _buildAnimeCarousel(_topRatedAnimeFuture),
                  const SizedBox(height: 20),

                  // Top Anime (Overall) Carousel
                  _buildSectionHeader('Anime Terbaik'),
                  _buildAnimeCarousel(_topAnimeFuture),
                  const SizedBox(height: 20),

                  // Genre Filter
                  _buildSectionHeader('Filter Genre'),
                  FutureBuilder<List<Genre>>(
                    future: _genresFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child: Text(
                                'Error loading genres: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No genres found.'));
                      }

                      final genres = snapshot.data!;
                      return DropdownButtonFormField<int?>(
                        value: _selectedGenreId,
                        hint: const Text('Pilih Genre'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Genre'),
                          ),
                          ...genres.map((genre) => DropdownMenuItem<int>(
                                value: genre.malId,
                                child: Text(genre.name),
                              )),
                        ],
                        onChanged: _applyGenreFilter,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Discover Anime (All Anime List)
                  _buildSectionHeader('Semua Anime'),
                  _buildAllAnimeGrid(),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_hasMore && _allAnime.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Semua anime telah dimuat.')),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAnimeCarousel(Future<List<Anime>> animeFuture) {
    return FutureBuilder<List<Anime>>(
      future: animeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada anime ditemukan.'));
        }

        final animeList = snapshot.data!;
        return SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animeList.length,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            itemBuilder: (context, index) {
              return JikanAnimeCard(anime: animeList[index], compactMode: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Tidak ada hasil untuk pencarian Anda.'));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.53,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return JikanAnimeCard(anime: _searchResults[index]);
      },
    );
  }

  Widget _buildAllAnimeGrid() {
    if (_allAnime.isEmpty && !_isLoadingMore) {
      return const Center(
          child: Text('Tidak ada anime yang bisa ditampilkan.'));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.53, // Sesuaikan rasio sesuai kebutuhan
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _allAnime.length,
      itemBuilder: (context, index) {
        return JikanAnimeCard(anime: _allAnime[index]);
      },
    );
  }
}
