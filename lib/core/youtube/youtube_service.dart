import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSearchResult {
  final String id;
  final String title;
  final String artist;
  final int? durationSeconds;
  final String thumbnailUrl;

  const YouTubeSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    this.durationSeconds,
    required this.thumbnailUrl,
  });

  factory YouTubeSearchResult.fromVideo(Video video) {
    return YouTubeSearchResult(
      id: video.id.value,
      title: video.title,
      artist: video.author,
      durationSeconds: video.duration?.inSeconds,
      thumbnailUrl: video.thumbnails.highResUrl,
    );
  }
}

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<YouTubeSearchResult>> search(String query, {int limit = 20}) async {
    final searchList = await _yt.search.search(query);
    final results = <YouTubeSearchResult>[];
    for (final video in searchList.take(limit)) {
      results.add(YouTubeSearchResult.fromVideo(video));
    }
    return results;
  }

  Future<Uri> getAudioStreamUrl(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return audioStream.url;
  }

  Future<AudioStreamInfo> getAudioStreamInfo(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    return manifest.audioOnly.withHighestBitrate();
  }

  Stream<List<int>> getAudioStream(AudioStreamInfo streamInfo) {
    return _yt.videos.streamsClient.get(streamInfo);
  }

  Future<Video> getVideoDetails(String videoId) async {
    return await _yt.videos.get(videoId);
  }

  void dispose() {
    _yt.close();
  }
}
