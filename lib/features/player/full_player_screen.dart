import 'dart:ui';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_state.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';
import '../downloads/download_notifier.dart';
import 'queue_sheet.dart';

class FullPlayerScreen extends ConsumerWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(playbackStateStreamProvider);
    final audioHandler = ref.watch(audioHandlerProvider);
    final downloads = ref.watch(downloadManagerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: stateAsync.when(
        data: (playbackState) {
          final track = playbackState.currentTrack;
          if (track == null) {
            return const Center(child: Text('No song playing'));
          }

          final isPlaying = playbackState.isPlaying;
          final downloadTask = downloads[track.id];

          return Stack(
            children: [
              // 1. Blurred Album Art Background
              if (track.thumbnailUrl != null)
                Positioned.fill(
                  child: Image.network(
                    track.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                ),
              ),

              // 2. Main Player Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 36, color: AppColors.textPrimary),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              letterSpacing: 2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded,
                                size: 28, color: AppColors.textPrimary),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => const QueueSheet(),
                              );
                            },
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Large Album Art with Shadow
                      Container(
                        width: MediaQuery.of(context).size.width * 0.78,
                        height: MediaQuery.of(context).size.width * 0.78,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 36,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: track.thumbnailUrl != null
                              ? Image.network(
                                  track.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.surface,
                                    child: const Icon(Icons.music_note,
                                        size: 80, color: AppColors.textMuted),
                                  ),
                                )
                              : Container(
                                  color: AppColors.surface,
                                  child: const Icon(Icons.music_note,
                                      size: 80, color: AppColors.textMuted),
                                ),
                        ),
                      ),

                      const Spacer(),

                      // Title & Artist + Download action
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Download Button
                          IconButton(
                            icon: Icon(
                              downloadTask?.isCompleted == true || track.isDownloaded
                                  ? Icons.download_done_rounded
                                  : downloadTask != null
                                      ? Icons.downloading_rounded
                                      : Icons.download_rounded,
                              color: downloadTask?.isCompleted == true || track.isDownloaded
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                              size: 28,
                            ),
                            onPressed: () {
                              ref
                                  .read(downloadManagerProvider.notifier)
                                  .startDownload(track);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Downloading "${track.title}" as MP3...'),
                                  backgroundColor: AppColors.surfaceVariant,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Seek Bar
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                            ),
                            child: Slider(
                              value: playbackState.position.inMilliseconds
                                  .toDouble()
                                  .clamp(
                                      0.0,
                                      playbackState.duration.inMilliseconds
                                          .toDouble()),
                              max: playbackState.duration.inMilliseconds > 0
                                  ? playbackState.duration.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (val) {
                                audioHandler
                                    .seek(Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DurationFormatter.format(playbackState.position),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted),
                                ),
                                Text(
                                  DurationFormatter.format(playbackState.duration),
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Shuffle
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: playbackState.isShuffle
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 26,
                            ),
                            onPressed: () => audioHandler.toggleShuffle(),
                          ),

                          // Previous
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded,
                                size: 40, color: AppColors.textPrimary),
                            onPressed: () => audioHandler.skipToPrevious(),
                          ),

                          // Play / Pause
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              iconSize: 42,
                              color: Colors.white,
                              icon: Icon(isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              onPressed: () {
                                if (isPlaying) {
                                  audioHandler.pause();
                                } else {
                                  audioHandler.play();
                                }
                              },
                            ),
                          ),

                          // Next
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded,
                                size: 40, color: AppColors.textPrimary),
                            onPressed: playbackState.hasNext
                                ? () => audioHandler.skipToNext()
                                : null,
                          ),

                          // Repeat
                          IconButton(
                            icon: Icon(
                              playbackState.repeatMode == RepeatMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: playbackState.repeatMode != RepeatMode.off
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 26,
                            ),
                            onPressed: () => audioHandler.toggleRepeat(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
