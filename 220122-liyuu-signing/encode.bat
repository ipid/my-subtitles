﻿
@echo off
chcp 65001

vspipe video.vpy -c y4m - | ffmpeg -y -i pipe: -i "220122-liyuu-signing.mp4" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -qcomp:v 0.995 -c:a copy -shortest v2.mp4
