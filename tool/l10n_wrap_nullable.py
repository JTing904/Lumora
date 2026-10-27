"""Wraps nullable placeholder arguments as interpolations.

An ARB placeholder of type Object takes no null, but the strings moved out of
the code interpolated nullable values ('$x' prints "null"). The analyzer's
argument_type_not_assignable errors name each such argument's position; the
argument there becomes '${expr}', which prints exactly what the original
interpolation did.

Usage: python -I tool/l10n_wrap_nullable.py [paths...]   (FLUTTER may name flutter)
"""
import os
import re
import subprocess
import sys

LINE = re.compile(r"can't be assigned to the parameter type 'Object'\.\s+- (lib[/\\][^ ]+\.dart):(\d+):(\d+) - argument_type_not_assignable")


def arg_end(src, i):
    depth, quote = 0, None
    while i < len(src):
        c = src[i]
        if quote:
            if c == '\\':
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in '\'"':
            quote = c
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            if depth == 0:
                return i
            depth -= 1
        elif c == ',' and depth == 0:
            return i
        i += 1
    return i


def main():
    targets = sys.argv[1:] or ['lib']
    out = subprocess.run([os.environ.get('FLUTTER', 'flutter'), 'analyze', '--no-pub', *targets],
                         capture_output=True, text=True, shell=True).stdout
    spots = {}
    for m in LINE.finditer(out):
        spots.setdefault(m.group(1), []).append((int(m.group(2)), int(m.group(3))))
    for path, items in spots.items():
        src = open(path, encoding='utf-8', newline='').read()
        starts = [0]
        for ln in src.split('\n'):
            starts.append(starts[-1] + len(ln) + 1)
        for line, col in sorted(set(items), reverse=True):
            a = starts[line - 1] + col - 1
            b = arg_end(src, a)
            expr = src[a:b].strip()
            src = src[:a] + "'${" + expr + "}'" + src[b:]
        open(path, 'w', encoding='utf-8', newline='').write(src)
        print(path, len(items))


if __name__ == '__main__':
    main()
