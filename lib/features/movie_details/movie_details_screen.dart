import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/watchlist_action_button.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final TmdbService tmdbService;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.tmdbService,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late Future<List<dynamic>> movieDataFuture;

  @override
  void initState() {
    super.initState();
    movieDataFuture = loadMovieData();
  }

  Future<List<dynamic>> loadMovieData() {
    final id = widget.movie['id'] as int;

    return Future.wait([
      widget.tmdbService.getMovieDetails(id),
      widget.tmdbService.getMovieCredits(id),
      widget.tmdbService.getMovieVideos(id),
      widget.tmdbService.getWatchProviders(id),
      widget.tmdbService.getSimilarMovies(id),
    ]);
  }

  Future<void> openExternalLink(String? url) async {
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 28),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget providerSection(String title, List providers, String? link) {
    if (providers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: providers.map((provider) {
            final item = Map<String, dynamic>.from(provider);
            final logo = item['logo_path'];

            return SizedBox(
              width: 85,
              child: Column(
                children: [
                  if (logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: 'https://image.tmdb.org/t/p/w92$logo',
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    item['provider_name'] ?? 'Provider',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (link != null && link.isNotEmpty)
          TextButton.icon(
            onPressed: () => openExternalLink(link),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View availability'),
          ),
      ],
    );
  }

  Widget buildSimilarMovies(List movies) {
    if (movies.isEmpty) {
      return const Text(
        'No similar movies found.',
        style: TextStyle(color: AppColors.secondaryText),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length > 12 ? 12 : movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final movie = Map<String, dynamic>.from(movies[index]);
          final poster = movie['poster_path'];

          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(
                    movie: movie,
                    tmdbService: widget.tmdbService,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: 125,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: poster != null
                          ? CachedNetworkImage(
                              imageUrl:
                                  'https://image.tmdb.org/t/p/w342$poster',
                              width: 125,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.movie),
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    movie['title'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Movie Details'),
        actions: [WatchlistActionButton(movie: widget.movie)],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: movieDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Unable to load movie details. Please try again.',
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          final details = Map<String, dynamic>.from(snapshot.data![0]);
          final credits = Map<String, dynamic>.from(snapshot.data![1]);
          final videos = snapshot.data![2] as List;
          final watchProviders = Map<String, dynamic>.from(snapshot.data![3]);
          final similarMovies = snapshot.data![4] as List;

          final cast = (credits['cast'] as List?) ?? [];
          final crew = (credits['crew'] as List?) ?? [];
          final genres = (details['genres'] as List?) ?? [];

          final director = crew
              .cast<Map<String, dynamic>>()
              .where((person) => person['job'] == 'Director')
              .firstOrNull;

          final trailer = videos
              .cast<Map<String, dynamic>>()
              .where(
                (video) =>
                    video['site'] == 'YouTube' && video['type'] == 'Trailer',
              )
              .firstOrNull;

          final india = watchProviders['IN'] == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(watchProviders['IN']);

          final posterPath = details['poster_path'];
          final backdropPath = details['backdrop_path'];
          final title = details['title'] ?? 'Unknown Movie';
          final overview = details['overview'] ?? 'No overview available.';
          final rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
          final releaseDate = details['release_date'] ?? 'Unknown release date';
          final runtime = details['runtime'];
          final providerLink = india['link']?.toString();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cinematic backdrop
                if (backdropPath != null)
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/w1280$backdropPath',
                          fit: BoxFit.cover,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (posterPath != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w342$posterPath',
                                width: 125,
                                height: 185,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: AppColors.gold,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  releaseDate,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                if (runtime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '$runtime minutes',
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: genres.map((genre) {
                                    return Chip(
                                      label: Text(
                                        genre['name'] ?? '',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: AppColors.surface,
                                      side: BorderSide.none,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      sectionTitle('Overview'),
                      Text(
                        overview,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      sectionTitle('Director'),
                      Text(
                        director?['name'] ?? 'Not available',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                        ),
                      ),

                      sectionTitle('Cast'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: cast.take(12).map((person) {
                          final name = person['name'] ?? 'Unknown';
                          final character = person['character'] ?? '';

                          return Container(
                            width: 145,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  character,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      sectionTitle('Watch Trailer'),
                      if (trailer != null)
                        ElevatedButton.icon(
                          onPressed: () => openExternalLink(
                            'https://www.youtube.com/watch?v=${trailer['key']}',
                          ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Watch on YouTube'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                          ),
                        )
                      else
                        const Text(
                          'Trailer not available.',
                          style: TextStyle(color: AppColors.secondaryText),
                        ),

                      sectionTitle('Where to Watch in India'),
                      if (india.isEmpty)
                        const Text(
                          'Streaming availability is not currently listed for India.',
                          style: TextStyle(color: AppColors.secondaryText),
                        )
                      else ...[
                        providerSection(
                          'Stream',
                          (india['flatrate'] as List?) ?? [],
                          providerLink,
                        ),
                        providerSection(
                          'Rent',
                          (india['rent'] as List?) ?? [],
                          providerLink,
                        ),
                        providerSection(
                          'Buy',
                          (india['buy'] as List?) ?? [],
                          providerLink,
                        ),
                      ],

                      sectionTitle('You May Also Like'),
                      buildSimilarMovies(similarMovies),

                      const SizedBox(height: 30),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 10),
                      const Text(
                        'Movie data provided by TMDB. Streaming availability '
                        'provided by JustWatch.',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
