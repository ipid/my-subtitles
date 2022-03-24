
@echo off
chcp 65001

rem 设置最终生成的视频的版本号
set FINAL_FILENAME=Liyuu的首次广播-#55-v1

rem 设置原始音频文件的路径（也可以设为视频文件，会使用其中的音频），当原始音频不是 AAC 格式时写在这里
rem 运行 encode original 脚本时，会直接把字幕压制在此处的视频上
set ORIGINAL_AUDIO_VIDEO_PATH=#55.mp3

rem 当 AAC_AUDIO_PATH 不存在时，脚本会将 ORIGINAL_AUDIO_VIDEO_PATH 编码为 AAC 并输出到 AAC_AUDIO_PATH，
rem 故原始音频为 AAC 时，可直接将音频路径写在此处
set AAC_AUDIO_PATH=audio_AAC.mp4

rem 一图流的图的路径
set COVER_PATH=广播55回封面16.9.png

rem 使用 VSFilter 压制的字幕文件路径，可留空
set SUBTITLE_PATH=#55.ass

rem 使用 VSFilterMod 压制的字幕文件的路径，可留空
set SUBTITLE_VSFM_PATH=

rem 一图流视频的 GoP 长度（单位：帧），该值越大则一图流视频大小越接近音频，设为 5 以下可提高视频在旧电脑中的观看体验
set BASE_VIDEO_GOP_LENGTH=5

rem 设置一图流视频的质量分数（CRF）
set BASE_VIDEO_CRF=16
