import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';
import '../../shared/providers/watchlist_provider.dart';
import '../movie_details/movie_details_screen.dart';

class WatchlistScreen extends StatelessWidget {
  final TmdbService tmdbService;

  const WatchlistScreen({super.key, required this.tmdbService});

  void openMovie(BuildContext context, Map<String, dynamic> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieDetailsScreen(movie: movie, tmdbService: tmdbService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Watchlist')),
      body: Consumer<WatchlistProvider>(
        builder: (context, watchlist, child) {
          if (watchlist.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final movies = watchlist.movies;

          if (movies.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_border,
                      size: 75,
                      color: AppColors.gold,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your watchlist is empty',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore movies and save the ones you want to watch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.secondaryText),
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

          final width = MediaQuery.of(context).size.width;

          final columns = width >= 1100
              ? 5
              : width >= 800
              ? 4
              : width >= 550
              ? 3
              : 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text(
                  '${movies.length} saved ${movies.length == 1 ? 'movie' : 'movies'}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
                  itemCount: movies.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    final movie = movies[index];

                    final poster = movie['poster_path'];
                    final title = movie['title'] ?? 'Unknown Movie';

                    final date = (movie['release_date'] ?? '').toString();

                    final year = date.isEmpty ? 'N/A' : date.split('-').first;

                    final rating =
                        (movie['vote_average'] as num?)?.toDouble() ?? 0;

                    return GestureDetector(
                      onTap: () => openMovie(context, movie),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      poster != null &&
                                          poster.toString().isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl:
                                              'https://image.tmdb.org/t/p/w342$poster',
                                          fit: BoxFit.cover,
                                          errorWidget: (_, url, error) =>
                                              const Icon(
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
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: Material(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    shape: const CircleBorder(),
                                    child: IconButton(
                                      tooltip: 'Remove from watchlist',
                                      onPressed: () {
                                        watchlist.removeMovie(
                                          movie['id'] as int,
                                        );

                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Movie removed from watchlist.',
                                              ),
                                            ),
                                          );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                              const Icon(
                                Icons.star,
                                size: 15,
                                color: AppColors.gold,
                              ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
