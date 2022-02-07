
@echo off
chcp 65001

vspipe video-海底捞.vpy -c y4m - | ffmpeg -y -i pipe: -i "【生肉】向健叔安利海底捞的鲤鱼姐.mp4" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -c:a libfdk_aac -b:a 320K -shortest 海底捞-v3.mp4
