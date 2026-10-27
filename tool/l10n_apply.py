"""Moves hard-coded UI strings into the ARB files.

Takes a JSON plan: {"file.dart": [[literal, key, en, zh], ...], ...}. Each
literal is the exact source text including its quotes ('Close' or "Don't");
it is replaced by `l10nCurrent().key` everywhere in that file, the en/zh
entries are added to lib/l10n/app_en.arb and app_zh.arb, the l10n import is
added when missing, and a `const` that the call made invalid is dropped.
A row with empty en and zh is a raw replacement: its key is the new text.
A fifth element, [[name, dart_expression], ...], makes the entry a message
with placeholders: en/zh use {name}, the call becomes
`l10nCurrent().key(expr, ...)` in that order, and the en ARB gets the
placeholder metadata (type Object).

`l10nCurrent()` rather than `l10nOf(context)` because it needs no context, so
the same replacement works in a build method, a callback or a field.

Usage: python -I tool/l10n_apply.py <plan.json>   (from the repo root)
Then: flutter gen-l10n && flutter analyze <files>
"""
import collections
import json
import os
import re
import sys

ARB_EN = 'lib/l10n/app_en.arb'
ARB_ZH = 'lib/l10n/app_zh.arb'


def add_arb(path, entries):
    with open(path, encoding='utf-8') as f:
        data = json.load(f, object_pairs_hook=collections.OrderedDict)
    for k, v in entries.items():
        if k in data and data[k] != v and not k.startswith('@'):
            raise SystemExit(f'{path}: key {k} already holds a different text')
        data[k] = v
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def relative_import(dart_path):
    depth = len(os.path.normpath(dart_path).split(os.sep)) - 2  # minus lib/ and the file
    return "import '" + '../' * depth + "l10n/l10n.dart';"


def drop_invalid_consts(s, key_pattern):
    # `const Text(l10nCurrent()...` and friends: the const is the nearest one
    # opening an expression that now contains a call.
    s = re.sub(r'const (\w+\(\s*)(l10nCurrent\(\))', r'\1\2', s)
    s = re.sub(r'const (\w+\(\s*\w+:\s*)(l10nCurrent\(\))', r'\1\2', s)
    s = re.sub(r'const (\w+\(\s*\w+:\s*\w+\(\s*)(l10nCurrent\(\))', r'\1\2', s)
    return s


def main():
    plan = json.load(open(sys.argv[1], encoding='utf-8'))
    en, zh = collections.OrderedDict(), collections.OrderedDict()
    for path, rows in plan.items():
        if path.startswith('_'):
            continue
        s = open(path, encoding='utf-8').read()
        for row in rows:
            literal, key, en_text, zh_text = row[:4]
            args = row[4] if len(row) > 4 else None
            if literal not in s:
                print(f'skip (not found) {path}: {literal}')
                continue
            if not en_text and not zh_text:
                # A raw replacement: [key] is the replacement text itself.
                s = s.replace(literal, key)
                continue
            if args:
                call = f'l10nCurrent().{key}(' + ', '.join(e for _, e in args) + ')'
                en['@' + key] = {'placeholders': {n: {'type': 'Object'} for n, _ in args}}
            else:
                call = f'l10nCurrent().{key}'
            s = s.replace(literal, call)
            en[key] = en_text
            zh[key] = zh_text
        s = drop_invalid_consts(s, None)
        imp = relative_import(path)
        if imp not in s:
            first = s.index('import ')
            s = s[:first] + imp + '\n' + s[first:]
        open(path, 'w', encoding='utf-8', newline='').write(s)
        print(f'done {path}: {len(rows)}')
    add_arb(ARB_EN, en)
    add_arb(ARB_ZH, zh)


if __name__ == '__main__':
    main()
