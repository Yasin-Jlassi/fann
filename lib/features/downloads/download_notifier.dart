import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_state.dart';
import '../../core/download/download_service.dart';
import '../../core/providers/core_providers.dart';

class DownloadManagerNotifier extends StateNotifier<Map<String, DownloadTask>> {
  final DownloadService _downloadService;

  DownloadManagerNotifier(this._downloadService) : super({});

  Future<void> startDownload(TrackItem track) async {
    if (state.containsKey(track.id) && state[track.id]!.isCompleted) {
      return;
    }

    state = {
      ...state,
      track.id: DownloadTask(
        videoId: track.id,
        title: track.title,
        artist: track.artist,
        stage: 'Starting...',
      ),
    };

    try {
      await _downloadService.downloadAndSave(
        videoId: track.id,
        title: track.title,
        artist: track.artist,
        thumbnailUrl: track.thumbnailUrl,
        durationSeconds: track.durationSeconds,
        onProgress: (progress, stage) {
          state = {
            ...state,
            track.id: state[track.id]!.copyWith(
              progress: progress,
              stage: stage,
              isCompleted: progress >= 1.0,
            ),
          };
        },
      );
    } catch (e) {
      state = {
        ...state,
        track.id: state[track.id]!.copyWith(
          stage: 'Failed',
          error: e.toString(),
        ),
      };
    }
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManagerNotifier, Map<String, DownloadTask>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return DownloadManagerNotifier(service);
});
