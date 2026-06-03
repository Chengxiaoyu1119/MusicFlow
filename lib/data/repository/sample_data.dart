/// 离线示例数据 — 让应用即使没有网络 API 也能展示丰富界面
class SampleData {
  static const List<Map<String, dynamic>> recommendPlaylists = [
    {'name': '每日推荐', 'picUrl': '', 'playCount': 3250000},
    {'name': '私人定制', 'picUrl': '', 'playCount': 1890000},
    {'name': '热门新歌', 'picUrl': '', 'playCount': 5620000},
    {'name': '经典老歌', 'picUrl': '', 'playCount': 4230000},
    {'name': '深夜放松', 'picUrl': '', 'playCount': 2780000},
    {'name': '运动健身', 'picUrl': '', 'playCount': 1560000},
  ];

  static const List<Map<String, dynamic>> toplists = [
    {'name': '飙升榜', 'description': '实时更新热门歌曲'},
    {'name': '新歌榜', 'description': '最新歌曲排行'},
    {'name': '热歌榜', 'description': '本周最热歌曲'},
    {'name': '原创榜', 'description': '原创音乐精选'},
    {'name': '影视榜', 'description': '影视原声带'},
    {'name': 'ACG 榜', 'description': '动漫游戏音乐'},
  ];

  static const List<Map<String, dynamic>> newReleases = [
    {'title': '新歌首发', 'artist': '华语新歌', 'album': '最新专辑'},
    {'title': '欧美新歌', 'artist': '国际新声', 'album': '欧美精选'},
    {'title': '日韩新歌', 'artist': '日韩前沿', 'album': '亚洲新势力'},
  ];

  static const List<Map<String, String>> genres = [
    {'name': '华语', 'icon': '🇨🇳'},
    {'name': '欧美', 'icon': '🌎'},
    {'name': '日韩', 'icon': '🇯🇵'},
    {'name': '摇滚', 'icon': '🎸'},
    {'name': '电子', 'icon': '🎹'},
    {'name': '说唱', 'icon': '🎤'},
    {'name': '民谣', 'icon': '🎶'},
    {'name': '古典', 'icon': '🎻'},
  ];
}
