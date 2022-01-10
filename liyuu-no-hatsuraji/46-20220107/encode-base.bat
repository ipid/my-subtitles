
@echo off
chcp 65001
call settings.bat
set ENCODE_VIDEO_MODE=base

if not exist audio_AAC.mp4 (
    ffmpeg -i "%ORIGINAL_AUDIO_VIDEO_PATH%" -map 0:a:0 -c:a libfdk_aac -b:a 320K audio_AAC.mp4
)

vspipe -y video.vpy - | ffmpeg -y -i pipe: -map 0:v:0 -c:v libx264 -preset:v veryfast -crf:v 24 -x264opts "keyint=9999:min-keyint=9999:no-scenecut:bframes=0" -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv Liyuu-no-hatsuraji-repetend.mp4

ffmpeg -y -i audio_AAC.mp4 -stream_loop -1 -i Liyuu-no-hatsuraji-repetend.mp4 -map 1:v:0 -map 0:a:0 -c:v copy -c:a copy -shortest -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv base-video.mp4

@del Liyuu-no-hatsuraji-repetend.mp4
