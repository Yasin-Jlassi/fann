import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/audio_player_handler.dart';
import '../audio/audio_state.dart';
import '../database/app_database.dart';
import '../download/download_service.dart';
import '../youtube/youtube_service.dart';

// Core service singletons
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService();
  ref.onDispose(() => service.dispose());
  return service;
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final yt = ref.watch(youtubeServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return DownloadService(yt, db);
});

final audioHandlerProvider = Provider<FannAudioHandler>((ref) {
  final yt = ref.watch(youtubeServiceProvider);
  final handler = FannAudioHandler(yt);
  ref.onDispose(() => handler.dispose());
  return handler;
});

// Playback state stream provider
final playbackStateStreamProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.stateStream;
});
