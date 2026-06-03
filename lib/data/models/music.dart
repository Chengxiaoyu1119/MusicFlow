enum MusicSource { local, plugin }

class Music {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? artworkUrl;
  final Duration duration;
  final String? filePath;
  final String? url;
  final MusicSource source;
  final String? pluginId;
  final int trackNumber;
  final int discNumber;
  final int? year;
  final String? genre;

  const Music({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.albumArtist,
    this.artworkUrl,
    this.duration = Duration.zero,
    this.filePath,
    this.url,
    this.source = MusicSource.plugin,
    this.pluginId,
    this.trackNumber = 0,
    this.discNumber = 1,
    this.year,
    this.genre,
  });

  Music copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? artworkUrl,
    Duration? duration,
    String? filePath,
    String? url,
    MusicSource? source,
    String? pluginId,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      source: source ?? this.source,
      pluginId: pluginId ?? this.pluginId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'albumArtist': albumArtist,
    'artworkUrl': artworkUrl,
    'duration': duration.inMilliseconds,
    'filePath': filePath,
    'url': url,
    'source': source.name,
    'pluginId': pluginId,
    'trackNumber': trackNumber,
    'discNumber': discNumber,
    'year': year,
    'genre': genre,
  };

  factory Music.fromJson(Map<String, dynamic> json) => Music(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    album: json['album'] as String? ?? '',
    albumArtist: json['albumArtist'] as String?,
    artworkUrl: json['artworkUrl'] as String?,
    duration: Duration(milliseconds: json['duration'] as int? ?? 0),
    filePath: json['filePath'] as String?,
    url: json['url'] as String?,
    source: MusicSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => MusicSource.plugin,
    ),
    pluginId: json['pluginId'] as String?,
    trackNumber: json['trackNumber'] as int? ?? 0,
    discNumber: json['discNumber'] as int? ?? 1,
    year: json['year'] as int?,
    genre: json['genre'] as String?,
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Music &&
      id == other.id &&
      title == other.title &&
      artist == other.artist;

  @override
  int get hashCode => Object.hash(id, title, artist);
}

class Album {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final int year;
  final int trackCount;
  final List<Music> tracks;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.year = 0,
    this.trackCount = 0,
    this.tracks = const [],
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Album && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> musicIds;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    required this.createdAt,
    required this.updatedAt,
    this.musicIds = const [],
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? musicIds,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      musicIds: musicIds ?? this.musicIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'artworkUrl': artworkUrl,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'musicIds': musicIds,
  };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    artworkUrl: json['artworkUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    musicIds: (json['musicIds'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Playlist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
