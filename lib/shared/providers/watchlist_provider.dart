import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistProvider extends ChangeNotifier {
  static const String _storageKey = 'cinescope_watchlist';

  List<Map<String, dynamic>> _movies = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get movies => List.unmodifiable(_movies);

  bool get isLoading => _isLoading;

  Future<void> loadWatchlist() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedData = preferences.getString(_storageKey);

      if (savedData != null) {
        final decoded = jsonDecode(savedData) as List;

        _movies = decoded
            .map((movie) => Map<String, dynamic>.from(movie as Map))
            .toList();
      }
    } catch (error) {
      debugPrint('Unable to load watchlist: $error');
      _movies = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isInWatchlist(int movieId) {
    return _movies.any((movie) => movie['id'] == movieId);
  }

  Future<bool> toggleMovie(Map<String, dynamic> movie) async {
    final movieId = movie['id'];

    if (movieId is! int) return false;

    final updatedMovies = List<Map<String, dynamic>>.from(_movies);

    final existingIndex = updatedMovies.indexWhere(
      (item) => item['id'] == movieId,
    );

    final added = existingIndex == -1;

    if (added) {
      updatedMovies.add(Map<String, dynamic>.from(movie));
    } else {
      updatedMovies.removeAt(existingIndex);
    }

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_storageKey, jsonEncode(updatedMovies));

    _movies = updatedMovies;
    notifyListeners();

    return added;
  }

  Future<void> removeMovie(int movieId) async {
    final updatedMovies = _movies
        .where((movie) => movie['id'] != movieId)
        .toList();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_storageKey, jsonEncode(updatedMovies));

    _movies = updatedMovies;
    notifyListeners();
  }
}
