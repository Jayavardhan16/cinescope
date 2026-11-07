import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/watchlist_provider.dart';

class WatchlistActionButton extends StatelessWidget {
  final Map<String, dynamic> movie;

  const WatchlistActionButton({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final movieId = movie['id'];

    return Consumer<WatchlistProvider>(
      builder: (context, watchlist, child) {
        final isSaved = movieId is int && watchlist.isInWatchlist(movieId);

        return IconButton(
          tooltip: isSaved ? 'Remove from watchlist' : 'Add to watchlist',
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: AppColors.gold,
          ),
          onPressed: () async {
            final added = await context.read<WatchlistProvider>().toggleMovie(
              movie,
            );

            if (!context.mounted) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    added
                        ? 'Added to your watchlist!'
                        : 'Removed from your watchlist.',
                  ),
                ),
              );
          },
        );
      },
    );
  }
}
