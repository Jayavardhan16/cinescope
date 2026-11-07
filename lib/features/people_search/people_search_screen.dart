import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/tmdb_service.dart';
import '../movie_details/movie_details_screen.dart';

class PeopleSearchScreen extends StatefulWidget {
  final TmdbService tmdbService;

  const PeopleSearchScreen({super.key, required this.tmdbService});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  final TextEditingController searchController = TextEditingController();

  Timer? debounce;

  Future<List<Map<String, dynamic>>> peopleFuture = Future.value([]);

  Future<Map<String, dynamic>>? creditsFuture;

  Map<String, dynamic>? selectedPerson;

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void searchPeople(String value) {
    debounce?.cancel();

    final query = value.trim();

    setState(() {
      selectedPerson = null;
      creditsFuture = null;
    });

    if (query.isEmpty) {
      setState(() {
        peopleFuture = Future.value([]);
      });
      return;
    }

    debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        peopleFuture = widget.tmdbService.searchPeople(query);
      });
    });
  }

  void selectPerson(Map<String, dynamic> person) {
    setState(() {
      selectedPerson = person;
      creditsFuture = widget.tmdbService.getPersonMovieCredits(
        person['id'] as int,
      );
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

  Widget buildPeopleResults(List<Map<String, dynamic>> people) {
    if (people.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(25),
        child: Text(
          'No people found. Try another name.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final person = people[index];

          final profile = person['profile_path'];
          final name = person['name'] ?? 'Unknown';
          final department =
              person['known_for_department'] ?? 'Film professional';

          final isSelected = selectedPerson?['id'] == person['id'];

          return GestureDetector(
            onTap: () => selectPerson(person),
            child: Container(
              width: 115,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        width: double.infinity,
                        child: profile != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    'https://image.tmdb.org/t/p/w185$profile',
                                fit: BoxFit.cover,
                                errorWidget: (_, url, error) => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.secondaryText,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.secondaryText,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 10,
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

  Widget buildMovieGrid(List<Map<String, dynamic>> movies, String role) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No movie credits found.',
          style: TextStyle(color: AppColors.secondaryText),
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

        final creditRole = movie['_credit_role'] ?? role;

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
              Text(
                creditRole.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.gold, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    year,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
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

  Widget buildFilmography(Map<String, dynamic> credits) {
    final cast = (credits['cast'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final crew = (credits['crew'] as List? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    cast.sort((a, b) {
      final popularityA = (a['popularity'] as num?)?.toDouble() ?? 0;
      final popularityB = (b['popularity'] as num?)?.toDouble() ?? 0;
      return popularityB.compareTo(popularityA);
    });

    crew.sort((a, b) {
      final popularityA = (a['popularity'] as num?)?.toDouble() ?? 0;
      final popularityB = (b['popularity'] as num?)?.toDouble() ?? 0;
      return popularityB.compareTo(popularityA);
    });

    final actingMovies = cast.take(40).toList();

    final crewMovies = crew.take(40).map((movie) {
      return {...movie, '_credit_role': movie['job'] ?? 'Crew'};
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acting Credits',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        buildMovieGrid(actingMovies, 'Actor'),
        const SizedBox(height: 25),
        const Text(
          'Crew Credits',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        buildMovieGrid(crewMovies, 'Crew'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Search by People')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Find movies by actor or director',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter an actor, actress, director or other film '
              'professional and explore their movies.',
              style: TextStyle(color: AppColors.secondaryText, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              onChanged: searchPeople,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                hintText: 'e.g. Allu Arjun, Christopher Nolan...',
                prefixIcon: const Icon(
                  Icons.person_search,
                  color: AppColors.gold,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          searchPeople('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 25),
            if (selectedPerson == null) ...[
              const Text(
                'Select a person',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: peopleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Unable to search people. Please try again.',
                      style: TextStyle(color: AppColors.error),
                    );
                  }

                  if (searchController.text.trim().isEmpty) {
                    return const Text(
                      'Start typing a name to find people.',
                      style: TextStyle(color: AppColors.secondaryText),
                    );
                  }

                  return buildPeopleResults(snapshot.data ?? []);
                },
              ),
            ],
            if (selectedPerson != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedPerson!['name'] ?? 'Film professional',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedPerson = null;
                        creditsFuture = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('People'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              FutureBuilder<Map<String, dynamic>>(
                future: creditsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      'Unable to load this person\'s movies.',
                      style: TextStyle(color: AppColors.error),
                    );
                  }

                  return buildFilmography(snapshot.data!);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
