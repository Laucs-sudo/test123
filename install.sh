#!/bin/bash
BIN="$HOME/.local/bin"
URL="https://raw.githubusercontent.com/Laucs-sudo/test123/refs/heads/main"
mkdir -p "$BIN"

(
echo "10"; echo "# Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3 yt-dlp ffmpeg zenity

echo "40"; echo "# Downloading scripts..."
curl -s "$URL/yt-archive.py" -o "$BIN/yt-archive"
curl -s "$URL/youtubearchive.py" -o "$BIN/youtubearchive"
chmod +x "$BIN/yt-archive" "$BIN/youtubearchive"

echo "80"; echo "# Setting up PATH..."
[[ ":$PATH:" != *":$BIN:"* ]] && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

echo "100"; echo "# Installation complete!"
sleep 1
) | zenity --progress --title="yt-archiver" --auto-close --width=300

zenity --info --text="Dependencies installed. Scripts ready in $BIN. Restart your terminal." --width=300
