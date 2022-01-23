（本批处理用于压制视频）

@chcp 65001
@ffmpeg -y -i 丈育ksks.mp4 -vf subtitles=filename=丈育ksks.ass:fontsdir=./fonts -map 0:v -map 0:a -c:v libx264 -preset:v veryfast -crf:v 16 -qcomp:v 0.99 -c:a libfdk_aac -b:a 320K 丈育ksks-v5.mp4
@echo 完成！
