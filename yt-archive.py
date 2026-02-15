#!/usr/bin/env python3
import subprocess, re, sys, os

def run():
    channels = os.path.expanduser("~/.yt-channels.txt")
    archive = os.path.expanduser("~/.yt-archive.txt")
    folder = os.path.expanduser("~/Downloads/YouTube")
    
    if not os.path.exists(channels):
        with open(channels, "w") as f: f.write("https://www.youtube.com/@RickAstley")
    
    cmd = [
        "yt-dlp", "--newline", "--progress",
        "--download-archive", archive,
        "-P", folder,
        "-o", "%(uploader)s/%(title)s.%(ext)s",
        "--batch-file", channels
    ]
    
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    zen = subprocess.Popen(["zenity", "--progress", "--title=Archiver", "--text=Starting", "--auto-close"], stdin=subprocess.PIPE, text=True)

    for line in proc.stdout:
        print(line, end="")
        match = re.search(r'([0-9.]+)% of\s+([0-9.]+)([a-zA-Z]+)', line)
        if match:
            p, total, unit = float(match.group(1)), float(match.group(2)), match.group(3)
            left = total * (1 - p / 100)
            zen.stdin.write(f"{int(p)}\n# {p}% ({left:.1f}{unit} left)\n")
            zen.stdin.flush()
    
    proc.wait()
    zen.stdin.close()
    zen.wait()

if __name__ == "__main__":
    run()
