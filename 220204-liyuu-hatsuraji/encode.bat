﻿
@echo off
chcp 65001

vspipe video.vpy -c y4m - | ffmpeg -y -i pipe: -i "导出.mp4" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -c:a libfdk_aac -b:a 320K -shortest v2.mp4
