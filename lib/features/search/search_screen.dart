import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';
import '../movie_details/movie_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final TmdbService tmdbService;

  const SearchScreen({super.key, required this.tmdbService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  Timer? debounce;

  late Future<List<Map<String, dynamic>>> moviesFuture;

  String searchQuery = '';
  int selectedGenre = 0;
  String selectedLanguage = '';
  double minimumRating = 0;
  String sortBy = 'popularity.desc';

  final Map<int, String> genres = {
    0: 'All Genres',
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    18: 'Drama',
    14: 'Fantasy',
    27: 'Horror',
    10749: 'Romance',
    878: 'Science Fiction',
    53: 'Thriller',
  };

  final Map<String, String> languages = {
    '': 'All Languages',
    'en': 'English',
    'te': 'Telugu',
    'hi': 'Hindi',
    'ta': 'Tamil',
    'ml': 'Malayalam',
    'kn': 'Kannada',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'es': 'Spanish',
    'fr': 'French',
  };

  @override
  void initState() {
    super.initState();
    moviesFuture = widget.tmdbService.discoverMovies();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    yearController.dispose();
    super.dispose();
  }

  int? get selectedYear {
    final value = int.tryParse(yearController.text.trim());

    if (value == null || value < 1888 || value > DateTime.now().year + 5) {
      return null;
    }

    return value;
  }

  void searchChanged(String value) {
    searchQuery = value.trim();

    setState(() {});

    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        moviesFuture = searchQuery.isEmpty
            ? loadFilteredMovies()
            : widget.tmdbService.searchMovies(searchQuery);
      });
    });
  }

  Future<List<Map<String, dynamic>>> loadFilteredMovies() {
    return widget.tmdbService.discoverMovies(
      genreId: selectedGenre,
      year: selectedYear,
      minimumRating: minimumRating,
      languageCode: selectedLanguage,
      sortBy: sortBy,
    );
  }

  void updateFilters() {
    setState(() {
      if (searchQuery.isEmpty) {
        moviesFuture = loadFilteredMovies();
      }
    });
  }

  List<Map<String, dynamic>> applySearchFilters(
    List<Map<String, dynamic>> movies,
  ) {
    var filtered = movies.where((movie) {
      if (selectedGenre != 0) {
        final ids = (movie['genre_ids'] as List?) ?? [];
        if (!ids.contains(selectedGenre)) return false;
      }

      if (selectedLanguage.isNotEmpty) {
        if (movie['original_language'] != selectedLanguage) {
          return false;
        }
      }

      if (selectedYear != null) {
        final date = (movie['release_date'] ?? '').toString();
        if (!date.startsWith(selectedYear.toString())) return false;
      }

      final rating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0;

      if (rating < minimumRating) return false;

      return true;
    }).toList();

    if (sortBy == 'vote_average.desc') {
      filtered.sort((a, b) {
        final ratingA = (a['vote_average'] as num?)?.toDouble() ?? 0;
        final ratingB = (b['vote_average'] as num?)?.toDouble() ?? 0;
        return ratingB.compareTo(ratingA);
      });
    } else {
      filtered.sort((a, b) {
        final popularityA = (a['popularity'] as num?)?.toDouble() ?? 0;
        final popularityB = (b['popularity'] as num?)?.toDouble() ?? 0;
        return popularityB.compareTo(popularityA);
      });
    }

    return filtered;
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

  Widget buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 165,
              child: DropdownButtonFormField<int>(
                initialValue: selectedGenre,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: AppColors.surface,
                items: genres.entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedGenre = value ?? 0;
                  updateFilters();
                },
              ),
            ),
            SizedBox(
              width: 165,
              child: DropdownButtonFormField<String>(
                initialValue: selectedLanguage,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: AppColors.surface,
                items: languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedLanguage = value ?? '';
                  updateFilters();
                },
              ),
            ),
            SizedBox(
              width: 125,
              child: TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Release year',
                  hintText: 'e.g. 2024',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (_) => updateFilters(),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: sortBy,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sort by',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(
                    value: 'popularity.desc',
                    child: Text('Popularity'),
                  ),
                  DropdownMenuItem(
                    value: 'vote_average.desc',
                    child: Text('Rating'),
                  ),
                ],
                onChanged: (value) {
                  sortBy = value ?? 'popularity.desc';
                  updateFilters();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'Minimum rating',
              style: TextStyle(color: AppColors.primaryText),
            ),
            const Spacer(),
            Text(
              minimumRating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: minimumRating,
          min: 0,
          max: 9,
          divisions: 18,
          activeColor: AppColors.gold,
          inactiveColor: AppColors.border,
          onChanged: (value) {
            setState(() {
              minimumRating = value;
              if (searchQuery.isEmpty) {
                moviesFuture = loadFilteredMovies();
              }
            });
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              searchController.clear();
              yearController.clear();
              debounce?.cancel();

              setState(() {
                searchQuery = '';
                selectedGenre = 0;
                selectedLanguage = '';
                minimumRating = 0;
                sortBy = 'popularity.desc';
                moviesFuture = loadFilteredMovies();
              });
            },
            child: const Text(
              'Clear filters',
              style: TextStyle(color: AppColors.gold),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildMovieGrid(List<Map<String, dynamic>> movies) {
    if (movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(35),
          child: Text(
            'No movies found. Try changing your search or filters.',
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
      padding: const EdgeInsets.only(bottom: 25),
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
        final rating = (movie['vote_average'] as num?)?.toDouble() ?? 0.0;

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
                            imageUrl: 'https://image.tmdb.org/t/p/w342$poster',
                            fit: BoxFit.cover,
                            placeholder: (_, url) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.gold,
                              ),
                            ),
                            errorWidget: (_, url, error) => const Center(
                              child: Icon(
                                Icons.movie,
                                color: AppColors.secondaryText,
                                size: 40,
                              ),
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
      appBar: AppBar(title: const Text('Search & Discover')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              onChanged: searchChanged,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'Search movies by title...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          searchChanged('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            buildFilters(),
            const Divider(color: AppColors.border),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Text(
                        'Unable to load movies. Please try again.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                final results = snapshot.data ?? [];
                final filtered = applySearchFilters(results);

                return buildMovieGrid(filtered);
              },
            ),
          ],
        ),
      ),
    );
  }
}
