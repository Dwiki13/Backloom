#!/bin/bash
# verify_vertical_video.sh
# Simple script to verify vertical video properties for social media

if [ $# -ne 1 ]; then
    echo "Usage: $0 <video_file>"
    echo "Example: $0 output.mp4"
    exit 1
fi

VIDEO_FILE="$1"

if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: File '$VIDEO_FILE' not found"
    exit 1
fi

echo "Verifying vertical video properties for: $VIDEO_FILE"
echo "========================================================"

# Check dimensions
DIMENSIONS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$VIDEO_FILE" 2>/dev/null)
if [ -z "$DIMENSIONS" ]; then
    echo "❌ Could not read video dimensions"
    exit 1
fi

WIDTH=$(echo "$DIMENSIONS" | cut -d',' -f1)
HEIGHT=$(echo "$DIMENSIONS" | cut -d',' -f2)

echo "Dimensions: ${WIDTH}x${HEIGHT}"

# Check if it's vertical (height > width)
if [ "$HEIGHT" -gt "$WIDTH" ]; then
    echo "✅ Vertical orientation (height > width)"
else
    echo "❌ Not vertical orientation (height <= width)"
fi

# Check for 9:16 ratio (allowing small tolerance)
# 9:16 = 0.5625, so width/height should be ~0.5625
RATIO=$(echo "scale=4; $WIDTH / $HEIGHT" | bc -l)
TARGET_RATIO="0.5625"
TOLERANCE="0.05"

# Check if ratio is within tolerance
RATIO_MIN=$(echo "$TARGET_RATIO - $TOLERANCE" | bc -l)
RATIO_MAX=$(echo "$TARGET_RATIO + $TOLERANCE" | bc -l)

if (( $(echo "$RATIO >= $RATIO_MIN" | bc -l) )) && (( $(echo "$RATIO <= $RATIO_MAX" | bc -l) )); then
    echo "✅ Aspect ratio ~9:16 (actual: $RATIO)"
else
    echo "❌ Aspect ratio not ~9:16 (actual: $RATIO, target: ~0.5625)"
fi

# Check duration
DURATION=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO_FILE" 2>/dev/null)
if [ -z "$DURATION" ]; then
    echo "❌ Could not read duration"
else
    echo "Duration: ${DURATION} seconds"
    # Warn if too long for social media (typically 60s max for Reels/TikTok)
    if (( $(echo "$DURATION > 65" | bc -l) )); then
        echo "⚠️  Duration may be too long for social media platforms ( > 60s )"
    elif (( $(echo "$DURATION > 60" | bc -l) )); then
        echo "⚠️  Duration approaching social media limits"
    else
        echo "✅ Duration suitable for social media platforms"
    fi
fi

# Check codecs
VIDEO_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO_FILE" 2>/dev/null)
AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$VIDEO_FILE" 2>/dev/null)

echo "Video codec: ${VIDEO_CODEC:-unknown}"
echo "Audio codec: ${AUDIO_CODEC:-unknown}"

if [ "$VIDEO_CODEC" = "h264" ] || [ "$VIDEO_CODEC" = "avc1" ]; then
    echo "✅ Video codec is H.264 (social media compatible)"
else
    echo "⚠️  Video codec may not be optimal for social media (consider H.264)"
fi

if [ "$AUDIO_CODEC" = "aac" ] || [ "$AUDIO_CODEC" = "mp4a" ]; then
    echo "✅ Audio codec is AAC (social media compatible)"
else
    echo "⚠️  Audio codec may not be optimal for social media (consider AAC)"
fi

echo "========================================================"
echo "Verification complete"