
@echo off
chcp 65001

vspipe video.vpy -c y4m - | ffmpeg -y -i pipe: -i "%VIDEO_PATH%" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -c:a libfdk_aac -b:a 320K "%OUT_FILENAME%-%OUT_VERSION%.mp4"
