import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_state.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../downloads/download_notifier.dart';
import 'search_notifier.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchNotifierProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final downloads = ref.watch(downloadManagerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _onSubmitted,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Songs, artists, or keywords...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchNotifierProvider.notifier).clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),

            // Search Results or Placeholder
            Expanded(
              child: Builder(
                builder: (context) {
                  if (searchState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (searchState.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Search failed: ${searchState.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  if (searchState.results.isEmpty && searchState.query.isNotEmpty) {
                    return const Center(
                      child: Text(
                        'No songs found. Try a different search term.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  }

                  if (searchState.results.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note_rounded, size: 64, color: AppColors.surfaceVariant),
                          SizedBox(height: 12),
                          Text(
                            'Search YouTube to stream or download songs',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  final results = searchState.results;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final track = TrackItem(
                        id: item.id,
                        title: item.title,
                        artist: item.artist,
                        durationSeconds: item.durationSeconds,
                        thumbnailUrl: item.thumbnailUrl,
                      );

                      final isDownloading = downloads.containsKey(track.id);
                      final dlTask = downloads[track.id];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.thumbnailUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: AppColors.surface,
                              child: const Icon(Icons.music_note),
                            ),
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${item.artist} • ${DurationFormatter.formatSeconds(item.durationSeconds)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            dlTask?.isCompleted == true
                                ? Icons.download_done_rounded
                                : isDownloading
                                    ? Icons.downloading_rounded
                                    : Icons.download_rounded,
                            color: dlTask?.isCompleted == true
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            ref.read(downloadManagerProvider.notifier).startDownload(track);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading "${track.title}" as MP3...'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.surfaceVariant,
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          final fullQueue = results
                              .map((r) => TrackItem(
                                    id: r.id,
                                    title: r.title,
                                    artist: r.artist,
                                    durationSeconds: r.durationSeconds,
                                    thumbnailUrl: r.thumbnailUrl,
                                  ))
                              .toList();

                          audioHandler.playTrack(track, queue: fullQueue, index: index);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
