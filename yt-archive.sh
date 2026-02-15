#!/usr/bin/env bash
# yt-archive.sh
# Automated YouTube archiver using yt-dlp.
# Downloads entire channels/playlists with full metadata for archival purposes.
# Supports first-run and incremental updates via download archive tracking.

set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults (override via flags or config file)
CHANNELS_FILE="${SCRIPT_DIR}/channels_to_download.txt"
ARCHIVE_FILE="${SCRIPT_DIR}/downloaded_videos.txt"
DOWNLOAD_DIR="${SCRIPT_DIR}/downloads"
CONFIG_FILE="${SCRIPT_DIR}/yt-archive.conf"

# yt-dlp output template
OUTPUT_TEMPLATE='%(uploader)s [%(channel_id)s]/%(upload_date)s - %(title).64s - (%(duration)ss) [%(resolution)s] [%(id)s].%(ext)s'

# Sleep intervals between downloads (avoids rate limiting)
MIN_SLEEP=1
MAX_SLEEP=15
THROTTLE_RATE="100K"

# Container format
REMUX_FORMAT="mkv"

# Verbosity
VERBOSE=false

# ─── Colors ──────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# ─── Functions ───────────────────────────────────────────────────────────────

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║          YT-ARCHIVE TOOL v1.0            ║"
    echo "║   Automated YouTube Channel Archiver     ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Automated YouTube channel/playlist archiver using yt-dlp.

OPTIONS:
  -c, --channels FILE     Path to channels file (one URL per line)
                          Default: ./channels_to_download.txt
  -a, --archive FILE      Path to download archive file (tracks downloaded videos)
                          Default: ./downloaded_videos.txt
  -d, --download-dir DIR  Directory to save downloads
                          Default: ./downloads
  -f, --format FMT        Remux container format (mkv, mp4)
                          Default: mkv
  -o, --output TEMPLATE   Output filename template
  -v, --verbose           Enable verbose output
  -n, --dry-run           Show the yt-dlp command without running it
  -u, --update            Update yt-dlp before downloading
  -h, --help              Show this help message

FIRST RUN:
  1. Add channel/playlist URLs to channels_to_download.txt (one per line)
  2. Run: ./yt-archive.sh

UPDATING:
  Re-run the same command. The archive file tracks already-downloaded
  videos, so only new content gets fetched.

EXAMPLES:
  ./yt-archive.sh
  ./yt-archive.sh -c my_channels.txt -d /mnt/storage/youtube
  ./yt-archive.sh --update --verbose
  ./yt-archive.sh --dry-run
EOF
}

check_dependency() {
    local cmd="$1"
    local install_hint="$2"

    if ! command -v "$cmd" &>/dev/null; then
        log_error "'$cmd' is not installed or not in PATH."
        log_error "Install it: $install_hint"
        return 1
    fi
    log_info "'$cmd' found: $(command -v "$cmd")"
    return 0
}

check_dependencies() {
    log_info "Checking dependencies..."
    local missing=0

    check_dependency "yt-dlp" "pip install yt-dlp  OR  https://github.com/yt-dlp/yt-dlp" || missing=1
    check_dependency "ffmpeg" "https://ffmpeg.org/download.html  OR  sudo apt install ffmpeg" || missing=1
    check_dependency "ffprobe" "Installed with ffmpeg" || missing=1

    if [ "$missing" -eq 1 ]; then
        echo ""
        log_error "Missing dependencies. Install them and try again."
        exit 1
    fi

    echo ""
    log_info "yt-dlp version: $(yt-dlp --version)"
    log_info "ffmpeg version: $(ffmpeg -version 2>&1 | head -1)"
    echo ""
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading config from: $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi
}

validate_channels_file() {
    if [ ! -f "$CHANNELS_FILE" ]; then
        log_warn "Channels file not found: $CHANNELS_FILE"
        log_info "Creating a template channels file..."

        cat > "$CHANNELS_FILE" <<'TEMPLATE'
# yt-archive: Channel/Playlist URLs
# Add one URL per line. Lines starting with # are ignored.
#
# Examples:
# https://www.youtube.com/@ChannelName
# https://www.youtube.com/channel/UCxxxxxxxxxxxxxxxxxxxxxxxxx
# https://www.youtube.com/playlist?list=PLxxxxxxxxxxxxxxxxxxxxxxxxx
#
# Add your URLs below:
TEMPLATE
        log_info "Template created at: $CHANNELS_FILE"
        log_info "Add your channel/playlist URLs to that file, then re-run this script."
        exit 0
    fi

    # Count non-empty, non-comment lines
    local url_count
    url_count=$(grep -cve '^\s*$' -e '^\s*#' "$CHANNELS_FILE" 2>/dev/null || echo 0)

    if [ "$url_count" -eq 0 ]; then
        log_error "No URLs found in $CHANNELS_FILE"
        log_error "Add at least one channel or playlist URL (one per line)."
        exit 1
    fi

    log_info "Found $url_count URL(s) in channels file."
}

build_command() {
    local cmd=()

    cmd+=(yt-dlp)

    # Archive tracking
    cmd+=(--download-archive "$ARCHIVE_FILE")

    # Continue on errors
    cmd+=(-i)

    # Output path and template
    cmd+=(-P "$DOWNLOAD_DIR")
    cmd+=(-o "$OUTPUT_TEMPLATE")

    # Container
    cmd+=(--remux-video "$REMUX_FORMAT")

    # Metadata
    cmd+=(--write-info-json)
    cmd+=(--write-description)
    cmd+=(--write-thumbnail)
    cmd+=(--embed-metadata)
    cmd+=(--write-playlist-metafiles)

    # Subtitles
    cmd+=(--write-subs)
    cmd+=(--all-subs)
    cmd+=(--embed-subs)

    # Thumbnail embedding
    cmd+=(--embed-thumbnail)

    # Rate limiting / throttle protection
    cmd+=(--min-sleep-interval "$MIN_SLEEP")
    cmd+=(--max-sleep-interval "$MAX_SLEEP")
    cmd+=(--throttled-rate "$THROTTLE_RATE")

    # DASH manifest
    cmd+=(--youtube-include-dash-manifest)

    # Batch file
    cmd+=(--batch-file="$CHANNELS_FILE")

    # Verbose
    if [ "$VERBOSE" = true ]; then
        cmd+=(--verbose)
    fi

    echo "${cmd[@]}"
}

run_download() {
    mkdir -p "$DOWNLOAD_DIR"

    log_info "Download directory: $DOWNLOAD_DIR"
    log_info "Archive file:      $ARCHIVE_FILE"
    log_info "Channels file:     $CHANNELS_FILE"
    log_info "Output template:   $OUTPUT_TEMPLATE"
    log_info "Container format:  $REMUX_FORMAT"
    echo ""

    local cmd
    cmd=$(build_command)

    log_info "Running command:"
    echo -e "${CYAN}$cmd${NC}"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warn "Dry run mode. No downloads will start."
        return 0
    fi

    # Track start time
    local start_time
    start_time=$(date +%s)

    # Run yt-dlp
    eval "$cmd"
    local exit_code=$?

    local end_time
    end_time=$(date +%s)
    local elapsed=$(( end_time - start_time ))
    local minutes=$(( elapsed / 60 ))
    local seconds=$(( elapsed % 60 ))

    echo ""
    if [ "$exit_code" -eq 0 ]; then
        log_info "Download complete. Time elapsed: ${minutes}m ${seconds}s"
    else
        log_warn "yt-dlp exited with code $exit_code. Some downloads may have failed."
        log_warn "Time elapsed: ${minutes}m ${seconds}s"
        log_info "Re-run this script to retry failed downloads."
    fi

    # Stats
    if [ -f "$ARCHIVE_FILE" ]; then
        local total
        total=$(wc -l < "$ARCHIVE_FILE")
        log_info "Total archived videos: $total"
    fi
}

update_ytdlp() {
    log_info "Updating yt-dlp..."
    if command -v pip &>/dev/null; then
        pip install --upgrade yt-dlp
    elif command -v pip3 &>/dev/null; then
        pip3 install --upgrade yt-dlp
    else
        yt-dlp -U
    fi
    echo ""
}

# ─── Main ────────────────────────────────────────────────────────────────────

DRY_RUN=false
UPDATE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--channels)
            CHANNELS_FILE="$2"
            shift 2
            ;;
        -a|--archive)
            ARCHIVE_FILE="$2"
            shift 2
            ;;
        -d|--download-dir)
            DOWNLOAD_DIR="$2"
            shift 2
            ;;
        -f|--format)
            REMUX_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_TEMPLATE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -u|--update)
            UPDATE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

print_banner
load_config
check_dependencies

if [ "$UPDATE" = true ]; then
    update_ytdlp
fi

validate_channels_file
run_download
