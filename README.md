# Lumora

**电影光影，尽在 Lumora。** 一个把电影、电视剧、动漫和直播放在一起的播放器，界面是中文的，支持 Windows、Android、Android TV 和 iPhone。

*Lumora — Luminous + Aura. A Chinese-first player for films, series, anime and live TV on Windows, Android, Android TV and iPhone.*

## 功能

- 首页、电视剧、电影、动漫分类页，按地区分排（国产剧、港剧、韩剧、国漫……），带「最近更新」和筛选（地区、类型、年份、排序）
- 中文片名、简介、演员（来自 TMDb）
- 自动挑片源：按你实际的网速选画质，原声优先
- 继续观看、下一集倒数、跳过片头片尾、选集
- 为你推荐：按你看过、收藏和点赞的内容学习口味
- 账号需要邀请码才能注册

## 下载和安装

正式版和各平台的安装教程（包括 iPhone 自签安装）会放在 [Releases](https://github.com/JTing904/Lumora/releases) 和项目网站上，整理中。

## 从源码编译

需要 [Flutter](https://flutter.dev)（3.47 或以上）。

```bash
flutter pub get
flutter run -d windows
```

在仓库根目录放一个 `.env`（已被 git 忽略）可以填入你自己的服务密钥，例如 `TMDB_API_KEY`。可以填哪些见 [docs/CUSTOM_CREDENTIALS.md](docs/CUSTOM_CREDENTIALS.md)。不要把密钥提交到仓库。

后端是 Supabase：数据表的改动在 [`supabase/migrations/`](supabase/migrations/)。app 里只有项目网址和公开的 publishable key，数据由行级安全（RLS）和服务器函数保护。

## 致谢与授权

Lumora 改自 **[ZPlay](https://github.com/tzero86/ZPlay)**（© tzero86），ZPlay 又改自 **[PlayTorrio V3](https://github.com/ayman708-UX/PlayTorrioV3)**（© 2026 Ayman, [@ayman708-UX](https://github.com/ayman708-UX)）。原项目的说明保留在 [docs/ZPLAY_README.md](docs/ZPLAY_README.md)。

本项目和它们一样，以 **GNU General Public License v3.0** 发布，完整条款见 [LICENSE](LICENSE)。

本产品使用 TMDb API，但未获 TMDb 认可或认证。Lumora 不托管任何影片，内容来自你自己添加的第三方来源。
