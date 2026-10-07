import 'package:flutter/foundation.dart';

class TrackItem {
  final String id;
  final String title;
  final String artist;
  final int? durationSeconds;
  final String? thumbnailUrl;
  final String? localFilePath;

  const TrackItem({
    required this.id,
    required this.title,
    required this.artist,
    this.durationSeconds,
    this.thumbnailUrl,
    this.localFilePath,
  });

  bool get isDownloaded => localFilePath != null && localFilePath!.isNotEmpty;

  TrackItem copyWith({
    String? localFilePath,
  }) {
    return TrackItem(
      id: id,
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
      thumbnailUrl: thumbnailUrl,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}

enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

enum RepeatMode {
  off,
  all,
  one,
}

@immutable
class PlaybackState {
  final TrackItem? currentTrack;
  final PlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final List<TrackItem> queue;
  final int currentIndex;
  final bool isShuffle;
  final RepeatMode repeatMode;
  final String? errorMessage;

  const PlaybackState({
    this.currentTrack,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.repeatMode = RepeatMode.off,
    this.errorMessage,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get hasNext => currentIndex >= 0 && currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackState copyWith({
    TrackItem? currentTrack,
    PlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    List<TrackItem>? queue,
    int? currentIndex,
    bool? isShuffle,
    RepeatMode? repeatMode,
    String? errorMessage,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
