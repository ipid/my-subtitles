
@echo off
chcp 65001

set VIDEO_PATH=导出-拔红薯-超分1080P.mp4
set SUBTITLE_PATH=字幕-拔红薯.ass
set OUT_FILENAME=拔红薯-v3

vspipe video.vpy -c y4m - | ffmpeg -y -i pipe: -i "%VIDEO_PATH%" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -af aresample=async=99999 -c:a libfdk_aac -b:a 320K "%OUT_FILENAME%.mp4"
