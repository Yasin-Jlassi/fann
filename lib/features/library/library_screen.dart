import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_state.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/duration_formatter.dart';

final downloadedTracksStreamProvider = StreamProvider<List<LocalTrack>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchDownloadedTracks();
});

final playlistsStreamProvider = StreamProvider<List<Playlist>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPlaylists();
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Playlist', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(appDatabaseProvider).createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadsAsync = ref.watch(downloadedTracksStreamProvider);
    final playlistsAsync = ref.watch(playlistsStreamProvider);
    final audioHandler = ref.watch(audioHandlerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 28, color: AppColors.primary),
                    onPressed: () => _showCreatePlaylistDialog(context),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Downloaded MP3s'),
                Tab(text: 'Playlists'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Downloaded Offline Tracks Tab
                  downloadsAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_done_rounded,
                                  size: 64, color: AppColors.surfaceVariant),
                              SizedBox(height: 12),
                              Text(
                                'No offline downloads yet',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final trackItem = TrackItem(
                            id: track.id,
                            title: track.title,
                            artist: track.artist,
                            durationSeconds: track.durationSeconds,
                            thumbnailUrl: track.thumbnailUrl,
                            localFilePath: track.localFilePath,
                          );

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: track.thumbnailUrl != null
                                  ? Image.network(
                                      track.thumbnailUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.music_note),
                                    )
                                  : const Icon(Icons.music_note),
                            ),
                            title: Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${track.artist} • ${DurationFormatter.formatSeconds(track.durationSeconds)} • Offline MP3',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.textMuted),
                              onPressed: () async {
                                if (track.localFilePath != null) {
                                  final file = File(track.localFilePath!);
                                  if (file.existsSync()) {
                                    await file.delete();
                                  }
                                }
                                ref.read(appDatabaseProvider).deleteTrack(track.id);
                              },
                            ),
                            onTap: () {
                              final queue = tracks
                                  .map((t) => TrackItem(
                                        id: t.id,
                                        title: t.title,
                                        artist: t.artist,
                                        durationSeconds: t.durationSeconds,
                                        thumbnailUrl: t.thumbnailUrl,
                                        localFilePath: t.localFilePath,
                                      ))
                                  .toList();

                              audioHandler.playTrack(trackItem,
                                  queue: queue, index: index);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),

                  // 2. Playlists Tab
                  playlistsAsync.when(
                    data: (playlists) {
                      if (playlists.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.playlist_play_rounded,
                                  size: 64, color: AppColors.surfaceVariant),
                              const SizedBox(height: 12),
                              const Text('No playlists created',
                                  style: TextStyle(color: AppColors.textMuted)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary),
                                onPressed: () => _showCreatePlaylistDialog(context),
                                child: const Text('Create Playlist',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final pl = playlists[index];
                          return Card(
                            color: AppColors.surface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.queue_music_rounded,
                                    color: AppColors.primary),
                              ),
                              title: Text(
                                pl.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Custom Playlist',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  ref.read(appDatabaseProvider).deletePlaylist(pl.id);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
