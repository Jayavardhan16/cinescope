import 'package:dio/dio.dart';

class TmdbService {
  static const String baseUrl = 'https://api.themoviedb.org/3';

  static const String accessToken = String.fromEnvironment('TMDB_ACCESS_TOKEN');

  late final Dio dio;

  final Map<int, Future<Map<String, dynamic>>> _creditsCache = {};

  TmdbService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getTrendingMovies() async {
    final response = await dio.get('/trending/movie/day');
    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMoviesByLanguage(
    String languageCode,
  ) async {
    final response = await dio.get(
      '/discover/movie',
      queryParameters: {
        'with_original_language': languageCode,
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMoviesByGenre(int genreId) async {
    final response = await dio.get(
      '/discover/movie',
      queryParameters: {
        'with_genres': genreId,
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  // Discover movies matching any of the supplied genres.
  Future<List<Map<String, dynamic>>> getMoviesByGenres(
    List<int> genreIds,
  ) async {
    if (genreIds.isEmpty) return [];

    final response = await dio.get(
      '/discover/movie',
      queryParameters: {
        'with_genres': genreIds.join(','),
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final response = await dio.get(
      '/search/movie',
      queryParameters: {'query': query, 'include_adult': false, 'page': 1},
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  // Search for actors, actresses, directors and other film professionals.
  Future<List<Map<String, dynamic>>> searchPeople(String query) async {
    final response = await dio.get(
      '/search/person',
      queryParameters: {'query': query, 'include_adult': false, 'page': 1},
    );

    final List people = response.data['results'] ?? [];
    return people.cast<Map<String, dynamic>>();
  }

  // Get both acting and crew credits for a person.
  Future<Map<String, dynamic>> getPersonMovieCredits(int personId) async {
    final response = await dio.get('/person/$personId/movie_credits');
    return Map<String, dynamic>.from(response.data);
  }

  // Get TMDB recommendations for an individual movie.
  Future<List<Map<String, dynamic>>> getMovieRecommendations(
    int movieId,
  ) async {
    final response = await dio.get(
      '/movie/$movieId/recommendations',
      queryParameters: {'page': 1},
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> discoverMovies({
    int? genreId,
    int? year,
    double? minimumRating,
    String? languageCode,
    String sortBy = 'popularity.desc',
  }) async {
    final parameters = <String, dynamic>{'page': 1, 'sort_by': sortBy};

    if (genreId != null && genreId != 0) {
      parameters['with_genres'] = genreId;
    }

    if (year != null) {
      parameters['primary_release_year'] = year;
    }

    if (minimumRating != null && minimumRating > 0) {
      parameters['vote_average.gte'] = minimumRating;
    }

    if (languageCode != null && languageCode.isNotEmpty) {
      parameters['with_original_language'] = languageCode;
    }

    final response = await dio.get(
      '/discover/movie',
      queryParameters: parameters,
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await dio.get('/movie/$movieId');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) {
    return _creditsCache.putIfAbsent(movieId, () async {
      final response = await dio.get('/movie/$movieId/credits');
      return Map<String, dynamic>.from(response.data);
    });
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) async {
    final response = await dio.get('/movie/$movieId/videos');
    final List videos = response.data['results'] ?? [];
    return videos.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final response = await dio.get('/movie/$movieId/watch/providers');
    final results = response.data['results'] ?? {};
    return Map<String, dynamic>.from(results);
  }

  Future<List<Map<String, dynamic>>> getSimilarMovies(int movieId) async {
    final response = await dio.get(
      '/movie/$movieId/similar',
      queryParameters: {'page': 1},
    );

    final List movies = response.data['results'] ?? [];
    return movies.cast<Map<String, dynamic>>();
  }
}
