# yt-archiver

Automated YouTube archiving toolkit. Two commands:

- `youtubearchive` - Search for a video across 12 archive services
- `yt-archive` - Download entire channels/playlists with full metadata

## Install

One-liner install (downloads from GitHub, uses zenity for GUI dialogs):

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/yt-archiver/main/install.sh | sh
```

Replace `YOUR_USERNAME` with your GitHub username after pushing this repo.

The installer will:
1. Download the latest version from GitHub
2. Install to `~/.local/share/yt-archiver/`
3. Create `youtubearchive` and `yt-archive` commands in `~/.local/bin/`
4. Add `~/.local/bin` to your PATH if needed
5. Offer to install yt-dlp and ffmpeg if missing

## Manual Install

```bash
git clone https://github.com/YOUR_USERNAME/yt-archiver.git
cd yt-archiver
chmod +x install.sh
./install.sh
```

## Requirements

- python3 (for `youtubearchive`)
- yt-dlp (for `yt-archive`) - `pip install yt-dlp`
- ffmpeg (for `yt-archive`) - `sudo apt install ffmpeg`
- zenity (optional, for GUI dialogs during install) - `sudo apt install zenity`

## Usage: youtubearchive

Search for any YouTube video across 12 services:

```bash
youtubearchive dQw4w9WgXcQ
youtubearchive https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

Services checked:
- YouTube (still live?)
- Wayback Machine
- Archive.org Details
- Archive.org CDX (thumbnails)
- GhostArchive
- Distributed YouTube Archive
- Hobune.stream
- Filmot
- RemovedEDM
- Odysee
- PreserveTube
- Nyane.online

## Usage: yt-archive

Download entire channels or playlists with archival-quality settings:

```bash
# 1. Add channel URLs to the channels file
nano ~/.local/share/yt-archiver/channels_to_download.txt

# 2. Run the downloader
yt-archive
```

Re-run anytime to fetch only new uploads. The `downloaded_videos.txt` file tracks everything already downloaded.

### CLI Options

| Flag | Description | Default |
|------|-------------|---------|
| `-c, --channels FILE` | Path to channels/URL list | `channels_to_download.txt` |
| `-a, --archive FILE` | Download archive tracker | `downloaded_videos.txt` |
| `-d, --download-dir DIR` | Download directory | `./downloads` |
| `-f, --format FMT` | Container format (mkv, mp4) | `mkv` |
| `-o, --output TEMPLATE` | yt-dlp output template | See script |
| `-v, --verbose` | Verbose output | off |
| `-n, --dry-run` | Print command without running | off |
| `-u, --update` | Update yt-dlp before downloading | off |

### What Gets Saved

Each video downloads with:
- Video file (remuxed into MKV)
- `.info.json` metadata (needed for DYA Archive submissions)
- `.description` text file
- Thumbnail image (also embedded in video)
- All subtitles (embedded in MKV)
- Embedded metadata

### File Organization

```
downloads/
  ChannelName [UCxxxxxxx]/
    20240115 - Video Title - (360s) [1080p] [dQw4w9WgXcQ].mkv
    20240115 - Video Title - (360s) [1080p] [dQw4w9WgXcQ].info.json
    20240115 - Video Title - (360s) [1080p] [dQw4w9WgXcQ].description
```

## Configuration

Edit `~/.local/share/yt-archiver/yt-archive.conf` to set persistent defaults.
All settings are commented out by default. Uncomment what you need.

## Publishing to GitHub

```bash
cd yt-archiver
git init
git add .
git commit -m "initial commit"
gh repo create yt-archiver --public --source=. --push
```

After pushing, the curl install command will work for anyone.
