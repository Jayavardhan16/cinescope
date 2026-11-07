import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';
import '../../shared/widgets/movie_card.dart';
import '../movie_details/movie_details_screen.dart';
import '../search/search_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../recommendations/recommendations_screen.dart';
import '../people_search/people_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService tmdbService = TmdbService();

  late Future<List<Map<String, dynamic>>> trendingMovies;
  late Future<List<Map<String, dynamic>>> teluguMovies;
  late Future<List<Map<String, dynamic>>> hindiMovies;
  late Future<List<Map<String, dynamic>>> tamilMovies;
  late Future<List<Map<String, dynamic>>> malayalamMovies;
  late Future<List<Map<String, dynamic>>> kannadaMovies;
  late Future<List<Map<String, dynamic>>> actionMovies;
  late Future<List<Map<String, dynamic>>> comedyMovies;
  late Future<List<Map<String, dynamic>>> romanceMovies;
  late Future<List<Map<String, dynamic>>> horrorMovies;
  late Future<List<Map<String, dynamic>>> thrillerMovies;

  @override
  void initState() {
    super.initState();

    trendingMovies = tmdbService.getTrendingMovies();

    teluguMovies = tmdbService.getMoviesByLanguage('te');
    hindiMovies = tmdbService.getMoviesByLanguage('hi');
    tamilMovies = tmdbService.getMoviesByLanguage('ta');
    malayalamMovies = tmdbService.getMoviesByLanguage('ml');
    kannadaMovies = tmdbService.getMoviesByLanguage('kn');

    actionMovies = tmdbService.getMoviesByGenre(28);
    comedyMovies = tmdbService.getMoviesByGenre(35);
    romanceMovies = tmdbService.getMoviesByGenre(10749);
    horrorMovies = tmdbService.getMoviesByGenre(27);
    thrillerMovies = tmdbService.getMoviesByGenre(53);
  }

  void openMovie(Map<String, dynamic> movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MovieDetailsScreen(movie: movie, tmdbService: tmdbService),
      ),
    );
  }

  void openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchScreen(tmdbService: tmdbService)),
    );
  }

  void openWatchlist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WatchlistScreen(tmdbService: tmdbService),
      ),
    );
  }

  void openRecommendations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationsScreen(tmdbService: tmdbService),
      ),
    );
  }

  void openPeopleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeopleSearchScreen(tmdbService: tmdbService),
      ),
    );
  }

  Widget buildFeaturedMovie() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: trendingMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final movie = snapshot.data!.first;

        final backdropPath = movie['backdrop_path'];
        final imageUrl = backdropPath != null
            ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
            : null;

        final title = movie['title'] ?? 'Featured Movie';
        final overview = movie['overview'] ?? '';
        final rating = movie['vote_average'];

        return GestureDetector(
          onTap: () => openMovie(movie),
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, stackTrace) {},
                    )
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Color(0xDD0B0B0F),
                    Color(0xFF0B0B0F),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'FEATURED MOVIE',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.gold, size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '${(rating as num).toStringAsFixed(1)} / 10',
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    overview.isEmpty
                        ? 'Discover this movie on CineScope.'
                        : overview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => openMovie(movie),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildMovieSection(
    String title,
    Future<List<Map<String, dynamic>>> moviesFuture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 350,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: moviesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Unable to load movies.',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }

              final movies = snapshot.data ?? [];

              if (movies.isEmpty) {
                return const Center(
                  child: Text(
                    'No movies found.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: movies.length,
                separatorBuilder: (context, index) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final movie = movies[index];

                  return Align(
                    alignment: Alignment.topLeft,
                    child: MovieCard(
                      movie: movie,
                      tmdbService: tmdbService,
                      onTap: () => openMovie(movie),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget buildDiscoveryButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.gold, size: 27),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CineScope',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: openWatchlist,
                          tooltip: 'My Watchlist',
                          icon: const Icon(
                            Icons.bookmark_border,
                            color: AppColors.gold,
                            size: 27,
                          ),
                        ),
                        IconButton(
                          onPressed: openSearch,
                          tooltip: 'Search movies',
                          icon: const Icon(
                            Icons.search,
                            color: AppColors.primaryText,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Discover',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Movies worth your time.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    buildDiscoveryButton(
                      title: 'For You',
                      subtitle: 'Personalized recommendations',
                      icon: Icons.auto_awesome,
                      onPressed: openRecommendations,
                    ),
                    const SizedBox(width: 12),
                    buildDiscoveryButton(
                      title: 'Search People',
                      subtitle: 'Find movies by actor or director',
                      icon: Icons.person_search,
                      onPressed: openPeopleSearch,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Featured movie from TMDB trending movies.
                buildFeaturedMovie(),

                const SizedBox(height: 35),
                buildMovieSection('Trending Now', trendingMovies),
                const Text(
                  'Explore by Genre',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 25),
                buildMovieSection('Action', actionMovies),
                buildMovieSection('Comedy', comedyMovies),
                buildMovieSection('Romance', romanceMovies),
                buildMovieSection('Horror', horrorMovies),
                buildMovieSection('Thriller', thrillerMovies),
                const Text(
                  'Indian Cinema',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Explore movies from different Indian film industries.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),
                buildMovieSection('Tollywood', teluguMovies),
                buildMovieSection('Bollywood', hindiMovies),
                buildMovieSection('Kollywood', tamilMovies),
                buildMovieSection('Mollywood', malayalamMovies),
                buildMovieSection('Sandalwood', kannadaMovies),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
