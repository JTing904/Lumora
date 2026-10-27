"""Opens stream links in the app's own libmpv and times the first decoded frame.

The liveness probe in the app (StreamHealthChecker) only reads the first bytes
of a link, and a link can pass it and still never play. This drives the same
player engine the app ships, headless (no window, no sound), so "does it play"
is answered by a decoded frame rather than by a guess.

Usage:
  python -I tool/mpv_check.py <libmpv-2.dll> <source_report.json> [filter]

<source_report.json> is what test/live/source_report_test.dart writes. Only
direct links are tried (torrents go through TorrServer). [filter] keeps sources
whose provider or title contains it, case-insensitively.
"""
import ctypes
import json
import os
import sys
import time

MPV_EVENT_SHUTDOWN = 1
MPV_EVENT_END_FILE = 7
MPV_EVENT_FILE_LOADED = 8
MPV_EVENT_PLAYBACK_RESTART = 21
END_FILE_REASON_ERROR = 4


class EndFile(ctypes.Structure):
    _fields_ = [('reason', ctypes.c_int), ('error', ctypes.c_int)]


class Event(ctypes.Structure):
    _fields_ = [
        ('event_id', ctypes.c_int),
        ('error', ctypes.c_int),
        ('reply_userdata', ctypes.c_uint64),
        ('data', ctypes.c_void_p),
    ]


def load(dll_path):
    os.add_dll_directory(os.path.dirname(os.path.abspath(dll_path)))
    lib = ctypes.CDLL(dll_path)
    lib.mpv_create.restype = ctypes.c_void_p
    lib.mpv_set_option_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
    lib.mpv_initialize.argtypes = [ctypes.c_void_p]
    lib.mpv_command.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_char_p)]
    lib.mpv_wait_event.argtypes = [ctypes.c_void_p, ctypes.c_double]
    lib.mpv_wait_event.restype = ctypes.POINTER(Event)
    lib.mpv_get_property_string.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lib.mpv_get_property_string.restype = ctypes.c_void_p
    lib.mpv_free.argtypes = [ctypes.c_void_p]
    lib.mpv_error_string.argtypes = [ctypes.c_int]
    lib.mpv_error_string.restype = ctypes.c_char_p
    lib.mpv_terminate_destroy.argtypes = [ctypes.c_void_p]
    return lib


def prop(lib, h, name):
    p = lib.mpv_get_property_string(h, name.encode())
    if not p:
        return None
    try:
        return ctypes.cast(p, ctypes.c_char_p).value.decode('utf-8', 'replace')
    finally:
        lib.mpv_free(p)


def try_url(lib, url, headers, timeout=20.0):
    """Returns (verdict, seconds, detail)."""
    h = lib.mpv_create()
    opt = lambda k, v: lib.mpv_set_option_string(h, k.encode(), v.encode())
    opt('vo', 'null')
    opt('ao', 'null')
    opt('ytdl', 'no')
    opt('network-timeout', '15')
    for k, v in (headers or {}).items():
        if k.lower() == 'user-agent':
            opt('user-agent', v)
        elif k.lower() == 'referer':
            opt('referrer', v)
        else:
            opt('http-header-fields-append', f'{k}: {v}')
    lib.mpv_initialize(h)
    args = (ctypes.c_char_p * 3)(b'loadfile', url.encode(), None)
    lib.mpv_command(h, args)
    t0 = time.time()
    verdict, detail = 'timeout', ''
    try:
        while time.time() - t0 < timeout:
            ev = lib.mpv_wait_event(h, 0.5).contents
            if ev.event_id == MPV_EVENT_END_FILE:
                ef = ctypes.cast(ev.data, ctypes.POINTER(EndFile)).contents
                if ef.reason == END_FILE_REASON_ERROR:
                    verdict = 'error'
                    detail = lib.mpv_error_string(ef.error).decode()
                else:
                    verdict = 'ended'
                break
            if ev.event_id == MPV_EVENT_SHUTDOWN:
                verdict = 'shutdown'
                break
            width = prop(lib, h, 'video-params/w')
            if width:
                pos = prop(lib, h, 'time-pos')
                dur = prop(lib, h, 'duration')
                verdict = 'plays'
                detail = f'{width}x{prop(lib, h, "video-params/h")} duration={dur} pos={pos}'
                break
        return verdict, round(time.time() - t0, 1), detail
    finally:
        lib.mpv_terminate_destroy(h)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    dll, report = sys.argv[1], sys.argv[2]
    needle = sys.argv[3].lower() if len(sys.argv) > 3 else ''
    lib = load(dll)
    data = json.load(open(report, encoding='utf-8'))
    for s in data['sources']:
        if s.get('torrent') or not s.get('url'):
            continue
        label = f"{s.get('provider') or ''} | {s.get('title') or ''}"
        if needle and needle not in label.lower():
            continue
        verdict, secs, detail = try_url(lib, s['url'], s.get('headers'))
        print(f"{verdict:8} {secs:5}s  probe={s.get('probeAlive')}  {label[:70]}  {detail}",
              flush=True)


if __name__ == '__main__':
    main()
