"""Helpers to write a Season 3 content pack from a compact Python description
(used by the scratch scripts that generated content/s3_chapter*/)."""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "content")


def L(sp, mood, t):
    assert len(t) <= 70, (t, len(t))
    return {"speaker": sp, "mood": mood, "text": t}


def write(pack, rel, data):
    path = os.path.join(ROOT, pack, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def pack(pid, title, region, levels, quests, dialogue, barks, shops=None, theme="dark", cutscenes=None):
    ch = {"id": pid, "title": title, "region": region, "theme": theme, "levels": levels, "spark": None,
          "quests": [q["id"] for q in quests], "dialogue": list(dialogue), "barks": "barks"}
    if shops:
        ch["shop"] = "shop"
        write(pid, "shop.json", {"shops": shops})
    write(pid, "chapter.json", ch)
    for q in quests:
        write(pid, "quests/%s.json" % q["id"], q)
    for npc, variants in dialogue.items():
        write(pid, "dialogue/%s.json" % npc, {"npc": npc, "variants": variants})
    write(pid, "barks.json", {"barks": barks})
    for cid, steps in (cutscenes or {}).items():
        write(pid, "cutscenes/%s.json" % cid, {"steps": steps})


def speakers(new):
    p = os.path.join(ROOT, "speakers.json")
    d = json.load(open(p))
    for k, v in new.items():
        d["speakers"].setdefault(k, {"name": v[0], "color": v[1]})
    open(p, "w").write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
