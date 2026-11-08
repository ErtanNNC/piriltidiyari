#!/usr/bin/env python3
"""Collect every player-facing Turkish string (content JSON + GDScript
literals) into translations/strings.json: {"tr text": "english or ''"}.
Existing translations are kept; new strings come in empty.

  python3 tools/i18n_extract.py        # then fill the empty ones
  python3 tools/i18n_build.py          # writes translations/en.po
"""
import glob
import json
import os
import re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "translations", "strings.json")
KEYS = {"text", "name", "title", "desc", "say", "species", "line", "special", "world", "story",
        "signature", "region", "card", "trees", "turn_in", "short", "hint", "label", "subtitle", "caption"}
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')
SKIP_LINE = re.compile(r"^\s*(print|push_warning|push_error|assert)\(|^\s*#|^\s*##")


def wanted(s):
    if len(s) < 2 or not re.search(r"[A-Za-zÇĞİÖŞÜçğıöşü]", s):
        return False
    if re.match(r"^#[0-9a-fA-F]{3,8}$", s):
        return False  # colors
    if re.search(r"res://|user://|^[a-z0-9_./:%-]+$|\.(gd|json|png|glb|wav|ogg|tscn)$", s):
        return False  # ids, paths, node names in lowercase
    if re.match(r"^[A-Z][A-Za-z0-9]*$", s) and not re.search(r"[çğıöşüÇĞİÖŞÜ]", s):
        # CamelCase node/class names (Rig, Pose, HeldTool) unless clearly Turkish
        return s in TURKISH_SINGLE
    return True


TURKISH_SINGLE = {"Aksesuar", "Alet", "Aletler", "Bak", "Baloncuk", "Buton", "Can", "Dolap", "Gir", "Kalkan",
                  "Kaydedilemedi", "Kedi", "Liman", "Renk", "Sincap", "Uykuya", "Yok", "Yolculukta", "Yuvarlan","Vur", "Yak", "Geri", "Evet", "Sil", "Kaydet", "Devam", "At", "Kombo", "Mola", "Kapat",
                  "Pati", "Davetiye", "Ninni", "Nefes", "Pamuk", "Toprak", "Pofu", "Paytak", "Minik", "Kor", "Vrakvrak", "Oyna", "Seviye", "Hediye", "Konuş", "Al", "Aç", "Oku", "Bin", "Git", "Tamam", "Ses", "Müzik"}


def from_content(found):
    for f in sorted(glob.glob(os.path.join(ROOT, "content", "**", "*.json"), recursive=True)):
        def walk(o, k=None):
            if isinstance(o, dict):
                for kk, v in o.items():
                    # keepers_s2.json "lines": {keeper id: line}
                    walk(v, "line" if k == "lines" else kk)
            elif isinstance(o, list):
                for v in o:
                    walk(v, None if isinstance(v, dict) else k)
            elif isinstance(o, str) and k in KEYS and wanted(o):
                found.setdefault(o, os.path.relpath(f, ROOT))
        walk(json.load(open(f, encoding="utf-8")))


def from_code(found):
    for f in sorted(glob.glob(os.path.join(ROOT, "src", "**", "*.gd"), recursive=True)):
        if f.endswith(("model_preview.gd", "dev_tools.gd")):
            continue
        for line in open(f, encoding="utf-8"):
            if SKIP_LINE.match(line) or "find_child" in line or "get_node" in line or "has_node" in line:
                continue
            for m in LIT.finditer(line):
                s = m.group(1).encode().decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in m.group(1) else m.group(1)
                if wanted(s):
                    found.setdefault(s, os.path.relpath(f, ROOT))


def main():
    import sys
    found = {}
    from_content(found)
    from_code(found)
    old = json.load(open(OUT, encoding="utf-8")) if os.path.exists(OUT) else {}
    data = {k: old.get(k, "") for k in found}
    if "--check" in sys.argv:
        # tests: every player-facing string must have an English line
        missing = [k for k, v in data.items() if not v]
        for k in missing[:20]:
            print("çevirisi yok:", k)
        sys.exit(1 if missing else 0)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(data, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1, sort_keys=True)
    src = {}
    for k, f in found.items():
        src.setdefault(f, []).append(k)
    json.dump(src, open(os.path.join(ROOT, "translations", "sources.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(len(data), "strings,", sum(1 for v in data.values() if not v), "untranslated")


if __name__ == "__main__":
    main()
