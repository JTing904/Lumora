import 'l10n.dart';

/// The names and blurbs of the appearance options (player presets, seek bars,
/// card densities...), which their enums spell in English. In Chinese they
/// read from this table; anything missing stays in English.
String localizedOptionLabel(String en) {
  if (l10nCurrent().localeName != 'zh') return en;
  return _zh[en] ?? en;
}

const Map<String, String> _zh = {
  'Modern Glass Island': '现代玻璃浮岛',
  'Sleek floating glassmorphism player with waveform scrubber & ambient glow':
      '轻盈悬浮的玻璃质感播放器，带波形进度条和环境光',
  'Vinyl Turntable Studio': '黑胶唱机',
  'Rotating vinyl disc, tonearm animation & analog vintage VU styling':
      '旋转黑胶、唱臂动画和复古 VU 表风格',
  'Minimalist Focus Capsule': '极简专注胶囊',
  'Compact distraction-free floating capsule with essential controls':
      '小巧不打扰的悬浮胶囊，只留必要按钮',
  'Immersive Canvas Studio': '沉浸式画布',
  'Full-screen cinematic ambient blur canvas with oversized artwork':
      '全屏电影感模糊背景，配大尺寸封面',
  'Custom Drag & Drop Studio': '自定义拖放工作室',
  'Your fully customized, arranged and styled audio player': '你自己排版、自己设计的播放器',
  'Dynamic Audio Waveform Canvas': '动态音频波形',
  'Procedural animated waveform bars with live equalizer scrubbing':
      '跟着声音跳动的波形条，可直接拖动',
  'Neon Gradient Progress Bar': '霓虹渐变进度条',
  'Multi-color vibrant linear gradient scrubber with glowing tip':
      '多彩渐变进度条，末端发光',
  'Precision Glass Slider': '精准玻璃滑杆',
  'Tactile interactive glass track with timecode readouts': '有手感的玻璃滑轨，显示时间码',
  'Radial Circular Ring Scrubber': '圆环进度条',
  'Radial circular dial scrubber for compact modern interfaces':
      '圆形转盘进度条，适合紧凑界面',
  'Circle Aura Glow': '圆形光晕',
  'Liquid Glass Neomorphic': '液态玻璃新拟态',
  'Rounded Glass Square': '圆角玻璃方块',
  'Wide Accent Pill': '宽胶囊按钮',
  'Scale & Spring Bounce': '缩放弹跳',
  'Theme Accent Glow Aura': '主题色光晕',
  'Liquid Glass Ripple': '液态玻璃涟漪',
  '3D Subtle Tilt Perspective': '3D 轻微倾斜',
  '3D Rounded Square with Glow': '发光 3D 圆角方块',
  'Spinning Vinyl Disc': '旋转黑胶',
  'Floating Glass Card': '悬浮玻璃卡片',
  'Hidden / Focus Mode': '隐藏（专注模式）',
  'Compact (Dense Grid)': '紧凑（密集网格）',
  'Standard (Balanced)': '标准（均衡）',
  'Spacious (Large Covers)': '宽松（大封面）',
  'Rotating 33rpm vinyl disc with tonearm and warm studio atmosphere':
      '33 转旋转黑胶、唱臂和温暖的录音室氛围',
  'Cyberpunk Wave Visualizer': '赛博朋克声波',
  'Real-time animated audio visualizer canvas with neon glow': '实时跳动的霓虹音频可视化',
  'Liquid Glass Sanctuary': '液态玻璃空间',
  'Deep optical refraction glass sheets powered by liquid_glass_easy':
      '带深度光学折射的玻璃层',
  'Cinematic Poster Focus': '电影海报',
  'Massive edge-to-edge immersive album art with blurred atmosphere':
      '铺满整屏的大专辑封面，配模糊背景',
  'Custom Drag & Drop Full Player': '自定义拖放全屏播放器',
  'Your fully customized, arranged and styled fullscreen player':
      '你自己排版、自己设计的全屏播放器',
  'Liquid Glass Track Slider': '液态玻璃滑轨',
  'Refractive frosted glass slider track with smooth thumb': '磨砂玻璃滑轨，滑块顺滑',
  'Precision Tactile Slider': '精准手感滑杆',
  'Radial Circular Ring Dial': '圆环转盘',
  'Aura Glow Circle': '光晕圆形',
  'Neon Glass Square': '霓虹玻璃方块',
  'Spinning Vinyl Disc with Center Label': '带中心贴纸的旋转黑胶',
  '3D Floating Glass Card with Elevation': '立体悬浮玻璃卡片',
  'Rounded Neomorphic Square with Glow': '发光新拟态圆角方块',
  'Atmospheric Glow Orb': '氛围光球',
  'Spacious (Large Posters)': '宽松（大海报）',
  'Vertical Continuous (Webtoon)': '垂直连续（条漫）',
  'Horizontal (Left to Right)': '横向（从左到右）',
  'Horizontal (Right to Left / Manga)': '横向（从右到左 / 日漫）',
  'Full Screen (100%)': '全屏（100%）',
  'Compact (720px)': '紧凑（720px）',
  'Standard (900px)': '标准（900px）',
  'Wide (1150px)': '宽（1150px）',
  'Pitch Black': '纯黑',
  'Deep Charcoal': '深炭灰',
  'Dark Slate': '暗石板',
  'Sepia Dark': '暗褐',
  'Floating Glass Island': '悬浮玻璃浮岛',
  'Docked Bottom Bar': '底部固定栏',
  'Minimalist Floating Pill': '极简悬浮胶囊',
  'Top (Below Hero Banner)': '顶部（大图下方）',
  'Under Cinemeta Addon': 'Cinemeta 插件下方',
  'Middle of Catalog': '分类中间',
  'Bottom of Page': '页面底部',
  'Immersive Cinematic Carousel': '沉浸式电影轮播',
  'Compact Spotlight': '紧凑焦点',
  'Minimalist Header': '极简标题',
  'Dual Floating Orbs': '双光球',
  'Top Aurora Horizon': '顶部极光',
  'Full Deep Ambient Mesh': '全屏深色光网',
  'Pulsing Core': '脉动光心',
  'Standard Balanced': '标准均衡',
  'Cinematic (Large Posters)': '电影感（大海报）',
  'Rich Card with Badges': '带标签的完整卡片',
  'Compact Row': '紧凑横排',
  'Grid Cards': '网格卡片',
  'Detailed List with EPG': '带节目表的详细列表',
  'Compact Channel List': '紧凑频道列表',
  'Subtle Glass': '轻玻璃',
  'Balanced Liquid': '均衡液态',
  'Hyper Jelly': '果冻',
  'Crystal Prism': '水晶棱镜',
  'Frosted Cyber': '磨砂赛博',
  'Custom': '自定义',
  'Lumora Gold': 'Lumora 金色',
  // Cinemeta's own manifest text; every installation has it.
  'The official addon for movie and series catalogs': '电影和剧集目录的官方插件',
  'Built-in fast HTTP stream scrapers (111477, Cinejoy, Vuflix, Movy, RiveStream, Vadapav, VidCore, VidSrc, etc.)':
      '内置高速 HTTP 片源抓取（111477、Cinejoy、Vuflix、Movy、RiveStream、Vadapav、VidCore、VidSrc 等）。',
  'Stremio addon that searches BitTorrent indexers and flags which results are already cached on the connected Debrid service.':
      '搜索 BitTorrent 索引站的 Stremio 插件，会标出哪些结果已缓存在你连接的 Debrid 服务上。',
  'Free key at store.wyzie.io/redeem': '在 store.wyzie.io/redeem 免费领取',
  'A credential for a third-party service that did not issue it to Lumora. Leave blank unless you have your own.':
      '这是第三方服务的凭证，并没有发给 Lumora。除非你有自己的，否则请留空。',
  'Create a free app at app.trakt.tv/settings/apps/api/new and copy its Client ID. Without this, Trakt cannot be paired at all.':
      '在 app.trakt.tv/settings/apps/api/new 免费建一个应用，复制它的 Client ID。没有它就无法连接 Trakt。',
  'The Client Secret from the same app. Optional: Trakt has deprecated the secret for user sign-in, so a build without one still pairs.':
      '同一个应用的 Client Secret。可不填：Trakt 登录已不再需要它，没有也能连接。',
  'Hide Rails With No Artwork': '隐藏没有图片的栏目',
  'Cyber Neon City': '赛博霓虹城市',
  'Cosmic Nebula': '宇宙星云',
  'Dark Liquid Silk': '暗色流光丝绸',
  'Synthwave Horizon': '合成波地平线',
  'Moody Forest Mist': '雾中森林',
  'Abstract Dark Neon': '抽象暗色霓虹',
};
