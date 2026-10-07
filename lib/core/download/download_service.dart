import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import '../youtube/youtube_service.dart';

class DownloadTask {
  final String videoId;
  final String title;
  final String artist;
  final double progress;
  final String stage;
  final bool isCompleted;
  final String? error;

  DownloadTask({
    required this.videoId,
    required this.title,
    required this.artist,
    this.progress = 0.0,
    this.stage = 'Queued',
    this.isCompleted = false,
    this.error,
  });

  DownloadTask copyWith({
    double? progress,
    String? stage,
    bool? isCompleted,
    String? error,
  }) {
    return DownloadTask(
      videoId: videoId,
      title: title,
      artist: artist,
      progress: progress ?? this.progress,
      stage: stage ?? this.stage,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}

class DownloadService {
  final YouTubeService _ytService;
  final AppDatabase _db;

  DownloadService(this._ytService, this._db);

  Future<String> getAudioDirectory() async {
    if (Platform.isWindows) {
      final appDir = await getApplicationSupportDirectory();
      final audioDir = Directory(p.join(appDir.path, 'fann_downloads'));
      if (!audioDir.existsSync()) {
        await audioDir.create(recursive: true);
      }
      return audioDir.path;
    } else if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      final audioDir = Directory(p.join(extDir?.path ?? (await getApplicationDocumentsDirectory()).path, 'Audio'));
      if (!audioDir.existsSync()) {
        await audioDir.create(recursive: true);
      }
      return audioDir.path;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      return docs.path;
    }
  }

  Future<String> downloadAndSave({
    required String videoId,
    required String title,
    required String artist,
    String? thumbnailUrl,
    int? durationSeconds,
    void Function(double progress, String stage)? onProgress,
  }) async {
    final saveDir = await getAudioDirectory();
    final cleanFileName = videoId.replaceAll(RegExp(r'[^\w\-]'), '_');
    
    // 1. Download raw stream
    onProgress?.call(0.1, 'Connecting stream...');
    final streamInfo = await _ytService.getAudioStreamInfo(videoId);
    final rawExt = streamInfo.container.name;
    final rawFilePath = p.join(saveDir, '$cleanFileName.$rawExt');
    final mp3FilePath = p.join(saveDir, '$cleanFileName.mp3');

    final rawFile = File(rawFilePath);
    final outputSink = rawFile.openWrite();
    final byteStream = _ytService.getAudioStream(streamInfo);

    final totalBytes = streamInfo.size.totalBytes;
    int receivedBytes = 0;

    onProgress?.call(0.2, 'Downloading audio...');
    await for (final chunk in byteStream) {
      outputSink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        final dlProgress = 0.2 + ((receivedBytes / totalBytes) * 0.5);
        onProgress?.call(dlProgress, 'Downloading (${(dlProgress * 100).toInt()}%)');
      }
    }
    await outputSink.flush();
    await outputSink.close();

    // 2. FFmpeg conversion to MP3 if available
    String finalPath = rawFilePath;
    onProgress?.call(0.75, 'Converting to MP3...');

    bool converted = false;
    try {
      final result = await Process.run('ffmpeg', [
        '-i', rawFilePath,
        '-vn',
        '-b:a', '192k',
        '-y',
        mp3FilePath,
      ]);

      if (result.exitCode == 0 && File(mp3FilePath).existsSync()) {
        finalPath = mp3FilePath;
        converted = true;
        if (rawFile.existsSync()) {
          await rawFile.delete();
        }
      }
    } catch (e) {
      debugPrint('FFmpeg fallback: keeping raw audio file ($e)');
    }

    onProgress?.call(0.95, 'Saving to library...');

    // 3. Save metadata to database
    await _db.insertOrUpdateTrack(
      LocalTracksCompanion.insert(
        id: videoId,
        title: title,
        artist: artist,
        durationSeconds: Value(durationSeconds),
        thumbnailUrl: Value(thumbnailUrl),
        localFilePath: Value(finalPath),
      ),
    );

    onProgress?.call(1.0, converted ? 'Completed (MP3)' : 'Completed (Audio)');
    return finalPath;
  }
}
