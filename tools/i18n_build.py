#!/usr/bin/env python3
"""translations/strings.json -> translations/en.po (msgid = Turkish source,
msgstr = English). Godot loads .po files listed in project.godot
[internationalization] locale/translations."""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\t", "\\t")


def main():
    d = json.load(open(os.path.join(ROOT, "translations", "strings.json"), encoding="utf-8"))
    out = ['msgid ""', 'msgstr ""', '"Content-Type: text/plain; charset=UTF-8\\n"', '"Language: en\\n"', ""]
    n = 0
    for k in sorted(d):
        v = d[k]
        if not v or v == k:
            continue
        out += ['msgid "%s"' % esc(k), 'msgstr "%s"' % esc(v), ""]
        n += 1
    open(os.path.join(ROOT, "translations", "en.po"), "w", encoding="utf-8").write("\n".join(out))
    print(n, "translations")


if __name__ == "__main__":
    main()
