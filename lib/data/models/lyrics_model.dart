/// A single line in an LRC lyrics file.
class LyricsLine {
  final Duration timestamp;
  final String text;

  const LyricsLine({required this.timestamp, required this.text});
}

/// Parsed LRC lyrics with metadata and sorted lines.
class Lyrics {
  final String? title;
  final String? artist;
  final String? album;
  final String? author;
  final Duration? offset;
  final List<LyricsLine> lines;

  const Lyrics({
    this.title,
    this.artist,
    this.album,
    this.author,
    this.offset,
    this.lines = const [],
  });

  bool get isEmpty => lines.isEmpty;

  /// Get the line index at the given playback position.
  /// Returns -1 if no active line.
  int getLineIndex(Duration position) {
    if (lines.isEmpty) return -1;

    // Apply offset
    final adjusted = offset != null
        ? position - offset!
        : position;

    int index = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= adjusted) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  /// Get progress within the current line (0.0 - 1.0)
  double getLineProgress(Duration position) {
    final idx = getLineIndex(position);
    if (idx < 0) return 0.0;
    if (idx >= lines.length - 1) return 1.0;

    final current = lines[idx].timestamp;
    final next = lines[idx + 1].timestamp;
    final duration = next - current;

    if (duration.inMilliseconds <= 0) return 0.0;
    final pos = position - current;
    return (pos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Parse LRC text into a Lyrics object.
  factory Lyrics.fromLrc(String lrcText) {
    String? title, artist, album, author;
    Duration? offset;
    final lines = <LyricsLine>[];

    final regex = RegExp(
      r'\[(\d{2}):(\d{2})(?:[.:](\d{2,3}))?\](.*)',
    );

    for (final line in lrcText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check metadata tags
      if (trimmed.startsWith('[ti:')) {
        title = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }
      if (trimmed.startsWith('[ar:')) {
        artist = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }
      if (trimmed.startsWith('[al:')) {
        album = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }
      if (trimmed.startsWith('[by:')) {
        author = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }
      if (trimmed.startsWith('[offset:')) {
        final offsetStr = trimmed.substring(8, trimmed.length - 1).trim();
        offset = Duration(milliseconds: int.tryParse(offsetStr) ?? 0);
        continue;
      }

      // Parse timestamped lines
      final matches = regex.allMatches(trimmed);
      for (final match in matches) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3) ?? '0';
        final ms = msStr.length == 2
            ? int.parse(msStr) * 10
            : int.parse(msStr);

        final text = match.group(4)?.trim() ?? '';
        if (text.isEmpty) continue;

        lines.add(LyricsLine(
          timestamp: Duration(
            minutes: min,
            seconds: sec,
            milliseconds: ms,
          ),
          text: text,
        ));
      }
    }

    // Sort by timestamp
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Lyrics(
      title: title,
      artist: artist,
      album: album,
      author: author,
      offset: offset,
      lines: lines,
    );
  }
}
