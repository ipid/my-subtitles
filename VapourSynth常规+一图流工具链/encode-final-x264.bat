
@echo off
chcp 65001
call settings.bat
set ENCODE_VIDEO_MODE=final

if not exist "%AAC_AUDIO_PATH%" (
    if not exist "%ORIGINAL_AUDIO_VIDEO_PATH%" (
        echo 音频文件 %ORIGINAL_AUDIO_VIDEO_PATH% 不存在，请检查设置是否有误。
        goto end
    )
    ffmpeg -i "%ORIGINAL_AUDIO_VIDEO_PATH%" -map 0:a:0 -c:a libfdk_aac -b:a 320K "%AAC_AUDIO_PATH%"
)

if not exist "%COVER_PATH%" (
    echo 封面图片文件 %COVER_PATH% 不存在，请检查设置是否有误。
    goto end
)

vspipe -y video.vpy - | ffmpeg -y -i pipe: -i "%AAC_AUDIO_PATH%" -map 0:v -map 1:a -c:v libx264 -preset:v veryfast -crf:v 16 -c:a copy -shortest -colorspace bt709 -color_primaries bt709 -color_trc bt709 "%FINAL_FILENAME%-temp.mp4"
del "%FINAL_FILENAME%.mp4"
move /y "%FINAL_FILENAME%-temp.mp4" "%FINAL_FILENAME%.mp4"

:end
