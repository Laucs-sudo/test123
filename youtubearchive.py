#!/usr/bin/env python3
import sys, re, urllib.request, json
from concurrent.futures import ThreadPoolExecutor

def get_id(text):
    m = re.search(r'v=([a-zA-Z0-9_-]{11})|^([a-zA-Z0-9_-]{11})$', text)
    return m.group(1) or m.group(2) if m else None

def check(name, url_fmt, vid):
    try:
        url = url_fmt.format(vid)
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=5) as r:
            if r.status == 200: return name, url
    except: pass
    return name, None

services = [
    ("YouTube", "https://www.youtube.com/watch?v={}"),
    ("Wayback", "https://archive.org/wayback/available?url=youtube.com/watch?v={}"),
    ("ArchiveDetails", "https://archive.org/details/youtube-{}"),
    ("GhostArchive", "https://ghostarchive.org/varchive/{}"),
    ("Hobune", "https://hobune.stream/videos/{}"),
    ("Odysee", "https://api.odysee.com/yt/resolve?video_ids={}")
]

def main():
    if len(sys.argv) < 2: return
    vid = get_id(sys.argv[1])
    if not vid: return
    
    print(f"Searching {vid}...")
    with ThreadPoolExecutor() as p:
        runs = [p.submit(check, s[0], s[1], vid) for s in services]
        for f in runs:
            name, url = f.result()
            if url: print(f"[FOUND] {name}: {url}")

if __name__ == "__main__":
    main()