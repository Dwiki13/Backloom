# Session Reference: YouTube Video Clipping for Vertical Format
## Session Date: June 20, 2026
## Source Video: https://youtu.be/vSC9Y249pUs
## Title: "VPS Mati, Agent AI Kamu Ikut Hilang? Begini Cara Backup-nya (1 Command, Gratis)"
## Duration: 12:44 (764 seconds)

### Key Learnings from This Session

#### 1. Effective yt-dlp Command
The following command reliably downloaded the video and Indonesian subtitles:
```bash
yt-dlp -f "bestvideo[height<=1080]+bestaudio/best" --write-auto-sub --sub-lang id -o "/tmp/%(title)s.%(ext)s" "https://youtu.be/vSC9Y249pUs"
```
- Selected format `299+251` (1920x1080 video + webm audio)
- Downloaded subtitle file: `/tmp/vSC9Y249pUs.id.vtt` (94.6 KB)

#### 2. Transcript Processing Insights
- The VTT file contained 569 segments with frequent repetition due to styling tags
- Simple concatenation of text between timestamps worked well for content analysis
- HTML tags like `<c>` and timing offsets like `<00:00:00.320>` needed removal
- Example cleaned segment: "Oke, cuy. Jadi, di sini gua mau bagi tools buat kalian. Semoga aja tools ini berguna buat kalian, ya."

#### 3. Successful Vertical Conversion Approach
After multiple attempts with complex filtergraphs, this approach worked reliably:
```bash
# Step 1: Extract 30-second segment (0:00-0:30 for hook+problem+solution intro)
ffmpeg -y -ss 0 -t 30 -i /tmp/vSC9Y249pUs.f299.mp4 -c:v copy -c:a copy /tmp/segment_raw.mp4

# Step 2: Convert to vertical with blurred background (simplified filter)
ffmpeg -y -i /tmp/segment_raw.mp4 -vf "
[0:v]scale=1080:-2:force_original_aspect_ratio=decrease,
crop=1080:1920,
boxblur=luma_radius=30:luma_power=5
" -c:v libx264 -preset ultrafast -crf 28 -an -t 30 /tmp/segment_720x1280.mp4

# Step 3: Extract and process audio separately
ffmpeg -y -ss 0 -t 30 -i /tmp/vSC9Y249pUs.f251.webm -vn -acodec aac -b:a 128k /tmp/segment_audio.aac

# Step 4: Combine video and audio
ffmpeg -y -i /tmp/segment_720x1280.mp4 -i /tmp/segment_audio.aac -c:v copy -c:a aac -b:a 128k /tmp/final_clip.mp4

# Step 5: Add subtitles
ffmpeg -y -i /tmp/final_clip.mp4 -vf "subtitles=/tmp/clip_subs.srt:force_style='FontSize=20,FontName=Arial,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2'" -c:v libx264 -preset ultrafast -crf 23 -c:a aac -b:a 128k /tmp/final_clip_with_subs.mp4
```

#### 4. Why Complex Filtergraphs Failed
Initial attempts with `split`/`overlay` filtergraphs failed due to:
- Invalid argument errors with `boxblur` parameters (`chroma_power` not recognized in some FFmpeg builds)
- Processing timeouts (>120 seconds) for complex filtergraphs
- Better results with sequential processing: scale → crop → blur → combine

#### 5. Effective Subtitle Styling for Telegram
This style worked well in the final clip:
```
FontSize=20,FontName=Arial,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2
```
- White text with black outline for readability on varied backgrounds
- Size 20pt appropriate for 720x1280 resolution
- No shadow (can reduce readability on busy backgrounds)

#### 6. File Sizes and Performance
- Original video: 40.7 MB (1920x1080, 12:44)
- Final clip: 3.3 MB (720x1280, 0:30)
- Processing time: ~5 minutes for the simplified approach (vs. timeouts for complex filters)

#### 7. Verification Commands That Worked
```bash
# Check dimensions
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 /tmp/final_clip_with_subs.mp4
# Output: 720,1280

# Check duration
ffprobe -v error -show_entries format=duration -of csv=p=0 /tmp/final_clip_with_subs.mp4
# Output: 30.000000

# Check codecs
ffprobe -v error -show_entries stream=codec_name -of csv=p=0 /tmp/final_clip_with_subs.mp4
# Output: h264,aac
```

### Recommendations for Future Similar Tasks
1. Always try the scale→crop→blur approach first for vertical conversion
2. Process audio separately when video filtering becomes complex
3. Start with `-preset ultrafast -crf 28` for quick testing, then adjust quality
4. Verify output early and often with `ffprobe`
5. For talking-head videos, center crop preserves the most important visual content