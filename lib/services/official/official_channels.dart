/// The rights holders' own YouTube channels that Lumora may play from.
///
/// This list is the whole of the "official upload" source: a video is offered
/// only when the channel that uploaded it is named here. Nothing outside it is
/// ever searched for, matched or played - not a re-upload, not a fan channel,
/// not a mirror - however well its title matches.
///
/// **How each entry was verified (2026-10-28).** Every channel id below was
/// read from YouTube itself (InnerTube search, `channelRenderer.channelId`) and
/// carries YouTube's verified badge (`BADGE_STYLE_TYPE_VERIFIED`), and its own
/// channel description names the company or the company's app (iQIYI app,
/// WeTV, YOUKU International, TVB Anywhere+, bilibili, Muse Communication,
/// Medialink/Ani-One). Channels that look official but carry no verified badge
/// (for example "iQIYI Anime Asia", "Tencent Video - SUSPENSE") are left out
/// on purpose; add one only after the same check.
///
/// **Second batch (2026-10-28).** Same InnerTube check from `gl=MY`, plus the
/// channel's recent uploads (most must be 20+ minute full episodes or films).
/// An entry passes on one of two kinds of evidence, noted above each entry:
/// * `badge` - YouTube's verified badge and a description naming the company
///   or its app;
/// * `featured by ...` - no badge, but a verified channel of the same company
///   lists it among its own featured channels (the rights holder linking to
///   it from its own account; checked on that channel's `channels` tab).
/// Rejected in that pass: clip-only channels (WeTV Malaysia, iQIYI Malaysia,
/// Viu Malaysia, Astro Gempak / Astro Shaw / Astro 本地圈, PTS 公視戲劇, It's
/// Anime, ANIPLUS Asia), channels whose film uploads are split into parts or
/// carry no film title (Tencent Video-MOVIE, iQIYI Action Movie), channels
/// with no ownership evidence (YOUKU COSTUME, iQIYI Anime Asia, 海风影视), and
/// the TVB channels that state a Malaysia block.
///
/// **Third batch (2026-10-28).** Same badge check, plus a description that
/// names the operating company and, for distributors, states the uploads are
/// licensed from the rights holders. Adds the Shanghai and Zhejiang
/// broadcasters' own channels and licensed English-language film, TV and
/// documentary distributors (FilmRise, Crackle Plus, VA Media, Content
/// Rocket, Grjngo, Quintus Studios, Little Dot Studios). Rejected in that
/// pass: clip-only channels (KBS WORLD TV, MBCdrama, SBS Catch, GMMTV, TMS,
/// Toei Animation, TOHO animation, Paramount Movies, Linmon), Ch3Thailand
/// (episodes split into parts), and channels with no badge or no owner named
/// (Kings of Horror, China Zone, 江苏卫视, BRTV, 欢娱影视, 正午阳光).
///
/// **Regions.** Licensors geo-block uploads per title. Where a channel states
/// a blanket restriction it is recorded in [OfficialChannel.blockedRegions] and
/// the resolver skips that channel for a viewer in one of those regions; any
/// other restriction shows up as YouTube's own "not available in your country"
/// inside the embed, which the player reports.
library;

/// What a channel mostly carries, so a lookup can try the likely channels
/// first when it has to search channel by channel.
enum OfficialContent {
  donghua,
  chineseDrama,
  anime,
  hongKongDrama,
  variety,
  documentary,
  movie,
  tvSeries,
}

/// One verified rights-holder channel.
class OfficialChannel {
  const OfficialChannel({
    required this.id,
    required this.name,
    required this.handle,
    required this.owner,
    required this.carries,
    required this.content,
    this.blockedRegions = const <String>{},
    this.regionNote,
  });

  /// YouTube channel id (`UC…`). This, not the name, is what is matched.
  final String id;

  /// The channel's display name on YouTube, shown next to the source.
  final String name;

  /// The channel's `@handle`, for a human checking this list.
  final String handle;

  /// Who owns the channel.
  final String owner;

  /// What it uploads, in a few words.
  final String carries;

  final Set<OfficialContent> content;

  /// ISO 3166 country codes where the channel says its uploads do not play.
  final Set<String> blockedRegions;

  /// Anything else known about where it plays.
  final String? regionNote;
}

/// The whitelist. Order is the order channels are tried in a per-channel
/// search, so the channels that post the most full episodes come first.
abstract final class OfficialChannels {
  static const List<OfficialChannel> all = [
    // ── bilibili ──────────────────────────────────────────────────────────
    OfficialChannel(
      id: 'UCQFyMGc6h30NMCd6HCk0ZPA',
      name: 'Made By Bilibili',
      handle: '@MadeByBilibili',
      owner: 'bilibili (哔哩哔哩)',
      carries:
          'bilibili-produced donghua: 凡人修仙传 A Mortal\'s Journey and '
          'others. Single episodes are public a week or so after the newest '
          '(the newest is members-only), plus multi-episode compilations.',
      content: {OfficialContent.donghua},
    ),
    // ── Tencent Video / WeTV ─────────────────────────────────────────────
    OfficialChannel(
      id: 'UCdpiId0eJGnnIvfhpbJIM1w',
      name: 'Tencent Video - Animation',
      handle: '@TencentVideoAnimation',
      owner: 'Tencent Video (腾讯视频)',
      carries:
          '腾讯动漫 donghua: 斗破苍穹, 仙逆 Renegade Immortal, 盘龙, 元尊, '
          '一念永恒, 武庚纪, 妖神记 - episodes and full-season compilations.',
      content: {OfficialContent.donghua},
    ),
    OfficialChannel(
      id: 'UCQatgKoA7lylp_UzvsLCgcw',
      name: 'Tencent Video',
      handle: '@TencentVideo',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Main channel: Tencent dramas, some donghua.',
      content: {OfficialContent.chineseDrama, OfficialContent.donghua},
    ),
    OfficialChannel(
      id: 'UCM5qb75ErC1JMmdgWjN8HJA',
      name: 'Yuewen Animation',
      handle: '@yuewenanimation',
      owner: 'China Literature / Yuewen (阅文集团, Tencent group)',
      carries: 'Yuewen-adapted donghua (狐妖小红娘 and others).',
      content: {OfficialContent.donghua},
    ),
    OfficialChannel(
      id: 'UC3PKcYXUAhao3p4kuNS4_9w',
      name: 'Tencent Video - Drama',
      handle: '@TencentVideoDrama',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Contemporary Chinese dramas, full episodes (EP01…).',
      content: {OfficialContent.chineseDrama},
    ),
    OfficialChannel(
      id: 'UCRABdhiBHX4Bie-jfPCd2pg',
      name: 'Tencent Video - Costume',
      handle: '@TencentVideoCostume',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Costume / xianxia dramas, full episodes.',
      content: {OfficialContent.chineseDrama},
    ),
    OfficialChannel(
      id: 'UCFh5x5AZHQQ6FaGKnG-QXDA',
      name: 'Tencent Video - Romantic',
      handle: '@TencentVideoRomantic',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Youth and romance dramas, full episodes.',
      content: {OfficialContent.chineseDrama},
    ),
    OfficialChannel(
      id: 'UCiu3bj4rR8KOYcUA4KNkOAA',
      name: 'WeTV English',
      handle: '@WeTVEnglish',
      owner: 'WeTV (Tencent Video international)',
      carries: 'Chinese dramas with English subtitles.',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: featured by Tencent Video and WeTV English (no badge).
    OfficialChannel(
      id: 'UC883KJNurPvauCdi_2DppXw',
      name: 'Tencent Video- Show',
      handle: '@TencentVideoShow',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Tencent variety, full episodes (《节目 第N季》EP3上/下).',
      content: {OfficialContent.variety},
    ),
    // Verified: featured by WeTV English (no badge).
    OfficialChannel(
      id: 'UCpzKGKh6ubkaPjHerfGaQ5A',
      name: 'Tencent Video - Documentary',
      handle: '@TencentVideoDocumentary',
      owner: 'Tencent Video (腾讯视频)',
      carries: 'Tencent documentaries, full episodes (【Title S2】EP04).',
      content: {OfficialContent.documentary},
    ),
    // ── iQIYI ────────────────────────────────────────────────────────────
    OfficialChannel(
      id: 'UCUhpu5MJQ_bjPkXO00jyxsw',
      name: 'iQIYI 爱奇艺',
      handle: '@iQIYIofficial',
      owner: 'iQIYI (爱奇艺)',
      carries: 'iQIYI dramas, "【FULL】 … EP01" uploads.',
      content: {OfficialContent.chineseDrama, OfficialContent.variety},
    ),
    OfficialChannel(
      id: 'UCvNzI_xPIHhB3Vfstj4PMWw',
      name: 'iQIYICDrama',
      handle: '@iQIYICDrama',
      owner: 'iQIYI (爱奇艺)',
      carries: 'iQIYI Chinese dramas, full-episode playlists.',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge; links iq.com.
    OfficialChannel(
      id: 'UCZ8ZJNzzIiDQFuGxdGTyWcQ',
      name: '爱奇艺大电影 iQIYI MOVIE THEATER',
      handle: '@iQIYIMOVIETHEATER',
      owner: 'iQIYI (爱奇艺)',
      carries:
          'Full Chinese films, one a day ("Title | tagline | Genre Movie").',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; featured by iQIYI 爱奇艺.
    OfficialChannel(
      id: 'UCD_83Jh-UFQXRDwC6S8caCQ',
      name: 'iQIYI SUSPENSE',
      handle: '@iQIYISuspense',
      owner: 'iQIYI (爱奇艺)',
      carries: 'Suspense dramas, "【Multi-Sub|FULL】Title EP36".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge; featured by iQIYI 爱奇艺.
    OfficialChannel(
      id: 'UCYCu2B0n-5jKLUHmlunQVAg',
      name: 'iQIYI 青春剧场',
      handle: '@iQIYIYoung',
      owner: 'iQIYI (爱奇艺)',
      carries: 'Youth dramas, "Title EP13 | ... | iQIYI青春剧场".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge; description says full episodes are free.
    OfficialChannel(
      id: 'UCQ6ptCagG3W0Bf4lexvnBEg',
      name: 'iQIYI SuperShow',
      handle: '@iQIYISuperShow',
      owner: 'iQIYI (爱奇艺)',
      carries: 'iQIYI variety, free full episodes ("EP17 | ... | Show").',
      content: {OfficialContent.variety},
    ),
    // Verified: badge; links iq.com.
    OfficialChannel(
      id: 'UCQUtD6-bWjvVZyv6CYxBBwQ',
      name: 'iQIYI LifeShow',
      handle: '@iQIYILifeShow',
      owner: 'iQIYI (爱奇艺)',
      carries: 'iQIYI lifestyle variety, "[FULL] EP10: ...".',
      content: {OfficialContent.variety},
    ),
    // Verified: badge; links iq.com.
    OfficialChannel(
      id: 'UCZrZaZM9IfX-uB-9yWf5gfQ',
      name: 'iQIYI English',
      handle: '@iQIYIEnglish',
      owner: 'iQIYI (爱奇艺)',
      carries:
          'Dramas and films with English subtitles ("【Multi-Sub|FULL】... EP01").',
      content: {OfficialContent.chineseDrama, OfficialContent.movie},
    ),
    // ── Youku ────────────────────────────────────────────────────────────
    OfficialChannel(
      id: 'UCYQPTeY3HOk0BprrGuCWCaA',
      name: 'YOUKU',
      handle: '@youku-official',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Youku dramas and variety, full episodes.',
      content: {OfficialContent.chineseDrama, OfficialContent.variety},
    ),
    OfficialChannel(
      id: 'UCvj3DtAqbx12PPHL6IVdhiA',
      name: '优酷华语剧场',
      handle: '@youkuhuayu',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Youku Chinese-language drama theatre, full episodes.',
      content: {OfficialContent.chineseDrama},
    ),
    OfficialChannel(
      id: 'UCI70JGG0hJS306Q-hGWfB7Q',
      name: 'YOUKU English',
      handle: '@youkuenglish',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Youku dramas with English subtitles.',
      content: {OfficialContent.chineseDrama},
    ),
    OfficialChannel(
      id: 'UCcYw1UUwxjIMYfvmdQrcyUA',
      name: 'YOUKU Animation',
      handle: '@youkuanimation',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Youku donghua, weekly episodes.',
      content: {OfficialContent.donghua},
    ),
    // Verified: badge; featured by YOUKU.
    OfficialChannel(
      id: 'UCE2UHXGOlqotRJgEWl_tiMw',
      name: 'YOUKU MOVIE',
      handle: '@youkumovie',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Full films, "ENGSUB【中文片名 English】... | 优酷电影".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; featured by YOUKU.
    OfficialChannel(
      id: 'UCzWUqYV4pst04ekfnJq0AOQ',
      name: 'YOUKU ROMANCE',
      handle: '@youkuromance',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Romance dramas, "ENGSUB【Title】EP20".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: featured by YOUKU (no badge).
    OfficialChannel(
      id: 'UCDyMUzlmyxAYiMravkxdDLQ',
      name: 'YOUKU SUSPENSE',
      handle: '@youkususpense',
      owner: 'Youku (优酷, Alibaba)',
      carries:
          '优酷白夜剧场 suspense dramas, "【中文名 English】EP11"; some members-only.',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge; featured by YOUKU.
    OfficialChannel(
      id: 'UCrnM42HxLis91e_VHYQusXw',
      name: 'YOUKU SHOW',
      handle: '@youkushow',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Youku variety, "【节目】EP01上 ... | 优酷综艺".',
      content: {OfficialContent.variety},
    ),
    // Verified: badge; featured by YOUKU.
    OfficialChannel(
      id: 'UClrB06PsOMunWlRUe7k9m9w',
      name: 'YOUKU DOCUMENTARY',
      handle: '@youkudocumentary',
      owner: 'Youku (优酷, Alibaba)',
      carries: 'Documentaries, "【节目】EP05 ... | 优酷纪实人文".',
      content: {OfficialContent.documentary},
    ),
    // Verified: featured by YOUKU (no badge).
    OfficialChannel(
      id: 'UCv75VdAIH18ZYp8wylU3NbA',
      name: '優酷台灣',
      handle: '@youkutaiwan',
      owner: 'Youku (优酷, Alibaba) - Taiwan',
      carries: 'Youku dramas in traditional Chinese, "【FULL】EP04 ... | 劇名".',
      content: {OfficialContent.chineseDrama},
    ),
    // ── Mango TV / Hunan TV ──────────────────────────────────────────────
    // Verified: badge; links mgtv.com.
    OfficialChannel(
      id: 'UC1pHFqCMAIHP8gr4lYGtNLA',
      name: 'China HunanTV Official Channel 湖南卫视芒果TV官方频道',
      handle: '@MangoTV-Official',
      owner: 'Hunan TV / Mango TV (湖南卫视, 芒果TV)',
      carries:
          'Mango variety, "FULL《节目》第5期"; VIP-prefixed titles are members-only.',
      content: {OfficialContent.variety},
    ),
    // Verified: featured by China HunanTV Official Channel (no badge).
    OfficialChannel(
      id: 'UCTulSfEm1c14WWRbSN-CNAQ',
      name: '芒果TV青春剧场 MangoTV Drama',
      handle: '@MangoTVDramaOfficial',
      owner: 'Mango TV (芒果TV)',
      carries: 'Mango dramas, "FULL【剧名】EP27".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: featured by China HunanTV Official Channel (no badge).
    OfficialChannel(
      id: 'UCN3iboRS-ghvH9uXK3FtCaA',
      name: '芒果TV热播综艺 MangoTV Super Variety',
      handle: '@MangoTVSuperVariety',
      owner: 'Mango TV (芒果TV)',
      carries: 'Mango variety, "FULL《节目》...".',
      content: {OfficialContent.variety},
    ),
    // Verified: featured by China HunanTV Official Channel (no badge).
    OfficialChannel(
      id: 'UCKm7iuaBY41nzqIk6J8eX0g',
      name: 'MangoTV Mystery Official Channel 芒果TV推理宇宙',
      handle: '@MangoTV-Mystery',
      owner: 'Mango TV (芒果TV)',
      carries: 'Mango mystery variety, "FULL "Show" EP01".',
      content: {OfficialContent.variety},
    ),
    // Verified: featured by 芒果TV青春剧场 MangoTV Drama (no badge).
    OfficialChannel(
      id: 'UCsPn92hQrq4VXJZc8e7fjoQ',
      name: 'MangoTV English',
      handle: '@MangoTVEnglishOfficial',
      owner: 'Mango TV (芒果TV)',
      carries: 'Mango dramas with English subtitles, "【FULL】EP01 Title中文名".',
      content: {OfficialContent.chineseDrama},
    ),
    // ── CCTV / China Movie Channel (CCTV-6) ─────────────────────────────
    // Verified: badge.
    OfficialChannel(
      id: 'UCAYkj2Fz9EvAe2fGJEGMXnQ',
      name: 'CCTV纪录',
      handle: '@CCTVDocumentary',
      owner: 'China Media Group - CCTV (中央电视台)',
      carries: 'CCTV documentaries, "《片名》01 ...【CCTV纪录】".',
      content: {OfficialContent.documentary},
    ),
    // Verified: featured by CCTV纪录 (no badge); gives the copyright.cctv contact.
    OfficialChannel(
      id: 'UC7Vl0YiY0rDlovqcCFN4yTA',
      name: 'CCTV电视剧',
      handle: '@CCTVDrama',
      owner: 'China Media Group - CCTV-8 (中央电视台)',
      carries: 'CCTV-8 dramas, "《剧名》EP20【CCTV电视剧】".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: featured by CCTV纪录 (no badge).
    OfficialChannel(
      id: 'UCQH_AXSKJ5qUp1CXW3044sg',
      name: 'CCTV百家讲坛官方频道',
      handle: '@ChinaHistoryTalks',
      owner: 'China Media Group - CCTV (中央电视台)',
      carries: 'Full 百家讲坛 lecture episodes.',
      content: {OfficialContent.documentary},
    ),
    // Verified: badge; description names CCTV6 and its copyright contact.
    OfficialChannel(
      id: 'UCGhGr_hznZxISOI_kaLWpfw',
      name: 'China Movie Channel ENGLISH',
      handle: '@CCTV6-English',
      owner: 'China Movie Channel - CCTV-6 (电影频道)',
      carries:
          'Full Chinese films with English subtitles, "【ENG SUB】Film | ... Movie".',
      content: {OfficialContent.movie},
    ),
    // Verified: featured by China Movie Channel (no badge); gives the CCTV6 copyright contact and links the 1905 app.
    OfficialChannel(
      id: 'UCnXAVNOIqCMqgN9yHwSfXdQ',
      name: 'CCTV-6 Movie Theater',
      handle: '@CCTV6-MovieTheater',
      owner: 'China Movie Channel - CCTV-6 (电影频道)',
      carries:
          'Licensed full films, one a night, "FULL "Film": ... | Movie Theater".',
      content: {OfficialContent.movie},
    ),
    // ── Studios and licensed distributors ────────────────────────────────
    // Verified: badge.
    OfficialChannel(
      id: 'UCAMrnDQlsPnrScHun5PgrXw',
      name: 'China Huace TV Official Channel',
      handle: '@huace',
      owner: 'Huace Group (华策影视)',
      carries: 'Huace dramas, "English EP12 | ... |【中文】第12集".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge.
    OfficialChannel(
      id: 'UCPIRD4yr1hlAEovBCSNlAKg',
      name: 'Croton MEGA HIT 克頓傳媒',
      handle: '@CrotonMEGAHIT',
      owner: 'Croton Media (克顿传媒, Huace group)',
      carries: 'Croton dramas (仙剑三 ...), "【剧名】第12集 | ENG SUB".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge.
    OfficialChannel(
      id: 'UC7ACqIQiy1SkjglQQ6bWDRg',
      name: 'HuashiTV',
      handle: '@HuashiRomance',
      owner: 'Jetsen Huashi (捷成华视, licensed distributor)',
      carries: 'Licensed Chinese dramas, "Ep12 | ...".',
      content: {OfficialContent.chineseDrama},
    ),
    // ── Licensed anime for Southeast Asia ────────────────────────────────
    OfficialChannel(
      id: 'UCGbshtvS9t-8CW11W7TooQg',
      name: 'Muse Asia',
      handle: '@MuseAsia',
      owner: 'Muse Communication (木棉花)',
      carries:
          'Licensed Japanese anime simulcasts, "Episode 03 [English Sub]".',
      content: {OfficialContent.anime},
      regionNote:
          'Most uploads are geo-blocked to South and Southeast Asia '
          '(Malaysia included).',
    ),
    OfficialChannel(
      id: 'UCOsFUU8EtJGDd6-AouF_MwQ',
      name: 'Muse木棉花-HK',
      handle: '@MuseHK',
      owner: 'Muse Communication (木棉花, Hong Kong)',
      carries: 'Licensed anime with Chinese subtitles.',
      content: {OfficialContent.anime},
      regionNote: 'Aimed at Hong Kong / Macau; per-title geo-blocks.',
    ),
    OfficialChannel(
      id: 'UC0wNSTMWIL3qaorLx0jie6A',
      name: 'Ani-One Asia',
      handle: '@AniOneAsia',
      owner: 'Ani-One (Medialink Group)',
      carries: 'Licensed Japanese anime simulcasts for Southeast Asia.',
      content: {OfficialContent.anime},
      regionNote: 'Uploads are geo-blocked to Asian markets per title.',
    ),
    OfficialChannel(
      id: 'UC45ONEZZfMDZCnEhgYmVu-A',
      name: 'Ani-One中文官方動畫頻道',
      handle: '@AniOneAnime',
      owner: 'Ani-One (Medialink Group)',
      carries: 'Licensed anime in Chinese (第11話 …), some Cantonese dubs.',
      content: {OfficialContent.anime},
      regionNote: 'Aimed at Hong Kong / Taiwan; per-title geo-blocks.',
    ),
    // ── Mediacorp (Singapore) ────────────────────────────────────────────
    // Verified: badge; mentions mewatch.
    OfficialChannel(
      id: 'UCL9njwWyBqP1JQ9T5kbxTUg',
      name: 'Mediacorp Classics',
      handle: '@MediacorpClassics',
      owner: 'Mediacorp (新传媒) - mewatch',
      carries: 'Classic Mediacorp dramas, "English 中文 EP20".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: featured by Mediacorp Classics (no badge).
    OfficialChannel(
      id: 'UCnUQ8urh9t0vlHluTJdVLTg',
      name: 'Mediacorp Drama',
      handle: '@MediacorpDrama',
      owner: 'Mediacorp (新传媒) - mewatch',
      carries: 'Mediacorp dramas (Chinese, Malay, Tamil), "English 中文 EP5".',
      content: {OfficialContent.chineseDrama},
    ),
    // ── TVB ──────────────────────────────────────────────────────────────
    OfficialChannel(
      id: 'UC6xVm161oqITVgVJ5AIW-Xw',
      name: 'TVB Anywhere (SG MY)',
      handle: '@tvbanywhere_sgmy',
      owner: 'TVB (無綫電視) - TVB Anywhere',
      carries: 'TVB dramas for Singapore and Malaysia.',
      content: {OfficialContent.hongKongDrama},
    ),
    OfficialChannel(
      id: 'UCD2SNRlEjxJODlwaKx-BoRw',
      name: 'TVB (official)',
      handle: '@TVB',
      owner: 'TVB Limited (無綫集團)',
      carries: 'Mostly highlights; occasional full classic episodes.',
      content: {OfficialContent.hongKongDrama},
    ),
    OfficialChannel(
      id: 'UC-vdzV9IVeIsp0YSCm16CkQ',
      name: 'TVB Best Drama 熱播劇場',
      handle: '@TVBBestDramaChannel',
      owner: 'TVB (無綫電視) - TVB Anywhere',
      carries: 'Full episodes of classic and recent TVB dramas ("01/25").',
      content: {OfficialContent.hongKongDrama},
      blockedRegions: {'HK', 'CN', 'MY', 'SG'},
      regionNote:
          'The channel states it is not available in Hong Kong, China, '
          'Malaysia or Singapore.',
    ),
    // Verified: badge; unlike TVB Best Drama it states no Malaysia block.
    OfficialChannel(
      id: 'UCJL8FI5LLq1G_qE5Ny-Zsqw',
      name: 'TVB Mandarin Drama 國語劇場',
      handle: '@TVBDrama',
      owner: 'TVB (無綫電視) - TVB Anywhere',
      carries: 'TVB dramas dubbed in Mandarin, "劇名｜TVB Drama 17 & 18/35".',
      content: {OfficialContent.hongKongDrama},
    ),
    // ── Taiwan ───────────────────────────────────────────────────────────
    // Verified: badge.
    OfficialChannel(
      id: 'UCt0H6f2yOF26wi_Ng8HssJQ',
      name: '三立台劇 SET Drama',
      handle: '@setdramatw',
      owner: 'SET 三立電視',
      carries: '三立 dramas, "劇名EP12｜三立台劇".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge.
    OfficialChannel(
      id: 'UC0Bp71S54Jsw9XsapPoUVFQ',
      name: '三立戲劇',
      handle: '@SETdrama',
      owner: 'SET 三立電視',
      carries: '三立 dramas, "【劇名】EP17+EP18".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge.
    OfficialChannel(
      id: 'UCiMiEL1XRXANaypB2wEdr5w',
      name: '民視戲劇館 Formosa TV Dramas',
      handle: '@FTVDRAMA',
      owner: 'FTV 民視',
      carries: '民視 dramas, "劇名 EP123".',
      content: {OfficialContent.chineseDrama},
    ),
    // Verified: badge.
    OfficialChannel(
      id: 'UCZ2EoLNz4EzAnAIKCGhiRzQ',
      name: 'GTV DRAMA 八大劇樂部',
      handle: '@gtv-drama',
      owner: 'GTV 八大電視',
      carries: '八大 dramas, "English EP.12 [MULTI SUB] | 中文".',
      content: {OfficialContent.chineseDrama},
    ),
    // ── Mainland broadcasters (third batch) ──────────────────────────────
    // Verified: badge; description names Zhejiang Radio and Television Group.
    OfficialChannel(
      id: 'UC52EYUUSlzcYqHj-qsx0RHg',
      name: 'Zhejiang STV Official Channel',
      handle: '@ZhejiangStv',
      owner: '浙江卫视 ZJSTV (Zhejiang Radio and Television Group)',
      carries: '浙江卫视 variety: 奔跑吧 Keep Running and others, full shows.',
      content: {OfficialContent.variety},
    ),
    // Verified: badge; SMG's own channel, cross-linked from SMG-Official.
    OfficialChannel(
      id: 'UCJ06BguWKS5GJsEue7u79PQ',
      name: '中国东方卫视官方频道China DragonTV Official',
      handle: '@SMGDragonTV',
      owner: '东方卫视 Dragon TV (SMG 上海广播电视台)',
      carries: '东方卫视 documentary and factual series (人间世, 真实第25小时).',
      content: {OfficialContent.documentary, OfficialContent.variety},
    ),
    // Verified: badge; SMG's own channel.
    OfficialChannel(
      id: 'UCahKjkez9olNwcpc5pZwzvg',
      name: 'SMG上海电视台官方频道 SMG Shanghai TV Official Channel',
      handle: '@SMG-Official',
      owner: 'SMG 上海广播电视台',
      carries:
          'Full variety shows marked FULL: 极限挑战, 我们的歌, 梦想改造家, '
          '这就是中国.',
      content: {OfficialContent.variety},
    ),
    // ── Licensed English-language distributors (third batch) ─────────────
    // Verified: badge; "operated by FilmRise".
    OfficialChannel(
      id: 'UC8IHAQMuiJdY6ALuhG7iU8Q',
      name: 'FilmRise Movies',
      handle: '@FilmRiseMovies',
      owner: 'FilmRise',
      carries: 'Full-length films, "Title | Full Movie".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; "operated by Radial Entertainment" (FilmRise's
    // library of 70,000 movies and episodes).
    OfficialChannel(
      id: 'UCVVXDVee0JZ2dlPYtpdTZVg',
      name: 'FilmRise Television',
      handle: '@FilmRiseTelevision',
      owner: 'Radial Entertainment (FilmRise)',
      carries:
          'Full episodes of licensed TV series (PSI Factor, The Rifleman, '
          'Iron Chef), "Title | S1E6".',
      content: {OfficialContent.tvSeries},
    ),
    // Verified: badge; "owned and operated by Crackle Plus".
    OfficialChannel(
      id: 'UCVFYikepF-avelvuIaQ_lHA',
      name: 'Popcornflix',
      handle: '@Popcornflix',
      owner: 'Popcornflix (Crackle Plus)',
      carries: 'Full-length films, "Title | FULL MOVIE | Genre".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; "owned and operated by VA Media Ltd", content "under
    // legal license (we have written contracts)".
    OfficialChannel(
      id: 'UCGBzBkV-MinlBvHBzZawfLQ',
      name: 'Movie Central',
      handle: '@MovieCentral',
      owner: 'VA Media Ltd',
      carries:
          'Licensed full-length films and mini-series, "Logline | Title | '
          'Full Movie" (also clips, which the length rule drops).',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; same owner and licence statement as Movie Central.
    OfficialChannel(
      id: 'UCvRI1Nyvj9pAyHPzX7AviWQ',
      name: 'Family Central',
      handle: '@Family_Central',
      owner: 'VA Media Ltd',
      carries: 'Licensed family and holiday films, "Logline | Full Movie".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; "owned and operated by CONTENT ROCKET LTD", content
    // "legally licensed".
    OfficialChannel(
      id: 'UC6A_LC-A5NVJ2vw9A0OjCug',
      name: 'The Midnight Screening',
      handle: '@TheMidnightScreening',
      owner: 'Content Rocket Ltd',
      carries: 'Licensed horror and thriller films, "Title FULL MOVIE".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; "Grjngo GmbH", films "legally licensed".
    OfficialChannel(
      id: 'UCyJYCQ6WaEMhdZAuPo799bA',
      name: 'Grjngo - Western Movies',
      handle: '@GrjngoWesternMovies',
      owner: 'Grjngo GmbH',
      carries: 'Licensed western films, "Title | Star | Western | English".',
      content: {OfficialContent.movie},
    ),
    // Verified: badge; "the official home for Kitchen Nightmares".
    OfficialChannel(
      id: 'UCUZzyuAlhHNP3oiuMjn7RfQ',
      name: 'Kitchen Nightmares',
      handle: '@KitchenNightmares',
      owner: 'Kitchen Nightmares (official)',
      carries:
          "Full episodes of Kitchen Nightmares and Hell's Kitchen, "
          '"... | Full Episode".',
      content: {OfficialContent.variety},
    ),
    // Verified: badge; "Quintus Studios GmbH" (all three).
    OfficialChannel(
      id: 'UCijcd0GR0fkxCAZwkiuWqtQ',
      name: 'Free Documentary',
      handle: '@FreeDocumentary',
      owner: 'Quintus Studios GmbH',
      carries: 'Full documentaries and series.',
      content: {OfficialContent.documentary},
    ),
    OfficialChannel(
      id: 'UCQtW2oz8ec8pHjjxawujNjg',
      name: 'Free Documentary - Nature',
      handle: '@FreeDocumentaryNature',
      owner: 'Quintus Studios GmbH',
      carries: 'Full nature documentaries.',
      content: {OfficialContent.documentary},
    ),
    OfficialChannel(
      id: 'UCsgPO6cNV0wBG-Og3bUZoFA',
      name: 'Free Documentary - History',
      handle: '@FreeDocumentaryHistory',
      owner: 'Quintus Studios GmbH',
      carries: 'Full history documentaries.',
      content: {OfficialContent.documentary},
    ),
    // Verified: badge; "part of the History Hit Network", Little Dot Studios.
    OfficialChannel(
      id: 'UC88lvyJe7aHZmcvzvubDFRg',
      name: 'Timeline - World History Documentaries',
      handle: '@TimelineChannel',
      owner: 'Little Dot Studios (History Hit)',
      carries:
          'History documentaries and series licensed from BBC, Channel 4, '
          'Discovery and PBS.',
      content: {OfficialContent.documentary},
    ),
    // Verified: badge; "part of the Little Dot Studios Network".
    OfficialChannel(
      id: 'UCu4XcDBdnZkV6-5z2f16M0g',
      name: 'Real Stories',
      handle: '@RealStories',
      owner: 'Little Dot Studios',
      carries: 'Full-length documentaries.',
      content: {OfficialContent.documentary},
    ),
  ];

  static final Map<String, OfficialChannel> _byId = {
    for (final c in all) c.id: c,
  };

  /// The whitelisted channel with [channelId], or null for any other channel.
  static OfficialChannel? byId(String? channelId) =>
      channelId == null ? null : _byId[channelId];

  static bool isWhitelisted(String? channelId) => byId(channelId) != null;

  /// The channels that play in [region] (an ISO country code; null or empty
  /// means unknown, which keeps every channel).
  static List<OfficialChannel> availableIn(String? region) {
    final r = region?.toUpperCase();
    if (r == null || r.isEmpty) return all;
    return [
      for (final c in all)
        if (!c.blockedRegions.contains(r)) c,
    ];
  }
}
