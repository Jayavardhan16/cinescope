import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';
import '../../shared/providers/watchlist_provider.dart';
import '../movie_details/movie_details_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final TmdbService tmdbService;

  const RecommendationsScreen({super.key, required this.tmdbService});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late Future<List<Map<String, dynamic>>> recommendationsFuture;

  @override
  void initState() {
    super.initState();
    recommendationsFuture = loadRecommendations();
  }

  Future<List<Map<String, dynamic>>> loadRecommendations() async {
    final savedMovies = context.read<WatchlistProvider>().movies;

    if (savedMovies.isEmpty) return [];

    final savedIds = savedMovies
        .map((movie) => movie['id'])
        .whereType<int>()
        .toSet();

    final genreIds = <int>{};

    for (final movie in savedMovies) {
      final ids = movie['genre_ids'];

      if (ids is List) {
        for (final id in ids) {
          if (id is int) genreIds.add(id);
        }
      }

      // Some movie objects may contain genres as objects instead.
      final genres = movie['genres'];

      if (genres is List) {
        for (final genre in genres) {
          if (genre is Map && genre['id'] is int) {
            genreIds.add(genre['id'] as int);
          }
        }
      }
    }

    final results = <Map<String, dynamic>>[];

    // Get recommendations from the first five saved movies.
    final moviesToUse = savedMovies.take(5).toList();

    final recommendationRequests = moviesToUse.map((movie) async {
      try {
        return await widget.tmdbService.getMovieRecommendations(
          movie['id'] as int,
        );
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    });

    final recommendationResults = await Future.wait(recommendationRequests);

    for (final list in recommendationResults) {
      results.addAll(list);
    }

    // Also discover movies matching the user's saved genres.
    if (genreIds.isNotEmpty) {
      try {
        final genreMovies = await widget.tmdbService.getMoviesByGenres(
          genreIds.take(5).toList(),
        );

        results.addAll(genreMovies);
      } catch (_) {
        // Keep the movie-based recommendations if genre discovery fails.
      }
    }

    // Remove saved movies and duplicate recommendations.
    final uniqueMovies = <int, Map<String, dynamic>>{};

    for (final movie in results) {
      final id = movie['id'];

      if (id is int && !savedIds.contains(id)) {
        uniqueMovies.putIfAbsent(id, () => movie);
      }
    }

    final finalMovies = uniqueMovies.values.toList();

    finalMovies.sort((a, b) {
      final popularityA = (a['popularity'] as num?)?.toDouble() ?? 0;
      final popularityB = (b['popularity'] as num?)?.toDouble() ?? 0;

      return popularityB.compareTo(popularityA);
    });

    return finalMovies.take(40).toList();
  }

  void refreshRecommendations() {
    setState(() {
      recommendationsFuture = loadRecommendations();
    });
  }

  void openMovie(Map<String, dynamic> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieDetailsScreen(movie: movie, tmdbService: widget.tmdbService),
      ),
    );
  }

  Widget buildMovieGrid(List<Map<String, dynamic>> movies) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(35),
        child: Center(
          child: Text(
            'No recommendations found yet. Try saving more movies!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;

    final columns = width >= 1100
        ? 5
        : width >= 800
        ? 4
        : width >= 550
        ? 3
        : 2;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: movies.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 15,
        mainAxisSpacing: 22,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final movie = movies[index];

        final poster = movie['poster_path'];
        final title = movie['title'] ?? 'Unknown Movie';

        final date = (movie['release_date'] ?? '').toString();
        final year = date.isEmpty ? 'N/A' : date.split('-').first;

        final rating = (movie['vote_average'] as num?)?.toDouble() ?? 0;

        return GestureDetector(
          onTap: () => openMovie(movie),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: poster != null
                        ? CachedNetworkImage(
                            imageUrl: 'https://image.tmdb.org/t/p/w500$poster',
                            fit: BoxFit.cover,
                            errorWidget: (_, url, error) => const Icon(
                              Icons.movie,
                              color: AppColors.secondaryText,
                              size: 40,
                            ),
                          )
                        : Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.movie,
                              color: AppColors.secondaryText,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 15, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    year,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recommended For You'),
        actions: [
          IconButton(
            tooltip: 'Refresh recommendations',
            onPressed: refreshRecommendations,
            icon: const Icon(Icons.refresh, color: AppColors.gold),
          ),
        ],
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, watchlist, child) {
          if (watchlist.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (watchlist.movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_filter_outlined,
                      size: 75,
                      color: AppColors.gold,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Build your movie taste!',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add movies to your Watchlist first. '
                      'We will use their genres and similar movies '
                      'to discover recommendations for you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.explore),
                      label: const Text('Explore Movies'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: recommendationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Unable to load recommendations. Please try again.',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              final movies = snapshot.data ?? [];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
                      child: Text(
                        'Picked based on your Watchlist',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Discover similar movies and explore genres '
                        'you already enjoy.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (movies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${movies.length} recommendations',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    buildMovieGrid(movies),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
