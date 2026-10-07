import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart' hide PlaybackState;
import 'package:just_audio/just_audio.dart';
import '../youtube/youtube_service.dart';
import 'audio_state.dart';

class FannAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YouTubeService _ytService;
  
  List<TrackItem> _playlist = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  final _stateController = StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get stateStream => _stateController.stream;

  FannAudioHandler(this._ytService) {
    _listenToPlayerEvents();
  }

  void _listenToPlayerEvents() {
    _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _handleTrackEnded();
      }
      _broadcastState();
    });

    _player.positionStream.listen((_) => _broadcastState());
    _player.bufferedPositionStream.listen((_) => _broadcastState());
    _player.durationStream.listen((_) => _broadcastState());
  }

  void _broadcastState() {
    final status = _mapProcessingState(_player.playerState);
    final track = (_currentIndex >= 0 && _currentIndex < _playlist.length) 
        ? _playlist[_currentIndex] 
        : null;

    final state = PlaybackState(
      currentTrack: track,
      status: status,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      duration: _player.duration ?? Duration.zero,
      queue: _playlist,
      currentIndex: _currentIndex,
      isShuffle: _isShuffle,
      repeatMode: _repeatMode,
    );

    _stateController.add(state);

    if (Platform.isAndroid && track != null) {
      mediaItem.add(MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        duration: _player.duration,
        artUri: track.thumbnailUrl != null ? Uri.tryParse(track.thumbnailUrl!) : null,
      ));

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
      ));
    }
  }

  PlaybackStatus _mapProcessingState(PlayerState state) {
    if (state.processingState == ProcessingState.loading) return PlaybackStatus.loading;
    if (state.processingState == ProcessingState.buffering) return PlaybackStatus.buffering;
    if (state.processingState == ProcessingState.completed) return PlaybackStatus.completed;
    if (state.playing) return PlaybackStatus.playing;
    if (!state.playing && state.processingState == ProcessingState.ready) return PlaybackStatus.paused;
    return PlaybackStatus.idle;
  }

  Future<void> playTrack(TrackItem track, {List<TrackItem>? queue, int? index}) async {
    if (queue != null) {
      _playlist = List.from(queue);
      _currentIndex = index ?? _playlist.indexWhere((t) => t.id == track.id);
    } else {
      _playlist = [track];
      _currentIndex = 0;
    }

    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    final track = _playlist[_currentIndex];

    try {
      if (track.localFilePath != null && File(track.localFilePath!).existsSync()) {
        await _player.setFilePath(track.localFilePath!);
      } else {
        final streamUri = await _ytService.getAudioStreamUrl(track.id);
        await _player.setUrl(streamUri.toString());
      }
      await _player.play();
    } catch (e) {
      _stateController.add(PlaybackState(
        currentTrack: track,
        status: PlaybackStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _handleTrackEnded() {
    if (_repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (hasNext) {
      skipToNext();
    } else if (_repeatMode == RepeatMode.all && _playlist.isNotEmpty) {
      _currentIndex = 0;
      _loadAndPlayCurrent();
    }
  }

  bool get hasNext => _currentIndex >= 0 && _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (hasNext) {
      _currentIndex++;
      await _loadAndPlayCurrent();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (hasPrevious) {
      _currentIndex--;
      await _loadAndPlayCurrent();
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _broadcastState();
  }

  void toggleRepeat() {
    if (_repeatMode == RepeatMode.off) {
      _repeatMode = RepeatMode.all;
    } else if (_repeatMode == RepeatMode.all) {
      _repeatMode = RepeatMode.one;
    } else {
      _repeatMode = RepeatMode.off;
    }
    _broadcastState();
  }

  void addToQueue(TrackItem track) {
    _playlist.add(track);
    _broadcastState();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    _broadcastState();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        if (_currentIndex < _playlist.length) {
          _loadAndPlayCurrent();
        } else {
          _currentIndex = _playlist.length - 1;
          if (_currentIndex >= 0) {
            _loadAndPlayCurrent();
          } else {
            _player.stop();
          }
        }
      }
      _broadcastState();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _stateController.close();
  }
}
