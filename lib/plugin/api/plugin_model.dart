enum PluginType { musicSource, lyrics, visualizer, other }

class PluginInfo {
  final String id;
  final String name;
  final String version;
  final String description;
  final PluginType type;
  final bool isBuiltin;
  final bool isEnabled;
  final String? author;
  final String? homepage;
  final String? installUrl;

  const PluginInfo({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.type = PluginType.musicSource,
    this.isBuiltin = false,
    this.isEnabled = true,
    this.author,
    this.homepage,
    this.installUrl,
  });

  PluginInfo copyWith({
    String? id,
    String? name,
    String? version,
    String? description,
    PluginType? type,
    bool? isBuiltin,
    bool? isEnabled,
    String? author,
    String? homepage,
    String? installUrl,
  }) {
    return PluginInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      description: description ?? this.description,
      type: type ?? this.type,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      isEnabled: isEnabled ?? this.isEnabled,
      author: author ?? this.author,
      homepage: homepage ?? this.homepage,
      installUrl: installUrl ?? this.installUrl,
    );
  }
}

/// Plugin search result model
class PluginSearchResult {
  final String platform;
  final List<PluginMusicItem> music;
  final List<PluginAlbumItem> albums;
  final List<PluginArtistItem> artists;
  final List<PluginSheetItem> sheets;
  final bool isEnd;

  const PluginSearchResult({
    this.platform = '',
    this.music = const [],
    this.albums = const [],
    this.artists = const [],
    this.sheets = const [],
    this.isEnd = true,
  });
}

class PluginMusicItem {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? artwork;
  final int duration;
  final Map<String, String> qualities;

  const PluginMusicItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.artwork,
    this.duration = 0,
    this.qualities = const {},
  });
}

class PluginAlbumItem {
  final String id;
  final String title;
  final String? artist;
  final String? artwork;
  final int trackCount;

  const PluginAlbumItem({
    required this.id,
    required this.title,
    this.artist,
    this.artwork,
    this.trackCount = 0,
  });
}

class PluginArtistItem {
  final String id;
  final String name;
  final String? artwork;
  final int musicCount;

  const PluginArtistItem({
    required this.id,
    required this.name,
    this.artwork,
    this.musicCount = 0,
  });
}

class PluginSheetItem {
  final String id;
  final String title;
  final String? description;
  final String? artwork;
  final int musicCount;

  const PluginSheetItem({
    required this.id,
    required this.title,
    this.description,
    this.artwork,
    this.musicCount = 0,
  });
}

/// Plugin interface that all music source plugins must implement
abstract class MusicSourcePlugin {
  String get platform;
  String get version;
  String get pluginId;
  bool get isEnabled;

  Future<PluginSearchResult> search(String query, {int page = 1, String type = 'music'});
  Future<String?> getMediaSource(String id, {String quality = 'standard'});
  Future<String?> getLyric(String id);
  Future<List<PluginMusicItem>> getAlbumTracks(String albumId);
  Future<List<PluginMusicItem>> getSheetTracks(String sheetId);
  Future<List<PluginMusicItem>> getArtistTracks(String artistId, {int page = 1});
}
