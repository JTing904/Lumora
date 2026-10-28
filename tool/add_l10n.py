"""Adds strings to lib/l10n/app_en.arb and app_zh.arb, safely while other
editors do the same, then regenerates the Dart localizations.

    python tool/add_l10n.py strings.json

strings.json:
    {"myKey": {"en": "Hello {name}", "zh": "你好 {name}", "placeholders": ["name"]},
     "otherKey": {"en": "Plain", "zh": "普通"}}

Existing keys are replaced. Keys must be lowerCamelCase and new to this
feature (prefix them with the feature, e.g. mangaReaderTitle).
"""
import collections
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOCK = os.path.join(ROOT, '.dart_tool', 'add_l10n.lock')


def main():
    new = json.load(open(sys.argv[1], encoding='utf-8'))
    os.makedirs(os.path.dirname(LOCK), exist_ok=True)
    for _ in range(600):
        try:
            os.mkdir(LOCK)
            break
        except FileExistsError:
            time.sleep(0.5)
    else:
        sys.exit('could not take the l10n lock')
    try:
        for lang in ('en', 'zh'):
            path = os.path.join(ROOT, 'lib', 'l10n', f'app_{lang}.arb')
            d = json.load(open(path, encoding='utf-8'),
                          object_pairs_hook=collections.OrderedDict)
            for key, v in new.items():
                d[key] = v[lang]
                if lang == 'en' and v.get('placeholders'):
                    d['@' + key] = {'placeholders': {
                        p: {'type': 'String'} for p in v['placeholders']}}
            with open(path, 'w', encoding='utf-8', newline='\n') as f:
                json.dump(d, f, ensure_ascii=False, indent=2)
                f.write('\n')
        flutter = os.path.join(os.path.expanduser('~'), 'flutter', 'bin',
                               'flutter.bat' if os.name == 'nt' else 'flutter')
        subprocess.run([flutter, 'gen-l10n'], cwd=ROOT, check=True,
                       stdout=subprocess.DEVNULL)
        print('added', ', '.join(new))
    finally:
        os.rmdir(LOCK)


if __name__ == '__main__':
    main()
