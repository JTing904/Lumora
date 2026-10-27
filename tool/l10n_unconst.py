"""Drops the `const` keywords that moved strings made invalid.

After tool/l10n_apply.py replaces a literal inside `const Text('x')`,
`const [...]` or a const constructor, the analyzer reports the expression as
not constant. This reads `flutter analyze` output, and for each such error
removes the nearest `const ` before the reported position, then runs again
until none are left.

Usage: python -I tool/l10n_unconst.py <dart files or dirs...>
"""
import os
import re
import subprocess
import sys

CODES = (
    'const_with_non_constant_argument',
    'non_constant_list_element',
    'non_constant_map_element',
    'non_constant_map_value',
    'invalid_constant',
    'const_initialized_with_non_constant_value',
    'const_eval_method_invocation',
    'non_constant_default_value',
)
LINE = re.compile(r'- (lib[/\\][^ ]+\.dart):(\d+):(\d+) - (\w+)')


def analyze(targets):
    out = subprocess.run(
        [os.environ.get('FLUTTER', 'flutter'), 'analyze', '--no-pub', *targets],
        capture_output=True, text=True, shell=True,
    ).stdout
    return [m for m in LINE.finditer(out) if m.group(4) in CODES]


def main():
    targets = sys.argv[1:] or ['lib']
    for _ in range(10):
        errors = analyze(targets)
        if not errors:
            print('clean')
            return
        by_file = {}
        for m in errors:
            by_file.setdefault(m.group(1), []).append((int(m.group(2)), int(m.group(3))))
        for path, spots in by_file.items():
            src = open(path, encoding='utf-8', newline='').read()
            lines = src.split('\n')
            starts = [0]
            for ln in lines:
                starts.append(starts[-1] + len(ln) + 1)
            # Later positions first, so earlier offsets stay valid.
            for line, col in sorted(set(spots), reverse=True):
                pos = starts[line - 1] + col - 1
                i = src.rfind('const ', 0, pos + 1)
                if i < 0:
                    continue
                src = src[:i] + src[i + len('const '):]
            open(path, 'w', encoding='utf-8', newline='').write(src)
            print(f'{path}: {len(spots)}')
    print('still not clean after 10 passes')


if __name__ == '__main__':
    main()
