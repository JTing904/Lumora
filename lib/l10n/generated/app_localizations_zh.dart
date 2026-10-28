// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Lumora';

  @override
  String get navHome => '首页';

  @override
  String get navBrowse => '浏览';

  @override
  String get navSearch => '搜索';

  @override
  String get navLibrary => '片库';

  @override
  String get navSettings => '设置';

  @override
  String get navLiveTv => '直播';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClose => '关闭';

  @override
  String get actionRetry => '重试';

  @override
  String get actionTryAgain => '再试一次';

  @override
  String get actionCopy => '复制';

  @override
  String get actionSave => '保存';

  @override
  String get actionCopyReport => '复制报告';

  @override
  String get actionSaveReport => '保存报告';

  @override
  String get actionCopyDiagnostic => '复制诊断信息';

  @override
  String get shellFullscreen => '全屏';

  @override
  String get shellExitFullscreen => '退出全屏';

  @override
  String get shellFullscreenTooltip => '全屏 (F11)';

  @override
  String get shellExitFullscreenTooltip => '退出全屏 (F11)';

  @override
  String get errorLoadFailed => '影片加载失败';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get listSeparator => '、';

  @override
  String get shortcutsTitle => '键盘快捷键';

  @override
  String get shortcutsClose => '关闭快捷键说明';

  @override
  String get shortcutsGroupAnywhere => '任何页面';

  @override
  String get shortcutsGroupMoving => '移动';

  @override
  String get shortcutsGroupPlaying => '播放时';

  @override
  String get shortcutsGroupReading => '阅读时';

  @override
  String get shortcutsShowSheet => '显示这份说明';

  @override
  String get shortcutsShowSheetNote => '也可以按 Shift + /';

  @override
  String get shortcutsToggleFullscreen => '切换全屏';

  @override
  String get shortcutsLeaveFullscreen => '退出全屏，或关闭打开的窗口';

  @override
  String get shortcutsLeaveFullscreenNote => '不会自己离开当前页面';

  @override
  String get shortcutsMyList => '我的收藏和下载';

  @override
  String get shortcutsSearchMacNote => 'macOS 上是 Cmd + K';

  @override
  String get shortcutsSettingsMacNote => 'macOS 上是 Cmd + ,';

  @override
  String get shortcutsPlayPause => '播放或暂停';

  @override
  String get shortcutsPlayPauseNote => 'K 键也可以';

  @override
  String get shortcutsSeek => '后退或前进 10 秒';

  @override
  String get shortcutsSeekNote => '视频获得焦点时，方向键也可以';

  @override
  String get shortcutsMute => '静音或取消静音';

  @override
  String get shortcutsAspect => '切换画面填充方式';

  @override
  String get shortcutsPage => '上一页或下一页、上一章或下一章';

  @override
  String get shortcutsLine => '专注模式下向下或向上一行';

  @override
  String nowPlayingSemantics(String title, String subtitle) {
    return '正在播放：$title，$subtitle';
  }

  @override
  String get nowPlayingOpenHint => '打开完整播放器';

  @override
  String get playerPrevious => '上一个';

  @override
  String get playerNext => '下一个';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionPlayback => '播放';

  @override
  String get settingsSectionSources => '片源';

  @override
  String get settingsSectionIntegrations => '第三方服务';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionContent => '内容';

  @override
  String get settingsSectionApp => '应用';

  @override
  String get stateEnabled => '已启用';

  @override
  String get stateDisabled => '已停用';

  @override
  String get stateActive => '运行中';

  @override
  String get stateOffline => '离线';

  @override
  String get stateConnected => '已连接';

  @override
  String get stateNotSet => '未设置';

  @override
  String get stateOn => '开';

  @override
  String get stateOff => '关';

  @override
  String get settingsVideoTitle => '画质与超分';

  @override
  String get settingsVideoSubtitle => 'Anime4K 着色器预设和 GPU 处理流程';

  @override
  String get settingsP2pTitle => '内置 P2P 种子片源';

  @override
  String get settingsP2pActiveSubtitle =>
      'Lumora 种子片源（Knaben、TorrentGalaxy）已启用';

  @override
  String get settingsP2pDisabledSubtitle => 'P2P 已关闭，只用 HTTP 直连串流';

  @override
  String get settingsP2pActiveValue => 'P2P 已开';

  @override
  String get settingsP2pHttpValue => '只用 HTTP';

  @override
  String get settingsP2pInfoTooltip => 'P2P 说明';

  @override
  String get settingsAddonsTitle => '插件';

  @override
  String get settingsAddonsSubtitle => 'Stremio 目录和内容来源';

  @override
  String settingsAddonsInstalled(int count) {
    return '已安装 $count 个';
  }

  @override
  String get settingsBuiltinTitle => '内置片源';

  @override
  String get settingsBuiltinSubtitle => 'HTTP 直连片源、优先顺序和开关';

  @override
  String get settingsBuiltinCustom => '自定义';

  @override
  String get settingsBuiltinDefault => '默认';

  @override
  String get settingsDebridTitle => 'Debrid 与云端串流';

  @override
  String get settingsDebridSubtitle =>
      'Real-Debrid、TorBox、AllDebrid、Premiumize 和 Debrid-Link';

  @override
  String get settingsTraktTitle => 'Trakt.tv 同步';

  @override
  String get settingsTraktSubtitle => '跨设备同步收藏、观看记录和播放进度';

  @override
  String get settingsSimklTitle => 'Simkl 同步';

  @override
  String get settingsSimklSubtitle => '跨设备同步电影、剧集和动漫';

  @override
  String get settingsTmdbTitle => 'TMDb API 密钥';

  @override
  String get settingsTmdbSubtitle => '用你自己的密钥获取排行榜和影片资料';

  @override
  String get settingsTmdbYourKey => '你的密钥';

  @override
  String get settingsServiceKeysTitle => '服务 API 密钥';

  @override
  String get settingsServiceKeysSubtitle => '字幕、有声书和抓取服务的密钥，由你自己提供';

  @override
  String settingsServiceKeysCount(int provided, int total) {
    return '已设置 $provided / $total';
  }

  @override
  String get settingsDiscordTitle => 'Discord 状态显示';

  @override
  String get settingsDiscordEnabledSubtitle => '把正在看的电影、剧集、音乐和直播显示在 Discord 上';

  @override
  String get settingsDiscordDisabledSubtitle => '已关闭，Discord 上不显示你的动态';

  @override
  String get settingsAppearanceTitle => '外观与界面';

  @override
  String get settingsAppearanceSubtitle => '玻璃效果、壁纸和首页界面';

  @override
  String get settingsGlassOn => '玻璃效果开';

  @override
  String get settingsCalendarTitle => '剧集播出日历';

  @override
  String get settingsCalendarOnSubtitle => '首页顶部和分区标题显示日历按钮';

  @override
  String get settingsCalendarOffSubtitle => '日历已关闭，所有页面都不显示';

  @override
  String get settingsAiQuizTitle => 'AI 推荐问答';

  @override
  String get settingsAiQuizOnSubtitle => '首页和搜索栏显示 AI 口味问答';

  @override
  String get settingsAiQuizOffSubtitle => 'AI 问答已关闭，所有页面都不显示';

  @override
  String get settingsAdultTitle => '成人内容';

  @override
  String get settingsAdultOnSubtitle => '18+ 目录、搜索结果和片源已开启';

  @override
  String get settingsAdultOffSubtitle => '已隐藏，不获取任何 18+ 目录、搜索结果或片源';

  @override
  String get settingsBackupTitle => '备份与还原';

  @override
  String get settingsBackupSubtitle => '导出或导入设置、主题和观看进度（JSON）';

  @override
  String get settingsBackupDialogSubtitle => '跨设备 JSON 配置';

  @override
  String get settingsBackupDescription =>
      '导出你的设置、主题、收藏和观看进度。不填密码会导出精简版，账号密码、IPTV 门户和插件网址都只留在这台设备上。填了密码会把完整资料（包括这些）加密导出。';

  @override
  String get settingsPassphraseOptional => '密码（可不填）';

  @override
  String get settingsPassphraseHelper => '加密完整资料需要至少 8 个字符。';

  @override
  String get settingsExportProfile => '导出资料';

  @override
  String get settingsPassphraseTooShort => '密码至少要 8 个字符。';

  @override
  String get settingsRedactedProfileCopied => '精简版资料已复制。账号、门户和插件都留在这台设备上。';

  @override
  String get settingsEncryptedProfileCopied => '加密的完整资料已复制。请保管好密码，忘了就无法找回。';

  @override
  String get settingsImportJson => '导入 JSON';

  @override
  String get settingsPasteJsonTitle => '粘贴配置 JSON';

  @override
  String get settingsPasteJsonHint => '在这里粘贴备份 JSON……';

  @override
  String get settingsPassphraseEncrypted => '密码（加密资料用）';

  @override
  String get settingsPassphraseEncryptedHelper => '精简版资料不用填。加密资料要填导出时设的密码。';

  @override
  String get settingsPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get settingsFromFile => '从文件导入';

  @override
  String get settingsRestoreNow => '立即还原';

  @override
  String settingsImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get settingsChooseProfile => '选择 Lumora 资料文件';

  @override
  String get settingsClearCacheTitle => '清除缓存';

  @override
  String get settingsClearCacheSubtitle => '删除缓存的图片和影片资料。登录、插件、收藏和观看记录都会保留';

  @override
  String get settingsClearCacheConfirmTitle => '要清除缓存吗？';

  @override
  String get settingsClearCacheConfirmBody =>
      '会删除缓存的图片和影片资料，之后重新下载。不会让你退出登录，也不会删除插件，你的资料、收藏、观看记录和设置都保持不变。';

  @override
  String get settingsClear => '清除';

  @override
  String settingsCacheArtwork(String error) {
    return '图片缓存（$error）';
  }

  @override
  String settingsCacheMetadata(String error) {
    return '影片资料缓存（$error）';
  }

  @override
  String settingsCacheHero(String error) {
    return '首页大图缓存（$error）';
  }

  @override
  String get settingsCacheCleared => '缓存已清除。';

  @override
  String settingsCacheClearedExcept(String failures) {
    return '缓存已清除，除了$failures。';
  }

  @override
  String get settingsCacheClearedSuffix => '你仍然保持登录，插件、收藏、观看记录和设置都没有变动。';

  @override
  String get settingsUpdatesTitle => '应用更新';

  @override
  String get settingsUpdatesSubtitle => '检查有没有新版本';

  @override
  String get settingsUpdatesCheck => '检查';

  @override
  String get settingsDiagnosticsSubtitle => '应用、设备和播放器状态（已隐去敏感信息），可以复制或保存';

  @override
  String get settingsLanguageSubtitle => '中文、English，或跟随设备';

  @override
  String get settingsAboutTitle => '关于 Lumora';

  @override
  String get settingsAboutSubtitle => '架构、播放引擎和致谢';

  @override
  String get diagnosticsTitle => '诊断';

  @override
  String get diagnosticsSubtitle => '本机的应用、设备和播放器报告（不会上传）';

  @override
  String get diagnosticsDescription =>
      '这台设备的本地快照：应用和设备资料、播放器设置、串流引擎状态和最近的崩溃记录。不会包含账号密码、插件网址、IPTV 门户和播放列表链接。什么都不会上传，只有你复制或保存时才会生成报告。';

  @override
  String get diagnosticsSectionDevice => '设备';

  @override
  String get diagnosticsSectionPlayerEngine => '播放器与引擎';

  @override
  String get diagnosticsSectionBreadcrumbs => '崩溃记录';

  @override
  String get diagnosticsSummary => '摘要';

  @override
  String get diagnosticsNotAvailable => '无';

  @override
  String diagnosticsBreadcrumbCount(int count, int shown) {
    return '共 $count 条，显示最近 $shown 条';
  }

  @override
  String get diagnosticsBreadcrumbs => '最近的操作';

  @override
  String get diagnosticsEmpty => '还没有记录。';

  @override
  String get diagnosticsCopied => '诊断报告已复制。';

  @override
  String get diagnosticsCopiedToClipboard => '诊断报告已复制到剪贴板';

  @override
  String get diagnosticsCopyFailed => '无法复制报告';

  @override
  String get diagnosticsSaveFailed => '无法保存报告';

  @override
  String diagnosticsSaved(String path) {
    return '诊断报告已保存到 $path';
  }

  @override
  String get searchHintTv => '搜索电影或剧集';

  @override
  String get searchHint => '搜索电影、剧集，或粘贴链接';

  @override
  String get searchVoice => '语音搜索';

  @override
  String get searchVoiceDenied => '麦克风权限已关闭。请允许 Lumora 使用麦克风来语音搜索。';

  @override
  String get searchAiQuiz => 'AI 口味问答';

  @override
  String get searchPaste => '从剪贴板粘贴';

  @override
  String get searchFailureTitle => '搜索连不上片源';

  @override
  String searchFailureBody(int failed, int total) {
    return '$total 个片源中有 $failed 个没有回应';
  }

  @override
  String get searchFailureAdvice => '失效的插件或过期的片源，可以在「插件」里修复。';

  @override
  String searchNoResults(String query) {
    return '找不到「$query」';
  }

  @override
  String get searchingMoreSources => '正在搜索更多片源……';

  @override
  String searchPartialFailure(String sources) {
    return '部分片源没有回应：$sources。其他片源正常，所以下面的结果是真的，但可能不完整。';
  }

  @override
  String get searchRecent => '最近搜索';

  @override
  String get searchClearAll => '全部清除';

  @override
  String get searchTrending => '热门与推荐';

  @override
  String get searchNothingToSuggest => '暂时没有推荐';

  @override
  String get searchNothingToSuggestBody => '在上面搜索片名，或到设置里连接插件。';

  @override
  String get searchPinnedSpine => '置顶';

  @override
  String searchCloudstreamSection(String provider) {
    return 'CloudStream • $provider';
  }

  @override
  String get searchCloudstreamExtension => 'CloudStream 扩展';

  @override
  String get searchTitlesSection => '影片';

  @override
  String get searchImdbSuggestions => 'IMDb 推荐';

  @override
  String get searchDirectStream => '直连串流';

  @override
  String get searchSourceTitleLookup => '片名查询';

  @override
  String get playerSeekBack => '后退 10 秒';

  @override
  String get playerSeekForward => '前进 10 秒';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerMute => '静音';

  @override
  String get playerUnmute => '取消静音';

  @override
  String get playerPreviousEpisode => '上一集';

  @override
  String get playerNextEpisode => '下一集';

  @override
  String get playerEpisodes => '选集';

  @override
  String get playerAspectRatio => '画面比例 (C)';

  @override
  String get playerPlaybackSpeed => '倍速';

  @override
  String get playerAudioTracks => '音轨';

  @override
  String get playerSubtitles => '字幕';

  @override
  String get playerSubtitleSync => '字幕同步';

  @override
  String get playerFullscreen => '全屏 (F)';

  @override
  String get playerExitFullscreen => '退出全屏 (F)';

  @override
  String playerVolume(int percent) {
    return '音量 $percent%';
  }

  @override
  String playerSeekPosition(String position, String duration) {
    return '$position / $duration';
  }

  @override
  String get a11yOpenDetails => '打开详情';

  @override
  String a11yResume(String title, int percent) {
    return '继续看 $title，已看 $percent%';
  }

  @override
  String get emptyMyList => '收藏还是空的';

  @override
  String get emptyMyListBody => '把喜欢的电影和剧集加进来，想看随时看';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSubtitle => '应用的语言。「跟随系统」会用设备的语言。';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get a11yResumePlayback => '继续播放';

  @override
  String get playerPlaybackPosition => '播放进度';

  @override
  String get playerVolumeLabel => '音量';

  @override
  String get homePlay => '播放';

  @override
  String get homeMoreInfo => '详情';

  @override
  String get homeTrailer => '预告片';

  @override
  String get homeContinueWatching => '继续观看';

  @override
  String get homeSeeAll => '查看全部';

  @override
  String get homeCalendar => '日历';

  @override
  String get homeTop10 => '本周 Top 10';

  @override
  String get homeLoadingLibrary => '正在加载片库……';

  @override
  String get homeEmptyShelf => '这里还是空的。到设置里添加插件，或下拉刷新。';

  @override
  String homeMinutesLeft(int minutes) {
    return '剩 $minutes 分钟';
  }

  @override
  String homeBecauseOnList(String title) {
    return '因为你收藏了「$title」';
  }

  @override
  String homeBecauseWatching(String title) {
    return '因为你在看「$title」';
  }

  @override
  String homeBasedOn(String title) {
    return '根据「$title」推荐';
  }

  @override
  String get homeTraktRecommended => '为你推荐（Trakt）';

  @override
  String get homeTraktRecommendedSub => '根据你在 Trakt 的观看记录推荐';

  @override
  String get homeTrendingWeek => '本周热门';

  @override
  String get homeTrendingWeekSub => 'Trakt 用户这周都在看';

  @override
  String get homePopularNow => '正在流行';

  @override
  String get homePopularNowSub => 'Trakt 上看的人最多';

  @override
  String get homeComingSoon => '即将上映';

  @override
  String get homeComingSoonSub => '最受期待的新片';

  @override
  String get homeFromTrakt => '来自 Trakt';

  @override
  String get homeSimklRecommended => '为你推荐（Simkl）';

  @override
  String get homeSimklRecommendedSub => 'Simkl 的高分与个性化推荐';

  @override
  String catalogPopular(String type) {
    return '热门$type';
  }

  @override
  String catalogNew(String type) {
    return '最新$type';
  }

  @override
  String catalogTopRated(String type) {
    return '高分$type';
  }

  @override
  String get typeMovies => '电影';

  @override
  String get typeSeries => '剧集';

  @override
  String get typeAnime => '动漫';

  @override
  String get typeCollections => '合集';

  @override
  String get kindMovie => '电影';

  @override
  String get kindSeries => '剧集';

  @override
  String get kindAnime => '动漫';

  @override
  String get detailsPlayMovie => '播放';

  @override
  String get detailsPlayEpisodes => '开始播放';

  @override
  String get detailsPlayFirstMovie => '播放第一部';

  @override
  String detailsResume(String time) {
    return '继续播放 · $time';
  }

  @override
  String detailsResumeEpisode(int episode, String time) {
    return '继续 第 $episode 集 · $time';
  }

  @override
  String get detailsLibrary => '收藏';

  @override
  String get detailsInLibrary => '已收藏';

  @override
  String detailsSeasonCount(int count) {
    return '$count 季';
  }

  @override
  String detailsSeason(int season) {
    return '第 $season 季';
  }

  @override
  String get detailsEpisodes => '剧集';

  @override
  String get detailsCollectionMovies => '系列电影';

  @override
  String get detailsSimilar => '相似推荐';

  @override
  String get detailsMoreLikeThis => '更多类似';

  @override
  String get detailsCast => '演员';

  @override
  String get detailsReadMore => '展开';

  @override
  String get detailsShowLess => '收起';

  @override
  String get detailsUnavailable => '无法加载详情。';

  @override
  String get detailsGoBack => '返回';

  @override
  String detailsEpisodeBadge(String episode) {
    return '第 $episode 集';
  }

  @override
  String detailsPartBadge(String part) {
    return '第 $part 部';
  }

  @override
  String detailsWatchedTo(String time) {
    return '看到 $time';
  }

  @override
  String get searchKindAnime => '动画';

  @override
  String get searchKindAnimeMovie => '动画电影';

  @override
  String get searchKindLiveSeries => '真人剧';

  @override
  String get searchKindSeries => '剧集';

  @override
  String get searchKindMovie => '电影';

  @override
  String searchFilterAll(int count) {
    return '全部 $count';
  }

  @override
  String searchFilterAnime(int count) {
    return '动画 $count';
  }

  @override
  String searchFilterSeries(int count) {
    return '剧集 $count';
  }

  @override
  String searchFilterMovies(int count) {
    return '电影 $count';
  }

  @override
  String get searchFilterEmpty => '这一类没有结果。';

  @override
  String searchResumeEpisode(int season, int episode) {
    return '看到 第 $season 季 第 $episode 集';
  }

  @override
  String get searchResumeMovie => '看过一部分';

  @override
  String get searchHot => '热门搜索';

  @override
  String get searchNoPoster => '暂无海报';

  @override
  String get watchSources => '片源';

  @override
  String get watchSearching => '正在找片源……';

  @override
  String watchFoundSearching(int count) {
    return '找到 $count 个 · 还在找……';
  }

  @override
  String watchFound(int count) {
    return '找到 $count 个片源';
  }

  @override
  String watchFilterAll(int count) {
    return '全部（$count）';
  }

  @override
  String watchFilterDebrid(String service, int count) {
    return '$service（$count）';
  }

  @override
  String watchFilterTorrents(int count) {
    return '种子（$count）';
  }

  @override
  String watchFilterDirect(int count) {
    return '直连（$count）';
  }

  @override
  String get watchSeedsAll => '做种不限';

  @override
  String get watchSeedsMost => '做种最多';

  @override
  String get watchSeedsMostLong => '做种从多到少';

  @override
  String watchSeedsAtLeast(int count) {
    return '$count+ 人做种';
  }

  @override
  String get watchSeedsActive => '有人做种';

  @override
  String get watchSeedsActiveLong => '有人做种（>0）';

  @override
  String get watchSizeAll => '大小不限';

  @override
  String get watchSizeLargest => '最大';

  @override
  String get watchSizeSmallest => '最小';

  @override
  String get watchSizeLargestFirst => '从大到小';

  @override
  String get watchSizeSmallestFirst => '从小到大';

  @override
  String get watchAllSources => '全部来源';

  @override
  String get watchAllAudio => '全部音轨';

  @override
  String get watchAudioMulti => '🌐 多音轨';

  @override
  String get watchAudioEnglish => '🇺🇸 英语 / 原声';

  @override
  String get watchAudioHindi => '🇮🇳 印地语';

  @override
  String get watchAudioGerman => '🇩🇪 德语';

  @override
  String get watchAudioFrench => '🇫🇷 法语';

  @override
  String get watchAudioCastilian => '🇪🇸 西班牙语（西班牙）';

  @override
  String get watchAudioLatino => '🇲🇽 西班牙语（拉美）';

  @override
  String get watchAudioSpanish => '🌎 全部西班牙语';

  @override
  String get watchAudioRussian => '🇷🇺 俄语';

  @override
  String get watchAudioJapanese => '🇯🇵 日语';

  @override
  String get watchAudioItalian => '🇮🇹 意大利语';

  @override
  String get watchSeedersFilter => '按做种筛选';

  @override
  String get watchSizeFilter => '按大小筛选';

  @override
  String get watchProviderFilter => '按来源筛选';

  @override
  String get watchUnavailable => '不可用';

  @override
  String watchSeeds(int count) {
    return '$count 人做种';
  }

  @override
  String get watchMagnetCopied => '已复制磁力链接';

  @override
  String get watchCopied => '已复制';

  @override
  String get watchCopyMagnet => '复制磁力链接';

  @override
  String get watchNoSources => '没找到片源';

  @override
  String get watchNoSourcesBody => '没有找到能播的片源。可以到设置里装更多插件，或者换一部试试。';

  @override
  String get watchInstallAddons => '安装插件';

  @override
  String get watchAutoTitle => '自动（推荐）';

  @override
  String get watchAutoIdle => '挑最快、而且确认是这一部的片源';

  @override
  String get watchAutoPicking => '正在挑最快的片源……';

  @override
  String get watchAutoNone => '没有能直接播的片源，可以在下面手动选。';

  @override
  String get watchDeadNoSeeds => '0 人做种 · 大概率播不了';

  @override
  String get watchDeadUnreachable => '连不上';

  @override
  String get detailsSourceAuto => '片源：自动选最快';

  @override
  String get detailsSourceManual => '片源：自己选';

  @override
  String playerSpeedLabel(String rate) {
    return '倍速 ${rate}x';
  }

  @override
  String playerSubtitlesWith(String language) {
    return '字幕 · $language';
  }

  @override
  String get playerSubtitlesOff => '字幕 · 关';

  @override
  String playerSourceWith(String quality) {
    return '片源 · $quality';
  }

  @override
  String get playerSource => '片源';

  @override
  String get playerSubChinese => '中字';

  @override
  String get playerSubEnglish => '英字';

  @override
  String get panelNoStreamsEpisode => '这一集没找到片源';

  @override
  String get panelNoStreamsTitle => '这一部没找到片源';

  @override
  String get panelEmptyEpisodeBody => '可以回到选集，换一集或换一个来源试试。';

  @override
  String get panelEmptyTitleBody => '可以换一个来源试试，或者关掉这个面板，到设置里检查插件。';

  @override
  String get panelBackToEpisodes => '回到选集';

  @override
  String panelEpisode(String episode) {
    return '第 $episode 集';
  }

  @override
  String panelAllProviders(String addon) {
    return '全部来源 · 正在用 $addon';
  }

  @override
  String get panelClose => '关闭';

  @override
  String get panelSearchingAll => '正在搜索所有来源……';

  @override
  String get panelRescrape => '重新找片源';

  @override
  String get panelScrapingMore => '还在找更多片源……';

  @override
  String get panelStreamSource => '片源';

  @override
  String get playerNotResponding => '这个片源没有反应，可能已经失效。';

  @override
  String get playerNotRespondingPick => '这个片源没有反应，可能已经失效。请在下面换一个片源。';

  @override
  String get playerTryingAnother => '这个片源没反应 · 正在换下一个';

  @override
  String get playerInitializing => '准备中……';

  @override
  String playerBuffering(String label) {
    return '正在缓冲 $label……';
  }

  @override
  String playerEpisodeLabel(String season, String episode, String title) {
    return '第 $season 季 第 $episode 集 · $title';
  }

  @override
  String get playerGatheringPeers => '正在连接做种的人……';

  @override
  String playerUsingDebrid(String service) {
    return '正在通过 $service 获取文件……';
  }

  @override
  String get playerSourceFailed => '这个片源播不了，请在下面换一个。';

  @override
  String get playerOpenError => '打不开这个片源：服务器限流，或者格式不支持。\n请换一个片源。';

  @override
  String get playerTestingOthers => '正在为你测试其他片源';

  @override
  String playerTrying(String source) {
    return '正在试 $source。';
  }

  @override
  String playerAttempt(String attempt, String max) {
    return '第 $attempt 次，共 $max 次';
  }

  @override
  String get playerChooseMyself => '我自己选片源';

  @override
  String get playerChooseAnother => '换一个片源';

  @override
  String get playerGoBack => '返回';

  @override
  String get playerBack => '返回';

  @override
  String get playerScreenshot => '截图';

  @override
  String get playerDownloading => '下载中……';

  @override
  String get playerDownloadMedia => '下载';

  @override
  String get playerLockScreen => '锁屏';

  @override
  String get playerCast => '投屏';

  @override
  String get playerLocked => '屏幕已锁定，点锁的图标解锁。';

  @override
  String get playerUnlock => '解锁';

  @override
  String get playerMuted => '静音';

  @override
  String get playerCannotSeek => '这个片源不能跳转 · 从头开始播';

  @override
  String get playerSubDownloadFailed => '字幕下载失败';

  @override
  String get playerSubSynced => '字幕时间已同步并保存';

  @override
  String get playerDownloadInProgress => '已经在后台下载了。';

  @override
  String get playerAlreadyDownloaded => '这部已经下载过了。';

  @override
  String get playerDownloadStarted => '已开始在后台下载，可以在「下载」里看进度。';

  @override
  String get playerUrlCopied => '已复制串流链接';

  @override
  String get playerNoUrl => '现在没有可以复制的串流链接。';

  @override
  String get playerSubSyncEmbedded => '内嵌字幕不能同步，请选一个外挂字幕。';

  @override
  String get playerSubSyncNeedExternal => '请先加载外挂字幕，再用字幕同步。';

  @override
  String get playerSubSyncEmbeddedShort => '内嵌字幕不能同步。';

  @override
  String get playerSpeechSyncNeedsFile => '语音同步需要外挂字幕文件。';

  @override
  String get playerDismiss => '关闭 (✕)';

  @override
  String get playerSources => '片源';

  @override
  String get playerQuality => '画质';

  @override
  String playerQualityWith(String quality) {
    return '画质 · $quality';
  }

  @override
  String get playerQualityAuto => '自动';

  @override
  String get playerQualityAutoNote => '按你的网速选最好的';

  @override
  String playerQualityAutoMeasured(String mbps) {
    return '按你的网速（约 $mbps Mbps）选最好的';
  }

  @override
  String get playerQualityPlaying => '正在播放';

  @override
  String playerQualitySources(int count) {
    return '$count 个片源';
  }

  @override
  String playerQualityNone(String quality) {
    return '这部片没有 $quality 的片源';
  }

  @override
  String get p2pAdvisory => '隐私与网络提示';

  @override
  String get p2pTitle => '关于种子（P2P）播放';

  @override
  String get p2pExit => '关闭';

  @override
  String get p2pQuestion => '要不要关掉内置的种子片源，只用直连播放？';

  @override
  String get p2pBody =>
      '种子（P2P）播放会直接连到公开的种子网络，一边下载影片片段，一边分享给别人。其他做种的人看得到你的 IP。在一些国家和地区，没加密的种子流量可能会被监控，网络供应商（ISP）可能会发警告信。';

  @override
  String get p2pDirectTitle => '直连';

  @override
  String get p2pDirectBody => '直接从网站串流，不下载种子，也不会上传给别人。';

  @override
  String get p2pTorrentTitle => '种子';

  @override
  String get p2pTorrentBody => '从种子网络下载（Knaben、TorrentGalaxy），会和别人互相分享数据。';

  @override
  String get p2pNote => '之后随时可以在「设置」里重新打开或关掉种子片源。';

  @override
  String get p2pDontShowAgain => '不再提示';

  @override
  String get p2pTurnOff => '关掉种子';

  @override
  String get p2pTurnedOff => '已关掉种子片源，之后只用直连。';

  @override
  String recommendFor(String kind) {
    return '为你推荐 · $kind';
  }

  @override
  String recommendBecause(String kind) {
    return '因为你常看$kind';
  }

  @override
  String get detailsLike => '喜欢';

  @override
  String get detailsDislike => '不喜欢';

  @override
  String get subRefreshOnline => '重新搜索网上字幕';

  @override
  String get subSyncBar => '字幕同步条';

  @override
  String get subAppearance => '字幕外观';

  @override
  String get subSpeechSync => '按对白同步字幕';

  @override
  String get subOff => '关';

  @override
  String get subEmbedded => '内嵌';

  @override
  String get subEmbeddedCaps => '内嵌字幕';

  @override
  String get subAllLanguages => '全部语言';

  @override
  String get subAll => '全部';

  @override
  String get subHearingImpaired => '听障字幕';

  @override
  String get subForced => '强制字幕';

  @override
  String get subForcedCaps => '强制';

  @override
  String get subLanguages => '语言';

  @override
  String get subSearchOnline => '在网上搜';

  @override
  String get subSearching => '正在搜索字幕……';

  @override
  String get subNone => '没有可用的字幕。';

  @override
  String get subSearchProviders => '搜索网上字幕来源';

  @override
  String get subSearchingMore => '正在网上找更多字幕……';

  @override
  String get subFindMore => '找更多字幕';

  @override
  String get speedTitle => '播放速度';

  @override
  String get speedNormal => '正常（1.0×）';

  @override
  String get speedSleepTimer => '定时关闭';

  @override
  String get audioTracksTitle => '音轨';

  @override
  String get audioDefaultPlaying => '正在播放默认音轨。';

  @override
  String get audioSyncOffset => '音画同步调整';

  @override
  String get aspectTitle => '画面比例';

  @override
  String get aspectSubtitleScale => '字幕大小';

  @override
  String get episodesScrollUp => '向上';

  @override
  String get episodesScrollDown => '向下';

  @override
  String get episodesPrevSeasons => '前面的季';

  @override
  String get episodesNextSeasons => '后面的季';

  @override
  String get episodesPlaying => '正在播';

  @override
  String get episodesSelectSources => '选片源';

  @override
  String get syncTextSync => '按对白同步';

  @override
  String get syncDiscard => '放弃修改';

  @override
  String get syncDone => '完成';

  @override
  String get syncDriftActive => '已按两个对齐点修正时间偏差，可以用按钮微调。';

  @override
  String get syncFixSectionCaps => '修正一段';

  @override
  String get syncTimingCaps => '字幕时间';

  @override
  String get syncSelectRange => '选一段来同步';

  @override
  String get syncSpeechDialogue => '按对白同步';

  @override
  String get syncSearchDialogue => '搜索对白……';

  @override
  String get syncNow => '现在';

  @override
  String get syncFromHere => '从这里对齐';

  @override
  String get syncJumpHere => '跳到这里';

  @override
  String get syncJumpNow => '跳到现在';

  @override
  String get syncSelecting => '正在选';

  @override
  String get syncFixSection => '修正一段';

  @override
  String get syncReset => '重置时间';

  @override
  String get syncSaving => '正在保存……';

  @override
  String get syncSave => '保存时间';

  @override
  String get listRemoveConfirm => '从收藏里移除？';

  @override
  String get commonCancel => '取消';

  @override
  String get listRemove => '移除';

  @override
  String get listTitle => '我的收藏';

  @override
  String get listSyncing => '正在同步……';

  @override
  String get listSynced => '已同步';

  @override
  String get listFilter => '筛选收藏';

  @override
  String get listSortRecent => '最近加入';

  @override
  String get listSortTitle => '按片名';

  @override
  String get listSortYear => '按年份';

  @override
  String get listSearch => '搜索收藏……';

  @override
  String get listEmpty => '收藏还是空的';

  @override
  String get listNoMatch => '没有符合的片';

  @override
  String get listEmptyBody => '把喜欢的电影和剧集加进收藏，随时回来看';

  @override
  String get listNoMatchBody => '换个关键词或筛选条件试试';

  @override
  String get listResetFilters => '重置筛选';

  @override
  String get dlFileMissing => '找不到这个文件，可能被移动或删除了。';

  @override
  String get dlDeleteTitle => '删除下载';

  @override
  String get commonDelete => '删除';

  @override
  String get dlList => '下载列表';

  @override
  String get dlActive => '下载中';

  @override
  String get dlDone => '已下载';

  @override
  String get dlTitle => '下载';

  @override
  String get dlOpenFolder => '打开下载文件夹';

  @override
  String get dlNoActive => '没有正在下载的';

  @override
  String get dlNoActiveBody => '在播放器里下载的影片会出现在这里。';

  @override
  String get dlTorrent => '种子';

  @override
  String get dlDebrid => 'Debrid 云端';

  @override
  String get dlDirect => '直连';

  @override
  String get dlUnknownError => '未知错误';

  @override
  String get dlResume => '继续';

  @override
  String get dlRetry => '重试';

  @override
  String get dlOpenLocation => '打开所在文件夹';

  @override
  String get dlNoDone => '还没有下载好的影片';

  @override
  String get dlNoDoneBody => '下载完成的影片会出现在这里，没网也能看。';

  @override
  String get dlOffline => '离线影片';

  @override
  String get animeLoadFailedArabic => '阿拉伯语动漫目录加载失败，请检查网络。';

  @override
  String get animeLoadFailedRetry => '动漫目录加载失败，请检查网络或重试。';

  @override
  String get animeLoadFailed => '动漫目录加载失败，请检查网络。';

  @override
  String get animeCouldNotLoad => '动漫加载不了';

  @override
  String get animeTrending => 'AniList 热门';

  @override
  String get animeTrendingSub => '最受欢迎、最热门的作品';

  @override
  String get animeSeasonPopular => '本季热门';

  @override
  String get animeMasterpieces => '历代神作';

  @override
  String get animeMasterpiecesSub => '评分最高、口碑最好的动漫';

  @override
  String get animeNextSeason => '下季期待';

  @override
  String get animeNextSeasonSub => '即将开播、不能错过';

  @override
  String get animeAction => '热血冒险';

  @override
  String get animeActionSub => '燃到爆的战斗和史诗旅程';

  @override
  String get animeRomance => '恋爱剧情';

  @override
  String get animeRomanceSub => '感人的故事';

  @override
  String get animeFantasy => '奇幻异世界';

  @override
  String get animeFantasySub => '魔法王国和异世界';

  @override
  String get animeSciFi => '科幻赛博朋克';

  @override
  String get animeSciFiSub => '未来科技和反乌托邦世界';

  @override
  String get animeCatalogue => '动漫目录';

  @override
  String get animeSearch => '搜索动漫';

  @override
  String get animeAnilistDetails => 'AniList 详情';

  @override
  String get animeSortTrending => '热门';

  @override
  String get animeSortPopular => '最受欢迎';

  @override
  String get animeSortTop => '评分最高';

  @override
  String get animeSortFavorited => '收藏最多';

  @override
  String get animeSortNewest => '最新';

  @override
  String get animeSortOldest => '最早';

  @override
  String get animeSortTitle => '按片名';

  @override
  String get commonClear => '清除';

  @override
  String get animeSearchHint => '搜索动漫、剧场版、OVA……';

  @override
  String get animeSortBy => '排序';

  @override
  String get animeGenre => '类型';

  @override
  String get animeYear => '年份';

  @override
  String get animeSeason => '季度';

  @override
  String get animeFormat => '形式';

  @override
  String get animeStatus => '状态';

  @override
  String get animeReset => '重置';

  @override
  String get animeNoMatch => '没有符合条件的动漫';

  @override
  String get animeNoMatchBody => '换个关键词，或清除筛选试试';

  @override
  String get animeTvSeries => '动画剧集';

  @override
  String get animeMovies => '动画电影';

  @override
  String get animeAddToList => '加入收藏';

  @override
  String get animeCast => '角色与声优';

  @override
  String get animeRelations => '系列与关联作品';

  @override
  String get animeAlsoLike => '你可能也喜欢';

  @override
  String get animeWatching => '在看';

  @override
  String get animePlan => '想看';

  @override
  String get animeCompleted => '看完了';

  @override
  String get animeDropped => '弃了';

  @override
  String get aboutTitle => '关于 Lumora';

  @override
  String get aboutTagline => '电影、剧集、动漫，一个 app 看完';

  @override
  String get aboutBody => 'Lumora 把电影、剧集、动漫和直播放在同一个 app 里，还会自动帮你挑最快能播的片源。';

  @override
  String get aboutTech => '核心技术';

  @override
  String get aboutTechEngine => '高性能播放引擎';

  @override
  String get aboutTechSources => '多来源片源搜索';

  @override
  String get aboutTechSourcesBody =>
      '支持 Real-Debrid、TorBox 和 Stremio 插件的高速云端播放。';

  @override
  String get aboutTechGlass => '液态玻璃视觉效果';

  @override
  String get aboutTechGlassBody => '实时的光线折射、透镜和流体效果。';

  @override
  String get aboutTechSync => 'Trakt 与云端同步';

  @override
  String get aboutTechSyncBody => '跨设备同步收藏、追剧进度和观看记录。';

  @override
  String get aboutCredits => '致谢与许可';

  @override
  String get aboutZplayCredit => 'Lumora 基于 tzero86 的 ZPlay';

  @override
  String get aboutPlaytorrio => 'ZPlay 基于 PlayTorrio V3';

  @override
  String get aboutPlaytorrioCredit => '原作者 Ayman（@ayman708-UX）';

  @override
  String get aboutFontLicense =>
      '内置的 Poppins 字体使用 SIL Open Font License 1.1 授权。';

  @override
  String get aboutTmdb => '本产品使用 TMDB API，但未获 TMDB 认可或认证。';

  @override
  String get aboutGplBody =>
      'Lumora 修改自 ZPlay，ZPlay 修改自 PlayTorrio V3，以 GNU 通用公共许可证 v3.0 发布。点这里看许可证全文。';

  @override
  String get updatesUpToDate => 'Lumora 已是最新版本！';

  @override
  String get updatesTitle => '应用更新';

  @override
  String get updatesBody => '让 Lumora 保持最新，获得新功能、安全修复和性能改进。';

  @override
  String get updatesChecking => '正在检查更新……';

  @override
  String get updatesCheck => '检查更新';

  @override
  String get updatesChannels => '更新渠道';

  @override
  String get updatesStable => '正式版';

  @override
  String get updatesStableBody => '直接从 GitHub 发布下载，并自动校验文件。';

  @override
  String get updatesInApp => '在 app 里直接更新';

  @override
  String get updatesInAppBody => '直接下载并安装更新，不用自己去找安装包。';

  @override
  String get provTitle => '内置片源';

  @override
  String get provResetConfirm => '重置片源顺序？';

  @override
  String get provResetBody => '会把 45 个直连片源恢复成默认顺序，并重新打开已关闭的片源。';

  @override
  String get provDefaultMode => '默认模式';

  @override
  String get provDefaultModeBody => '45 个片源自动排序';

  @override
  String get provCustomMode => '自定义模式';

  @override
  String get provCustomModeBody => '自己排顺序、开关片源、设优先';

  @override
  String get provDefault => '默认';

  @override
  String get provDefaultShort => '自动排序';

  @override
  String get provCustom => '自定义';

  @override
  String get provCustomShort => '手动排序和开关';

  @override
  String get provDefaultActive => '正在用默认模式';

  @override
  String get provDefaultActiveBody =>
      '默认模式下所有片源同时搜索，结果按清晰度（4K、1080p、720p）和文件大小排序。';

  @override
  String get provSwitchCustom => '切换到自定义模式';

  @override
  String get provPriority => '搜索优先级和结果排序';

  @override
  String get provPriorityBody => '排在上面的片源先搜，它们的结果永远排在最前面，不管大小和画质。';

  @override
  String get provSearch => '搜索片源（比如 CineSrc）……';

  @override
  String get provSearch2 => '搜索片源（比如 CineSrc、Dulo）……';

  @override
  String get provEnableAll => '全部打开';

  @override
  String get provDisableAll => '全部关闭';

  @override
  String get provClearToReorder => '清除搜索后才能拖动排序';

  @override
  String get provMoveUp => '上移';

  @override
  String get provMoveDown => '下移';

  @override
  String get navSeries => '电视剧';

  @override
  String get navMovies => '电影';

  @override
  String get navAnime => '动漫';

  @override
  String get navMyList => '我的收藏';

  @override
  String get navMyListShort => '收藏';

  @override
  String get navDownloads => '下载';

  @override
  String get navMe => '我的';

  @override
  String get navMore => '更多内容';

  @override
  String get catTrendingSeries => '热门剧集';

  @override
  String get catCnDrama => '国产剧';

  @override
  String get catHkDrama => '港剧';

  @override
  String get catKrDrama => '韩剧';

  @override
  String get catUsDrama => '美剧';

  @override
  String get catTwDrama => '台剧';

  @override
  String get catJpDrama => '日剧';

  @override
  String get catGbDrama => '英剧';

  @override
  String get catTopSeries => '高分剧集';

  @override
  String get catTrendingMovies => '热门电影';

  @override
  String get catNowPlaying => '正在上映';

  @override
  String get catChineseMovies => '华语电影';

  @override
  String get catHkMovies => '港片';

  @override
  String get catUsMovies => '好莱坞电影';

  @override
  String get catKrMovies => '韩国电影';

  @override
  String get catJpMovies => '日本电影';

  @override
  String get catAnimatedMovies => '动画电影';

  @override
  String get catTopMovies => '高分电影';

  @override
  String get catTrendingAnime => '热门动漫';

  @override
  String get catDonghua => '国漫';

  @override
  String get catJpAnime => '日本动漫';

  @override
  String get catTopAnime => '高分动漫';

  @override
  String get catAddToList => '加入收藏';

  @override
  String get catDetails => '详情';

  @override
  String get catEmpty => '这里暂时没有内容。这些片单来自 TMDb，请到设置里检查 TMDb key。';

  @override
  String get settingsMoreSubtitle => '漫画、电子书、有声书、音乐和合集';

  @override
  String get homeResume => '继续播放';

  @override
  String homeResumeEpisode(int episode) {
    return '继续 第 $episode 集';
  }

  @override
  String cwEpisode(int episode) {
    return '第 $episode 集';
  }

  @override
  String cwSeasonEpisode(int season, int episode) {
    return '第 $season 季 第 $episode 集';
  }

  @override
  String get cwMovie => '电影';

  @override
  String get cwRemove => '从继续观看移除';

  @override
  String get catRecentlyUpdated => '最近更新';

  @override
  String get heroSeriesBadge => '剧集';

  @override
  String get filterTitle => '筛选';

  @override
  String get filterClear => '清除';

  @override
  String get filterAll => '全部';

  @override
  String get filterRegion => '地区';

  @override
  String get filterGenre => '类型';

  @override
  String get filterYear => '年份';

  @override
  String get filterSort => '排序';

  @override
  String get filterSortPopular => '最热';

  @override
  String get filterSortNewest => '最新';

  @override
  String get filterSortRating => '评分最高';

  @override
  String get filterRegionCn => '大陆';

  @override
  String get filterRegionHk => '香港';

  @override
  String get filterRegionTw => '台湾';

  @override
  String get filterRegionKr => '韩国';

  @override
  String get filterRegionJp => '日本';

  @override
  String get filterRegionUs => '美国';

  @override
  String get filterRegionGb => '英国';

  @override
  String get filterRegionTh => '泰国';

  @override
  String get filterRegionIn => '印度';

  @override
  String get filterRegionWest => '欧美';

  @override
  String get filterGenreAction => '动作';

  @override
  String get filterGenreComedy => '喜剧';

  @override
  String get filterGenreDrama => '剧情';

  @override
  String get filterGenreRomance => '爱情';

  @override
  String get filterGenreSciFi => '科幻';

  @override
  String get filterGenreFantasy => '奇幻';

  @override
  String get filterGenreHorror => '恐怖';

  @override
  String get filterGenreThriller => '惊悚';

  @override
  String get filterGenreCrime => '犯罪';

  @override
  String get filterGenreMystery => '悬疑';

  @override
  String get filterGenreAdventure => '冒险';

  @override
  String get filterGenreWar => '战争';

  @override
  String get filterGenreFamily => '家庭';

  @override
  String get filterGenreDocumentary => '纪录片';

  @override
  String get filterGenreActionAdventure => '动作冒险';

  @override
  String get filterGenreSciFiFantasy => '科幻奇幻';

  @override
  String get filterGenreWarPolitics => '战争政治';

  @override
  String get filterGenreReality => '综艺';

  @override
  String get filterGenreKids => '儿童';

  @override
  String get filterYears2020s => '2020年代';

  @override
  String get filterYears2010s => '2010年代';

  @override
  String get filterYears2000s => '2000年代';

  @override
  String get filterYearsOlder => '更早';

  @override
  String get filterNoResults => '没有符合筛选条件的内容。';

  @override
  String get filterLoadMore => '加载更多';

  @override
  String get heroMovieBadge => '电影';

  @override
  String get introOutroTitle => '跳过片头片尾';

  @override
  String get introOutroButton => '片头片尾';

  @override
  String get introOutroAuto => '自动跳过片头';

  @override
  String get introOutroOn => '开';

  @override
  String get introOutroOff => '关';

  @override
  String get introOutroIntro => '片头结束';

  @override
  String get introOutroOutro => '片尾开始';

  @override
  String get introOutroSetHere => '设为当前';

  @override
  String get introOutroClear => '清除';

  @override
  String get introOutroHint => '播到片头结束或片尾开始时按「设为当前」，这部剧的每一集都会照这个时间跳过。';

  @override
  String get introSkipped => '已跳过片头';

  @override
  String upNextIn(int seconds) {
    return '$seconds 秒后播放下一集';
  }

  @override
  String get upNextPlayNow => '立即播放';

  @override
  String get upNextCancel => '取消';

  @override
  String get skipIntro => '跳过片头';

  @override
  String get skipRecap => '跳过前情提要';

  @override
  String get skipCredits => '跳过片尾';

  @override
  String get skipPreview => '跳过预告';

  @override
  String detailsPlayEpisode(int episode) {
    return '播放 第 $episode 集';
  }

  @override
  String detailsPlaySeasonEpisode(int season, int episode) {
    return '播放 第 $season 季 第 $episode 集';
  }

  @override
  String get detailsWatched => '已看';

  @override
  String playerTooShort(int minutes) {
    return '这个片源只有 $minutes 分钟，不是正片，请换一个片源。';
  }

  @override
  String playerTooShortNext(int minutes) {
    return '这个片源只有 $minutes 分钟，不是正片，正在换下一个…';
  }

  @override
  String get abkAudiobookDetails => '有声书详情';

  @override
  String get abkChaptersAudioFiles => '章节与音频文件';

  @override
  String get abkCouldNotLoadChapters => '无法加载章节';

  @override
  String get abkNoPlayableChaptersFound => '没有可播放的章节。';

  @override
  String get abkPlayFirstChapter => '播放第一章';

  @override
  String get abkInitializingChapter => '正在初始化章节…';

  @override
  String get abkFetchingTorrentMetadataPeers => '正在获取种子元数据与节点…';

  @override
  String get abkAudioPlayerDesignPreset => '音频播放器设计预设';

  @override
  String get abkSeekBarScrubberStyle => '进度条滑块样式';

  @override
  String get abkPlayPauseButtonStyle => '播放/暂停按钮样式';

  @override
  String get abkOpenDragDropPlayerStudio => '打开拖放式播放器工作室';

  @override
  String get abkCustomizeAudioPlayer => '自定义音频播放器';

  @override
  String get abkChaptersList => '章节列表';

  @override
  String get abkRetryChapter => '重试本章';

  @override
  String get abkPreviousChapter => '上一章';

  @override
  String get abkRewind10s => '后退 10 秒';

  @override
  String get abkForward10s => '快进 10 秒';

  @override
  String get abkNextChapter => '下一章';

  @override
  String get abkPauseCaps => '暂停';

  @override
  String get abkPlayCaps => '播放';

  @override
  String get abkFilterChaptersByName => '按名称筛选章节…';

  @override
  String get abkVolume => '音量';

  @override
  String get abkCustomizeAudiobookSection => '自定义有声书版块';

  @override
  String get abkPosterCardDensity => '海报卡片密度';

  @override
  String get abkAudiobookPosterCardDensity => '有声书海报卡片密度';

  @override
  String get abkFeaturedHeroSpotlightCarousel => '精选焦点轮播';

  @override
  String get abkMovingAmbientBackgroundGlow => '动态氛围背景光';

  @override
  String get abkShowContinueListeningCarousel => '显示“继续收听”轮播';

  @override
  String get abkOpenPlayerStudioThemes => '打开播放器工作室与主题';

  @override
  String get abkAudiobookHub => '有声书中心';

  @override
  String get abkExploreStreamListenToThousandsOf => '探索、在线收听数千部故事';

  @override
  String get abkAudiobookGeneratorStudio => '有声书生成器与工作室';

  @override
  String get abkAudiobookCustomizer => '有声书自定义';

  @override
  String get abkSearchAudiobooksByTitleAuthorOr => '按书名、作者或类型搜索有声书…';

  @override
  String get abkAudiobookGenres => '有声书类型';

  @override
  String get abkSearchResults => '搜索结果';

  @override
  String get abkFeaturedAudiobooks => '精选有声书';

  @override
  String get abkScrapingHighQualityAudiobookSources => '正在抓取高品质有声书来源…';

  @override
  String get abkCouldNotLoadAudiobooks => '无法加载有声书';

  @override
  String get abkNoAudiobooksFoundTryAnotherSearch => '未找到有声书，请换个关键词试试。';

  @override
  String get abkNowPlayingAudiobook => '正在播放的有声书';

  @override
  String get abkSpotlightFeatured => '焦点推荐';

  @override
  String get abkListenNow => '立即收听';

  @override
  String get abkContinueListening => '继续收听';

  @override
  String get abkAiAudiobookStudioEpubGenerator => 'AI 有声书工作室与 EPUB 生成器';

  @override
  String get abkGenerateAudiobooksFromEpubsOrImport =>
      '用 EPUB 生成有声书，或导入你自己的 MP3/M4B 有声书。';

  @override
  String get abkOpenStudio => '打开工作室';

  @override
  String get abkMyGeneratedUploadedAudiobooks => '我生成和上传的有声书';

  @override
  String get abkStudio => '工作室';

  @override
  String get abkFailed => '失败';

  @override
  String get abkPlay => '播放';

  @override
  String get abkEpubExceeds250kWords => 'EPUB 超过 25 万字';

  @override
  String get abkCancel => '取消';

  @override
  String get abkSplitGenerate => '拆分并生成';

  @override
  String get abkUploadCompleteGenerationStarted => '上传完成，已开始生成 AI 有声书！';

  @override
  String get abkRemove => '移除';

  @override
  String get abkAddPersonalAudiobook => '添加个人有声书';

  @override
  String get abkAudiobookTitle => '有声书标题';

  @override
  String get abkAuthorNarrator => '作者 / 朗读者';

  @override
  String get abkSelectCoverArt => '选择封面';

  @override
  String get abkChangeCover => '更换封面';

  @override
  String get abkImportToLibrary => '导入书库';

  @override
  String get abkAudiobookStudioGenerator => '有声书工作室与生成器';

  @override
  String get abkAudiobookStudioTabs => '有声书工作室标签页';

  @override
  String get abkRefreshStatus => '刷新状态';

  @override
  String get abkNoGeneratedAudiobooksYet => '还没有生成的有声书';

  @override
  String get abkPickAnEpubAboveToSynthesize => '在上方选择一本 EPUB，即可合成高品质语音朗读。';

  @override
  String get abkAiNarratorVoiceKokoroEngine => 'AI 朗读音色（Kokoro 引擎）';

  @override
  String get abkRescanBooks => '重新扫描书籍';

  @override
  String get abkGenerate => '生成';

  @override
  String get abkAnalyzingUploadingBook => '正在分析并上传书籍…';

  @override
  String get abkSelectExternalEpubFile => '选择外部 EPUB 文件';

  @override
  String get abkPickAnyEpubFileFromYour =>
      '从设备中选择任意 .epub 文件。大型书籍（超过 25 万字）会自动拆分。';

  @override
  String get abkCompleted => '已完成';

  @override
  String get abkPlayInApp => '在应用内播放';

  @override
  String get abkCopyStreamUrl => '复制流地址';

  @override
  String get abkUploadPersonalAudiobookFiles => '上传个人有声书文件';

  @override
  String get abkImportYourOwnMp3M4bM4a =>
      '导入你自己的 .mp3、.m4b、.m4a 或 .flac 有声书，离线收听。';

  @override
  String get abkNoPersonalAudiobooksAddedYet => '还没有添加个人有声书';

  @override
  String get abkTapTheBannerAboveToImport => '点按上方横幅，从设备导入音频文件。';

  @override
  String get abkDelete => '删除';

  @override
  String get bkResumeReading => '继续阅读';

  @override
  String get bkReadNow => '立即阅读';

  @override
  String get bkGenerateAiAudiobookTts => '生成 AI 有声书（TTS）';

  @override
  String get bkDeleteDownloadedFile => '删除已下载文件';

  @override
  String get bkPublisher => '出版社';

  @override
  String get bkSeries => '系列';

  @override
  String get bkLanguage => '语言';

  @override
  String get bkFileFormat => '文件格式';

  @override
  String get bkSize => '大小';

  @override
  String get bkDiscoverBooks => '发现好书';

  @override
  String get bkCouldNotLoadBooks => '无法加载书籍';

  @override
  String get bkNoBooksFound => '未找到书籍';

  @override
  String get bkTrySearchingForAnotherTitleAuthor => '试试搜索其他书名、作者或语言';

  @override
  String get bkSearchMillionsOfBooksAuthors => '搜索数百万本书籍和作者…';

  @override
  String get bkFontEngine => '字体引擎：';

  @override
  String get bkReaderFontEngine => '阅读器字体引擎';

  @override
  String get bkCompact => '紧凑';

  @override
  String get bkStandard => '标准';

  @override
  String get bkWide => '宽松';

  @override
  String get bkBookFormats => '书籍格式';

  @override
  String get bkTableOfContentsT => '目录 (T)';

  @override
  String get bkFocusModeLineByLine => '专注模式（逐行）';

  @override
  String get bkAppearanceCustomization => '外观与自定义';

  @override
  String get bkToggleFullscreenF => '切换全屏 (F)';

  @override
  String get bkPreviousChapterLeftArrow => '上一章（左方向键）';

  @override
  String get bkNextChapterRightArrow => '下一章（右方向键）';

  @override
  String get bkUnableToOpenBook => '无法打开书籍';

  @override
  String get bkNoReadableChaptersFound => '没有可阅读的章节。';

  @override
  String get bkTableOfContents => '目录';

  @override
  String get bkNoTableOfContentsAvailable => '暂无目录';

  @override
  String get bkBackToLibrary => '返回书库';

  @override
  String get bkZoomIn => '放大';

  @override
  String get bkZoomOut => '缩小';

  @override
  String get bkFullscreenF => '全屏 (F)';

  @override
  String get bkPreviousPage => '上一页';

  @override
  String get bkNextPage => '下一页';

  @override
  String get bkZoomOutCtrl => '缩小 (Ctrl -)';

  @override
  String get bkZoomInCtrl => '放大 (Ctrl +)';

  @override
  String get bkResetZoom => '重置缩放 (100%)';

  @override
  String get bkFocusModeActive => '专注模式已开启';

  @override
  String get bkExitFocusMode => '退出专注模式';

  @override
  String get bkExitEsc => '退出 (Esc)';

  @override
  String get bkTapAboveBelowToMoveKeys => '点按上方/下方移动 · 用 ↑ ↓ 键导航';

  @override
  String get bkPreviousLineUpArrow => '上一行（上方向键）';

  @override
  String get bkNextLineDownArrowSpace => '下一行（下方向键 / 空格）';

  @override
  String get bkCloseSettings => '关闭设置';

  @override
  String get bkAppearance => '外观';

  @override
  String get bkReset => '已重置 ✓';

  @override
  String get bkResetToDefaults => '恢复默认';

  @override
  String get bkSerif => '衬线';

  @override
  String get bkSans => '无衬线';

  @override
  String get bkDyslexic => '读写障碍友好';

  @override
  String get bkMono => '等宽';

  @override
  String get bkFontFamily => '字体';

  @override
  String get bkFontSize => '字号';

  @override
  String get bkLineHeight => '行高';

  @override
  String get bkAlignment => '对齐方式';

  @override
  String get bkFirstLineIndent => '首行缩进';

  @override
  String get bkReadingThemes => '阅读主题';

  @override
  String get bkLight => '浅色';

  @override
  String get bkSepia => '护眼';

  @override
  String get bkDark => '深色';

  @override
  String get bkAmoled => 'AMOLED 纯黑';

  @override
  String get bkReaderBrightness => '阅读亮度';

  @override
  String get bkPageMargins => '页边距';

  @override
  String get bkBalanced => '标准';

  @override
  String get bkReadingMode => '阅读模式';

  @override
  String get bkContinuousScroll => '连续滚动';

  @override
  String get bkPaginatedTurns => '分页翻页';

  @override
  String get mgChapters => '章节';

  @override
  String get mgNoChaptersFound => '未找到章节。';

  @override
  String get mgChapter => '章节';

  @override
  String get mgPreviousChapterPage => '上一页章节';

  @override
  String get mgNextChapterPage => '下一页章节';

  @override
  String get mgSearchChapters => '搜索章节…';

  @override
  String get mgClearChapterSearch => '清除章节搜索';

  @override
  String get mgStartReading => '开始阅读';

  @override
  String get mgBack => '返回';

  @override
  String get mgCustomizeMangaSection => '自定义漫画版块';

  @override
  String get mgClose => '关闭';

  @override
  String get mgPosterCardDensity => '海报卡片密度';

  @override
  String get mgMangaPosterCardDensity => '漫画海报卡片密度';

  @override
  String get mgMovingAmbientBackgroundGlow => '动态氛围背景光';

  @override
  String get mgShowContinueReadingSlider => '显示“继续阅读”横栏';

  @override
  String get mgShowContentTypeBadgeOnPosters => '在海报上显示内容类型标签';

  @override
  String get mgMoreAppearanceReaderSettings => '更多外观与阅读器设置';

  @override
  String get mgContinueReading => '继续阅读';

  @override
  String get mgSearchResults => '搜索结果';

  @override
  String get mgDiscoverManga => '发现漫画';

  @override
  String get mgFilteredByCategory => '已按分类筛选';

  @override
  String get mgResetToAllCategories => '重置为全部分类';

  @override
  String get mgNoMangaFound => '未找到漫画';

  @override
  String get mgSearchMangaManhwaManhua => '搜索日漫、韩漫、国漫…';

  @override
  String get mgClearSearch => '清除搜索';

  @override
  String get mgRemoveFromContinueReading => '从继续阅读中移除';

  @override
  String get mgReaderSettingsLayout => '阅读器设置与布局';

  @override
  String get mgReadingOrientationMode => '阅读方向模式';

  @override
  String get mgReadingOrientationModeLabel => '阅读方向模式';

  @override
  String get mgPageReadingWidthConstraint => '页面阅读宽度限制';

  @override
  String get mgPageReadingWidthConstraintLabel => '页面阅读宽度限制';

  @override
  String get mgReaderBackgroundAtmosphere => '阅读器背景氛围';

  @override
  String get mgShowPageDeckPreviewsDrawer => '显示页面预览抽屉';

  @override
  String get mgShowNextChapterDeckCard => '显示下一章卡片';

  @override
  String get mgNoPagesFoundForThisChapter => '本章没有找到页面。';

  @override
  String get mgYouAreAllCaughtUp => '已经全部看完啦！';

  @override
  String get mgUpNext => '下一章';

  @override
  String get mgChapterFinished => '本章已读完';

  @override
  String get mgReadNextChapter => '阅读下一章';

  @override
  String get mgBackToMangaDetails => '返回漫画详情';

  @override
  String get mgPageDeckPreview => '页面预览';

  @override
  String get mgReaderCustomization => '阅读器自定义';

  @override
  String get mgPreviousChapter => '上一章';

  @override
  String get mgZoomOut => '缩小 (-)';

  @override
  String get mgZoomIn => '放大 (+)';

  @override
  String get mgTogglePageDeck => '切换页面预览';

  @override
  String get mgNextChapter => '下一章';

  @override
  String get mgReaderAtmosphere => '阅读器氛围：';

  @override
  String get mgWebtoonScroll => '条漫滚动';

  @override
  String get mgHorizontalLtr => '横向 从左到右';

  @override
  String get mgHorizontalRtl => '横向 从右到左';

  @override
  String get musHome => '首页';

  @override
  String get musSearch => '搜索';

  @override
  String get musBrowse => '浏览';

  @override
  String get musRadio => '电台';

  @override
  String get musLibrary => '音乐库';

  @override
  String get musLoadingArtistDetails => '正在加载歌手详情…';

  @override
  String get musLoadingAlbum => '正在加载专辑…';

  @override
  String get musLoadingPlaylist => '正在加载歌单…';

  @override
  String get musSeekBack5s => '后退 5 秒';

  @override
  String get musSeekForward5s => '快进 5 秒';

  @override
  String get musMuted => '已静音';

  @override
  String get musUnmuted => '已取消静音';

  @override
  String get musNewPlaylist => '新建歌单';

  @override
  String get musEnterPlaylistTitle => '输入歌单名称…';

  @override
  String get musCancel => '取消';

  @override
  String get musCreate => '创建';

  @override
  String get musDownloadedOfflineTapToRemove => '已离线下载（点按移除）';

  @override
  String get musDownloadingQueued => '下载中 / 排队中…';

  @override
  String get musDownloadTrackOffline => '离线下载歌曲';

  @override
  String get musSaveToPlaylist => '保存到歌单';

  @override
  String get musNoCustomPlaylistsYet => '还没有自建歌单';

  @override
  String get musCreateFirstPlaylist => '创建第一个歌单';

  @override
  String get musSavedToLibrary => '已保存到音乐库';

  @override
  String get musRemovedFromLibrary => '已从音乐库移除';

  @override
  String get musNewAlbumReleases => '新专辑上架';

  @override
  String get musCuratedChartsMixes => '精选榜单与合辑';

  @override
  String get musSearchResults => '搜索结果';

  @override
  String get musSearchToFindTracksArtistsAlbums => '搜索歌曲、歌手、专辑和歌单';

  @override
  String get musSongs => '歌曲';

  @override
  String get musHipHopRap => '嘻哈与说唱';

  @override
  String get musElectronicEdm => '电子与 EDM';

  @override
  String get musChillLofiBeats => '轻松 Lofi 节拍';

  @override
  String get musRBSoul => 'R&B 与灵魂乐';

  @override
  String get musSoundtracksGaming => '原声与游戏音乐';

  @override
  String get musJazzBlues => '爵士与蓝调';

  @override
  String get musBrowseMoodsGenres => '按心情与流派浏览';

  @override
  String get musPopRadio => '流行电台';

  @override
  String get musRapHipHop => '说唱与嘻哈';

  @override
  String get musRockMix => '摇滚混音';

  @override
  String get musDanceElectro => '舞曲与电子';

  @override
  String get musRBStation => 'R&B 电台';

  @override
  String get musLofiAmbient => 'Lofi 与氛围音乐';

  @override
  String get musHeavyMetalStation => '重金属电台';

  @override
  String get musJazzClub => '爵士俱乐部';

  @override
  String get musYourLibrary => '你的音乐库';

  @override
  String get musNoLikedSongsYet => '还没有喜欢的歌曲';

  @override
  String get musLikedSongs => '喜欢的歌曲';

  @override
  String get musDownloadedSongs => '已下载的歌曲';

  @override
  String get musCustomPlaylists => '自建歌单';

  @override
  String get musRecentlyPlayed => '最近播放';

  @override
  String get musSearchShort => '搜索…';

  @override
  String get musSearchMusic => '搜索音乐…';

  @override
  String get musSearchSongsArtistsAlbumsPlaylists => '搜索歌曲、歌手、专辑、歌单…';

  @override
  String get musMusicPlayerStudio => '音乐播放器工作室';

  @override
  String get musMusicAtmosphereSettings => '音乐氛围设置';

  @override
  String get musAppSettings => '应用设置';

  @override
  String get musMusicView => '音乐视图';

  @override
  String get musAudioSourceQuality => '音源与音质';

  @override
  String get musChooseExtractionEngine => '选择你偏好的音乐解析引擎';

  @override
  String get musFlacLosslessQobuzHiRes => 'FLAC 无损（Qobuz 高解析）';

  @override
  String get musStudioMasterQualityDesc => '录音室母带音质，最高 24-bit/192kHz，零压缩';

  @override
  String get musLossless => '无损';

  @override
  String get musYoutubeAudio => 'YouTube 音频';

  @override
  String get musYoutubeAudioDesc => '高速音频解析，智能匹配曲目与时长';

  @override
  String get musFast => '极速';

  @override
  String get musTopChartHit => '热门榜单单曲';

  @override
  String get musPlayNow => '立即播放';

  @override
  String get musTrendingArtists => '热门歌手';

  @override
  String get musDownloadedOffline => '已下载（离线）';

  @override
  String get musQueuedForDownload => '已加入下载队列';

  @override
  String get musDownloadTrack => '下载歌曲';

  @override
  String get musSyncedLyrics => '同步歌词';

  @override
  String get musNoLyricsFoundForThisTrack => '未找到这首歌的歌词。';

  @override
  String get musClear => '清空';

  @override
  String get musQueueIsEmpty => '播放队列为空';

  @override
  String get musPlayAll => '全部播放';

  @override
  String get musTopSongs => '热门歌曲';

  @override
  String get musAlbumsDiscography => '专辑与作品';

  @override
  String get musAlbum => '专辑';

  @override
  String get musPlayAlbum => '播放专辑';

  @override
  String get musDownloadAlbum => '下载专辑';

  @override
  String get musPlayPlaylist => '播放歌单';

  @override
  String get musDownloadPlaylist => '下载歌单';

  @override
  String get musDownloadAll => '全部下载';

  @override
  String get musNoTracksInThisPlaylistYet => '这个歌单还没有歌曲';

  @override
  String get musPlayingQueue => '播放队列';

  @override
  String get musTogglePlayPause => '播放 / 暂停';

  @override
  String get musSeek5SecondsBackward => '后退 5 秒';

  @override
  String get musSeek5SecondsForward => '快进 5 秒';

  @override
  String get musToggleMuteUnmute => '静音 / 取消静音';

  @override
  String get musToggleQueueDrawer => '打开/关闭播放队列';

  @override
  String get musToggleFullscreenNowPlaying => '切换全屏正在播放';

  @override
  String get musShowShortcuts => '显示快捷键';

  @override
  String get musKeyboardShortcuts => '键盘快捷键';

  @override
  String get musShuffle => '随机播放';

  @override
  String get musSearchOffline => '搜索离线歌曲…';

  @override
  String get musNoOfflineDownloadsYetTapThe =>
      '还没有离线下载。\n点按任意歌曲、专辑或歌单上的下载图标即可离线收听。';

  @override
  String get musDeleteFromDownloads => '从下载中删除';

  @override
  String get musDeleteDownloadedSong => '删除已下载歌曲';

  @override
  String get musDelete => '删除';

  @override
  String get tvLiveBadge => '直播';

  @override
  String get tvCancelSelection => '取消选择';

  @override
  String get tvManageDeleteChannels => '管理 / 删除频道';

  @override
  String get tvDeselectAll => '取消全选';

  @override
  String get tvSelectAll => '全选';

  @override
  String get tvStop => '停止';

  @override
  String get tvScanningPortals => '正在并行扫描所有已验证的门户…';

  @override
  String get tvNoAliveStreams => '暂未发现可用的直播源。';

  @override
  String get tvTapScanMoreHint => '点击“扫描更多门户”以发现新的直播源。';

  @override
  String get tvClearSearch => '清除搜索';

  @override
  String get tvFreeBadge => '免费';

  @override
  String get tvWatchLive => '观看直播';

  @override
  String get tvScanMore => '扫描更多';

  @override
  String get tvChannelListAndSchedule => '频道列表与节目单';

  @override
  String get tvDescPremier => '全球顶级体育赛事与锦标赛频道';

  @override
  String get tvDescBoxing =>
      'Sky Sports Box Office、DAZN、TNT Sports Box Office 及免费格斗频道';

  @override
  String get tvDescUs =>
      'ABC News Live、CBS News 24/7、NBC News Now、Weather Channel 等';

  @override
  String get tvDescUk => 'BBC One UK、ITV News、Sky News UK、Channel 4 等';

  @override
  String get tvDescIntlSports =>
      'Willow Cricket、Fox Soccer Plus、GolTV、TUDN、Viaplay 等';

  @override
  String get tvManagePortalsPlaylists => '管理门户与播放列表';

  @override
  String get tvSearchChannels => '搜索频道';

  @override
  String get tvSettings => '设置';

  @override
  String get tvMultiStreamsTooltip => '多路直播（多画面窗口）';

  @override
  String get tvMultiStreams => '多路直播';

  @override
  String get tvQuickChannels => '快捷频道';

  @override
  String get tvAddQuickChannel => '添加快捷频道';

  @override
  String get tvAddChannel => '添加频道';

  @override
  String get tvChannelName => '频道名称';

  @override
  String get tvRequired => '必填';

  @override
  String get tvShortCodeOptional => '简称（可选）';

  @override
  String get tvCategory => '分类';

  @override
  String get tvKeywordsCommaSeparated => '关键词（用逗号分隔）';

  @override
  String get tvKeywordsHint => '例如：cnn, news, international';

  @override
  String get tvGradient => '渐变色';

  @override
  String get tvCancel => '取消';

  @override
  String get tvConnectingToStream => '正在连接直播源…';

  @override
  String get tvChannelNoSources => '该频道暂无直播源。';

  @override
  String get tvFeedWouldNotPlay => '该直播源无法播放。';

  @override
  String get tvFeedStalled => '该直播源卡顿，无法继续播放。';

  @override
  String get tvAspectFitContain => '画面比例：适应';

  @override
  String get tvAspectFillZoomCrop => '画面比例：填充（缩放 / 裁剪）';

  @override
  String get tvAspectStretchFill => '画面比例：拉伸';

  @override
  String get tvReconnecting => '正在重新连接…';

  @override
  String get tvMuted => '已静音';

  @override
  String get tvPlayerLive => '直播';

  @override
  String get tvPlayerVod => '点播';

  @override
  String get tvCategoryChannels => '分类频道';

  @override
  String get tvAlternativeFeeds => '备用直播源';

  @override
  String get tvExitFullscreenF11 => '退出全屏 (F11)';

  @override
  String get tvFullscreenF11 => '全屏 (F11)';

  @override
  String get tvSeekBack10 => '后退 10 秒';

  @override
  String get tvSeekForward10 => '快进 10 秒';

  @override
  String get tvFitShort => '适应';

  @override
  String get tvZoomShort => '缩放';

  @override
  String get tvStretchShort => '拉伸';

  @override
  String get tvStreamFeeds => '直播源';

  @override
  String get tvCustomizePortalsModal => '自定义门户面板';

  @override
  String get tvCardDisplayStyle => '卡片显示样式';

  @override
  String get tvShowPortalExpiry => '显示门户到期日';

  @override
  String get tvShowMaxConnections => '显示最大连接数';

  @override
  String get tvDefaultStartingTab => '默认起始标签页';

  @override
  String get tvPortalsAndPlaylists => '门户与播放列表';

  @override
  String get tvIptvPortalsAndPlaylists => 'IPTV 门户与播放列表';

  @override
  String get tvCustomizeModalStyle => '自定义面板样式';

  @override
  String get tvFinding => '查找中…';

  @override
  String get tvGenerate => '生成';

  @override
  String get tvGeneratePortals => '生成门户';

  @override
  String get tvChoosePortalSource => '选择门户来源';

  @override
  String get tvCloudVault => '云端库';

  @override
  String get tvCloudVaultDesc => '收录在线 IPTV 服务器的高速云端数据库';

  @override
  String get tvRedditCommunities => 'Reddit 社区';

  @override
  String get tvRedditDesc => '抓取各 Reddit 版块中实时分享的内容';

  @override
  String get tvPortalsAdd => '添加';

  @override
  String get tvAddPortal => '添加门户';

  @override
  String get tvDone => '完成';

  @override
  String get tvManage => '管理';

  @override
  String get tvPortalsDeselectAll => '取消全选';

  @override
  String get tvPortalsSelectAll => '全选';

  @override
  String get tvDeleteAll => '全部删除';

  @override
  String get tvAddXtreamPortal => '添加 Xtream Codes 门户';

  @override
  String get tvUsername => '用户名';

  @override
  String get tvPassword => '密码';

  @override
  String get tvShowPassword => '显示密码';

  @override
  String get tvHidePassword => '隐藏密码';

  @override
  String get tvCopyLogin => '复制登录信息 (url:user:pass)';

  @override
  String get tvRemoveFavorite => '取消收藏';

  @override
  String get tvAddToFavorites => '加入收藏';

  @override
  String get tvRemovePortal => '移除门户';

  @override
  String get tvAddM3u => '添加 M3U';

  @override
  String get tvAddM3uUrl => '添加 M3U 链接';

  @override
  String get tvAddM3uSubscription => '添加 M3U 播放列表订阅';

  @override
  String get tvPlaylistName => '播放列表名称';

  @override
  String get tvM3uUrlLabel => 'M3U / M3U8 链接';

  @override
  String get tvNoM3uPlaylists => '尚未保存 M3U 播放列表。';

  @override
  String get tvCopyPlaylistUrl => '复制播放列表链接';

  @override
  String get tvRemovePlaylist => '移除播放列表';

  @override
  String get tvIptvPortal => 'IPTV 门户';

  @override
  String get tvCustomizePortalBrowser => '自定义门户浏览器';

  @override
  String get tvChannelLayoutMode => '频道布局模式';

  @override
  String get tvGridColumns => '网格列数';

  @override
  String get tvShowChannelLogos => '显示频道台标';

  @override
  String get tvShowEpgNowPlaying => '显示节目单“正在播出”摘要';

  @override
  String get tvShowCategoryCounts => '显示分类频道数量';

  @override
  String get tvFavoritesStar => '⭐ 收藏';

  @override
  String get tvLiveChannels => '直播频道';

  @override
  String get tvMovies => '电影';

  @override
  String get tvSeries => '剧集';

  @override
  String get tvBrowserLive => '直播';

  @override
  String get tvBrowserVod => '点播';

  @override
  String get tvBrowserSeriesBadge => '剧集';

  @override
  String get tvSelectCategory => '选择分类';

  @override
  String get tvFilterCategories => '筛选分类…';

  @override
  String get tvBrowserBack => '返回';

  @override
  String get tvLiveTv => '直播';

  @override
  String get tvTvSeries => '电视剧';

  @override
  String get tvSearchChannelsHint => '搜索频道…';

  @override
  String get tvCheckHealth => '检测可用性';

  @override
  String get tvCustomizeBrowserLayout => '自定义门户浏览器布局';

  @override
  String get tvCustomize => '自定义';

  @override
  String get tvLive => '直播';

  @override
  String get tvSearchInCategory => '在此分类中搜索…';

  @override
  String get tvCouldNotLoadPortal => '无法加载此门户';

  @override
  String get tvNoFavoritedChannels => '暂无收藏频道';

  @override
  String get tvFavoritesHint => '点击频道上的星标即可加入收藏。';

  @override
  String get tvNoStreamsInCategory => '此分类下暂无频道。';

  @override
  String get tvEpgNow => '正在播出：';

  @override
  String get tvEpgNext => '   即将播出：';

  @override
  String get tvLiveStreamFeed => '直播源';

  @override
  String get tvRemoveFromFavorites => '取消收藏';

  @override
  String get tvBrowserAddToFavorites => '加入收藏';

  @override
  String get tvCouldNotLoadEpisodes => '无法加载剧集';

  @override
  String get tvSearchBack => '返回';

  @override
  String get tvSearchHint => '搜索 60+ 个直播频道、联赛、电视网…';

  @override
  String get tvChannelCategories => '频道分类';

  @override
  String get tvNoChannelsMatch => '没有符合搜索条件的频道。';

  @override
  String get tvLiveBroadcast => '直播节目';

  @override
  String get tvUpcomingOnChannel => '本频道即将播出';

  @override
  String get tvNothingElseListed => '本频道暂无其他节目。';

  @override
  String get tvNoProgrammeGuide => '本频道暂无节目单。';

  @override
  String get tvFindLiveStreams => '查找直播源';

  @override
  String get tvGuideLive => '直播';

  @override
  String get tvWatchLiveStream => '观看直播';

  @override
  String get tvScheduledProgramme => '预定节目';

  @override
  String get aniPlayEp1Modal => '播放第 1 集';

  @override
  String get aniJumpToEpModal => '跳转到第几集';

  @override
  String get aniPlayEp1 => '播放第 1 集';

  @override
  String get aniJumpToEp => '跳转到第几集';

  @override
  String get aniGeneralTab => '🇯🇵 日本番剧';

  @override
  String get aniArabicAnimeTab => '🇸🇦 阿拉伯语番剧';

  @override
  String get aniSettings => '设置';

  @override
  String get aniWatchS1E1 => '观看第 1 季第 1 集';

  @override
  String get aniArabicToggle => '🇸🇦 阿拉伯语';

  @override
  String get aniAnimeToggle => '🇯🇵 番剧';

  @override
  String get aniOvasOnasSpecials => 'OVA、ONA 与特别篇';

  @override
  String get aniTrendingAnime => '热门番剧';

  @override
  String get aniPopularThisSeason => '本季热门';

  @override
  String get aniAllTimeTopRated => '历史高分';

  @override
  String get aniCascadingExtractors => '正在依次调用番剧解析器…';

  @override
  String get aniSubtitleOrDub => '字幕或配音';

  @override
  String get aniStreamAll => '全部';

  @override
  String get aniSources => '片源';

  @override
  String get aniExtractingStreams =>
      '正在解析 MegaPlay、VidWish、AllAnime 与 Miruro 的片源...';

  @override
  String get aniRetryScraping => '重新解析';

  @override
  String get aniStreamSource => '片源';

  @override
  String get aniStreamDubBadge => '配音';

  @override
  String get aniStreamSubBadge => '字幕';

  @override
  String get aiAnalyzingStorylines => '正在分析你喜爱的剧情与主题...';

  @override
  String get aiStudyingPreferences => '正在研究你的叙事与情绪偏好...';

  @override
  String get aiFindingMatches => '正在寻找高度匹配的影片...';

  @override
  String get aiPolishingRecs => '正在完善你的专属推荐...';

  @override
  String get aiBack => '返回';

  @override
  String get aiRecommendationQuiz => '推荐测试';

  @override
  String get aiRetake => '重新测试';

  @override
  String get aiWhatDoYouLike => '你喜欢看什么？';

  @override
  String get aiQuizIntro => '为至少 3 部电影或剧集打分，选择喜欢或不喜欢，并勾选关键元素，即可生成精准的 AI 推荐。';

  @override
  String get aiAddAnotherTitle => '再添加一部';

  @override
  String get aiRate3ToUnlock => '为 3 部作品打分即可解锁推荐';

  @override
  String get aiRemoveTitle => '移除此作品';

  @override
  String get aiSearchHint => '搜索电影或剧集...';

  @override
  String get aiNeedIdeas => '没有头绪？';

  @override
  String get aiHowWasExperience => '你觉得这部作品怎么样？';

  @override
  String get aiLovedIt => '超爱 ❤️';

  @override
  String get aiLikedIt => '喜欢 👍';

  @override
  String get aiItWasOkay => '一般 😐';

  @override
  String get aiDisliked => '不喜欢 👎';

  @override
  String get aiWhatStoodOut => '哪些地方让你印象深刻？（选择关键元素或写下备注）：';

  @override
  String get aiFetchingTags => '正在获取标签...';

  @override
  String get aiNotesHint => '补充说明（可选）...';

  @override
  String get aiSynthesizing => 'AI 正在综合分析你的口味...';

  @override
  String get aiYourMatches => '你的专属推荐';

  @override
  String get plyMedia3EngineError => 'Media3 引擎播放出错';

  @override
  String get plyRefusedByProvider => '服务商拒绝';

  @override
  String get plyNoticeRefused => '拒绝了此片源';

  @override
  String get plyNotReadyYet => '尚未就绪';

  @override
  String get plyNoticeNotReady => '尚未准备好此片源';

  @override
  String get plyAccountRejected => '账号被拒绝';

  @override
  String get plyNoticeAccountRejected => '拒绝了该账号';

  @override
  String get plyTemporarilyUnavailable => '暂时不可用';

  @override
  String get plyNoticeCouldNotServe => '无法提供此片源';

  @override
  String get plyWaitingForData => '⏳ 正在等待片源传输数据';

  @override
  String get plyBlackScreenSoftware => '⚠️ 检测到黑屏 • 已切换为软件解码';

  @override
  String get plyDecoderResynced => '⚠️ 当前分辨率解码失败 • 已重新同步硬件解码';

  @override
  String get plyMaxBoost => '最大增强';

  @override
  String get plyBoost => '音量增强';

  @override
  String get ply2xSpeed => '2 倍速';

  @override
  String get plyAspectFillCrop => '画面比例：填充 / 裁剪';

  @override
  String get plyAspectStretch => '画面比例：拉伸填充';

  @override
  String get plyAspectFit => '画面比例：适应屏幕';

  @override
  String get plyDirector => '导演';

  @override
  String get plyDismiss => '关闭';

  @override
  String get plyAudioDubLanguage => '音轨与配音语言';

  @override
  String get plyUnknownSource => '未知';

  @override
  String get mnzRestoring => '正在恢复...';

  @override
  String get mnzPlaybackError => '播放出错';

  @override
  String get mnzSwitchingFeed => '正在切换直播源...';

  @override
  String get mnzSwitchFailed => '切换失败';

  @override
  String get mnzCustomStream => '自定义直播';

  @override
  String get mnzConnecting => '正在连接...';

  @override
  String get mnzSelectChannel => '选择频道';

  @override
  String get mnzStreamDetails => '直播详情';

  @override
  String get mnzStreamName => '直播名称';

  @override
  String get mnzLiveStream => '直播';

  @override
  String get mnzDiscoveringStream => '正在查找直播源...';

  @override
  String get mnzNoActiveFeeds => '未找到可用直播源';

  @override
  String get mnzConnectingToFeed => '正在连接直播源...';

  @override
  String get mnzFailedToLoadFeed => '直播源加载失败';

  @override
  String get mnzCancel => '取消';

  @override
  String get mnzAdd => '添加';

  @override
  String get mnzAddLiveFeed => '添加直播源';

  @override
  String get mnzBackToLiveTv => '返回直播';

  @override
  String get mnzMultiStreams => '多路直播';

  @override
  String get mnzPreviousLayout => '上一个布局';

  @override
  String get mnzNextLayout => '下一个布局';

  @override
  String get mnzDoneRearranging => '完成排列';

  @override
  String get mnzRearrangeStreams => '调整排列';

  @override
  String get mnzMuteAll => '全部静音';

  @override
  String get mnzClearAllWindows => '清空所有窗口';

  @override
  String get dscCustom => '自定义';

  @override
  String get dscNoAdultSources => '暂无 18+ 片源。\n请在 设置 → 插件 中将插件标记为 18+，或安装一个。';

  @override
  String get dscNoTitlesInCatalog => '此片单中暂无内容';

  @override
  String get dscSelectRequiredFilter => '选择必选筛选项';

  @override
  String get dscCancel => '取消';

  @override
  String get dscDiscover => '发现';

  @override
  String get dscSearchHint => '搜索...';

  @override
  String get dscSearchCatalog => '搜索片单';

  @override
  String get colFranchises => '系列电影';

  @override
  String get colMemoryLane => '时光回忆';

  @override
  String get colCuratedTitle => '精选系列与年代合集';

  @override
  String get colCuratedSubtitle => '精心挑选的影片合集，按观看顺序排列。';

  @override
  String get colBack => '返回';

  @override
  String get calBack => '返回';

  @override
  String get calTitle => '剧集播出日历';

  @override
  String get calSubtitle => '即将播出的电视与流媒体剧集，可按电视网筛选';

  @override
  String get calFilterShows => '筛选剧集...';

  @override
  String get calToday => '今天';

  @override
  String get calTomorrow => '明天';

  @override
  String get calNetwork => '电视网：';

  @override
  String get calNoEpisodesThisDay => '当天没有剧集播出';

  @override
  String get calTryAllNetworks => '请尝试选择上方的“全部”或其他电视网';

  @override
  String get calSelectAnotherDay => '请从上方时间轴选择其他日期';

  @override
  String get hmCinemaUniverse => '你的私人影院';

  @override
  String get hmAiTasteQuiz => 'AI 口味测试';

  @override
  String get hmTvAiringCalendar => '剧集播出日历';

  @override
  String get ctlNoItemsFound => '暂无内容';

  @override
  String get ctlSearchHint => '搜索...';

  @override
  String get ctlAll => '全部';

  @override
  String get araResolvingServers => '正在解析服务器…';

  @override
  String get araCrackingServerMap => '正在解析阿拉伯语服务器列表…';

  @override
  String get stgaAddStremioAddon => '添加 Stremio 插件';

  @override
  String get stgaPasteStremioManifestHint =>
      '粘贴 Stremio 插件的 manifest.json URL，即可安装片单、元数据、片源或字幕。';

  @override
  String get stgaCancel => '取消';

  @override
  String get stgaInstall => '安装';

  @override
  String get stgaRemoveAddonBody => '其片单和元数据将从首页移除。';

  @override
  String get stgaRemove => '移除';

  @override
  String get stgaInstallRepoPluginsBody => '要立即安装此仓库的全部插件吗？安装后其片源会立刻出现在播放页。';

  @override
  String get stgaBrowseLater => '稍后浏览';

  @override
  String get stgaInstallAllNow => '立即全部安装';

  @override
  String get stgaInstallingPlugins => '正在安装插件';

  @override
  String get stgaPreparingRuntime => '正在准备运行环境…';

  @override
  String get stgaAddCloudStreamRepo => '添加 CloudStream 仓库';

  @override
  String get stgaPasteRepoUrlHint =>
      '粘贴仓库 URL（支持 cloudstreamrepo://、repo.json 或 plugins.json）。';

  @override
  String get stgaBrowseMarketplace => '浏览插件市场';

  @override
  String get stgaAddRepository => '添加仓库';

  @override
  String get stgaCsExtensionWillUninstall => '此 CloudStream 扩展将被卸载。';

  @override
  String get stgaRemoveRepoBody => '此仓库的插件不会被删除，但将不再获取仓库更新。';

  @override
  String get stgaStremioAddons => 'Stremio 插件';

  @override
  String get stgaStremioTabDescription =>
      '插件提供元数据、片单和片源。长按拖动可调整优先级，排在上面的会优先加载并在片源中靠前显示。';

  @override
  String get stgaInstalledProvidersAddons => '已安装的来源与插件';

  @override
  String get stgaNoAddonsInstalled => '尚未安装插件';

  @override
  String get stgaNoAddonsHint => '点击上方的“添加插件”，输入 Stremio manifest URL 进行安装。';

  @override
  String get stgaDebridAddons => 'Debrid 插件';

  @override
  String get stgaDebridAddonsDescription =>
      '为设置中所选的 Debrid 服务安装插件，并在请求时自动填入已保存的密钥，密钥不会重复存储。';

  @override
  String stgaDebridAddonsPlaceholderNote(String realdebrid) {
    return '以 URL 参数传递密钥的插件支持 $realdebrid 这类占位符；把密钥藏在 base64 配置中的插件则需粘贴完整配置好的地址。';
  }

  @override
  String get stgaCloudStreamTabDescription =>
      'CloudStream（.cs3）扩展直接从热门影视站点提供片源，扩展在本地沙盒 sidecar 或原生 ART 引擎中运行。';

  @override
  String get stgaCsEngineReady => 'CloudStream 引擎已就绪';

  @override
  String get stgaRuntimeSetupRequired => '需要配置运行环境';

  @override
  String get stgaNativeEngineActive => '原生引擎已启动，正在等待请求。';

  @override
  String get stgaDownloadingRuntime => '正在下载运行组件…';

  @override
  String get stgaRequiresRuntimeHost => '需要运行宿主来执行 .cs3 字节码。';

  @override
  String get stgaRequiresSidecarRuntime => '需要 sidecar 运行环境来执行 .cs3 字节码。';

  @override
  String get stgaRepoMarketplace => '仓库市场';

  @override
  String get stga45PlusRepos => '45+ 仓库';

  @override
  String get stgaRepoMarketplaceDescription =>
      '浏览精选的土耳其语、阿拉伯语、英语、印地语及全球仓库，支持一键安装。';

  @override
  String get stgaBrowseAvailablePlugins => '浏览可用插件';

  @override
  String get stgaDeselectAll => '取消全选';

  @override
  String get stgaSelectAll => '全选';

  @override
  String get stgaInstalledExtensions => '已安装的扩展';

  @override
  String get stgaInstalledCsExtensions => '已安装的 CloudStream 扩展';

  @override
  String get stgaNoExtensionsInstalled => '尚未安装扩展';

  @override
  String get stgaNoExtensionsHint => '点击“浏览可用插件”查找并安装扩展。';

  @override
  String get stgaRepositories => '仓库';

  @override
  String get stgaNoReposHint => '尚未添加自定义仓库。点击“添加仓库”订阅 CloudStream 仓库。';

  @override
  String get stgaInstallAllFromRepoTooltip => '安装此仓库的全部插件';

  @override
  String get stgaBrowseRepoPlugins => '浏览仓库插件';

  @override
  String get stgaRemoveRepository => '移除仓库';

  @override
  String get stgaSetupEngine => '配置引擎';

  @override
  String get stgaBuiltinTorrServer => '内置 TorrServer P2P 播放引擎';

  @override
  String get stgaBuiltinHttpScrapers => '内置多源高速 HTTP 抓取';

  @override
  String get stgaMoveUpPriority => '提高优先级';

  @override
  String get stgaMoveDownPriority => '降低优先级';

  @override
  String get stgaBuiltinTorrent => '内置种子';

  @override
  String get stgaBuiltinHttp => '内置 HTTP';

  @override
  String get stgaRemoveAddon => '移除插件';

  @override
  String get stgaFunctions => '功能';

  @override
  String get stgaCatalogs => '片单';

  @override
  String get stgaSearch => '搜索';

  @override
  String get stgaSources => '片源';

  @override
  String get stgaSubtitles => '字幕';

  @override
  String get stgaInstalling => '正在安装…';

  @override
  String get stgaAddAddon => '添加插件';

  @override
  String get stgaConnecting => '正在连接…';

  @override
  String get stgaConnect => '连接';

  @override
  String get stgaDisconnect => '断开连接';

  @override
  String get stgaConnected => '已连接';

  @override
  String get stgaNoDebridProviderYet => '尚未设置 Debrid 服务';

  @override
  String get stgaSetupDebridFirst => '请先在设置中配置 Debrid 服务，再回来连接。';

  @override
  String get stgaCsDefaultDescription => 'CloudStream 抓取与播放来源';

  @override
  String get stgaAvailablePlugins => '可用插件';

  @override
  String get stgaAvailableCsPlugins => '可用的 CloudStream 插件';

  @override
  String get stgaSearchPluginsHint => '搜索插件（如 Sflix、SuperStream）…';

  @override
  String get stgaNoPluginsInRepos => '已添加的仓库中没有找到插件。\n请先添加 CloudStream 仓库 URL。';

  @override
  String get stgaInstalled => '已安装';

  @override
  String get stgaUninstall => '卸载';

  @override
  String get stgaInstallRepoPluginsNowQ => '要立即安装此仓库的插件吗？';

  @override
  String get stgaLater => '稍后';

  @override
  String get stgaInstallingRepoPlugins => '正在安装仓库插件';

  @override
  String get stgaInstallingExtensions => '正在安装扩展…';

  @override
  String get stgaMarketplace => '插件市场';

  @override
  String get stgaRefreshListFromWeb => '从网络刷新列表';

  @override
  String get stgaSearchRepoOrPluginHint =>
      '搜索仓库或插件（如 Turkish、3rabi、DiziBox、Shahid）…';

  @override
  String get stgaAdded => '已添加';

  @override
  String get stgaAddingRepository => '正在添加仓库…';

  @override
  String get stgaInstallRepository => '安装仓库';

  @override
  String get stgaInstallAllPlugins => '安装全部插件';

  @override
  String get stgaBrowse => '浏览';

  @override
  String get stgaHidePlugins => '收起插件';

  @override
  String get stgaPastedKeyFromClipboard => '已从剪贴板粘贴密钥';

  @override
  String get stgaDismiss => '关闭';

  @override
  String get stgaDebridPageDescription =>
      '通过高速云端 Debrid 服务即时播放种子和磁力链接，无需本地 P2P 下载。';

  @override
  String get stgaUseDebridForStreams => '使用 Debrid 播放';

  @override
  String get stgaRouteTorrentsThroughCloud => '通过云端服务器解析种子链接';

  @override
  String get stgaSelectDebridAndSaveKey => '请选择一个 Debrid 服务，并在下方保存 API 密钥。';

  @override
  String get stgaDebridDisabledLocal => '已关闭 Debrid 播放，改用本地引擎。';

  @override
  String get stgaDebridToggleNote =>
      '开启后，来自 Lumora 和 Stremio 插件的所有种子都只通过当前 Debrid 服务解析，不使用本地种子引擎。';

  @override
  String get stgaActiveProvider => '当前服务';

  @override
  String get stgaSelectDefaultDebrid => '选择默认 Debrid 服务';

  @override
  String get stgaDebridProviderNote => '播放时 Lumora 会向此服务发送请求。';

  @override
  String get stgaProviderCredentials => '服务凭据';

  @override
  String get stgaGetTokenRealDebrid => '在 real-debrid.com/apitoken 获取令牌';

  @override
  String get stgaGetKeyTorBox => '在 torbox.app/settings 获取密钥';

  @override
  String get stgaGetKeyAllDebrid => '在 alldebrid.com/apikeys 获取密钥';

  @override
  String get stgaAccountConnected => '账号：已连接';

  @override
  String get stgaGetKeyPremiumize => '在 premiumize.me/account 获取密钥';

  @override
  String get stgaGetKeyDebridLink => '在 debrid-link.com/webapp/apikey 获取密钥';

  @override
  String get stgaActiveBadge => '使用中';

  @override
  String get stgaPasteApiKeyToken => '粘贴 API 密钥 / 令牌';

  @override
  String get stgaClear => '清除';

  @override
  String get stgaShowKey => '显示密钥';

  @override
  String get stgaHideKey => '隐藏密钥';

  @override
  String get stgaPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get stgaSave => '保存';

  @override
  String get stgaPurposeWyzie => '在 Wyzie 字幕库中搜索电影和剧集字幕。';

  @override
  String get stgaPurposeAudiobookSearch => '生成 Audionest 有声书搜索 API 所需的匿名令牌。';

  @override
  String get stgaPurposeAudiobookService => 'Audionest 有声书搜索接口的 Bearer 令牌。';

  @override
  String get stgaPurposePaper2audio => 'paper2audio PDF 转有声书后端的 Firebase 密钥。';

  @override
  String get stgaPurposeVidgod => '内置片源所用 VidGod 云缓存的 Bearer 令牌。';

  @override
  String get stgaPurposeFilms365 => 'Films365 直链片源 API 的 Bearer 令牌。';

  @override
  String get stgaPurposeTraktSecret => '用设备码换取 Trakt 访问令牌。';

  @override
  String get stgaSourceUser => '正在使用你的密钥。';

  @override
  String get stgaSourceBuildTime => '由本版本构建时提供。';

  @override
  String get stgaSourceInherited => '正在使用应用自带的值。';

  @override
  String get stgaSourceNone => '没有可用密钥，此来源保持关闭。';

  @override
  String get stgaPastedKeyFromClipboardDot => '已从剪贴板粘贴密钥。';

  @override
  String get stgaKeysYouCanObtain => '可自行获取的密钥';

  @override
  String get stgaBorrowedCredentials => '借用的凭据';

  @override
  String get stgaRelated => '相关';

  @override
  String get stgaSavedBadge => '已保存';

  @override
  String get stgaClearKey => '清除密钥';

  @override
  String get stgaTmdbApiKey => 'TMDb API 密钥';

  @override
  String get stgaTmdbRowDescription => '用于 90 年代片单排序及抓取器的元数据查询。';

  @override
  String get stgbGpuUpscaling => 'GPU 画质增强';

  @override
  String get stgbUpscalingPresets => '画质增强预设';

  @override
  String get stgbDisabledOff => '停用（关闭）';

  @override
  String get stgbStandardPlaybackDesc => '标准视频播放，不使用 GLSL 神经网络滤镜。GPU 开销最低。';

  @override
  String get stgbStandard => '标准';

  @override
  String get stgbModeAFast => '模式 A — 快速 / 均衡';

  @override
  String get stgbModeAFastDesc => '锐利线条修复与 2 倍 CNN 放大。最适合 1080p 动漫和中等性能 GPU。';

  @override
  String get stgbRecommended => '推荐';

  @override
  String get stgbModeAHq => '模式 A — 高画质（极致）';

  @override
  String get stgbModeAHqDesc => '使用超大型 CNN 实现最高感知保真度。推荐独立显卡（RTX/Radeon）使用。';

  @override
  String get stgbUltraQuality => '极致画质';

  @override
  String get stgbModeBSoft => '模式 B — 柔和 / 降噪';

  @override
  String get stgbModeBSoftDesc => '平滑线条重建并减少画面瑕疵。最适合模糊、压缩严重或较老的动漫。';

  @override
  String get stgbDenoise => '降噪';

  @override
  String get stgbModeCDeblur => '模式 C — 去模糊与放大';

  @override
  String get stgbModeCDeblurDesc => '强力去模糊与放大。最适合 480p 和 720p 低分辨率动漫剧集。';

  @override
  String get stgbDeblur => '去模糊';

  @override
  String get stgbFsrSmooth => 'FSR 1.0 — 柔和';

  @override
  String get stgbLiveAction => '真人影视';

  @override
  String get stgbFsrSharp => 'FSR 1.0 — 锐利';

  @override
  String get stgbUseWithCare => '谨慎使用';

  @override
  String get stgbPipelineCompat => '渲染管线与兼容性';

  @override
  String get stgbPlaybackStartApply => '播放开始时生效';

  @override
  String get stgbPlaybackStartApplyDesc =>
      '着色器在播放开始前配置。更改预设后，将在下一次打开的串流或视频中生效。';

  @override
  String get stgbHwDecoderAccel => '硬件解码加速';

  @override
  String get stgbHwDecoderAccelDesc =>
      'media_kit 使用原生自动安全硬件解码，将 GPU 纹理内存直接送入 GLSL 着色器处理。';

  @override
  String get stgbPlatformRecommendation => '平台建议';

  @override
  String get stgbPlatformRecommendationDesc =>
      '桌面端（Windows/macOS/Linux）推荐模式 A 高画质，线条清晰锐利；移动设备推荐模式 A 快速，可流畅播放 60fps。';

  @override
  String get stgbHwAccelDecoding => '硬件加速与解码';

  @override
  String get stgbAllPlatforms => '全平台';

  @override
  String get stgbAutoSafeRecommended => '自动安全（推荐）';

  @override
  String get stgbAutoSafeDesc => 'GPU 硬件解码，并带有安全的驱动回退机制。对大多数电脑和设备效率最佳。';

  @override
  String get stgbDefault => '默认';

  @override
  String get stgbSoftwareDecoding => '软件解码（防崩溃）';

  @override
  String get stgbSoftwareDecodingDesc =>
      '通过 FFmpeg libavcodec 纯 CPU 解码。可消除旧 GPU 或虚拟机上的黑屏和驱动卡死。';

  @override
  String get stgbFullyReliable => '100% 稳定';

  @override
  String get stgbDirectHardware => '直接硬件解码';

  @override
  String get stgbDirectHardwareDesc =>
      '直接 GPU 解码（Direct3D 11 / MediaCodec / VAAPI）。在新款高端显卡上速度最快。';

  @override
  String get stgbMaxGpu => 'GPU 满载';

  @override
  String get stgbPlaybackEngine => '播放引擎';

  @override
  String get stgbMpvOnly => '仅 mpv';

  @override
  String get stgbExoPlayerFastest => 'Android ExoPlayer（4K 最快）';

  @override
  String get stgbExoPlayerDesc =>
      '直接解码到画面表面，4K 画面无需先从解码器中复制出来。在 2 GB 内存的电视上，延迟可从 1,900 毫秒以上降到 904 毫秒，并且从每秒丢一帧半变为不丢帧。字幕由 Android 渲染，因此下方的字幕样式选项不适用。';

  @override
  String get stgbFasterAt4k => '4K 更快';

  @override
  String get stgbMpvFullSubtitle => 'mpv（完整字幕控制）';

  @override
  String get stgbMpvDesc =>
      '内置引擎。可播放种子和直播，提供下方完整的字幕样式选项，并支持画质增强预设。解码后的画面需经纹理复制，这也是低配电视播放 4K 卡顿的原因。';

  @override
  String get stgbMostFeatures => '功能最全';

  @override
  String get stgbTorrentsLiveUseMpv => '种子和电视直播始终使用 mpv';

  @override
  String get stgbTorrentsLiveUseMpvDesc =>
      '无论此处选择哪个引擎，种子来源和直播频道都会通过 mpv 播放，因为 Android 播放器无法打开它们。此选择适用于电影、剧集以及其他通过普通 HTTP 获取的内容。';

  @override
  String get stgbAutoRecoverBlack => '黑屏自动恢复';

  @override
  String get stgbActiveWatchdog => '主动监控';

  @override
  String get stgbActiveWatchdogDesc =>
      '监控串流启动。若有声音但 2.5 秒内没有画面，或发生 GPU 解码错误，播放器会自动恢复。在 Android 上，1080p 及以下会切换为软件解码，更高分辨率则重新同步硬件解码器，因为 4K 软件解码所需内存超出设备容量。若来源只是尚未传输数据，会继续等待，而不会视为解码故障。';

  @override
  String get stgbAndroidRenderingEngine => 'Android 渲染引擎';

  @override
  String get stgbDirectSurface => '直接表面（SurfaceView）';

  @override
  String get stgbZeroCopy => '零拷贝';

  @override
  String get stgbOffTextureView => '关闭（TextureView）';

  @override
  String get stgbDirectSurfaceDesc =>
      '使用 Flutter SurfaceProducer 将画面直接渲染到硬件表面，无需纹理复制。在 Android 上可显著提升 4K/60fps 播放表现并降低耗电。（如设备出现显示异常，请保持关闭。）';

  @override
  String get stgbAppearanceIntro => '微调视觉氛围、自定义壁纸背景和界面布局。';

  @override
  String get stgbInterfaceAtmosphere => '界面与氛围';

  @override
  String get stgbCustomBgWallpaper => '自定义背景与壁纸';

  @override
  String get stgbCustomBgWallpaperDesc => '上传自定义照片、选择精选深色壁纸，并融合主题环境光';

  @override
  String get stgbCustomActive => '自定义已启用';

  @override
  String get stgbDefaultTheme => '默认主题';

  @override
  String get stgbLiquidGlassSetup => '液态玻璃设置';

  @override
  String get stgbLiquidGlassSetupDesc => '调整悬停效果、弹簧摆动物理、透镜折射和色差';

  @override
  String get stgbDisabled => '已停用';

  @override
  String get stgbHomeUiThemes => '首页界面';

  @override
  String get stgbHomeUiThemesDesc => '“因为你收藏了”智能轮播、焦点大图和卡片密度';

  @override
  String get stgbLiveTvSportsUi => '电视直播与体育界面';

  @override
  String get stgbLiveTvSportsUiDesc => '直播焦点大图、频道卡片密度、分类排序和直播标识样式';

  @override
  String get stgbSpotlightOn => '焦点已开启';

  @override
  String get stgbCompact => '紧凑';

  @override
  String get stgbContent => '内容';

  @override
  String get stgbMangaUiReader => '漫画界面与阅读氛围';

  @override
  String get stgbMangaUiReaderDesc => '动态环境光、卡片密度、阅读版面宽度、条漫/横向模式和页面预览';

  @override
  String get stgbWebtoon => '条漫';

  @override
  String get stgbHorizontal => '横向';

  @override
  String get stgbPlayback => '播放';

  @override
  String get stgbAudiobookUiStudio => '有声书界面与播放器工作室';

  @override
  String get stgbAudiobookUiStudioDesc => '焦点大图、5 种播放器设计、拖放式模块化工作室、波形进度条和自定义控件';

  @override
  String get stgbMusicUiStudio => '音乐界面与播放器工作室';

  @override
  String get stgbMusicUiStudioDesc =>
      '焦点大图、无损标识，以及可调整布局、进度条、物理效果和唱盘样式的全屏播放器工作室';

  @override
  String get stgbDiagnostics => '诊断';

  @override
  String get stgbGraphicsBackend => '图形后端';

  @override
  String get stgbRestartToApplyBackend => '重启应用后生效 — 图形后端在引擎启动时确定。';

  @override
  String get stgbSkiaRecommended => 'Skia（推荐）';

  @override
  String get stgbSimklIntro => '连接你的 Simkl 账号，同步电影、剧集和动漫的待看清单、继续观看进度以及自定义片单。';

  @override
  String get stgbConnected => '已连接';

  @override
  String get stgbDisconnected => '未连接';

  @override
  String get stgbCheckingCredentials => '正在检查凭据...';

  @override
  String get stgbSimklSignInPin => '使用 PIN 码登录以启用 Simkl 云同步';

  @override
  String get stgbDisconnect => '断开连接';

  @override
  String get stgbConnectSimkl => '连接 Simkl';

  @override
  String get stgbSimklEnterPin => '请在 simkl.com/pin 输入此 PIN 码：';

  @override
  String get stgbOpenSimklPin => '打开 simkl.com/pin';

  @override
  String get stgbSimklWaitingPin => '正在等待 simkl.com 上的 PIN 码确认...';

  @override
  String get stgbCloudSyncControls => '云同步控制';

  @override
  String get stgbSyncSimklWatchlist => '同步 Simkl 待看清单与继续观看';

  @override
  String get stgbSimklManualPull => '手动立即从 Simkl 拉取数据';

  @override
  String get stgbTraktIntro =>
      '连接你的 Trakt.tv 账号，在所有设备间无缝同步观看记录、待看清单、继续观看进度和评分。';

  @override
  String get stgbTraktSignIn => '登录以启用双向云同步';

  @override
  String get stgbPairAccount => '配对账号';

  @override
  String get stgbTraktEnterCode => '请在 trakt.tv/activate 输入此激活码：';

  @override
  String get stgbOpenTraktActivate => '打开 trakt.tv/activate';

  @override
  String get stgbTraktWaitingAuth => '正在等待 trakt.tv 授权...';

  @override
  String get stgbSyncWatchlistNow => '立即同步待看清单与继续观看';

  @override
  String get stgbTraktManualPull => '手动立即从 Trakt 拉取数据';

  @override
  String get stgbConnectedStatus => '已连接';

  @override
  String get stgbTmdbKeyRejected => '该密钥被 TMDb 拒绝';

  @override
  String get stgbTmdbUnreachable => '无法连接 TMDb';

  @override
  String get stgbTmdbPasteFirst => '请先粘贴 TMDb API 密钥。';

  @override
  String get stgbTmdbKeySaved => 'TMDb 密钥已保存。90 年代栏目现在使用 TMDb 排名。';

  @override
  String get stgbTmdbKeyCleared => 'TMDb 密钥已清除。已恢复内置的 90 年代精选。';

  @override
  String get stgbPastedKey => '已从剪贴板粘贴密钥。';

  @override
  String get stgbDismiss => '关闭';

  @override
  String get stgbTmdbCredential => 'TMDB 凭据';

  @override
  String get stgbCredits => '致谢';

  @override
  String get stgbSaved => '已保存';

  @override
  String get stgbTmdbSavedOnDevice => '已保存在此设备上。输入新密钥即可替换。';

  @override
  String get stgbTmdbFreeKey => '可从 themoviedb.org 免费获取密钥';

  @override
  String get stgbTmdbPasteHint => '粘贴你的 TMDb API 密钥';

  @override
  String get stgbShowKey => '显示密钥';

  @override
  String get stgbHideKey => '隐藏密钥';

  @override
  String get stgbPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get stgbSaveAndTest => '保存并测试';

  @override
  String get stgbTmdbKeySavedTest => '已保存密钥。可运行测试确认它仍然有效。';

  @override
  String get stgbTmdbNoKey => '尚未保存密钥，当前使用内置精选。';

  @override
  String get stgbClearKey => '清除密钥';

  @override
  String get stgbAboutPoweredBy => '由内置 media_kit / libmpv 驱动，支持硬件加速解码。';

  @override
  String get stgbPlayerStudio => '播放器工作室';

  @override
  String get stgbCustomAudiobookStudio => '自定义有声书播放器工作室';

  @override
  String get stgbAudiobookStudioDesc => '拖动组件、变换进度条、自定义按钮物理效果';

  @override
  String get stgbApplyAsActivePlayer => '设为当前播放器';

  @override
  String get stgbStudioDesigner => '工作室设计器';

  @override
  String get stgbLivePreviewCanvas => '实时预览画布';

  @override
  String get stgbTestLiveCanvas => '测试实时画布';

  @override
  String get stgbBackToCustomizer => '返回自定义';

  @override
  String get stgbLiveInteractiveCanvas => '实时互动画布';

  @override
  String get stgbCustomStudio => '自定义工作室';

  @override
  String get stgbPremadeChaptersPanel => '预设章节面板';

  @override
  String get stgbPauseCaps => '暂停';

  @override
  String get stgbPlayCaps => '播放';

  @override
  String get stgbPremadeChaptersPreview => '预设章节面板预览';

  @override
  String get stgbDragDropLayout => '拖放布局';

  @override
  String get stgbSeekBarCanvas => '进度条画布';

  @override
  String get stgbPlayButtonPhysics => '播放按钮与物理效果';

  @override
  String get stgbArtworkFrame => '封面与边框';

  @override
  String get stgbArtworkVinylFrame => '封面与黑胶边框';

  @override
  String get stgbChapterBookTitles => '章节与书名';

  @override
  String get stgbSeekBarScrubberCanvas => '进度条拖动画布';

  @override
  String get stgbPrimaryControlsAudiobook => '主要控件（播放、暂停、快进/快退 10 秒）';

  @override
  String get stgbSecondaryControlsAudiobook => '次要控件（倍速与音量）';

  @override
  String get stgbPremadeChaptersButton => '预设章节面板按钮';

  @override
  String get stgbDragDropArranger => '拖放组件排列';

  @override
  String get stgbAudiobookArrangerDesc => '按住并拖动任意模块，实时调整音频播放器的纵向布局。';

  @override
  String get stgbSeekBarStyles => '进度条画布与拖动样式';

  @override
  String get stgbSeekBarStylesDesc => '选择进度条和拖动滑块在自定义播放器画布中的显示方式。';

  @override
  String get stgbPlayPauseStyle => '播放 / 暂停按钮样式';

  @override
  String get stgbHoverTouchPhysics => '悬停与触控物理效果';

  @override
  String get stgbPhysicsPlayground => '实时触控与悬停物理效果试玩';

  @override
  String get stgbArtworkDisplayMode => '封面显示模式';

  @override
  String get stgbColorThemesAccents => '配色主题与强调色';

  @override
  String get stgbAmbientLightingGlows => '背景环境光与动态光晕';

  @override
  String get stgbDiscoveryAudiobookPosters => '发现与有声书封面';

  @override
  String get stgbChooseAudioPreset => '选择音频播放器预设';

  @override
  String get stgbMakeCustomAudiobookPlayer => '打造你的自定义有声书播放器（拖放工作室）';

  @override
  String get stgbEnableMovingAtmosphere => '启用动态环境氛围';

  @override
  String get stgbLightingFlowPattern => '光效流动样式';

  @override
  String get stgbGlowStrengthOpacity => '光晕强度 / 不透明度';

  @override
  String get stgbMotionDriftSpeed => '动态漂移速度';

  @override
  String get stgbLiveAtmospherePreview => '实时氛围预览';

  @override
  String get stgbShowHeroCarousel => '显示焦点大图轮播';

  @override
  String get stgbAudiobookHeroDesc => '在有声书主页顶部展示精选畅销有声书';

  @override
  String get stgbShowContinueListening => '显示“继续收听”轮播';

  @override
  String get stgbContinueListeningDesc => '带章节进度条的快速续播卡片，可直接播放';

  @override
  String get stgbAudiobookCardDensity => '有声书封面卡片密度';

  @override
  String get stgbShowGenreBadges => '显示类型与分类标签';

  @override
  String get stgbShowAudiobookRuntime => '显示有声书时长 / 总时长';

  @override
  String get stgbPosterHoverGlowElevation => '封面卡片悬停光晕与浮起';

  @override
  String get stgbOpenStudio => '打开工作室';

  @override
  String get stgbVisualPlayerStudio => '可视化自定义播放器工作室';

  @override
  String get stgbFullStudio => '完整工作室';

  @override
  String get stgbVisualPlayerStudioDesc => '实时拖放布局元素、程序化波形画布、液态玻璃按钮和预设章节面板。';

  @override
  String get stgbEnterPlayerStudio => '进入自定义播放器工作室';

  @override
  String get stgbInteractiveStudioPreview => '互动工作室预览';

  @override
  String get stgbLiveCaps => '实时';

  @override
  String get stgbSeekBarScrubberStyle => '进度条 / 拖动滑块样式';

  @override
  String get stgbPlayPauseStyling => '播放 / 暂停按钮样式';

  @override
  String get stgbArtworkDisplayStyle => '封面显示样式';

  @override
  String get stgbButtonHoverPhysics => '按钮悬停与触控物理效果';

  @override
  String get stgbPlayerLayoutComponents => '播放器布局组件（拖动排列）';

  @override
  String get stgbPlayerLayoutComponentsDesc => '按住并拖动任意模块，调整控件在播放器中的显示顺序';

  @override
  String get stgbLiquidGlassPlayerBlur => '液态玻璃播放器模糊与折射';

  @override
  String get stgbShowSpeedSelector => '显示播放倍速选择（0.5x - 2.5x）';

  @override
  String get stgbShowSkipButtons => '显示快进 / 快退按钮（±10 秒）';

  @override
  String get stgbShowChaptersDrawerButton => '显示快速章节抽屉按钮';

  @override
  String get stgbLaunchFullStudio => '启动完整自定义播放器工作室';

  @override
  String get stgbAudiobookCoverDeck => '有声书封面展示';

  @override
  String get stgbTitleAuthorChapter => '书名、作者与章节标签';

  @override
  String get stgbSeekBarWaveformScrubber => '进度条与波形画布拖动条';

  @override
  String get stgbMainControlsCluster => '主控件组（播放 / 暂停 / 快进快退 10 秒）';

  @override
  String get stgbSpeedVolumeControls => '倍速选择与音量控件';

  @override
  String get stgbPremadeChaptersTrigger => '预设滑出章节面板按钮';

  @override
  String get stgbBgUploadedApplied => '背景图片已上传并应用到全部界面！';

  @override
  String get stgbEnterValidImageUrl => '请输入有效的 HTTP 或 HTTPS 图片网址。';

  @override
  String get stgbCustomBgUrlApplied => '已应用自定义背景网址！';

  @override
  String get stgbCustomBgIntro =>
      '上传你自己的照片或选择精选壁纸。主题色和动态环境光会柔和地融入背景，呈现统一的视觉效果。';

  @override
  String get stgbUploading => '正在上传...';

  @override
  String get stgbUploadPhotoFromDevice => '从设备上传照片';

  @override
  String get stgbResetToDefaultBg => '恢复默认背景';

  @override
  String get stgbBgResetDefault => '背景已恢复为默认主题。';

  @override
  String get stgbPasteImageUrlHint => '或粘贴图片网址（https://...）';

  @override
  String get stgbApply => '应用';

  @override
  String get stgbCuratedDarkWallpapers => '精选深色壁纸';

  @override
  String get stgbWallpaperBlendControls => '壁纸与光效融合控制';

  @override
  String get stgbPhotoVisibility => '照片可见度 / 暗度';

  @override
  String get stgbPhotoSoftBlur => '照片柔化模糊';

  @override
  String get stgbThemeTintOverlay => '主题色叠加';

  @override
  String get stgbBlendAmbientLights => '融合动态环境光';

  @override
  String get stgbBlendAmbientLightsDesc => '在壁纸上柔和地照亮并呈现动态主题光效';

  @override
  String get stgbCustomBgWallpaperCaps => '自定义背景与壁纸';

  @override
  String get stgbCustomWallpaperBlend => '自定义壁纸与光效融合';

  @override
  String get stgbCustomBgActiveBlend => '自定义背景已启用，并融合环境光';

  @override
  String get stgbUploadOrChooseWallpaper => '上传照片或选择精选深色壁纸';

  @override
  String get stgbSmartRecsCaps => '智能推荐（“因为你收藏了”）';

  @override
  String get stgbCuratedCollections => '精选合集';

  @override
  String get stgbHeroBannerSpotlight => '焦点横幅与大图';

  @override
  String get stgbPosterCardsDensity => '海报卡片与密度';

  @override
  String get stgbHeaderShortcuts => '顶栏快捷方式与按钮';

  @override
  String get stgbLiveLightingPreview => '实时光效引擎预览';

  @override
  String get stgbMovingAmbientLights => '动态环境光与光晕';

  @override
  String get stgbMovingAmbientLightsDesc => '背景中飘动的柔和光波与漂浮的彩色光球';

  @override
  String get stgbLightingPatternPosition => '光效样式与位置';

  @override
  String get stgbGlowStrengthIntensity => '光晕强度';

  @override
  String get stgbMotionFlowSpeed => '动态流动速度';

  @override
  String get stgbSmartRecommendations => '智能推荐';

  @override
  String get stgbSmartRecommendationsDesc => '配置个性化和算法推荐轮播';

  @override
  String get stgbBecauseYouHave => '“因为你收藏了…”（我的收藏）';

  @override
  String get stgbBecauseYouHaveDesc => '根据“我的收藏”中的作品提供 BestSimilar 推荐';

  @override
  String get stgbBecauseYoureWatching => '“因为你正在看...”';

  @override
  String get stgbBecauseYoureWatchingDesc => '根据“继续观看”中的作品提供 BestSimilar 推荐';

  @override
  String get stgbTraktRecommendations => 'Trakt 推荐';

  @override
  String get stgbTraktRecommendationsDesc => '由 Trakt 计算的个性化推荐';

  @override
  String get stgbRequiresTraktLogin => '需要在 设置 -> Trakt 中登录 Trakt';

  @override
  String get stgbSimklRecommendations => 'Simkl 推荐';

  @override
  String get stgbSimklRecommendationsDesc => '来自 Simkl 的高分与个性化推荐';

  @override
  String get stgbRequiresSimklLogin => '需要在 设置 -> Simkl 中登录 Simkl';

  @override
  String get stgbRecSlidersPosition => '推荐轮播在首页的位置';

  @override
  String get stgbCollections => '合集';

  @override
  String get stgbCollectionsDesc => '在首页显示精选合集栏目';

  @override
  String get stgbShowHeroBanner => '显示焦点大图横幅';

  @override
  String get stgbShowHeroBannerDesc => '首页顶部的精选轮播横幅';

  @override
  String get stgbSpotlightStyle => '焦点大图样式';

  @override
  String get stgbAutoRotateSpotlight => '焦点大图自动轮播';

  @override
  String get stgbAutoRotateSpotlightDesc => '自动轮换展示精选作品';

  @override
  String get stgbAmbientBackdropLighting => '背景环境光';

  @override
  String get stgbAmbientBackdropLightingDesc => '在当前焦点海报后方显示柔和的漫射色彩光晕';

  @override
  String get stgbPosterSizeDensity => '海报尺寸与网格密度';

  @override
  String get stgbShowImdbBadges => '显示 IMDB 评分标识';

  @override
  String get stgbShowImdbBadgesDesc => '在海报角落显示星级评分标签';

  @override
  String get stgbPosterHoverZoom => '海报悬停缩放比例';

  @override
  String get stgbTvAiringCalendar => '剧集播出日历';

  @override
  String get stgbTvAiringCalendarDesc => '在首页顶栏和轮播中显示剧集日历按钮';

  @override
  String get stgbAiRecQuiz => 'AI 推荐问答';

  @override
  String get stgbAiRecQuizDesc => '在首页和搜索栏显示 AI 问答按钮';

  @override
  String get stgbReset => '重置';

  @override
  String get stgbEnableLiquidGlass => '启用液态玻璃';

  @override
  String get stgbEnableLiquidGlassDesc => '实时折射着色器、果冻弹簧效果和透镜';

  @override
  String get stgbPresets => '预设';

  @override
  String get stgbPhysicsOptical => '物理与光学参数';

  @override
  String get stgbHoverScaleImpact => '悬停缩放幅度';

  @override
  String get stgbHoverScaleImpactDesc => '悬停时播放器玻璃控件的放大程度';

  @override
  String get stgbWobbleElasticity => '摆动与流体弹性';

  @override
  String get stgbWobbleElasticityDesc => '弹簧回弹强度与形变响应速度';

  @override
  String get stgbRefractionIndex => '光学折射率';

  @override
  String get stgbRefractionIndexDesc => '玻璃透镜内的光线弯曲与背景扭曲程度';

  @override
  String get stgbLensMagnification => '透镜放大倍率';

  @override
  String get stgbLensMagnificationDesc => '透过玻璃看到的底层缩放倍数';

  @override
  String get stgbChromaticAberration => '色差（棱镜分光）';

  @override
  String get stgbChromaticAberrationDesc => '沿玻璃斜边分离 RGB 光谱颜色';

  @override
  String get stgbFrostedGlassBlur => '磨砂玻璃模糊';

  @override
  String get stgbFrostedGlassBlurDesc => '在玻璃组件后方应用高斯模糊扩散';

  @override
  String get stgbSpecularShimmer => '高光与闪光';

  @override
  String get stgbSpecularShimmerDesc => '光泽镜面反射与边框照明强度';

  @override
  String get stgbBorderWidth => '边框宽度';

  @override
  String get stgbBorderWidthDesc => '折射外边缘的厚度';

  @override
  String get stgbLiveInteractivePreview => '实时互动预览';

  @override
  String get stgbPreviewEnableGlass => '预览（请先在上方启用玻璃效果）';

  @override
  String get stgbHoverTapPreview => '悬停或点按图标，预览弹簧摆动与缩放效果';

  @override
  String get stgbLiveSpotlightHero => '直播焦点与横幅';

  @override
  String get stgbChannelCardsDensity => '频道卡片与海报密度';

  @override
  String get stgbSectionsCategoryManager => '栏目与分类管理';

  @override
  String get stgbPortalsPlaylistsModal => '门户与播放列表窗口';

  @override
  String get stgbPortalBrowserGuide => '门户浏览与频道指南';

  @override
  String get stgbStreamSources => '串流来源';

  @override
  String get stgbShowLiveSpotlight => '显示直播焦点横幅';

  @override
  String get stgbShowLiveSpotlightDesc => '在顶部展示精选赛事和热门直播频道';

  @override
  String get stgbHeroBannerStyle => '横幅样式';

  @override
  String get stgbAutoRotateChannels => '频道自动轮播';

  @override
  String get stgbAutoRotateChannelsDesc => '自动轮换展示精选直播活动';

  @override
  String get stgbRotationInterval => '轮播间隔';

  @override
  String get stgbChannelCardSize => '频道卡片尺寸';

  @override
  String get stgbCardHoverZoom => '卡片悬停缩放';

  @override
  String get stgbShowLiveHdBadge => '显示直播 / 高清标识';

  @override
  String get stgbShowLiveHdBadgeDesc => '在频道角落显示醒目的直播标识';

  @override
  String get stgbShowChannelCategoryTag => '显示频道分类标签';

  @override
  String get stgbShowChannelCategoryTagDesc => '在频道名称下方显示分类标签';

  @override
  String get stgbShowFeedHealthBadge => '显示信号状态标识';

  @override
  String get stgbShowFeedHealthBadgeDesc => '在拳击栏目中将频道标记为可用、未检测或失效';

  @override
  String get stgbChannelCategoriesSections => '频道分类与栏目';

  @override
  String get stgbToggleLiveTvRows => '切换电视直播栏目的显示';

  @override
  String get stgbResetAll => '全部重置';

  @override
  String get stgbPortalCardStyle => '门户卡片显示样式';

  @override
  String get stgbShowPortalExpiry => '显示门户到期日';

  @override
  String get stgbShowPortalExpiryDesc => '在门户卡片上显示订阅到期标签';

  @override
  String get stgbShowMaxConnections => '显示最大连接数标签';

  @override
  String get stgbShowMaxConnectionsDesc => '显示当前及最大同时串流连接数';

  @override
  String get stgbDefaultStartingTab => '默认起始标签页';

  @override
  String get stgbChannelStreamLayout => '频道串流布局模式';

  @override
  String get stgbGridStreamColumns => '网格列数';

  @override
  String get stgbCategorySidebarWidth => '分类侧栏宽度';

  @override
  String get stgbShowChannelLogos => '显示频道台标';

  @override
  String get stgbShowChannelLogosDesc => '在串流列表中显示频道海报和台标';

  @override
  String get stgbShowEpgNowPlaying => '显示 EPG“正在播出”摘要';

  @override
  String get stgbShowEpgNowPlayingDesc => '在频道下方显示当前节目指南中的节目名';

  @override
  String get stgbShowCategoryCounts => '显示分类串流数量';

  @override
  String get stgbShowCategoryCountsDesc => '在分类名称旁显示可用串流数量';

  @override
  String get stgbIncludeFreePublicSources => '包含免费公共来源';

  @override
  String get stgbIncludeFreePublicSourcesDesc =>
      '将公共 M3U 播放列表（如 iptv-org）加入频道的串流列表';

  @override
  String get stgbDiscoveryPosterCards => '发现与海报卡片';

  @override
  String get stgbMangaReaderViewer => '漫画阅读器与章节查看';

  @override
  String get stgbEnableMovingLighting => '启用动态环境光';

  @override
  String get stgbShowContinueReading => '显示“继续阅读”轮播';

  @override
  String get stgbShowContinueReadingDesc => '在漫画页顶部显示你的阅读记录';

  @override
  String get stgbMangaCardDensity => '漫画封面卡片密度';

  @override
  String get stgbShowContentTypeBadge => '显示内容类型标识（漫画/韩漫）';

  @override
  String get stgbShowPublicationYear => '在卡片上显示出版年份';

  @override
  String get stgbPosterHoverGlow => '封面卡片悬停光晕效果';

  @override
  String get stgbShowDesktopScrollTrack => '显示桌面滚动条';

  @override
  String get stgbDefaultReadingMode => '默认阅读模式';

  @override
  String get stgbPageWidthConstraint => '阅读页面宽度限制';

  @override
  String get stgbReaderBgAtmosphere => '阅读器背景氛围';

  @override
  String get stgbControlToolbarStyle => '控制工具栏样式';

  @override
  String get stgbVerticalPageGap => '页面纵向间距';

  @override
  String get stgbShowPageThumbnails => '显示页面缩略图预览';

  @override
  String get stgbShowPageThumbnailsDesc => '可交互的缩略图预览栏，快速跳转页面';

  @override
  String get stgbShowPageScrubber => '显示页面拖动条';

  @override
  String get stgbEnableNextChapterPreview => '启用下一章预览卡片';

  @override
  String get stgbEnableNextChapterPreviewDesc => '在每章末尾显示带章节插图的玻璃卡片，可直接进入下一章';

  @override
  String get stgbMusicPlayerStudio => '音乐播放器工作室';

  @override
  String get stgbCustomMusicStudio => '自定义音乐播放器工作室';

  @override
  String get stgbMusicStudioDesc => '设计全屏播放器、拖动组件、自定义物理效果与液态玻璃';

  @override
  String get stgbApplyActive => '设为当前';

  @override
  String get stgbFullscreenLiveStudio => '全屏实时工作室';

  @override
  String get stgbSyncedLyrics => '同步歌词';

  @override
  String get stgbPlayingQueue => '播放队列';

  @override
  String get stgbSyncedLyricsSandbox => '同步歌词示例';

  @override
  String get stgbPlayingQueueSandbox => '播放队列示例（4 首曲目）';

  @override
  String get stgbArtworkTurntable => '封面与唱盘';

  @override
  String get stgbAlbumArtTurntable => '专辑封面与黑胶唱盘';

  @override
  String get stgbTrackArtistAlbum => '曲目、艺人与专辑名称';

  @override
  String get stgbTrackTitleQuality => '曲目名称与音质标识';

  @override
  String get stgbLosslessQualityBadge => '无损高解析音质标识';

  @override
  String get stgbPrimaryControlsMusic => '主要控件（播放、暂停、切歌、随机、循环）';

  @override
  String get stgbSecondaryControlsMusic => '次要控件（音量滑块）';

  @override
  String get stgbLyricsQueueButtons => '同步歌词与队列快捷按钮';

  @override
  String get stgbFullscreenArranger => '全屏播放器拖放排列';

  @override
  String get stgbFullscreenArrangerDesc => '按住并拖动任意模块，实时调整全屏播放器的布局。';

  @override
  String get stgbSeekBarScrubberEngine => '进度条画布拖动引擎';

  @override
  String get stgbSeekBarScrubberEngineDesc => '选择音频波形和拖动轨道在音乐播放器中的显示方式。';

  @override
  String get stgbPlayButtonAesthetic => '播放按钮外观与样式';

  @override
  String get stgbHoverTouchPhysicsEngine => '悬停与触控物理引擎';

  @override
  String get stgbHoverTouchPhysicsEngineDesc => '选择悬停或按下控件时的交互物理反馈。';

  @override
  String get stgbLivePhysicsTestPad => '实时物理效果测试区';

  @override
  String get stgbArtworkTurntablePresentation => '封面与唱盘展示';

  @override
  String get stgbArtworkTurntablePresentationDesc =>
      '选择专辑封面、黑胶唱盘动画和卡片在播放器中的显示方式。';

  @override
  String get stgbVisualThemePalette => '视觉主题配色';

  @override
  String get stgbAmbientAtmosphereGlow => '环境氛围与光晕';

  @override
  String get stgbDiscoveryCatalogConfig => '发现与曲库配置';

  @override
  String get stgbFullscreenPlayerPresets => '全屏播放器预设';

  @override
  String get stgbCustomPlayerEngineDesigner => '自定义播放器引擎设计器';

  @override
  String get stgbMovingBgAmbientLighting => '动态背景环境光';

  @override
  String get stgbMovingBgAmbientLightingDesc => '随主题强调色变化的动态发光光球';

  @override
  String get stgbAmbientLightPattern => '环境光样式';

  @override
  String get stgbShowHeroShowcase => '显示焦点大图展示';

  @override
  String get stgbMusicHeroDesc => '在音乐页顶部展示精选畅销专辑与曲目';

  @override
  String get stgbShowLosslessBadges => '显示无损高解析音频标识';

  @override
  String get stgbShowLosslessBadgesDesc => '在音乐卡片和播放器上显示 FLAC / 高解析无损串流标识';

  @override
  String get stgbMusicCardDensity => '音乐卡片与网格密度';

  @override
  String get stgbFullPlayerEngine => '完整播放器引擎';

  @override
  String get stgbCustomizeFullscreenDesc => '自定义全屏播放器：拖放模块、波形均衡器、黑胶唱盘和液态玻璃按钮。';

  @override
  String get stgbLiveWaveformPreview => '实时波形与控件预览';

  @override
  String get stgbOpenFullStudio => '打开完整工作室 ➔';

  @override
  String tv2RemovedStreamFeeds(Object count) {
    return '已删除 $count 个直播源';
  }

  @override
  String tv2SearchChannelsHint(Object count) {
    return '搜索 $count 个频道（如 1080p、4K、源名称）…';
  }

  @override
  String tv2DeleteSelectedFeeds(Object count) {
    return '删除（$count）';
  }

  @override
  String tv2FoundFeedsOfTotal(Object found, Object total) {
    return '共 $total 个源，找到 $found 个';
  }

  @override
  String tv2LiveFeedsAvailable(Object count) {
    return '共 $count 个直播源可用';
  }

  @override
  String tv2NoFeedsMatch(Object query) {
    return '没有与“$query”匹配的源';
  }

  @override
  String tv2ServerNumber(Object number) {
    return '服务器 $number';
  }

  @override
  String tv2ChannelsCountCaps(Object count) {
    return '$count 个频道';
  }

  @override
  String get tv2Add => '添加';

  @override
  String tv2FeedStopped(Object error) {
    return '该直播源已中断：$error';
  }

  @override
  String tv2BufferingName(Object name) {
    return '正在缓冲 $name…';
  }

  @override
  String tv2NoOtherSource(Object reason) {
    return '$reason该频道没有其他源。';
  }

  @override
  String tv2AllSourcesFailed(Object count) {
    return '该频道的 $count 个源全部失败。';
  }

  @override
  String tv2SourcesFailedInRow(Object count) {
    return '已连续 $count 个源失败，请从列表中选择其他源。';
  }

  @override
  String tv2AspectMode(Object mode) {
    return '画面比例：$mode';
  }

  @override
  String tv2ChannelPosition(Object current, Object total, Object portal) {
    return '频道 $current/$total · $portal';
  }

  @override
  String tv2SourcePosition(Object current, Object total, Object portal) {
    return '源 $current/$total · $portal';
  }

  @override
  String get tv2TryAgain => '重试';

  @override
  String tv2RemovedPortals(Object count) {
    return '已删除 $count 个门户';
  }

  @override
  String tv2RemovedAllPortals(Object count) {
    return '已删除全部 $count 个门户';
  }

  @override
  String tv2RemovedPlaylists(Object count) {
    return '已删除 $count 个播放列表';
  }

  @override
  String tv2RemovedAllPlaylists(Object count) {
    return '已删除全部 $count 个播放列表';
  }

  @override
  String tv2XtreamPanelsCount(Object count) {
    return 'Xtream 面板（$count）';
  }

  @override
  String tv2M3uPlaylistsCount(Object count) {
    return 'M3U 播放列表（$count）';
  }

  @override
  String tv2DeleteSelectedPortals(Object count) {
    return '删除（$count）';
  }

  @override
  String tv2AllPortalsCount(Object count) {
    return '全部（$count）';
  }

  @override
  String tv2MyPortalsCount(Object count) {
    return '我的门户（$count）';
  }

  @override
  String tv2FavoritesStarCount(Object count) {
    return '收藏 ⭐（$count）';
  }

  @override
  String tv2NoVerifiedPortalsHint(Object source) {
    return '暂无已验证的门户。点击“生成门户”（$source）自动发现。';
  }

  @override
  String tv2NoPortalsInFilter(Object filter) {
    return '“$filter”筛选下没有门户。';
  }

  @override
  String tv2CopiedText(Object text) {
    return '已复制：$text';
  }

  @override
  String tv2ExpShort(Object expiry) {
    return '到期：$expiry';
  }

  @override
  String tv2ConnShort(Object active, Object max) {
    return '连接：$active/$max';
  }

  @override
  String tv2DeleteSelectedPlaylists(Object count) {
    return '删除（$count）';
  }

  @override
  String tv2PlaylistChannelsSource(Object count, Object source) {
    return '$count 个频道 $source';
  }

  @override
  String get tv2XtreamPanels => 'Xtream 面板';

  @override
  String get tv2M3uPlaylists => 'M3U 播放列表';

  @override
  String get tv2VerifyAndSave => '验证并保存';

  @override
  String get tv2FetchAndSave => '获取并保存';

  @override
  String tv2GridColumns(Object cols) {
    return '$cols 列';
  }

  @override
  String tv2FailedLoadContent(Object error) {
    return '内容加载失败：$error';
  }

  @override
  String tv2NoPlayableStreamNamed(Object name) {
    return '“$name”没有可播放的流。请重新连接该门户，或删除后添加其他门户。';
  }

  @override
  String tv2CategoriesTotal(Object count) {
    return '共 $count 个';
  }

  @override
  String tv2ExpiryLabel(Object expiry) {
    return '到期时间：$expiry';
  }

  @override
  String tv2ConnectionsLabel(Object active, Object max) {
    return '连接数：$active/$max';
  }

  @override
  String tv2StopHealthCheck(Object checked, Object total) {
    return '停止（$checked/$total）';
  }

  @override
  String tv2ConnAndExpiry(Object active, Object max, Object expiry) {
    return '连接：$active/$max • $expiry';
  }

  @override
  String tv2NoStreamsMatching(Object query) {
    return '没有与“$query”匹配的流';
  }

  @override
  String tv2SeriesEpisodes(Object series) {
    return '$series 剧集';
  }

  @override
  String tv2EpisodeNumber(Object episode) {
    return '第 $episode 集';
  }

  @override
  String get tv2AllCategories => '全部分类';

  @override
  String tv2NowAiringOn(Object channel) {
    return '$channel 正在播出';
  }

  @override
  String tv2GuideProgress(
    Object start,
    Object stop,
    Object minutes,
    Object percent,
  ) {
    return '$start – $stop · 已播 $minutes 分钟（$percent%）';
  }

  @override
  String ani2ResumeEpModal(Object episode) {
    return '继续观看第 $episode 集';
  }

  @override
  String ani2TotalEpsModal(Object count) {
    return '（共 $count 集）';
  }

  @override
  String get ani2SubCapsModal => '字幕版';

  @override
  String get ani2DubCapsModal => '配音版';

  @override
  String ani2ResumeEp(Object episode) {
    return '继续观看第 $episode 集';
  }

  @override
  String ani2TotalEps(Object count) {
    return '（共 $count 集）';
  }

  @override
  String get ani2SubCaps => '字幕版';

  @override
  String get ani2DubCaps => '配音版';

  @override
  String ani2CurrentlyAiringHits(Object season) {
    return '本季热播 · $season';
  }

  @override
  String ani2EpisodesCount(Object count) {
    return '$count 集';
  }

  @override
  String ani2SortLabel(Object sort) {
    return '排序：$sort';
  }

  @override
  String ani2TvSeriesResults(Object count) {
    return '$count 个结果';
  }

  @override
  String ani2MoviesResults(Object count) {
    return '$count 个结果';
  }

  @override
  String ani2OvasResults(Object count) {
    return '$count 个结果';
  }

  @override
  String ani2NoPlayableStreamsEp(Object episode) {
    return '第 $episode 集暂无可播放的视频源。';
  }

  @override
  String ani2TitleEpisode(Object title, Object episode) {
    return '$title - 第 $episode 集';
  }

  @override
  String ani2NoCategorySources(Object category) {
    return '未找到$category源。';
  }

  @override
  String get ani2Sub => '字幕';

  @override
  String get ani2Dub => '配音';

  @override
  String ai2FailedGenerateRecs(Object error) {
    return '推荐生成失败：$error';
  }

  @override
  String ai2RatedOfThree(Object rated) {
    return '已评分 $rated/3';
  }

  @override
  String ai2DiscoverRecsCount(Object count) {
    return '发现推荐（$count 部）';
  }

  @override
  String ai2TitleNumber(Object number) {
    return '片名 #$number';
  }

  @override
  String ai2CinemaPicksCount(Object count) {
    return '根据你的口味精选 $count 部影片';
  }

  @override
  String ai2MatchPercent(Object percent) {
    return '匹配度 $percent%';
  }

  @override
  String ply2VideoTrack(Object id) {
    return '视频 $id';
  }

  @override
  String ply2SubtitleTrack(Object index) {
    return '字幕 $index';
  }

  @override
  String ply2ErrorPrefix(Object error) {
    return '错误：$error';
  }

  @override
  String ply2DebridTryingAnother(Object service, Object notice) {
    return '$service $notice • 正在尝试其他源';
  }

  @override
  String ply2TrackNumber(Object number) {
    return '音轨 $number';
  }

  @override
  String ply2SwitchedEmbeddedSub(Object title) {
    return '已切换到内嵌字幕：$title';
  }

  @override
  String ply2DownloadingSubtitle(Object language) {
    return '正在下载$language字幕…';
  }

  @override
  String ply2SubtitleLoaded(Object language, Object lines) {
    return '$language字幕已加载（$lines 行）';
  }

  @override
  String ply2CouldNotLoadSubtitle(Object error) {
    return '字幕加载失败：$error';
  }

  @override
  String ply2PlaybackErrorMsg(Object error) {
    return '播放出错：$error';
  }

  @override
  String ply2SelectAnotherSourceBelow(Object message) {
    return '$message请在下方选择其他源。';
  }

  @override
  String ply2BufferingEpisode(Object season, Object episode, Object title) {
    return '正在缓冲 第 $season 季 第 $episode 集 - $title…';
  }

  @override
  String ply2DownloadFailedStart(Object error) {
    return '下载启动失败：$error';
  }

  @override
  String ply2PartWithTitle(Object part, Object title) {
    return '第 $part 部$title';
  }

  @override
  String ply2TrackIdx(Object index) {
    return '音轨 $index';
  }

  @override
  String ply2AudioSyncOffset(Object sign, Object seconds) {
    return '音频同步：$sign$seconds 秒';
  }

  @override
  String ply2PartCaps(Object part) {
    return '第 $part 部';
  }

  @override
  String mnz2StreamUrlFor(Object name) {
    return '$name 的直播流地址';
  }

  @override
  String mnz2ActiveStreams(Object count) {
    return '$count 路画面';
  }

  @override
  String get mnz2CustomUrl => '自定义地址';

  @override
  String dsc2NoCatalogsForType(Object type) {
    return '“$type”暂无可用片单';
  }

  @override
  String dsc2CatalogRequiresSelecting(Object fields) {
    return '此片单需先选择$fields才能加载内容。';
  }

  @override
  String dsc2SelectExtra(Object first, Object rest) {
    return '选择$first$rest';
  }

  @override
  String dsc2EnterExtra(Object name) {
    return '输入$name';
  }

  @override
  String dsc2EnterExtraName(Object name) {
    return '输入$name';
  }

  @override
  String dsc2TypeExtraHere(Object name) {
    return '在此输入$name…';
  }

  @override
  String dsc2AllExtra(Object name) {
    return '全部$name';
  }

  @override
  String dsc2SearchWithinCatalog(Object catalog) {
    return '在$catalog中搜索…';
  }

  @override
  String dsc2GenreQuery(Object query) {
    return '类型：$query';
  }

  @override
  String dsc2SearchQuery(Object query) {
    return '搜索：$query';
  }

  @override
  String dsc2NoResultsFor(Object query) {
    return '未找到与“$query”相关的结果';
  }

  @override
  String get dsc2Apply => '应用';

  @override
  String dl3EpisodeNumber(Object episode) {
    return '第 $episode 集';
  }

  @override
  String dl3ConfirmDeleteTask(Object title) {
    return '确定要删除“$title”并从存储中移除该文件吗？';
  }

  @override
  String dl3ActiveAndDownloaded(Object active, Object completed) {
    return '$active 个进行中 • $completed 个已下载';
  }

  @override
  String dl3FolderPath(Object path) {
    return '文件夹路径：$path';
  }

  @override
  String dl3PeersCount(Object count) {
    return '$count 个节点';
  }

  @override
  String dl3FailedReason(Object error) {
    return '失败：$error';
  }

  @override
  String dl3PausedPercent(Object percent) {
    return '已暂停（$percent%）';
  }

  @override
  String dl3ProgressSpeedEta(Object percent, Object speed, Object eta) {
    return '$percent% • $speed • 剩余时间：$eta';
  }

  @override
  String dl3FolderLabel(Object path) {
    return '文件夹：$path';
  }

  @override
  String dl3PathLabel(Object path) {
    return '路径：$path';
  }

  @override
  String dl3EpisodeOffline(Object season, Object episode) {
    return '第 $season 季 第 $episode 集 • 离线';
  }

  @override
  String dl3YearOffline(Object year) {
    return '$year • 离线';
  }

  @override
  String dl3DeviceStorageUsed(Object used, Object total) {
    return '设备存储：已用 $used，共 $total';
  }

  @override
  String dl3FreeSpace(Object free) {
    return '可用 $free';
  }

  @override
  String cal2NoEpisodesOnNetwork(Object network) {
    return '$network 当天没有剧集播出';
  }

  @override
  String cal2EpisodesAiring(Object count) {
    return '$count 集播出';
  }

  @override
  String get cal2ShowAllNetworks => '显示全部电视网';

  @override
  String ctl2SelectExtra(Object name) {
    return '选择$name';
  }

  @override
  String ctl2AllExtra(Object name) {
    return '全部$name';
  }

  @override
  String ara2FailedLoadDetails(Object error) {
    return '动漫详情加载失败：$error';
  }

  @override
  String get ara2Retry => '重试';

  @override
  String ara2NoArabicStreamsEp(Object episode) {
    return '第 $episode 集暂无可播放的阿拉伯语视频源。';
  }

  @override
  String ara2FailedLoadArabicStreams(Object error) {
    return '阿拉伯语视频源加载失败：$error';
  }

  @override
  String ara2TitleEpisode(Object title, Object episode) {
    return '$title - 第 $episode 集';
  }

  @override
  String mus2AddedTrackToPlaylist(Object track, Object playlist) {
    return '已将「$track」添加到「$playlist」';
  }

  @override
  String mus2CreatedPlaylist(Object name) {
    return '已创建歌单「$name」';
  }

  @override
  String mus2RemovedFromDownloads(Object title) {
    return '已从下载中移除「$title」';
  }

  @override
  String mus2AddedToDownloadQueue(Object title) {
    return '已将「$title」加入下载队列';
  }

  @override
  String mus2RemovedFromPlaylist(Object playlist) {
    return '已从「$playlist」移除';
  }

  @override
  String mus2AddedToPlaylist(Object playlist) {
    return '已添加到「$playlist」';
  }

  @override
  String mus2TracksTabCount(Object count) {
    return '单曲（$count）';
  }

  @override
  String mus2ArtistsTabCount(Object count) {
    return '歌手（$count）';
  }

  @override
  String mus2AlbumsTabCount(Object count) {
    return '专辑（$count）';
  }

  @override
  String mus2PlaylistsTabCount(Object count) {
    return '歌单（$count）';
  }

  @override
  String mus2NoResultsFor(Object query) {
    return '没有找到「$query」的相关结果';
  }

  @override
  String mus2FavouriteTracksCount(Object count) {
    return '$count 首喜欢的歌曲';
  }

  @override
  String mus2QueueCount(Object count) {
    return '播放队列（$count）';
  }

  @override
  String mus2OfflineTracksSize(Object count, Object size) {
    return '$count 首离线歌曲 • $size MB';
  }

  @override
  String mus2TrackNumber(Object number) {
    return '第 $number 首';
  }

  @override
  String mus2DownloadingPercent(Object percent) {
    return '正在下载 $percent%';
  }

  @override
  String mus2TracksCount(Object count) {
    return '$count 首歌曲';
  }

  @override
  String mus2AddedAlbumTracksToQueue(Object count, Object album) {
    return '已将「$album」中的 $count 首歌曲加入下载队列';
  }

  @override
  String mus2CuratedByTracks(Object creator, Object count) {
    return '由 $creator 精选 • $count 首歌曲';
  }

  @override
  String mus2AddedPlaylistTracksToQueue(Object count, Object playlist) {
    return '已将「$playlist」中的 $count 首歌曲加入下载队列';
  }

  @override
  String mus2CustomPlaylistTracks(Object count) {
    return '自建歌单 • $count 首歌曲';
  }

  @override
  String mus2OfflineTracksStorage(Object count, Object size) {
    return '$count 首离线歌曲 • 占用 $size MB';
  }

  @override
  String mus2NoDownloadedTracksMatch(Object query) {
    return '没有与「$query」匹配的已下载歌曲';
  }

  @override
  String mus2DeleteFromOfflineStorage(Object title) {
    return '要从离线存储中删除「$title」吗？';
  }

  @override
  String mus2ExtractingStreamFor(Object title) {
    return '正在解析「$title」的音频流…';
  }

  @override
  String mus2DownloadingTrackPercent(Object title, Object percent) {
    return '正在下载「$title」（$percent%）';
  }

  @override
  String mus2InQueueCount(Object count) {
    return '队列中 $count 首';
  }

  @override
  String get mus2RadioStationsLiveStreams => '电台与直播流';

  @override
  String get mus2ContinuousMusicChannels => '随心情不间断播放的音乐频道。';

  @override
  String abk2FailedToLoadChapters(Object error) {
    return '章节加载失败：$error';
  }

  @override
  String abk2PreparingChapter(Object title) {
    return '正在准备 $title…';
  }

  @override
  String abk2ResolvingAudioVia(Object service) {
    return '正在通过 $service 云端解析音频…';
  }

  @override
  String abk2PlaybackErrorErr(Object error) {
    return '播放出错：$error';
  }

  @override
  String abk2PlaybackError(Object error) {
    return '播放出错：$error';
  }

  @override
  String abk2ChapterNumber(Object number) {
    return '第 $number 章';
  }

  @override
  String abk2ChapterOfTotalBook(Object current, Object total, Object book) {
    return '第 $current 章 / 共 $total 章 • $book';
  }

  @override
  String abk2ChaptersCountUpper(Object count) {
    return '共 $count 章';
  }

  @override
  String get abk2AudioPlayerStyleStudio => '播放器样式与工作室';

  @override
  String get abk2SelectPlayerDesignPreset => '选择播放器设计预设';

  @override
  String get abk2SeekBarScrubberStyle => '进度条滑块样式';

  @override
  String get abk2PlayPauseButtonStyle => '播放/暂停按钮样式';

  @override
  String get abk2Autoplay => '自动播放';

  @override
  String get abk2OpenChaptersPanel => '打开章节面板';

  @override
  String get abk2AudiobookChapters => '有声书章节';

  @override
  String abk2FailedToFetchAudiobooks(Object error) {
    return '有声书获取失败：$error';
  }

  @override
  String abk2ChapterOfTotal(Object current, Object total) {
    return '第 $current 章 / 共 $total 章';
  }

  @override
  String abk2ResumeTimeLeft(Object remaining) {
    return '继续收听（剩余 $remaining）';
  }

  @override
  String abk2VoiceLabel(Object voice) {
    return '音色：$voice';
  }

  @override
  String abk2GeneratingPercent(Object percent) {
    return '正在生成 $percent%';
  }

  @override
  String abk2AuthorLocal(Object author) {
    return '$author • 本地';
  }

  @override
  String abk2ResumeChapterNumber(Object number) {
    return '第 $number 章';
  }

  @override
  String abk2PercentCompleted(Object percent) {
    return '已完成 $percent%';
  }

  @override
  String abk2UploadedPartsGenerationStarted(Object count) {
    return '已上传 $count 个分段，正在后台生成！';
  }

  @override
  String abk2GenerationFailed(Object error) {
    return '生成失败：$error';
  }

  @override
  String abk2RemoveFromGenerationList(Object name) {
    return '要从生成列表中移除「$name」吗？';
  }

  @override
  String abk2SelectedAudioFiles(Object count) {
    return '已选择 $count 个音频文件：';
  }

  @override
  String abk2GenerationQueueCompleted(Object count) {
    return '生成队列与已完成（$count）';
  }

  @override
  String abk2DownloadedBooksFromLibrary(Object count) {
    return '书库中已下载的图书（$count）';
  }

  @override
  String abk2FileSizeMb(Object size) {
    return '大小：$size MB';
  }

  @override
  String abk2SynthesizingPercent(Object percent) {
    return '正在合成 $percent%';
  }

  @override
  String abk2JobVoiceLabel(Object voice) {
    return '音色：$voice';
  }

  @override
  String abk2ImportedAudiobooksCount(Object count) {
    return '已导入的有声书（$count）';
  }

  @override
  String abk2AuthorPartsSize(Object author, Object parts, Object size) {
    return '$author • $parts 个分段（$size MB）';
  }

  @override
  String abk2DeleteFromLibrary(Object title) {
    return '要从书库中删除「$title」吗？';
  }

  @override
  String get abk2StreamUrlCopied => '音频流链接已复制到剪贴板！';

  @override
  String get abk2RemoveGenerationJob => '移除生成任务？';

  @override
  String get abk2AiEpubGeneratorTts => 'AI EPUB 生成器（TTS）';

  @override
  String get abk2MyUploadedAudiobooks => '我上传的有声书';

  @override
  String get abk2DeleteAudiobook => '删除有声书？';

  @override
  String bk2FailedToDownloadBook(Object error) {
    return '图书下载失败：$error';
  }

  @override
  String bk2PageOfTotal(Object current, Object total) {
    return '第 $current 页 / 共 $total 页';
  }

  @override
  String bk2ChapterOfTotal(Object current, Object total) {
    return '第 $current 章 / 共 $total 章';
  }

  @override
  String bk2PercentCompleted(Object percent) {
    return '已完成 $percent%';
  }

  @override
  String bk2DownloadingPercent(Object percent) {
    return '正在下载 $percent%…';
  }

  @override
  String get bk2Information => '信息';

  @override
  String get bk2Overview => '简介';

  @override
  String bk2FailedToLoadBooks(Object error) {
    return '图书加载失败：$error';
  }

  @override
  String bk2ResultsFor(Object query) {
    return '「$query」的搜索结果';
  }

  @override
  String bk2FontSizeMargins(Object size, Object margins) {
    return '字号：$size pt · 页边距：$margins';
  }

  @override
  String bk2AuthorPercentRead(Object author, Object percent) {
    return '$author · 已读 $percent%';
  }

  @override
  String get bk2AllFormats => '全部格式';

  @override
  String bk2FailedToOpenBook(Object title, Object error) {
    return '无法打开「$title」：$error';
  }

  @override
  String bk2PercentMinsLeft(Object percent, Object mins) {
    return '$percent% · 约剩 $mins 分钟';
  }

  @override
  String get bk2BackToLibrary => '返回书库';

  @override
  String get bk2Retry => '重试';

  @override
  String bk2PdfPageOfTotal(Object current, Object total) {
    return '第 $current 页 / 共 $total 页';
  }

  @override
  String bk2PageNumber(Object page) {
    return '第 $page 页';
  }

  @override
  String bk2SliderAuthorPercentRead(Object author, Object percent) {
    return '$author · 已读 $percent%';
  }

  @override
  String bk2SliderPositionPercentRead(Object position, Object percent) {
    return '$position · 已读 $percent%';
  }

  @override
  String mg2NoChaptersMatching(Object query) {
    return '没有与「$query」匹配的章节';
  }

  @override
  String mg2ChapterNumber(Object number) {
    return '第 $number 话';
  }

  @override
  String mg2PageOfTotal(Object current, Object total) {
    return '第 $current 页 / 共 $total 页';
  }

  @override
  String mg2ResumeChapter(Object number) {
    return '继续阅读第 $number 话';
  }

  @override
  String get mg2Synopsis => '简介';

  @override
  String mg2GenreManga(Object genre) {
    return '$genre漫画';
  }

  @override
  String mg2PercentRead(Object percent) {
    return '已读 $percent%';
  }

  @override
  String mg2AuthorPercentRead(Object author, Object percent) {
    return '$author · 已读 $percent%';
  }

  @override
  String mg2CurrentChapterNumber(Object number) {
    return '第 $number 话';
  }

  @override
  String mg2NextChapterNumber(Object number) {
    return '第 $number 话';
  }

  @override
  String mg2ReaderPageOfTotal(Object current, Object total) {
    return '第 $current 页 / 共 $total 页';
  }

  @override
  String mg2ReaderPageSlashTotal(Object current, Object total) {
    return '第 $current / $total 页';
  }

  @override
  String mg2PageModeLabel(Object mode) {
    return '翻页模式：$mode';
  }

  @override
  String mg2AtmosphereLabel(Object atmosphere) {
    return '氛围：$atmosphere';
  }

  @override
  String get bk2Typography => '字体排版';

  @override
  String get bk2Theme => '主题';

  @override
  String get bk2Layout => '版式';

  @override
  String stgcAddonConnectedTo(Object name, Object service) {
    return '$name 已连接到 $service';
  }

  @override
  String stgcAddonInstalled(Object name) {
    return '$name 安装成功！';
  }

  @override
  String stgcRemoveAddonQ(Object name) {
    return '移除 $name？';
  }

  @override
  String get stgcRepoAdded => '插件源添加成功！';

  @override
  String get stgcInstallRepoPluginsQ => '安装插件源中的插件？';

  @override
  String stgcInstalledFromRepo(Object count) {
    return '已从插件源成功安装 $count 个插件！';
  }

  @override
  String stgcInstallError(Object error) {
    return '安装出错：$error';
  }

  @override
  String stgcRemoveExtQ(Object name) {
    return '移除 $name？';
  }

  @override
  String stgcRemoveCountPluginsQ(Object count) {
    return '移除 $count 个插件？';
  }

  @override
  String stgcConfirmRemoveAllCs(Object count) {
    return '确定要移除全部 $count 个已安装的 CloudStream 插件吗？所有已下载的插件文件（.jar/.cs3）都会被删除。';
  }

  @override
  String stgcConfirmRemoveSelectedCs(Object count) {
    return '确定要移除所选的 $count 个 CloudStream 插件吗？它们已下载的文件将从设备中删除。';
  }

  @override
  String stgcRemovedCountPlugins(Object count) {
    return '已成功移除 $count 个插件。';
  }

  @override
  String stgcRemoveCount(Object count) {
    return '移除（$count）';
  }

  @override
  String stgcRemoveRepoQ(Object name) {
    return '移除 $name？';
  }

  @override
  String get stgcAddonsExtensions => '插件与扩展';

  @override
  String stgcAddonsTotal(Object count) {
    return '共 $count 个';
  }

  @override
  String stgcRemoveSelectedCount(Object count) {
    return '移除（$count）';
  }

  @override
  String stgcInstalledTotal(Object count) {
    return '共 $count 个';
  }

  @override
  String stgcReposCount(Object count) {
    return '$count 个插件源';
  }

  @override
  String stgcRuntimeSetupError(Object error) {
    return '运行环境设置出错：$error';
  }

  @override
  String stgcAddonSubtitlesProvider(Object version) {
    return 'v$version  ·  字幕提供方';
  }

  @override
  String stgcAddonCatalogs(Object version, Object count, Object subtitles) {
    return 'v$version  ·  $count 个目录$subtitles';
  }

  @override
  String get stgcAddonSubtitlesSuffix => '  ·  字幕';

  @override
  String stgcLabelCount(Object label, Object count) {
    return '$label（$count）';
  }

  @override
  String stgcUsesYourServiceKey(Object service) {
    return '使用你的 $service 密钥';
  }

  @override
  String stgcPluginInstalled(Object name) {
    return '$name 安装成功！';
  }

  @override
  String stgcPluginUninstalled(Object name) {
    return '$name 已卸载。';
  }

  @override
  String stgcInstalledCountPlugins(Object count) {
    return '已成功安装 $count 个插件！';
  }

  @override
  String stgcRemoveListPluginsQ(Object count) {
    return '移除 $count 个插件？';
  }

  @override
  String stgcConfirmUninstallList(Object count) {
    return '确定要卸载此列表中全部 $count 个已安装插件吗？它们已下载的文件将被删除。';
  }

  @override
  String stgcRemoveAllListCount(Object count) {
    return '全部移除（$count）';
  }

  @override
  String stgcUninstalledCount(Object count) {
    return '已成功卸载 $count 个插件。';
  }

  @override
  String stgcRemoveAllCount(Object count) {
    return '全部移除（$count）';
  }

  @override
  String stgcInstallAllCount(Object count) {
    return '全部安装（$count）';
  }

  @override
  String stgcNoPluginsMatching(Object query) {
    return '没有匹配“$query”的插件';
  }

  @override
  String get stgcAllMatchingInstalled => '所有匹配的插件均已安装！';

  @override
  String stgcRepoNameAdded(Object name) {
    return '$name 添加成功！';
  }

  @override
  String stgcInstallRepoNamePluginsQ(Object name) {
    return '安装 $name 的插件？';
  }

  @override
  String stgcRepoIncludesPlugins(Object count, Object sample) {
    return '该插件源包含 $count 个插件（$sample…）。现在全部安装，让它们的片源立即可用？';
  }

  @override
  String stgcPluginsInstalledReady(Object count) {
    return '$count 个插件已安装，可以使用了！';
  }

  @override
  String stgcMarketplaceSubtitle(Object count) {
    return '$count 个插件源 · 直接安装链接与已验证的提供方';
  }

  @override
  String stgcNoReposFound(Object query) {
    return '未找到与“$query”相关的插件源';
  }

  @override
  String stgcRepoPluginsCount(Object count) {
    return '$count 个插件';
  }

  @override
  String stgcCopiedLink(Object url) {
    return '已复制链接：$url';
  }

  @override
  String stgcContainsPlugins(Object plugins) {
    return '包含：$plugins';
  }

  @override
  String stgcViewAllPlugins(Object count) {
    return '查看全部 $count 个插件';
  }

  @override
  String stgcDebridKeyVerified(Object provider, Object user) {
    return '$provider 密钥已验证（$user），并已设为当前服务！';
  }

  @override
  String stgcDebridKeySaved(Object provider) {
    return '$provider 密钥已保存，并已设为当前服务！';
  }

  @override
  String stgcDebridKeyCleared(Object provider) {
    return '$provider 密钥已清除。';
  }

  @override
  String get stgcDebridCloudStreaming => 'Debrid 与云端播放';

  @override
  String stgcServiceNoKey(Object service) {
    return '$service 尚未保存 API 密钥，请在下方输入并保存。';
  }

  @override
  String stgcDebridActivatedVia(Object service) {
    return '已通过 $service 启用 Debrid 播放';
  }

  @override
  String stgcSelectedNoKey(Object service) {
    return '已选择 $service，但尚未保存 API 密钥，请在下方输入并保存。';
  }

  @override
  String stgcActiveDebridSet(Object service) {
    return '当前 Debrid 服务已设为 $service';
  }

  @override
  String stgcRdLoggedInAs(Object user) {
    return '已登录：$user';
  }

  @override
  String stgcTorboxAccount(Object account) {
    return '账户：$account';
  }

  @override
  String stgcAllDebridAccount(Object account) {
    return '账户：$account';
  }

  @override
  String stgcDebridLinkAccount(Object account) {
    return '账户：$account';
  }

  @override
  String get stgcPurposeTrakt =>
      '标识配对流程向其请求设备码的 Trakt 应用，并附加在每次 Trakt API 调用中。';

  @override
  String get stgcServiceKeysIntro =>
      'Lumora 会连接多个第三方服务。你在这里保存的密钥会替换此版本内置的密钥，并立即生效，无需重启。';

  @override
  String get stgcServiceKeysUnobtainable =>
      '以下密钥无法申请：每一项都是第三方服务的凭据，并非发给 Lumora，除非你有自己的密钥，否则请留空。私有构建可通过 --dart-define 提供自己的密钥；在源码中清空某个注册项只会停用对应的那一个来源。';

  @override
  String get stgcServiceKeysStoredLocally => '所有值仅保存在本设备上，且不会在这些输入框中回显。';

  @override
  String stgcPasteKeyFirst(Object label) {
    return '请先粘贴 $label 的密钥。';
  }

  @override
  String stgcKeySavedInUse(Object label) {
    return '$label 密钥已保存并已启用。';
  }

  @override
  String stgcLabelKeyCleared(Object label) {
    return '$label 密钥已清除。';
  }

  @override
  String stgcPasteYourKey(Object label) {
    return '粘贴你的 $label 密钥';
  }

  @override
  String get stgcServiceApiKeys => '服务 API 密钥';

  @override
  String get stgcVideoUpscaling => '视频与超分辨率';

  @override
  String get stgcUpscalingIntro =>
      '在视频引擎上进行实时 GLSL 超分。Anime4K 重建动画线条，AMD FSR 适合真人影视。只能选择其中一类，两者不会叠加。';

  @override
  String get stgcFsrDesc =>
      'AMD FidelityFX 边缘自适应超分，适合真人影视。只放大不锐化，是最稳妥的 FSR 选项。与 NVIDIA RTX Video 不同，可在任何 GPU 上运行。';

  @override
  String get stgcFsrCasDesc =>
      '带对比度自适应锐化的 FSR，可让偏软或低码率的视频更清晰。用于 2K 或 4K 片源时，效果可能还不如不超分。';

  @override
  String get stgcAppearanceInterface => '外观与界面';

  @override
  String get stgcSkiaRecommended =>
      '在 Windows 上建议使用 Skia —— 曾出现 Impeller 与 NVIDIA 驱动崩溃同时发生的情况。';

  @override
  String get stgcSimklPinFailed => '请求 Simkl PIN 码失败。';

  @override
  String get stgcSimklSync => 'Simkl 同步';

  @override
  String stgcSimklLoggedInAs(Object user) {
    return '已登录：$user';
  }

  @override
  String get stgcPinCopied => 'PIN 已复制到剪贴板！';

  @override
  String get stgcSyncingSimkl => '正在与 Simkl 同步…';

  @override
  String get stgcSimklSyncDone => 'Simkl 同步完成！';

  @override
  String get stgcTraktSync => 'Trakt.tv 同步';

  @override
  String get stgcCodeCopied => '代码已复制到剪贴板！';

  @override
  String get stgcSyncingTrakt => '正在与 Trakt.tv 同步…';

  @override
  String get stgcTraktSyncDone => 'Trakt 同步完成！';

  @override
  String stgcTraktLoggedInAs(Object user) {
    return '已登录：$user';
  }

  @override
  String stgcTraktNeedsClientId(Object url) {
    return 'Trakt 需要 Client ID 才能配对。请先在 $url 免费创建一个应用，然后在“设置 > 服务 API 密钥”中粘贴其 Client ID。同一应用的 Client Secret 可选填。';
  }

  @override
  String get stgcTraktRejected =>
      'Trakt 拒绝了配对请求。请检查“设置 > 服务 API 密钥”中的 Client ID；如果你的应用需要 Client Secret，也请一并填写。';

  @override
  String get stgcTmdbApiKey => 'TMDb API 密钥';

  @override
  String get stgcTmdbIntro =>
      '添加你自己的免费 TMDb 密钥，可按 TMDb 投票数为六个“90 年代”栏目排序，并用于内置抓取器的 TMDb 查询。可在 themoviedb.org 获取密钥。';

  @override
  String get stgcTmdbStoredLocally =>
      '密钥仅保存在本设备上。本应用不内置密钥，没有密钥时内置的备用方案也能让抓取查询正常工作。清除密钥后将恢复内置的 90 年代精选。';

  @override
  String stgcAboutVersion(Object version) {
    return '版本 $version • 新一代影音中心';
  }

  @override
  String get stgcAboutLegalese =>
      'Lumora，Copyright (C) 2026 JTing904\nhttps://github.com/JTing904/Lumora\n基于 ZPlay，Copyright (C) 2026 tzero86\n基于 PlayTorrio V3，Copyright (C) 2026 Ayman\nhttps://github.com/tzero86/ZPlay\nhttps://github.com/ayman708-UX/PlayTorrioV3\n\n本程序是自由软件：你可以依据自由软件基金会发布的 GNU General Public License v3.0（或你选择的任何更高版本）的条款重新分发和/或修改它。\n\n发布本程序是希望它能有所帮助，但不提供任何担保；甚至不包含对适销性或特定用途适用性的默示担保。详情请参阅 GNU General Public License v3.0。';

  @override
  String stgcUpdateCheckError(Object error) {
    return '检查更新出错：$error';
  }

  @override
  String stgcInstalledVersion(Object version, Object build) {
    return '已安装版本：v$version（构建 $build）';
  }

  @override
  String get stgcAudiobookStudioApplied => '自定义播放器工作室布局已应用，并设为当前播放器！';

  @override
  String stgcPreviewSpeed(Object speed) {
    return '${speed}x 倍速';
  }

  @override
  String stgcPositionN(Object n) {
    return '位置 #$n';
  }

  @override
  String stgcHoverToFeel(Object effect) {
    return '将光标悬停或点按下方，实时体验“$effect”：';
  }

  @override
  String stgcTestEffect(Object effect) {
    return '测试“$effect”';
  }

  @override
  String get stgcAudiobookUiStudio => '有声书界面与播放器工作室';

  @override
  String stgcAuroraThemedTo(Object palette) {
    return '柔和流动的发光光球与极光波纹，配色跟随 $palette';
  }

  @override
  String get stgcCustomBgWallpaper => '自定义背景与壁纸';

  @override
  String stgcWallpaperActiveWith(Object palette) {
    return '壁纸已启用，搭配 $palette 环境光';
  }

  @override
  String stgcDefaultThemeBg(Object palette) {
    return '默认 $palette 主题背景';
  }

  @override
  String stgcAppliedWallpaper(Object title) {
    return '已应用“$title”壁纸';
  }

  @override
  String get stgcHomeUiThemes => '首页界面';

  @override
  String get stgcDropImagelessRails =>
      '当首页某个栏目中没有任何影片能显示图片时将其隐藏。横版卡片下方不显示名称，这样的栏目只会是一排空白方块。';

  @override
  String stgcIntervalSeconds(Object seconds) {
    return '间隔：$seconds 秒';
  }

  @override
  String get stgcLiquidGlassReset => '液态玻璃设置已恢复默认。';

  @override
  String get stgcLiveTvSportsUi => '直播电视与体育界面';

  @override
  String stgcNSeconds(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String stgcNColumns(Object cols) {
    return '$cols 列';
  }

  @override
  String get stgcXtreamPanels => 'Xtream 面板';

  @override
  String get stgcM3uPlaylists => 'M3U 播放列表';

  @override
  String get stgcMangaUiAtmosphere => '漫画界面与阅读氛围';

  @override
  String get stgcMusicStudioApplied => '自定义全屏播放器工作室布局已设为当前播放器！';

  @override
  String get stgcMusicUiAtmosphere => '音乐界面与播放器氛围';

  @override
  String get wgShellPressBackAgain => '再按一次返回键退出';

  @override
  String get wgAniSeriesBadge => '剧集';

  @override
  String wgAniEpisodeCountShort(Object count) {
    return '$count 集';
  }

  @override
  String get wgAniFeaturedAnime => '精选动漫';

  @override
  String wgAniEpisodeCount(Object count) {
    return '共 $count 集';
  }

  @override
  String get wgAniPlayEpisodeOne => '播放第 1 集';

  @override
  String wgComTabTitleCount(Object label, Object count) {
    return '$label，共 $count 部';
  }

  @override
  String get wgComTrailer => '预告片';

  @override
  String get wgComTrailerUnavailable => '预告片暂不可用';

  @override
  String get wgComTrailerCannotPlay => '该预告片无法在应用内播放。';

  @override
  String get wgComCloseTrailer => '关闭预告片';

  @override
  String get wgComUnmuteTrailer => '打开预告片声音';

  @override
  String get wgComMuteTrailer => '预告片静音';

  @override
  String get wgIptvLiveBadge => '直播';

  @override
  String get wgIptvHdLive => '高清直播';

  @override
  String get wgIptvHealthAlive => '可用';

  @override
  String get wgIptvHealthUnchecked => '未检测';

  @override
  String get wgIptvHealthDead => '失效';

  @override
  String get wgIptvLiveBroadcast => '直播中';

  @override
  String get wgIptvHeroTagline => '多源直播秒开，实时解析直播流，高帧率流畅播放。';

  @override
  String get wgIptvWatchLive => '立即观看';

  @override
  String get wgIptvStreamFeeds => '直播源';

  @override
  String wgIptvRemovedPortals(Object count, Object plural) {
    return '已移除 $count 个门户';
  }

  @override
  String wgIptvRemovedAllPortals(Object count) {
    return '已移除全部 $count 个门户';
  }

  @override
  String wgIptvRemovedPlaylists(Object count, Object plural) {
    return '已移除 $count 个播放列表';
  }

  @override
  String wgIptvRemovedAllPlaylists(Object count) {
    return '已移除全部 $count 个播放列表';
  }

  @override
  String get wgIptvSearchChannels => '搜索频道…';

  @override
  String get wgIptvFinding => '查找中…';

  @override
  String get wgIptvGenerate => '生成';

  @override
  String get wgIptvChoosePortalSource => '选择门户来源';

  @override
  String get wgIptvCloudVault => '云端库';

  @override
  String get wgIptvRedditCommunities => 'Reddit 社区';

  @override
  String get wgIptvRedditPastes => '来自 Reddit 子版块的实时分享';

  @override
  String get wgIptvAddPortal => '添加门户';

  @override
  String get wgIptvDone => '完成';

  @override
  String get wgIptvManage => '管理';

  @override
  String get wgIptvDeselectAll => '取消全选';

  @override
  String get wgIptvSelectAll => '全选';

  @override
  String wgIptvDeleteSelectedPortals(Object count) {
    return '删除（$count）';
  }

  @override
  String get wgIptvDeleteAll => '全部删除';

  @override
  String get wgIptvAddXtreamPortal => '添加 Xtream Codes 门户';

  @override
  String get wgIptvServerUrlLabel => '服务器地址（例如 http://example.com:8080）';

  @override
  String get wgIptvUsername => '用户名';

  @override
  String get wgIptvPassword => '密码';

  @override
  String get wgIptvVerifySave => '验证并保存';

  @override
  String wgIptvChipAll(Object count) {
    return '全部（$count）';
  }

  @override
  String wgIptvChipCloudVault(Object count) {
    return '云端库（$count）';
  }

  @override
  String wgIptvChipFavorites(Object count) {
    return '收藏 ⭐（$count）';
  }

  @override
  String get wgIptvNoXtreamPortals => '尚未加载 Xtream 门户';

  @override
  String get wgIptvNoMatchingChannels => '没有匹配的频道';

  @override
  String get wgIptvCopyLogin => '复制登录信息（url:user:pass）';

  @override
  String wgIptvCopiedText(Object text) {
    return '已复制：$text';
  }

  @override
  String get wgIptvRemoveFavorite => '取消收藏';

  @override
  String get wgIptvAddToFavorites => '加入收藏';

  @override
  String get wgIptvRemovePortal => '移除门户';

  @override
  String wgIptvExpiryShort(Object expiry) {
    return '到期：$expiry';
  }

  @override
  String wgIptvConnShort(Object active, Object max) {
    return '连接：$active/$max';
  }

  @override
  String wgIptvGroupExpiry(Object expiry) {
    return '到期：$expiry';
  }

  @override
  String wgIptvGroupConn(Object active, Object max) {
    return '连接：$active/$max';
  }

  @override
  String get wgIptvNoLiveChannelsPortal => '该门户暂无可用直播频道';

  @override
  String wgIptvLiveChannelCount(Object count) {
    return '$count 个直播频道';
  }

  @override
  String get wgIptvAddM3uUrl => '添加 M3U 地址';

  @override
  String wgIptvDeleteSelectedM3u(Object count) {
    return '删除（$count）';
  }

  @override
  String get wgIptvAddM3uSubscription => '添加 M3U 播放列表订阅';

  @override
  String get wgIptvPlaylistName => '播放列表名称';

  @override
  String get wgIptvM3uUrlLabel => 'M3U / M3U8 地址';

  @override
  String get wgIptvFetchSave => '获取并保存';

  @override
  String get wgIptvNoM3uPlaylists => '尚未加载 M3U 播放列表';

  @override
  String get wgIptvCopyPlaylistUrl => '复制播放列表地址';

  @override
  String get wgIptvRemovePlaylist => '移除播放列表';

  @override
  String wgIptvPlaylistChannelsSource(Object count, Object source) {
    return '$count 个频道$source';
  }

  @override
  String get wgIptvNoChannelsPlaylist => '该播放列表中没有频道';

  @override
  String wgIptvChannelCount(Object count) {
    return '$count 个频道';
  }

  @override
  String get wgMgaUnknownYear => '年份未知';

  @override
  String get wgMgaCategories => '漫画分类';

  @override
  String get wgMgaFilterCategories => '筛选分类…';

  @override
  String get wgMgaNoMatchingCategories => '没有匹配的分类';

  @override
  String get wgMgaResetAllCategories => '重置为全部分类';

  @override
  String get wgMovSeriesBadge => '剧集';

  @override
  String get wgMovAnimeBadge => '动漫';

  @override
  String get wgPlySurround51 => '5.1 环绕声';

  @override
  String get wgPlySurround71 => '7.1 环绕声';

  @override
  String wgPlyAudioChannels(Object count) {
    return '$count 声道';
  }

  @override
  String wgPlySeasonLabel(Object season) {
    return '第 $season 季';
  }

  @override
  String get wgPlySeasonOne => '第 1 季';

  @override
  String wgPlySeasonEpisodeSummary(Object season, Object count) {
    return '$season · 共 $count 集';
  }

  @override
  String wgPlySeasonTab(Object season) {
    return '第 $season 季';
  }

  @override
  String wgPlyEpisodeFallback(Object episode) {
    return '第 $episode 集';
  }

  @override
  String wgPlyEpisodeBadge(Object episode) {
    return '第 $episode 集';
  }

  @override
  String wgPlySeasonEpisodeBadge(Object season, Object episode) {
    return '第 $season 季 · 第 $episode 集';
  }

  @override
  String wgPlySleepMinutes(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String get wgPlySubtitleSizeCaps => '字幕大小';

  @override
  String get wgPlyDecreaseSize => '缩小';

  @override
  String get wgPlyIncreaseSize => '放大';

  @override
  String get wgPlyResetTo100 => '恢复为 100%';

  @override
  String get wgPlySubBarClose => '关闭';

  @override
  String get wgPlySubAppearance => '字幕外观';

  @override
  String get wgPlySubAppearanceSubtitle => 'libass / libmpv 硬件渲染字幕';

  @override
  String get wgPlyResetSubDefaults => '恢复默认字幕设置';

  @override
  String get wgPlySubModalClose => '关闭';

  @override
  String get wgPlySubTabTypography => '字体';

  @override
  String get wgPlySubTabColors => '颜色与背景';

  @override
  String get wgPlySubTabOutline => '描边与阴影';

  @override
  String get wgPlySubTabPosition => '位置';

  @override
  String get wgPlySubTabAdvanced => '高级 / ASS';

  @override
  String get wgPlySubFontFamily => '字体';

  @override
  String get wgPlySubDefaultFont => '默认（Lumora 字幕字体）';

  @override
  String wgPlySubBaseFontSize(Object size) {
    return '基础字号（${size}pt）';
  }

  @override
  String wgPlySubScaleMultiplier(Object percent) {
    return '缩放倍率（$percent%）';
  }

  @override
  String get wgPlySubBold => '粗体';

  @override
  String get wgPlySubItalic => '斜体';

  @override
  String get wgPlySubTextColor => '字幕文字颜色';

  @override
  String get wgPlySubBackgroundBox => '背景框（无障碍与易读性）';

  @override
  String get wgPlySubOutlineColor => '描边颜色';

  @override
  String wgPlySubOutlineThickness(Object size) {
    return '描边粗细（${size}px）';
  }

  @override
  String wgPlySubShadowOffset(Object size) {
    return '阴影偏移（${size}px）';
  }

  @override
  String get wgPlySubHorizontalAlign => '水平对齐';

  @override
  String get wgPlySubAlignLeft => '左对齐';

  @override
  String get wgPlySubAlignCenter => '居中';

  @override
  String get wgPlySubAlignRight => '右对齐';

  @override
  String wgPlySubBottomMargin(Object size) {
    return '底部边距（${size}px）';
  }

  @override
  String wgPlySubVerticalPosition(Object percent) {
    return '垂直位置（$percent%）';
  }

  @override
  String get wgPlyAssPreserveTitle => '保留动漫与 SSA/ASS 样式（推荐）';

  @override
  String get wgPlyAssPreserveDesc =>
      '不改动 SSA/ASS 动漫字幕，保留卡拉 OK 特效、样式与位置；普通 SRT/VTT 字幕使用你的自定义样式。';

  @override
  String get wgPlyAssScaleTitle => '仅缩放';

  @override
  String get wgPlyAssScaleDesc => '仅对 SSA/ASS 字幕缩放大小，保留其原有字体、颜色和排版。';

  @override
  String get wgPlyAssOverrideTitle => '覆盖颜色与描边';

  @override
  String get wgPlyAssOverrideDesc => '在 SSA/ASS 字幕上应用你的自定义颜色和描边。';

  @override
  String get wgPlyAssForceTitle => '强制完全覆盖（激进）';

  @override
  String get wgPlyAssForceDesc => '对所有字幕格式强制应用自定义字体、颜色和样式（可能破坏动漫字幕特效）。';

  @override
  String get wgPlySubRenderingEngine => '字幕渲染引擎';

  @override
  String get wgPlyFlutterSubEngine => 'Flutter 字幕引擎（推荐）';

  @override
  String get wgPlyFlutterSubEngineDesc =>
      '在 Android、iOS、Windows、Mac 和 Linux 上稳定可靠的硬件加速字幕叠加，支持全部样式设置。';

  @override
  String get wgPlyMpvLibassEngine => '原生 mpv libass 引擎';

  @override
  String get wgPlyMpvLibassEngineDesc =>
      '由 libass 驱动的 GPU 直接渲染，内置 Poppins 字体，支持 SSA/ASS 字幕排版。';

  @override
  String get wgPlyAssOverrideMode => 'SSA / ASS 字幕组脚本覆盖模式';

  @override
  String get wgPlyCopyStreamUrl => '复制播放地址';

  @override
  String wgPlySyncSaveError(Object error) {
    return '保存字幕同步失败：$error';
  }

  @override
  String get wgPlySyncHintSection => '先点选片段的第一行和最后一行，再点当前正在播放的那一行，然后点“从这里对齐”。';

  @override
  String get wgPlySyncHintFirst => '点选你此刻听到的台词，然后点“从这里对齐”。';

  @override
  String get wgPlySyncHintSecond => '已设置第 1 个对齐点。如果之后字幕又出现偏移，请在后面的台词上点“从这里对齐”。';

  @override
  String get wgPlySyncMinChars => '至少 3 个字';

  @override
  String wgSrchMagnetNoFiles(Object service) {
    return '$service 未返回此磁力链接的任何文件。';
  }

  @override
  String get wgSrchMagnetMetadataFailed => '无法从 P2P 网络获取种子元数据，请检查节点连接。';

  @override
  String wgSrchUsingProvider(Object provider) {
    return '正在通过 $provider 获取文件…';
  }

  @override
  String get wgSrchConnectingPeers => '正在连接 P2P 节点…';

  @override
  String get wgSrchGatheringFiles => '正在获取文件列表和播放信息';

  @override
  String get wgSrchMagnetReadFailed => '磁力链接读取失败';

  @override
  String get wgSrchTryAgain => '重试';

  @override
  String get wgSrchNoFilesMatch => '没有符合筛选条件的文件';

  @override
  String wgSrchProviderCloud(Object provider) {
    return '$provider 云端';
  }

  @override
  String get wgSrchP2pSwarm => 'P2P 网络';

  @override
  String wgSrchFileCount(Object count, Object unit) {
    return '$count 个文件';
  }

  @override
  String wgSrchVideoCount(Object count, Object unit) {
    return '$count 个视频';
  }

  @override
  String get wgSrchFilterFilesHint => '按名称筛选文件…';

  @override
  String wgSrchChipAll(Object count) {
    return '全部（$count）';
  }

  @override
  String wgSrchChipVideos(Object count) {
    return '视频（$count）';
  }

  @override
  String wgSrchChipOther(Object count) {
    return '其他（$count）';
  }

  @override
  String get wgSrchPlay => '播放';

  @override
  String get wgSrchNonVideo => '非视频';

  @override
  String get wgSrchKeySpace => '空格';

  @override
  String get wgSrchKeyClear => '清空';

  @override
  String get wgSrchKeySearch => '搜索';

  @override
  String get wgUpdAvailableCaps => '发现新版本';

  @override
  String wgUpdVersion(Object version) {
    return '版本 $version';
  }

  @override
  String get wgUpdCurrent => '当前版本';

  @override
  String get wgUpdLatest => '最新版本';

  @override
  String get wgUpdWhatsNew => '更新内容';

  @override
  String get wgUpdNoReleaseNotes => '此版本暂无更新说明。';

  @override
  String get wgUpdIosRedirect => 'iOS：将跳转到 GitHub 下载 IPA';

  @override
  String get wgUpdMacRedirect => 'macOS：将跳转到 GitHub 下载';

  @override
  String get wgUpdDownloading => '下载中…';

  @override
  String get wgUpdLater => '稍后';

  @override
  String get wgUpdUpdateNow => '立即更新';

  @override
  String get wgUpdNotVerified => '无法验证此更新';

  @override
  String get wgUpdCancel => '取消';

  @override
  String get wgUpdOpenReleasePage => '打开发布页面';

  @override
  String wgIptvChipMyPortals(Object count) {
    return '我的门户（$count）';
  }

  @override
  String get wgUpdNoChecksum =>
      '此版本未提供 SHA-256 校验值，Lumora 不会自动安装。请打开发布页面，自行校验下载文件后再安装。';

  @override
  String get wgUpdInstallPermission => '请在 Android 设置中允许 Lumora「安装未知应用」，然后重试。';

  @override
  String wgUpdFailed(String error) {
    return '更新失败：$error';
  }

  @override
  String wgUpdDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get wgUpdChecksumMismatch => '更新文件的校验值不匹配，已删除下载的文件。';

  @override
  String get wgUpdSignatureConflictHint =>
      '如果之前安装的版本使用了不同的签名密钥，安装可能会失败并提示「应用未安装：软件包与现有软件包存在冲突」。请先卸载旧版本一次再重新安装；卸载前可在 设置 → 备份与还原（JSON）中导出设置以保留它们。';

  @override
  String get wgUpdDownloadComplete => '下载完成';

  @override
  String get wgUpdWillCloseAndInstall => 'Lumora 将关闭并安装更新。';

  @override
  String get wgUpdDownloadedTo => '更新已下载到：';

  @override
  String get wgUpdMakeExecutable => '为文件添加可执行权限并运行：';

  @override
  String get wgUpdOpenFolder => '打开文件夹';

  @override
  String get wgUpdCloseAndInstall => '关闭并立即安装';

  @override
  String get wgUpdOk => '确定';

  @override
  String get updatesCheckFailed => '无法检查更新。请检查网络连接后重试。';

  @override
  String detailsRuntimeMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get authTagline => '电影光影，尽在 Lumora';

  @override
  String get authSignIn => '登录';

  @override
  String get authSignUp => '注册';

  @override
  String get authEmail => '邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get authInviteCode => '邀请码';

  @override
  String get authInviteHint => '第一次注册才需要邀请码，可以向管理员索取。';

  @override
  String get authSubmitSignIn => '登录';

  @override
  String get authSubmitSignUp => '注册';

  @override
  String get authWorking => '请稍候…';

  @override
  String get authErrInvalidInvite => '邀请码无效，或者已经被用过了。';

  @override
  String get authErrInviteMissing => '请填写邀请码。';

  @override
  String get authErrWrongPassword => '邮箱或密码不对。';

  @override
  String get authErrEmailTaken => '这个邮箱已经注册过了，请直接登录。';

  @override
  String get authErrWeakPassword => '密码至少要 6 位。';

  @override
  String get authErrInvalidEmail => '邮箱格式好像不对。';

  @override
  String get authErrEmailNotConfirmed => '请先到邮箱点确认链接。';

  @override
  String get authErrNetwork => '连不上服务器，请检查网络。';

  @override
  String get authErrUnknown => '出了点问题，请再试一次。';

  @override
  String get authConfirmEmail => '注册成功！请到邮箱点确认链接，然后再登录。';

  @override
  String get accountSection => '账号';

  @override
  String accountSignedInAs(String email) {
    return '已登录：$email';
  }

  @override
  String get accountAdmin => '管理员';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get accountSignOutSubtitle => '在这台设备上退出 Lumora';

  @override
  String get inviteManage => '邀请码管理';

  @override
  String get inviteManageSubtitle => '生成邀请码，给朋友注册用';

  @override
  String get invitesTitle => '邀请码管理';

  @override
  String get invitesIntro => '每个邀请码只能注册一个账号。把码给朋友，他们注册时填进去就行。';

  @override
  String get invitesNote => '备注（可选，例如给谁）';

  @override
  String invitesGenerate(int count) {
    return '生成 $count 个';
  }

  @override
  String invitesCopied(String code) {
    return '已复制 $code';
  }

  @override
  String get invitesCopy => '复制';

  @override
  String get invitesEmpty => '还没有邀请码。';

  @override
  String get invitesUnused => '未使用';

  @override
  String invitesUsedBy(String email) {
    return '已被 $email 使用';
  }

  @override
  String invitesCount(int total, int unused) {
    return '共 $total 个 · $unused 个未使用';
  }

  @override
  String get invitesLoadFailed => '邀请码加载失败。';

  @override
  String get invitesCreateFailed => '邀请码生成失败。';

  @override
  String get authWelcomeBack => '欢迎回来';

  @override
  String get authCreateAccount => '创建账号';

  @override
  String get authSignInSubtitle => '登录后继续看你的收藏和观看记录。';

  @override
  String get authSignUpSubtitle => '用朋友给你的邀请码注册，一个码只能用一次。';

  @override
  String get authFirstTime => '第一次来？';

  @override
  String get authUseInvite => '用邀请码注册';

  @override
  String get authHaveAccount => '已经有账号了？';

  @override
  String get authSignInInstead => '直接登录';

  @override
  String get authDragToTurn => '拖动旋转';

  @override
  String authSwitchFigure(String name) {
    return '换成$name';
  }

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authPasswordHint => '至少 6 位';

  @override
  String get authInviteFieldHint => 'ABCD-2345';

  @override
  String get splashLoading => '正在启动';

  @override
  String homeTodayTop(int rank) {
    return '今日 Top $rank';
  }

  @override
  String get homeKindSeries => '剧集';

  @override
  String get homeKindMovie => '电影';

  @override
  String get homeHeroNext => '下一个';

  @override
  String get homeHeroPrevious => '上一个';

  @override
  String homeHeroSlide(int index) {
    return '第 $index 个';
  }

  @override
  String get moreAiPicks => 'AI 选片';

  @override
  String get moreCalendar => '追剧日历';

  @override
  String get browseMoviesTv => '影视';

  @override
  String get browseCollections => '合集';

  @override
  String get browseManga => '漫画';

  @override
  String get browseBooks => '书籍';

  @override
  String get browseAudiobooks => '有声书';

  @override
  String get browseMusic => '音乐';

  @override
  String get liveCatPremier => '精选直播';

  @override
  String get liveCatEspn => 'ESPN 与大学篮球';

  @override
  String get liveCatUsSports => '美国职业联赛';

  @override
  String get liveCatSoccer => '足球';

  @override
  String get liveCatBoxing => '拳击';

  @override
  String get liveCatCombat => '格斗';

  @override
  String get liveCatRacing => '赛车';

  @override
  String get liveCatMovies => '电影与付费频道';

  @override
  String get liveCatNews => '新闻';

  @override
  String get liveCatArabic => '阿拉伯频道';

  @override
  String get liveCatDiscovery => '纪录片';

  @override
  String get liveCatKids => '少儿与家庭';

  @override
  String get liveCatUs => '美国频道';

  @override
  String get liveCatUk => '英国频道';

  @override
  String get liveCatCanada => '加拿大频道';

  @override
  String get liveCatBayArea => '旧金山湾区';

  @override
  String get liveCatIntlSports => '国际体育';

  @override
  String get liveSubtitle => '来自你的片源的直播频道';

  @override
  String listSummary(int count) {
    return '共 $count 部';
  }

  @override
  String get dscRequired => '必选';

  @override
  String get dscEnter => '输入';

  @override
  String get dscTypeTv => '电视';

  @override
  String get dscTypeChannel => '频道';

  @override
  String get tvStatusStopped => '已停止。';

  @override
  String get tvStatusDiscovering => '正在寻找新的门户…';

  @override
  String get tvStatusNoMore => '没有更多可用的门户。';

  @override
  String tvStatusVerifying(int count) {
    return '正在验证 $count 个门户…';
  }

  @override
  String tvStatusVerifyingProgress(int done, int total, int active) {
    return '验证门户 $done/$total · $active 个可用';
  }

  @override
  String tvStatusScanning(int count) {
    return '正在并行扫描 $count 个门户…';
  }

  @override
  String tvStatusFound(int count) {
    return '找到 $count 个直播流 · 正在检查可用性…';
  }

  @override
  String tvStatusSniffing(int checked, int total, int live) {
    return '检测 $checked/$total · $live 个可直播';
  }

  @override
  String tvGuideFromPanel(String channel) {
    return '节目单来自频道自己的面板，等你的片源里有一个确认能播的「$channel」直播流后就会显示。';
  }

  @override
  String get liveCatSports => '体育';

  @override
  String get liveCatSoccerShort => '足球';

  @override
  String get liveCatMoviesShort => '电影';

  @override
  String get liveCatNewsShort => '新闻';

  @override
  String get authWithGoogle => '用 Google 登录';

  @override
  String get authWithFacebook => '用 Facebook 登录';

  @override
  String get authOr => '或';

  @override
  String get authRedeemTitle => '输入一次邀请码';

  @override
  String get authRedeemBody =>
      'Lumora 是邀请制。第一次用 GitHub 或 Discord 登录，需要输入朋友给你的邀请码，以后就不用了。';

  @override
  String get authRedeemAction => '确认';

  @override
  String get authRedeemSwitch => '换个账号';

  @override
  String get authOAuthFailed => '打不开登录页面，请再试一次。';

  @override
  String get authWithGithub => '用 GitHub 登录';

  @override
  String get authWithDiscord => '用 Discord 登录';

  @override
  String get authForgot => '忘记密码？';

  @override
  String get authForgotNeedEmail => '先在上面填你的邮箱。';

  @override
  String authForgotSent(String email) {
    return '重设密码的邮件已寄到 $email。在这台装置上点邮件里的链接，就会回到 Lumora 设新密码。';
  }

  @override
  String get authNewPasswordTitle => '设置新密码';

  @override
  String authNewPasswordBody(String email) {
    return '为 $email 设一个新密码。';
  }

  @override
  String get authNewPasswordAction => '保存密码';

  @override
  String get authNewPasswordSaved => '密码已更新。';

  @override
  String get authResetCodeTitle => '查看邮箱';

  @override
  String authResetCodeBody(String email) {
    return '验证码已寄到 $email。在哪个装置看邮件都可以，把邮件里的验证码填在这里。';
  }

  @override
  String get authResetCode => '验证码';

  @override
  String get authResetCodeHint => '邮件里的数字';

  @override
  String get authResetVerify => '下一步';

  @override
  String get authResetWrongCode => '验证码不对或已过期，请重新寄一封。';

  @override
  String get authResetResend => '重新寄';

  @override
  String get authResetBack => '返回登录';

  @override
  String get authErrSamePassword => '这是你现在的密码，请换一个新的。';

  @override
  String get authNewPasswordKeep => '保留现在的密码';

  @override
  String get filterLoading => '正在加载…';

  @override
  String get filterEmptyOrFailed => '这里暂时没有内容：可能没有符合条件的结果，也可能没能加载。';

  @override
  String get filterMoreFailed => '没能加载更多。';

  @override
  String get profileEdit => '编辑个人资料';

  @override
  String get profileNameLabel => '昵称';

  @override
  String get profileNameHint => '朋友看到的名字';

  @override
  String get profileColorLabel => '头像颜色';

  @override
  String get profileSave => '保存';

  @override
  String get profileCancel => '取消';

  @override
  String get profileSaved => '个人资料已保存。';

  @override
  String get profileSaveFailed => '保存失败，请检查网络后再试。';

  @override
  String whatsNewTitle(String version) {
    return 'Lumora $version 更新了什么';
  }

  @override
  String get whatsNewDone => '知道了';

  @override
  String get newEpBadge => '有新集';

  @override
  String newEpCode(String season, String episode) {
    return 'S$season E$episode';
  }

  @override
  String get newEpRail => '新集上线';

  @override
  String newEpAirsNext(String date) {
    return '$date 更新';
  }

  @override
  String newEpMonthDay(String month, String day) {
    return '$month月$day日';
  }

  @override
  String get newEpCalTitle => '追剧日历';

  @override
  String get newEpCalSubtitle => '你收藏的剧什么时候更新';

  @override
  String get newEpCalEmptyTitle => '收藏里还没有剧';

  @override
  String get newEpCalEmptyBody => '把剧加进收藏，这里就会显示它们的播出时间';

  @override
  String get newEpCalNoneThisDay => '你收藏的剧这天没有更新';

  @override
  String get newEpCalChecking => '正在查询播出时间…';

  @override
  String get mangaGenreAll => '全部';

  @override
  String get mangaGenreAction => '动作';

  @override
  String get mangaGenreAdventure => '冒险';

  @override
  String get mangaGenreComedy => '喜剧';

  @override
  String get mangaGenreDrama => '剧情';

  @override
  String get mangaGenreFantasy => '奇幻';

  @override
  String get mangaGenreHistorical => '历史';

  @override
  String get mangaGenreHorror => '恐怖';

  @override
  String get mangaGenreIsekai => '异世界';

  @override
  String get mangaGenreMartialArts => '武侠';

  @override
  String get mangaGenreMystery => '悬疑';

  @override
  String get mangaGenrePsychological => '心理';

  @override
  String get mangaGenreRomance => '恋爱';

  @override
  String get mangaGenreSchoolLife => '校园';

  @override
  String get mangaGenreSciFi => '科幻';

  @override
  String get mangaGenreSeinen => '青年';

  @override
  String get mangaGenreShounen => '少年';

  @override
  String get mangaGenreSliceOfLife => '日常';

  @override
  String get mangaGenreSports => '运动';

  @override
  String get mangaGenreSupernatural => '超自然';

  @override
  String get mangaGenreTragedy => '悲剧';

  @override
  String get mangaTypeManga => '日漫';

  @override
  String get mangaTypeManhwa => '韩漫';

  @override
  String get mangaTypeManhua => '国漫';

  @override
  String get mangaModeWebtoon => '竖向滚动（条漫）';

  @override
  String get mangaModeLtr => '翻页，从左到右';

  @override
  String get mangaModeRtl => '翻页，从右到左（日漫）';

  @override
  String get mangaWidthFull => '全屏';

  @override
  String get mangaWidthCompact => '紧凑';

  @override
  String get mangaWidthStandard => '标准';

  @override
  String get mangaWidthWide => '宽屏';

  @override
  String get mangaBgPitchBlack => '纯黑';

  @override
  String get mangaBgDeepCharcoal => '深炭灰';

  @override
  String get mangaBgDarkSlate => '暗石板';

  @override
  String get mangaBgSepiaDark => '暗褐';

  @override
  String get mangaDensityCompact => '紧凑';

  @override
  String get mangaDensityStandard => '标准';

  @override
  String get mangaDensitySpacious => '宽松';

  @override
  String mangaChapterShort(String number) {
    return '第$number话';
  }

  @override
  String get mangaPageTitle => '漫画';

  @override
  String get mangaPageSubtitle => '日漫、韩漫、国漫，随时随地翻开就读';

  @override
  String get mangaReaderSettings => '阅读器';

  @override
  String booksChapterShort(String number) {
    return '第$number章';
  }

  @override
  String booksChapterOfTotal(String current, String total) {
    return '第 $current / $total 章';
  }

  @override
  String booksFontSizePt(String size) {
    return '$size 磅';
  }

  @override
  String booksFontSizePx(String size) {
    return '$size 像素';
  }

  @override
  String get booksPreviewSample => '春日午后，阳光穿过窗棂落在书页上，字里行间仿佛都有了温度。';

  @override
  String get booksPageTitle => '书籍';

  @override
  String get booksPageSubtitle => '找到一本书，下载一次，随处阅读';

  @override
  String get booksReaderStyle => '阅读样式';

  @override
  String get booksShowControls => '显示控制栏';

  @override
  String get musArtistsHeading => '艺人';

  @override
  String get musAlbumsHeading => '专辑';

  @override
  String get musPlaylistsHeading => '歌单';

  @override
  String get musGenrePopHits => '流行金曲';

  @override
  String get musGenreRockClassics => '经典摇滚';

  @override
  String get musGenreHeavyMetal => '重金属';

  @override
  String get musGenreClassicalPiano => '古典钢琴';

  @override
  String musHiResLossless(String quality) {
    return '高解析无损 · $quality';
  }

  @override
  String musHiResLosslessAudio(String quality) {
    return '$quality · 高解析无损音频';
  }

  @override
  String get musPlayTip => '播放';

  @override
  String get musPauseTip => '暂停';

  @override
  String get musPreviousTip => '上一首';

  @override
  String get musNextTip => '下一首';

  @override
  String get musRepeatTip => '循环播放';

  @override
  String get musLikeTip => '喜欢';

  @override
  String get musAddToPlaylistTip => '加入歌单';

  @override
  String get musLyricsTip => '歌词';

  @override
  String get musQueueTip => '播放队列';

  @override
  String get musClosePlayerTip => '收起播放器';

  @override
  String get musMoreTip => '更多';

  @override
  String get musRemoveFromQueueTip => '从队列移除';

  @override
  String get musRemoveFromPlaylistTip => '从歌单移除';

  @override
  String get musClearSearchTip => '清除搜索';

  @override
  String get musCancelDownloadTip => '取消下载';

  @override
  String get musNowPlayingKicker => '正在播放';

  @override
  String get abkCatFantasy => '奇幻';

  @override
  String get abkCatSciFi => '科幻';

  @override
  String get abkCatMystery => '悬疑';

  @override
  String get abkCatThriller => '惊悚';

  @override
  String get abkCatNonFiction => '非虚构';

  @override
  String get abkCatSelfHelp => '自我成长';

  @override
  String get abkCatHorror => '恐怖';

  @override
  String get abkCatRomance => '爱情';

  @override
  String get abkCatAdventure => '冒险';

  @override
  String get abkCatClassics => '经典名著';

  @override
  String abkTimeLeft(String time) {
    return '剩余 $time';
  }

  @override
  String get abkTorrentSource => 'AudiobookBay · 种子';

  @override
  String get abkAiGenerated => 'AI 生成';

  @override
  String get abkAiGeneratedKokoro => 'AI 生成 · Kokoro TTS';

  @override
  String get abkUnknownAuthor => '未知作者';

  @override
  String abkSplitMessage(String words, String parts, String list) {
    return '这本书约有 $words 个词，将按章节拆分为 $parts 部分并加入队列：\n\n$list';
  }

  @override
  String abkSplitPartLine(String name, String words) {
    return '• $name（约 $words 词）';
  }

  @override
  String get abkBackTip => '返回';

  @override
  String get abkPlaybackSpeedTip => '播放速度';

  @override
  String get abkRemoveFromContinue => '从继续收听中移除？';

  @override
  String get abkClearSearchTip => '清除搜索';

  @override
  String get abkDeleteJobTip => '移除';

  @override
  String get playerSubPreviewSample => 'Lumora · 字幕样式预览';

  @override
  String get abkDensityCompact => '紧凑';

  @override
  String get abkDensityStandard => '标准';

  @override
  String get abkDensitySpacious => '宽松';

  @override
  String get abkPresetModern => '经典';

  @override
  String get abkPresetVinyl => '唱片机';

  @override
  String get abkPresetCapsule => '极简';

  @override
  String get abkPresetCanvas => '大封面';

  @override
  String get abkPresetCustom => '自定义';

  @override
  String get abkSeekWaveform => '波形';

  @override
  String get abkSeekGradient => '进度条';

  @override
  String get abkSeekSlider => '滑块';

  @override
  String get abkSeekRing => '圆环';

  @override
  String get abkButtonCircle => '圆形';

  @override
  String get abkButtonGlass => '描边';

  @override
  String get abkButtonSquare => '方形';

  @override
  String get abkButtonPill => '胶囊';

  @override
  String get profilePhotoUpload => '上传照片';

  @override
  String get profilePhotoRemove => '移除照片';

  @override
  String get profilePhotoFailed => '照片上传失败，请换一张图片再试。';

  @override
  String get booksAlignLeft => '左对齐';

  @override
  String get booksAlignJustify => '两端对齐';

  @override
  String get wgPlyAspectFit => '适应屏幕（完整显示）';

  @override
  String get wgPlyAspectCover => '填满屏幕（裁剪/放大）';

  @override
  String get wgPlyAspectStretch => '拉伸填满';

  @override
  String get wgPlySubColorWhite => '白色';

  @override
  String get wgPlySubColorCinemaYellow => '影院黄';

  @override
  String get wgPlySubColorAmberGold => '琥珀金';

  @override
  String get wgPlySubColorElectricCyan => '电光青';

  @override
  String get wgPlySubColorNeonGreen => '霓虹绿';

  @override
  String get wgPlySubColorVibrantOrange => '活力橙';

  @override
  String get wgPlySubColorSoftRose => '柔粉';

  @override
  String get wgPlySubColorLightGray => '浅灰';

  @override
  String get wgPlySubColorBlack => '黑色';

  @override
  String get wgPlySubColorDarkSlate => '深石板灰';

  @override
  String get wgPlySubColorGold => '金色';

  @override
  String get wgPlySubColorCrimson => '深红';

  @override
  String get wgPlySubColorNeonCyan => '霓虹青';

  @override
  String get wgPlySubBoxNone => '无';

  @override
  String wgPlySubBoxDark(String percent) {
    return '$percent% 深色';
  }

  @override
  String get wgPlySubBoxSolid => '100% 实色';

  @override
  String get wgPlySubBoxIndigo => '50% 靛蓝';

  @override
  String get wgPlySubBoxDescTransparent => '透明';

  @override
  String get wgPlySubBoxDescSubtle => '轻微';

  @override
  String get wgPlySubBoxDescStandard => '标准底框';

  @override
  String get wgPlySubBoxDescHighContrast => '高对比度';

  @override
  String get wgPlySubBoxDescOpaque => '不透明黑';

  @override
  String get wgPlySubBoxDescSlate => '石板色调';

  @override
  String get tvDescEspn => 'ESPN+、ESPN、ESPN2、ESPNU、NCAA 男女篮、SEC 与 ACC';

  @override
  String get tvDescCombat => 'UFC Fight Pass、WWE、AEW、World Boxing 与按次付费 (PPV)';

  @override
  String get musRailTrending => '🔥 全球热门榜单';

  @override
  String get musRailPop => '🌟 流行精选';

  @override
  String get musRailHipHop => '🎙️ 嘻哈说唱重磅';

  @override
  String get musRailElectronic => '🎧 电子舞曲与 EDM';

  @override
  String get musRailRock => '🎸 经典摇滚与另类';

  @override
  String get musRailSoundtracks => '🎬 电影与动漫原声';

  @override
  String get musRailChill => '🌙 放松、Lofi 与氛围音乐';

  @override
  String abkDebridCouldNotResolveAudio(String service) {
    return '$service 无法解析音频流。';
  }

  @override
  String get abkAudioStreamUrlUnresolved => '无法解析音频流地址。';

  @override
  String get abkCatalogueUnavailableTitle => '此版本不提供在线有声书目录';

  @override
  String get abkCatalogueUnavailableBody =>
      '你仍可以在工作室导入自己的 MP3 或 M4B 有声书，或把 EPUB 生成为有声书。';

  @override
  String get abkCatalogueUnavailableBodyImportOnly =>
      '你仍可以在工作室导入自己的 MP3 或 M4B 有声书。';

  @override
  String get abkHubSubtitleOwnLibrary => '你自己的有声书，随时收听';

  @override
  String get detailsSpecials => '特别篇';
}
