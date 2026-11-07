import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';

class MovieCard extends StatefulWidget {
  final Map<String, dynamic> movie;
  final TmdbService tmdbService;
  final VoidCallback onTap;

  const MovieCard({
    super.key,
    required this.movie,
    required this.tmdbService,
    required this.onTap,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool isHovered = false;
  Future<Map<String, dynamic>>? creditsFuture;

  void handleHover(bool hovering) {
    if (hovering && creditsFuture == null) {
      final id = widget.movie['id'];

      if (id is int) {
        creditsFuture = widget.tmdbService.getMovieCredits(id);
      }
    }

    if (mounted) {
      setState(() => isHovered = hovering);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;

    final title = movie['title'] ?? 'Unknown Movie';
    final posterPath = movie['poster_path'];
    final releaseDate = (movie['release_date'] ?? '').toString();

    final year = releaseDate.isEmpty ? 'N/A' : releaseDate.split('-').first;

    final rating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0;

    final screenWidth = MediaQuery.sizeOf(context).width;

    final normalWidth = 170.0;
    final expandedWidth = screenWidth < 600 ? 230.0 : 260.0;

    return MouseRegion(
      onEnter: (_) => handleHover(true),
      onExit: (_) => handleHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isHovered ? expandedWidth : normalWidth,
          height: isHovered ? 325 : 285,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isHovered ? AppColors.gold : AppColors.border,
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Movie poster.
              if (posterPath != null && posterPath.toString().isNotEmpty)
                CachedNetworkImage(
                  imageUrl: 'https://image.tmdb.org/t/p/w500$posterPath',
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: AppColors.secondaryText,
                      size: 45,
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.movie_outlined,
                    color: AppColors.secondaryText,
                    size: 45,
                  ),
                ),

              // Poster readability gradient.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.90),
                    ],
                    stops: const [0.0, 0.35, 1.0],
                  ),
                ),
              ),

              // Normal poster information.
              if (!isHovered)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 13,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            year,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Expanded hover information.
              if (isHovered)
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 15,
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: creditsFuture,
                    builder: (context, snapshot) {
                      final credits = snapshot.data ?? {};

                      final crew = (credits['crew'] as List?) ?? [];

                      final cast = (credits['cast'] as List?) ?? [];

                      Map<String, dynamic>? director;

                      for (final person in crew) {
                        if (person is Map<String, dynamic> &&
                            person['job'] == 'Director') {
                          director = person;
                          break;
                        }
                      }

                      final actors = cast
                          .take(3)
                          .map((person) => person['name'] ?? '')
                          .where((name) => name.toString().isNotEmpty)
                          .join(', ');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.gold,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                year,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const LinearProgressIndicator(
                              color: AppColors.gold,
                              minHeight: 2,
                            )
                          else if (snapshot.hasError)
                            const Text(
                              'Credits unavailable.',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            )
                          else ...[
                            Text(
                              'DIRECTOR',
                              style: TextStyle(
                                color: AppColors.gold.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              director?['name'] ?? 'Not available',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'CAST',
                              style: TextStyle(
                                color: AppColors.gold.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              actors.isEmpty ? 'Not available' : actors,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          const Row(
                            children: [
                              Icon(
                                Icons.open_in_new,
                                color: AppColors.gold,
                                size: 15,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Click to explore movie',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
