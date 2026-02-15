#!/bin/bash
BIN="$HOME/.local/bin"
URL="https://raw.githubusercontent.com/Laucs-sudo/test123/main"
mkdir -p "$BIN"

(
echo "25"; echo "# Downloading scripts..."
curl -s "$URL/yt-archive.py" -o "$BIN/yt-archive"
curl -s "$URL/youtubearchive.py" -o "$BIN/youtubearchive"
chmod +x "$BIN/yt-archive" "$BIN/youtubearchive"

echo "75"; echo "# Setting up PATH..."
[[ ":$PATH:" != *":$BIN:"* ]] && echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

echo "100"; echo "# Installation complete!"
sleep 1
) | zenity --progress --title="yt-archiver" --auto-close --width=300

zenity --info --text="Installed to $BIN. Restart your terminal to use the commands." --width=300
