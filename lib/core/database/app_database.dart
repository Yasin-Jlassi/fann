import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class LocalTracks extends Table {
  TextColumn get id => text()(); // YouTube video ID
  TextColumn get title => text()();
  TextColumn get artist => text()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get localFilePath => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PlaylistTracks extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id)();
  TextColumn get trackId => text().references(LocalTracks, #id)();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, trackId};
}

@DriftDatabase(tables: [LocalTracks, Playlists, PlaylistTracks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'fann_music_db');
  }

  // --- Track operations ---
  Stream<List<LocalTrack>> watchAllTracks() {
    return select(localTracks).watch();
  }

  Stream<List<LocalTrack>> watchDownloadedTracks() {
    return (select(localTracks)..where((tbl) => tbl.localFilePath.isNotNull())).watch();
  }

  Future<int> insertOrUpdateTrack(LocalTracksCompanion track) {
    return into(localTracks).insertOnConflictUpdate(track);
  }

  Future<int> deleteTrack(String id) {
    return (delete(localTracks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<LocalTrack?> getTrackById(String id) {
    return (select(localTracks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // --- Playlist operations ---
  Stream<List<Playlist>> watchPlaylists() {
    return select(playlists).watch();
  }

  Future<int> createPlaylist(String name) {
    return into(playlists).insert(PlaylistsCompanion.insert(name: name));
  }

  Future<int> deletePlaylist(int id) async {
    await (delete(playlistTracks)..where((tbl) => tbl.playlistId.equals(id))).go();
    return (delete(playlists)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> addTrackToPlaylist(int playlistId, String trackId, int order) {
    return into(playlistTracks).insertOnConflictUpdate(
      PlaylistTracksCompanion.insert(
        playlistId: playlistId,
        trackId: trackId,
        sortOrder: order,
      ),
    );
  }

  Stream<List<LocalTrack>> watchPlaylistTracks(int playlistId) {
    final query = select(playlistTracks).join([
      innerJoin(localTracks, localTracks.id.equalsExp(playlistTracks.trackId)),
    ])
      ..where(playlistTracks.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistTracks.sortOrder)]);

    return query.watch().map((rows) => rows.map((row) => row.readTable(localTracks)).toList());
  }
}
