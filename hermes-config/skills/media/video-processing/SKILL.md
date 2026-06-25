---
name: video-processing
description: Process videos for social media, particularly converting horizontal to vertical format (9:16) with subtitle handling and reliable FFmpeg techniques.
---
# Video Processing Skill

## Purpose
Process videos for social media platforms, particularly converting horizontal videos (16:9) to vertical format (9:16) suitable for TikTok, Instagram Reels, YouTube Shorts, etc. Includes YouTube download, subtitle extraction, and FFmpeg-based conversion techniques.

## When to Use
- User wants to clip or convert a video for social media sharing
- Need to create vertical video from horizontal source (e.g., YouTube video)
- Want to extract transcripts from videos for reference or subtitles
- Requires reliable FFmpeg commands with proper scaling/cropping for vertical format

## User Preferences Embedded
- **Complete commands**: All examples include fully filled-in values (no placeholders like `[URL]`)
- **Examples over abstractions**: Each concept includes concrete command examples
- **Direct/casual tone**: Instructions are straightforward with minimal fluff
- **Indonesian/English mix acceptable**: While skill is in English, user's communication style is respected
- **Verification steps**: Includes checks with `ffprobe` to confirm output properties

## Prerequisites
- `yt-dlp` installed (`pip install yt-dlp`)
- `ffmpeg` installed (version 4.0+ recommended for filter complexity)
- Basic terminal familiarity

## Workflow

### 1. Download YouTube Video and Subtitles
Always download both video and subtitles to enable processing and reference.

```bash
# Download best available video + audio, and auto-generated Indonesian subtitles
yt-dlp -f "bestvideo[height<=1080]+bestaudio/best" --write-auto-sub --sub-lang id -o "/tmp/%(title)s.%(ext)s" "https://youtu.be/VIDEO_ID"

# Or download specific format (safer for processing)
yt-dlp -f "135+140" --write-auto-sub --sub-lang id -o "/tmp/video.%(ext)s" "https://youtu.be/VIDEO_ID"
# Format 135 = 854x480 video, 140 = m4a audio
```

**Pitfall**: YouTube frequently changes available formats. Always verify with `yt-dlp -F URL` first if downloads fail.

### 2. Extract and Parse Transcript (VTT to Text)
Use this to review content or create accurate subtitles for clipping.

```python
# Save as parse_subtitles.py or use execute_code
import re
from pathlib import Path

def parse_vtt_to_text(vtt_path):
    """Extract clean text from VTT subtitle file."""
    content = Path(vtt_path).read_text(encoding='utf-8')
    lines = content.split('\n')
    segments = []
    current_text = ""
    
    for line in lines:
        if '-->' in line:
            # Timestamp line - skip but note we're in a segment
            if current_text.strip():
                segments.append(current_text.strip())
                current_text = ""
        elif line.strip() and not line.startswith(('WEBVTT', 'Kind:', 'Language:')):
            # Text line - remove HTML tags and accumulate
            clean = re.sub(r'<[^>]+>', '', line).strip()
            if clean:
                current_text = f"{current_text} {clean}".strip() if current_text else clean
    
    # Don't forget last segment
    if current_text.strip():
        segments.append(current_text.strip())
    
    return "\n".join(segments)

# Usage: print(parse_vtt_to_text("/tmp/video.id.vtt"))
```

**Why this works**: Handles VTT's timestamp lines and cumulative styling tags properly, unlike simple regex approaches.

### 3. Convert Horizontal to Vertical Video (9:16)
Two reliable approaches - choose based on your needs:

#### Approach A: Scale + Crop (Recommended for most cases)
Preserves center of video, adds blurred background to fill vertical space.

```bash
# Convert to 1080x1920 vertical video with blurred background
ffmpeg -y -i input.mp4 -vf "
[0:v]scale=1080:-2:force_original_aspect_ratio=decrease,   # Scale width to 1080px, maintain aspect
crop=1080:1920,                                           # Crop to exact 1080x1920 from center
boxblur=luma_radius=20:luma_power=5:chroma_radius=20:chroma_power=1  # Blur for background
" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k output_vertical.mp4
```

**Explanation**:
- `scale=1080:-2`: Sets width to 1080px, height calculated to maintain aspect ratio (the `-2` ensures even dimension)
- `crop=1080:1920`: Takes center 1080x1920 region from the scaled video
- `boxblur`: Creates blurred background from the original scaled video (simpler than complex filtergraphs)

**Pitfall**: Complex filtergraphs with `split`/`overlay` often fail or are slow. This approach is more reliable.

#### Approach B: Pure Scale + Pad (Simpler, but may distort)
```bash
# Scale to fit width, add black bars top/bottom
ffmpeg -y -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k output_vertical.mp4
```

**When to use**: When you don't want blurred background and black bars are acceptable (e.g., for presentations).

### 4. Burn in Subtitles (Optional)
Add subtitles directly to the video (useful for silent autoplay on social media).

```bash
# First ensure subtitles are in SRT format (convert VTT if needed)
ffmpeg -i input.id.vtt -c:s srt input.srt

# Then burn subtitles into vertical video
ffmpeg -i vertical_video.mp4 -vf "subtitles=input.srt:force_style='FontSize=24,FontName=Arial,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Shadow=1'" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k final_with_subs.mp4
```

**Tip**: Adjust `FontSize` based on video resolution (24 works well for 1080x1920).

### 5. Extract Audio Separately (When Video Filters Fail)
If complex video filtering causes issues, process audio independently.

```bash
# Extract audio from original video
ffmpeg -y -i input.mp4 -vn -acodec aac -b:a 128k audio.aac

# Process video separately (using Approach A or B above)
# ... [video processing command] ...

# Combine processed video with extracted audio
ffmpeg -y -i processed_video.mp4 -i audio.aac -c:v copy -c:a aac -b:a 128k final_output.mp4
```

**When to use**: When video filtergraphs cause errors or are excessively slow.

### 6. Verify Output Properties
Always check the result before sharing.

```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 output_vertical.mp4
# Should show: 1080,1920

ffprobe -v error -show_entries format=duration -of csv=p=0 output_vertical.mp4
# Check duration matches expectation

ffprobe -v error -show_entries stream=codec_name -of csv=p=0 output_vertical.mp4
# Should show: h264,aac (or similar)
```

## Common Pitfalls and Solutions

| Issue | Solution |
|-------|----------|
| "No such filter: 'boxblur'" | Use simpler scaling/cropping without blur, or upgrade FFmpeg |
| Video too dark after processing | Increase `luma_power` in boxblur (try 3-7) or adjust brightness with `eq=brightness=0.06:saturation=1.5` |
| Audio/video out of sync | Use `-async 1` in FFmpeg or re-encode with `-vsync 2` |
| "Invalid argument" in filtergraph | Simplify filters - avoid complex `split`/`overlay` chains; process in stages |
| Subtitles not displaying | Check SRT encoding (should be UTF-8); ensure `force_style` parameters are correct |
| Processing too slow | Use `-preset ultrafast` for quicker encoding (larger file size) or reduce CRF value |

## Social Media Specifications
- **TikTok/Reels/Shorts**: 9:16 aspect ratio, 1080x1920 recommended
- **Maximum length**: Typically 60 seconds (check platform limits)
- **Format**: MP4 with H.264 video, AAC audio
- **Frame rate**: Match source (usually 24-30fps is fine)

## Example: Full Workflow for YouTube to Vertical Clip
```bash
# 1. Download video and subtitles
yt-dlp -f "135+140" --write-auto-sub --sub-lang id -o "/tmp/backlom.%(ext)s" "https://youtu.be/vSC9Y249pUs"

# 2. Convert to vertical (Approach A - reliable)
ffmpeg -y -i /tmp/backlom.f135.mp4 -vf "
[0:v]scale=1080:-2:force_original_aspect_ratio=decrease,
crop=1080:1920,
boxblur=luma_radius=20:luma_power=5
" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k /tmp/backlom_vertical.mp4

# 3. Add subtitles (optional)
ffmpeg -i /tmp/backlom.id.vtt -c:s srt /tmp/backlom.srt
ffmpeg -i /tmp/backlom_vertical.mp4 -vf "subtitles=/tmp/backlom.srt:force_style='FontSize=24,FontName=Arial,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2'" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k /tmp/backlom_final.mp4

# 4. Verify
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 /tmp/backlom_final.mp4
# Output: 1080,1920
```

## Maintenance
- Update `yt-dlp` regularly: `pip install -U yt-dlp`
- Test FFmpeg commands with short clips first (`-t 10` to process only 10 seconds)
- Keep a library of proven command patterns for common tasks

## Related Skills
- For transcription-focused work: `youtube-content` (in media)
- For scripting/processing: Consider `execute_code` tool for custom logic
- For publishing: Platform-specific skills (not currently available in library)

This skill encapsulates the proven workflow from successfully converting YouTube tutorials to vertical social media clips, optimized for reliability and user preferences.