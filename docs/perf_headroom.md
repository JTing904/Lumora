# Perf headroom — 2 targets

## 1) Recently-seen service cache
- Add bounded `Map<String, List>` to `ContinueWatchingService` / `MyListService` (max 20, LRU via insertion order).
- Key = `sectionType + filter + lastWatchedAt` (stable); value = last list snapshot.
- Invalidate on `add`/`remove`/`toggle`; never touch storage (memory only).
- Reduces redundant rebuilds when the same tab is revisited.

## 2) Manga / dense-grid precache
- Bump reader precache from `current±1` to `current±2` at `2× screenWidth`.
- Keep thumb precache at 140 (`memCacheWidth`).
- Memory stays bounded (resize key is same `ResizeImage` entry).
