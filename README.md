# Lumora

**电影光影，尽在 Lumora。** 一个把电影、电视剧、动漫和直播放在一起的播放器，界面是中文的，支持 Windows、Android、Android TV 和 iPhone。

*Lumora — Luminous + Aura. A Chinese-first player for films, series, anime and live TV on Windows, Android, Android TV and iPhone.*

## 功能

- 首页、电视剧、电影、动漫分类页，按地区分排（国产剧、港剧、韩剧、国漫……），带「最近更新」和筛选（地区、类型、年份、排序）
- 中文片名、简介、演员（来自 TMDb）
- 自动挑片源：按你实际的网速选画质，原声优先
- 继续观看、下一集倒数、跳过片头片尾、选集
- 为你推荐：按你看过、收藏和点赞的内容学习口味
- 新集提醒：收藏的剧有新一集时会标出来，首页有「新集上线」，追剧日历只显示你的剧
- 个人资料：昵称、头像照片或颜色，跟着帐号走
- 观看记录和收藏在多台设备之间合并同步
- 漫画、书籍（EPUB / PDF）、音乐和有声书
- 中文 / English 一键切换，每个按钮都能用电视遥控器操作
- 账号需要邀请码才能注册

## 下载和安装

最新版本在 [Releases](https://github.com/JTing904/Lumora/releases/latest)，安装教程和常见问题在[项目网站](https://jting904.github.io/Lumora/)。

| 文件 | 适用 |
|---|---|
| `Lumora-<版本>-Windows-Setup.exe` | Windows 安装版 |
| `Lumora-<版本>-Windows-Portable.zip` | Windows 免安装版 |
| `Lumora-<版本>-Android-arm64.apk` | 大部分安卓手机、平板和电视 |
| `Lumora-<版本>-Android-armv7.apk` | 较旧的安卓设备、便宜的电视盒子 |
| `Lumora-<版本>-Android-x86_64.apk` | 安卓模拟器 |

app 打开时会自动检查有没有新版本。每个版本附带 `SHA256SUMS` 和它的签名 `SHA256SUMS.sig`，app 内更新会先验证签名再安装。iPhone 版之后推出。

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
