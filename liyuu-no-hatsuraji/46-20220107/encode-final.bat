
@echo off
chcp 65001
call settings.bat
set ENCODE_VIDEO_MODE=final

if not exist audio_AAC.mp4 (
    ffmpeg -i "%ORIGINAL_AUDIO_VIDEO_PATH%" -map 0:a:0 -c:a libfdk_aac -b:a 320K audio_AAC.mp4
)

vspipe -y video.vpy - | ffmpeg -y -i pipe: -i audio_AAC.mp4 -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -c:a copy -shortest -colorspace bt709 -color_primaries bt709 -color_trc bt709 %FILENAME%-%VERSION%-temp.mp4
del %FILENAME%-%VERSION%.mp4
move %FILENAME%-%VERSION%-temp.mp4 %FILENAME%-%VERSION%.mp4
