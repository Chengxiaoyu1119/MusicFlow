/// 所有 UI 字符串集中管理。默认中文。
///
/// 使用方式：`Strings.libraryTitle` 直接调用。
class Strings {
  Strings._();

  static Strings? _instance;
  static Strings get of {
    _instance ??= Strings._();
    return _instance!;
  }

  // ==================== 通用 ====================
  static const appName = 'MusicFlow';

  // ==================== 底部导航 ====================
  static const navLibrary = '音乐库';
  static const navSearch = '搜索';
  static const navPlugins = '插件';
  static const navSettings = '设置';

  // ==================== 播放器 ====================
  static const nowPlaying = '正在播放';
  static const noMusicPlaying = '暂无播放';
  static const upNext = '即将播放';
  static const clear = '清空';
  static const noLyrics = '暂无歌词';
  static const toggleLyrics = '切换歌词';
  static const volume = '音量';
  static const desktopLyrics = '桌面歌词';

  // ==================== 音乐库 ====================
  static const libraryTitle = '音乐库';
  static const tracksTab = '曲目';
  static const albumsTab = '专辑';
  static const smartTab = '智能';
  static const emptyLibrary = '音乐库为空';
  static const emptyLibraryDesc = '导入本地音乐文件或安装插件即可开始聆听';
  static const importMusic = '导入音乐文件';
  static const browsePlugins = '浏览插件';
  static const scanLocal = '扫描本地音乐';
  static const importFiles = '导入文件';
  static const noAlbums = '暂无专辑';

  // ==================== 搜索 ====================
  static const searchHint = '搜索歌曲、艺术家、专辑...';
  static const noResults = '未找到结果';
  static const searchYourMusic = '搜索你的音乐或探索在线资源';

  // ==================== 歌单 ====================
  static const emptyPlaylist = '这个歌单是空的';
  static const addSongs = '添加歌曲';
  static const playlistNotFound = '歌单未找到';

  // ==================== 插件 ====================
  static const pluginsTitle = '插件';
  static const installPlugin = '安装插件';
  static const builtin = '内置';
  static const installed = '已安装';
  static const noPlugins = '暂无插件';
  static const installFromUrl = '从 URL 安装';
  static const installPluginHint = '输入插件 JS 或 JSON 文件的 URL';
  static const cancel = '取消';
  static const install = '安装';
  static const pluginSystemInfo = '插件可扩展音乐来源。内置插件支持网易云音乐和 QQ 音乐。你也可以从任何 URL 安装外部 JS 插件。';

  // ==================== 设置 ====================
  static const settingsTitle = '设置';
  static const playback = '播放';
  static const display = '显示';
  static const tools = '工具';
  static const storage = '存储';
  static const about = '关于';
  static const theme = '主题';
  static const accentColor = '强调色';
  static const accentColorSub = '自定义应用颜色';
  static const chooseTheme = '选择主题';
  static const light = '浅色';
  static const dark = '深色';
  static const system = '跟随系统';
  static const speed = '播放速度';
  static const sleepTimer = '睡眠定时器';
  static const sleepTimerSub = '自动暂停播放';
  static const sleepTimerDesc = '到达设定时间后自动暂停播放';
  static const sleepTimerRunning = '运行中';
  static const min = '分钟';
  static const equalizer = '均衡器';
  static const equalizerSub = '调节频率波段';
  static const downloads = '下载';
  static const downloadsSub = '管理已下载歌曲';
  static const statistics = '统计';
  static const statisticsSub = '听歌数据和热门曲目';
  static const desktopLyricsSub = '字体、颜色、透明度设置';
  static const crossfade = '淡入淡出';
  static const crossfadeSub = '歌曲切换时淡入淡出（即将推出）';
  static const libraryPath = '音乐库路径';
  static const libraryPathSub = '从文件夹导入音乐';
  static const clearCache = '清除缓存';
  static const clearCacheSub = '释放存储空间';
  static const cacheCleared = '缓存已清除';
  static const version = '版本';
  static const openSource = '开源声明';
  static const openSourceSub = '使用 Flutter 构建';

  // ==================== 下载 ====================
  static const downloadsTitle = '下载';
  static const noDownloads = '暂无下载';
  static const noDownloadsDesc = '从搜索结果中下载歌曲';
  static const downloading = '下载中';
  static const completed = '已完成';
  static const failed = '失败';
  static const clearCompleted = '清空已完成';
  static const couldNotOpen = '无法打开文件';

  // ==================== 均衡器 ====================
  static const eqTitle = '均衡器';
  static const enableEq = '启用均衡器';
  static const presets = '预设';
  static const resetToFlat = '重置为平坦';
  static const eqInfo = '原生均衡器仅支持 Android 平台。其他平台可预览界面。';

  // ==================== 统计 ====================
  static const statsTitle = '播放统计';
  static const totalPlays = '总播放次数';
  static const listeningTime = '听歌时长';
  static const uniqueTracks = '不同曲目';
  static const avgPlays = '平均播放';
  static const mostPlayed = '播放最多';
  static const noData = '暂无数据，开始听歌吧！';
  static const plays = '次播放';

  // ==================== 智能歌单 ====================
  static const mostPlayedTitle = '播放最多';
  static const mostPlayedDesc = '播放次数最多的曲目';
  static const recentlyPlayedTitle = '最近播放';
  static const recentlyPlayedDesc = '最近听过的曲目';
  static const recentlyAddedTitle = '最近添加';
  static const recentlyAddedDesc = '最新导入的曲目';
  static const favoritesTitle = '收藏';
  static const favoritesDesc = '你喜欢的曲目';
  static const frequentArtistsTitle = '常听歌手';
  static const frequentArtistsDesc = '你常听的歌手作品';
  static const recentFavoritesTitle = '最近收藏';
  static const recentFavoritesDesc = '最近收藏的曲目';

  // ==================== 桌面歌词设置 ====================
  static const desktopLyricsTitle = '桌面歌词';
  static const fontSize = '字体大小';
  static const activeLineColor = '当前行颜色';
  static const textColor = '文字颜色';
  static const bgOpacity = '背景不透明度';
  static const pauseTransparent = '暂停时提高透明度';
  static const pauseTransparentSub = '播放暂停时歌词更加透明';
  static const sampleLyrics = '示例歌词文字';
  static const samplePastLine = '上一句歌词文字';

  // ==================== 歌手/曲目 ====================
  static const tracks = '首曲目';
  static const unknownArtist = '未知艺术家';
  static const unknownAlbum = '未知专辑';
}
