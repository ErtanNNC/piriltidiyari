#!/usr/bin/env python3
"""Pull single files out of Godot's ~1.3 GB export-template archive (.tpz)
with HTTP range requests, without downloading the whole archive.

  tools/fetch_template.py 4.7.2-stable web_nothreads_release.zip [more names...]

Files land in ~/.local/share/godot/export_templates/<version>/.
"""
import os
import struct
import sys
import time
import urllib.request
import zlib

ver = sys.argv[1]
names = sys.argv[2:]
url = "https://github.com/godotengine/godot/releases/download/%s/Godot_v%s_export_templates.tpz" % (ver, ver)
dest = os.path.expanduser("~/.local/share/godot/export_templates/%s" % ver.replace("-", "."))
os.makedirs(dest, exist_ok=True)


def fetch(start, end, tries=6):
    """Range GET with retries; returns (bytes, total archive size)."""
    for i in range(tries):  # GitHub sometimes answers 5xx for a moment
        try:
            req = urllib.request.Request(url, headers={"Range": "bytes=%d-%d" % (start, end)})
            with urllib.request.urlopen(req, timeout=120) as r:
                total = int(r.headers.get("Content-Range", "/0").rsplit("/", 1)[1])
                return r.read(), total
        except Exception as e:
            if i == tries - 1:
                raise
            print("yeniden deneniyor (%s)" % e, file=sys.stderr)
            time.sleep(5 * (i + 1))


def get(start, end):
    return fetch(start, end)[0]


# total size (from the Content-Range of a 1-byte read; retried like the rest)
size = fetch(0, 0)[1]
tail = get(max(0, size - 65536 - 22), size - 1)
eocd = tail.rfind(b"PK\x05\x06")
cd_size, cd_off = struct.unpack_from("<II", tail, eocd + 12)
cd = get(cd_off, cd_off + cd_size - 1)
pos = 0
entries = {}
while pos < len(cd):
    (sig, _, _, _, method, _, _, crc, csize, usize, nlen, xlen, clen, _, _, _, off) = struct.unpack_from("<IHHHHHHIIIHHHHHII", cd, pos)
    name = cd[pos + 46:pos + 46 + nlen].decode()
    entries[name] = (method, csize, usize, off)
    pos += 46 + nlen + xlen + clen
for n in names + ["version.txt"]:
    key = "templates/" + n
    if key not in entries:
        sys.exit("bulunamadı: " + key)
    method, csize, usize, off = entries[key]
    head = get(off, off + 29)
    nlen, xlen = struct.unpack_from("<HH", head, 26)
    start = off + 30 + nlen + xlen
    data = get(start, start + csize - 1)
    if method == 8:
        data = zlib.decompress(data, -15)
    with open(os.path.join(dest, n), "wb") as f:
        f.write(data)
    print("%s (%d KB)" % (n, len(data) // 1024))
