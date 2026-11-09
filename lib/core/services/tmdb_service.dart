
import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:dio/dio.dart';

class TmdbService {
  static const String baseUrl = 'https://api.themoviedb.org/3';

  static const String accessToken =
      String.fromEnvironment('TMDB_ACCESS_TOKEN');

  static const Duration _discoveryCacheDuration = Duration(minutes: 5);
  static const Duration _searchCacheDuration = Duration(minutes: 1);
  static const Duration _detailsCacheDuration = Duration(minutes: 15);
  static const Duration _creditsCacheDuration = Duration(minutes: 30);

  static const int _maximumConcurrentRequests = 4;
  static const int _maximumRetries = 2;
  static const int _maximumCacheEntries = 120;

  late final Dio dio;

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  int _activeRequests = 0;
  final List<Completer<void>> _requestQueue = [];

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
        sendTimeout: const Duration(seconds: 15),
      ),
    );
  }

  // ------------------------------------------------------------
  // REQUEST CONCURRENCY CONTROL
  // ------------------------------------------------------------

  Future<void> _acquireRequestSlot() async {
    if (_activeRequests < _maximumConcurrentRequests) {
      _activeRequests++;
      return;
    }

    final completer = Completer<void>();
    _requestQueue.add(completer);

    await completer.future;
  }

  void _releaseRequestSlot() {
    if (_requestQueue.isNotEmpty) {
      final nextRequest = _requestQueue.removeAt(0);
      nextRequest.complete();
    } else {
      _activeRequests--;
    }
  }

  // ------------------------------------------------------------
  // RESPONSE CACHE AND DUPLICATE REQUEST PREVENTION
  // ------------------------------------------------------------

  Future<T> _cachedRequest<T>({
    required String key,
    required Duration duration,
    required Future<T> Function() loader,
  }) async {
    final cached = _cache[key];

    if (cached != null) {
      if (cached.expiresAt.isAfter(DateTime.now())) {
        return cached.value as T;
      }

      _cache.remove(key);
    }

    final existingRequest = _inFlightRequests[key];

    if (existingRequest != null) {
      return await existingRequest as T;
    }

    final request = loader();
    _inFlightRequests[key] = request;

    try {
      final result = await request;

      _cache[key] = _CacheEntry(
        value: result,
        expiresAt: DateTime.now().add(duration),
      );

      _removeExpiredCacheEntries();

      while (_cache.length > _maximumCacheEntries) {
        _cache.remove(_cache.keys.first);
      }

      return result;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  void _removeExpiredCacheEntries() {
    final now = DateTime.now();

    _cache.removeWhere(
      (key, entry) => !entry.expiresAt.isAfter(now),
    );
  }

  // ------------------------------------------------------------
  // API REQUEST AND RETRY HANDLING
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> _fetchJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw StateError(
        'TMDB access token is missing. Check your environment configuration.',
      );
    }

    await _acquireRequestSlot();

    try {
      for (var attempt = 0; attempt <= _maximumRetries; attempt++) {
        try {
          final response = await dio.get(
            path,
            queryParameters: queryParameters,
          );

          if (response.data is! Map) {
            throw FormatException(
              'TMDB returned an unexpected response for $path.',
            );
          }

          return Map<String, dynamic>.from(response.data as Map);
        } on DioException catch (error) {
          final statusCode = error.response?.statusCode;

          final shouldRetry = error.type != DioExceptionType.cancel &&
              (statusCode == null ||
                  statusCode == 408 ||
                  statusCode == 429 ||
                  statusCode >= 500);

          if (!shouldRetry || attempt == _maximumRetries) {
            throw _createApiException(path, error);
          }

          await Future.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
        }
      }

      throw TmdbApiException(
        endpoint: path,
        message: 'The request could not be completed.',
      );
    } finally {
      _releaseRequestSlot();
    }
  }

  TmdbApiException _createApiException(
    String path,
    DioException error,
  ) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message;

    if (statusCode == 401) {
      message = 'TMDB rejected the access token.';
    } else if (statusCode == 403) {
      message = 'TMDB denied access to this request.';
    } else if (statusCode == 429) {
      message = 'TMDB request limit reached. Please try again shortly.';
    } else if (statusCode != null && statusCode >= 500) {
      message = 'TMDB is temporarily unavailable.';
    } else if (statusCode != null) {
      message = 'TMDB returned an unsuccessful response.';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'The connection timed out.';
    } else {
      message = 'Unable to connect to TMDB. Check your internet connection.';
    }

    if (responseData is Map &&
        responseData['status_message'] is String &&
        statusCode != 401 &&
        statusCode != 403) {
      message = responseData['status_message'] as String;
    }

    return TmdbApiException(
      endpoint: path,
      statusCode: statusCode,
      message: message,
    );
  }

  // ------------------------------------------------------------
  // COMMON API HELPERS
  // ------------------------------------------------------------

  String _createCacheKey(
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    final sortedParameters = SplayTreeMap<String, dynamic>.from(
      queryParameters ?? <String, dynamic>{},
    );

    return '$path?${jsonEncode(sortedParameters)}';
  }

  Future<List<Map<String, dynamic>>> _getMovieList(
    String path, {
    Map<String, dynamic>? queryParameters,
    Duration cacheDuration = _discoveryCacheDuration,
  }) {
    final key = _createCacheKey(path, queryParameters);

    return _cachedRequest<List<Map<String, dynamic>>>(
      key: key,
      duration: cacheDuration,
      loader: () async {
        final data = await _fetchJson(
          path,
          queryParameters: queryParameters,
        );

        final results = data['results'];

        if (results == null) return [];

        if (results is! List) {
          throw FormatException(
            'TMDB returned an invalid movie list for $path.',
          );
        }

        return results
            .whereType<Map>()
            .map((movie) => Map<String, dynamic>.from(movie))
            .toList();
      },
    );
  }

  Future<Map<String, dynamic>> _getObject(
    String path, {
    Duration cacheDuration = _detailsCacheDuration,
  }) {
    return _cachedRequest<Map<String, dynamic>>(
      key: path,
      duration: cacheDuration,
      loader: () => _fetchJson(path),
    );
  }

  // ------------------------------------------------------------
  // HOME AND DISCOVERY
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTrendingMovies() {
    return _getMovieList('/trending/movie/day');
  }

  Future<List<Map<String, dynamic>>> getMoviesByLanguage(
    String languageCode,
  ) {
    return _getMovieList(
      '/discover/movie',
      queryParameters: {
        'with_original_language': languageCode,
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMoviesByGenre(int genreId) {
    return _getMovieList(
      '/discover/movie',
      queryParameters: {
        'with_genres': genreId,
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getMoviesByGenres(
    List<int> genreIds,
  ) {
    if (genreIds.isEmpty) return Future.value([]);

    return _getMovieList(
      '/discover/movie',
      queryParameters: {
        'with_genres': genreIds.join(','),
        'sort_by': 'popularity.desc',
        'page': 1,
      },
    );
  }

  Future<List<Map<String, dynamic>>> discoverMovies({
    int? genreId,
    int? year,
    double? minimumRating,
    String? languageCode,
    String sortBy = 'popularity.desc',
  }) {
    final parameters = <String, dynamic>{
      'page': 1,
      'sort_by': sortBy,
    };

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

    return _getMovieList(
      '/discover/movie',
      queryParameters: parameters,
    );
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> searchMovies(String query) {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) return Future.value([]);

    return _getMovieList(
      '/search/movie',
      queryParameters: {
        'query': cleanedQuery,
        'include_adult': false,
        'page': 1,
      },
      cacheDuration: _searchCacheDuration,
    );
  }

  Future<List<Map<String, dynamic>>> searchPeople(String query) {
    final cleanedQuery = query.trim();

    if (cleanedQuery.isEmpty) return Future.value([]);

    return _getMovieList(
      '/search/person',
      queryParameters: {
        'query': cleanedQuery,
        'include_adult': false,
        'page': 1,
      },
      cacheDuration: _searchCacheDuration,
    );
  }

  Future<Map<String, dynamic>> getPersonMovieCredits(int personId) {
    return _getObject(
      '/person/$personId/movie_credits',
      cacheDuration: _creditsCacheDuration,
    );
  }

  // ------------------------------------------------------------
  // MOVIE DETAILS AND RELATED CONTENT
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> getMovieDetails(int movieId) {
    return _getObject('/movie/$movieId');
  }

  Future<Map<String, dynamic>> getMovieCredits(int movieId) {
    return _getObject(
      '/movie/$movieId/credits',
      cacheDuration: _creditsCacheDuration,
    );
  }

  Future<List<Map<String, dynamic>>> getMovieRecommendations(
    int movieId,
  ) {
    return _getMovieList(
      '/movie/$movieId/recommendations',
      queryParameters: {'page': 1},
    );
  }

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) {
    return _getMovieList(
      '/movie/$movieId/videos',
      cacheDuration: _creditsCacheDuration,
    );
  }

  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final data = await _cachedRequest<Map<String, dynamic>>(
      key: '/movie/$movieId/watch/providers',
      duration: _creditsCacheDuration,
      loader: () async {
        final response = await _fetchJson(
          '/movie/$movieId/watch/providers',
        );

        final results = response['results'];

        if (results is! Map) return {};

        return Map<String, dynamic>.from(results);
      },
    );

    return data;
  }

  Future<List<Map<String, dynamic>>> getSimilarMovies(int movieId) {
    return _getMovieList(
      '/movie/$movieId/similar',
      queryParameters: {'page': 1},
    );
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  const _CacheEntry({
    required this.value,
    required this.expiresAt,
  });
}

class TmdbApiException implements Exception {
  final String endpoint;
  final int? statusCode;
  final String message;

  const TmdbApiException({
    required this.endpoint,
    this.statusCode,
    required this.message,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';

    return 'TMDB request failed$status: $message [$endpoint]';
  }
}
