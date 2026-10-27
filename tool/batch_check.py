"""Checks what 自动 would play for a list of titles, end to end, unattended.

For each title it resolves the IMDb id and runtime on TMDb, runs the live
source report (test/live/source_report_test.dart) to get every source and the
queue the picker builds, then opens the first few queued links in the app's own
libmpv (tool/mpv_check.py) until one decodes a frame. Each check stops at the
first frame, so it costs a few MB; torrents are listed but never started.

A link whose length is far from the title's runtime is flagged: that is how a
wrong title (an episode of another show, a trailer) gives itself away.

Usage:
  python -I tool/batch_check.py <out_dir> [titles.json]

Reads TMDB_API_KEY from .env in the repo root. Writes <out_dir>/summary.md and
one report JSON per title.
"""
import importlib.util
import json
import os
import subprocess
import sys
import urllib.parse
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLUTTER = os.path.join(os.path.expanduser('~'), 'flutter', 'bin', 'flutter.bat')
DLL = os.path.join(REPO, 'build', 'windows', 'x64', 'runner', 'Debug', 'libmpv-2.dll')

DEFAULT_TITLES = [
    # label, kind, query, year, season, episode
    ('Spider-Man: Brand New Day', 'movie', 'Spider-Man: Brand New Day', 2026, None, None),
    ('Superman', 'movie', 'Superman', 2025, None, None),
    ('Oppenheimer', 'movie', 'Oppenheimer', 2023, None, None),
    ('哪吒之魔童闹海', 'movie', 'Ne Zha 2', 2025, None, None),
    ('凡人修仙传 S1E1', 'tv', "A Record of a Mortal's Journey to Immortality", 2020, 1, 1),
    ('斗破苍穹 S1E1', 'tv', 'Battle Through the Heavens', 2017, 1, 1),
    ('繁花 S1E1', 'tv', '繁花', 2023, 1, 1),
    ('新闻女王 S1E1', 'tv', '新聞女王', 2023, 1, 1),
    ('Squid Game S1E1', 'tv', 'Squid Game', 2021, 1, 1),
    ('葬送的芙莉莲 S1E1', 'tv', 'Frieren: Beyond Journey\'s End', 2023, 1, 1),
    ('The Last of Us S1E1', 'tv', 'The Last of Us', 2023, 1, 1),
    ('Spider-Man: Into the Spider-Verse', 'movie', 'Spider-Man: Into the Spider-Verse', 2018, None, None),
]


def env_key():
    for line in open(os.path.join(REPO, '.env'), encoding='utf-8'):
        if line.startswith('TMDB_API_KEY='):
            return line.split('=', 1)[1].strip().strip('"').strip("'")
    raise SystemExit('TMDB_API_KEY missing from .env')


def tmdb(path, key, **params):
    headers = {}
    if key.startswith('ey'):
        headers['Authorization'] = 'Bearer ' + key
    else:
        params['api_key'] = key
    url = 'https://api.themoviedb.org/3' + path + '?' + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers=headers)
    return json.load(urllib.request.urlopen(req, timeout=20))


def resolve(key, kind, query, year, season, episode):
    params = {'query': query}
    params['year' if kind == 'movie' else 'first_air_date_year'] = year
    hits = tmdb(f'/search/{kind}', key, **params)['results']
    if not hits:
        hits = tmdb(f'/search/{kind}', key, query=query)['results']
    if not hits:
        return None
    tid = hits[0]['id']
    imdb = tmdb(f'/{kind}/{tid}/external_ids', key).get('imdb_id')
    if kind == 'movie':
        runtime = tmdb(f'/movie/{tid}', key).get('runtime')
        name = hits[0].get('title')
    else:
        try:
            runtime = tmdb(f'/tv/{tid}/season/{season}/episode/{episode}', key).get('runtime')
        except Exception:
            runtime = None
        name = hits[0].get('name')
    return {'tmdb': tid, 'imdb': imdb, 'runtime': runtime, 'name': name}


def load_mpv_check():
    spec = importlib.util.spec_from_file_location(
        'mpv_check', os.path.join(REPO, 'tool', 'mpv_check.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def run_report(meta, kind, year, season, episode, out_path, mbps):
    env = dict(os.environ)
    env.update({
        'LUMORA_TITLE': meta['name'],
        'LUMORA_ID': meta['imdb'],
        'LUMORA_TYPE': 'movie' if kind == 'movie' else 'series',
        'LUMORA_YEAR': str(year),
        'LUMORA_REPORT': out_path,
        'LUMORA_RUNTIME': str(meta['runtime'] or ''),
        'LUMORA_MBPS': str(mbps),
    })
    if season is not None:
        env['LUMORA_SEASON'] = str(season)
        env['LUMORA_EPISODE'] = str(episode)
    subprocess.run(
        [FLUTTER, 'test', '--run-skipped', '--tags', 'network',
         'test/live/source_report_test.dart'],
        cwd=REPO, env=env, capture_output=True, timeout=300)
    return json.load(open(out_path, encoding='utf-8'))


def length_ok(duration_s, runtime_min, kind):
    if not duration_s or not runtime_min:
        return None
    minutes = duration_s / 60
    slack = max(runtime_min * (0.15 if kind == 'movie' else 0.4), 8)
    return abs(minutes - runtime_min) <= slack


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    out_dir = sys.argv[1]
    titles = DEFAULT_TITLES
    if len(sys.argv) > 2:
        titles = [tuple(t) for t in json.load(open(sys.argv[2], encoding='utf-8'))]
    os.makedirs(out_dir, exist_ok=True)
    key = env_key()
    mpv = load_mpv_check()
    lib = mpv.load(DLL)
    mbps = float(os.environ.get('LUMORA_MBPS', '6'))

    lines = ['| 片名 | 片源总数 | 直连 | 自动选到 | 结果 | 首帧 | 时长核对 |',
             '|---|---|---|---|---|---|---|']
    for label, kind, query, year, season, episode in titles:
        print(f'== {label}', flush=True)
        meta = resolve(key, kind, query, year, season, episode)
        if not meta or not meta['imdb']:
            lines.append(f'| {label} | - | - | - | TMDb 找不到 IMDb 编号 | - | - |')
            continue
        safe = ''.join(c if c.isalnum() else '_' for c in meta['imdb'])
        report_path = os.path.join(out_dir, f'{safe}.json')
        try:
            report = run_report(meta, kind, year, season, episode, report_path, mbps)
        except Exception as e:  # noqa: BLE001 - report and move on
            lines.append(f'| {label} | - | - | - | 报告失败: {e} | - | - |')
            continue
        sources = report['sources']
        links = [s for s in sources if not s.get('torrent')]
        verdict, picked, secs, length = '没有片源', '-', '-', '-'
        tried = 0
        for index in report.get('queue', []):
            s = sources[index]
            if s.get('torrent'):
                picked = f"种子 · {s.get('title', '')[:40]}"
                verdict = '种子（今晚不测，省流量）'
                break
            if tried == 3:
                verdict = '前 3 个直连都播不了'
                break
            tried += 1
            result, t, detail = mpv.try_url(lib, s['url'], s.get('headers'))
            print(f'   {result:8} {t:5}s {s.get("provider")} | {s.get("title")} {detail}', flush=True)
            if result == 'plays':
                duration = None
                for part in detail.split():
                    if part.startswith('duration='):
                        try:
                            duration = float(part.split('=', 1)[1])
                        except ValueError:
                            duration = None
                ok = length_ok(duration, meta['runtime'], kind)
                picked = f"{s.get('provider')} · {s.get('quality') or '?'}"
                verdict = f'能播（第 {tried} 个）'
                secs = f'{t}s'
                length = ('✅' if ok else '⚠️ 时长不符') if ok is not None else '未知'
                if duration:
                    length += f" {duration / 60:.0f}/{meta['runtime']} 分钟"
                break
        lines.append(
            f'| {label} | {len(sources)} | {len(links)} | {picked} | {verdict} | {secs} | {length} |')
        open(os.path.join(out_dir, 'summary.md'), 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
