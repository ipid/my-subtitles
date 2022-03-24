
@echo off
chcp 65001
call settings.bat
set ENCODE_VIDEO_MODE=base

if not exist "%COVER_PATH%" (
    echo 封面图片文件 %COVER_PATH% 不存在，请检查设置是否有误。
    goto end
)

if not exist "%AAC_AUDIO_PATH%" (
    if not exist "%ORIGINAL_AUDIO_VIDEO_PATH%" (
        echo 音频文件 %ORIGINAL_AUDIO_VIDEO_PATH% 不存在，请检查设置是否有误。
        goto end
    )
    ffmpeg -i "%ORIGINAL_AUDIO_VIDEO_PATH%" -map 0:a:0 -c:a libfdk_aac -b:a 320K "%AAC_AUDIO_PATH%"
)

vspipe -c y4m video.vpy - | ffmpeg -y -i pipe: -map 0:v:0 -c:v libx264 -preset:v veryfast -crf:v "%BASE_VIDEO_CRF%" -x264opts "keyint=999999:min-keyint=999999:no-scenecut:bframes=0" -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv base-video-repetend.mp4

ffmpeg -y -i "%AAC_AUDIO_PATH%" -stream_loop -1 -i base-video-repetend.mp4 -map 1:v:0 -map 0:a:0 -c:v copy -c:a copy -shortest -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv base-video.mp4

@del base-video-repetend.mp4

:end
