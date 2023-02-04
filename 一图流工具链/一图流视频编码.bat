    
@echo off 
chcp 65001
    
rem ip君的一图流脚本 https://github.com/ipid/my-subtitles
rem ------ ↓ 请修改此部分 ↓ ------
    
set FINAL_FILENAME=一图流
    
set ORIGINAL_AUDIO_VIDEO_PATH=测试音频 - Dream Land! Dream World!.mp3
    
set COVER_PATH=测试图片 - 彩条 - sRGB.jpg
    
set AAC_AUDIO_PATH=请根据README的说明，在需要的时候修改这个参数
    
rem ------ ↑ 请修改此部分 ↑ ------
    
set FRAME_RATE=30
set AAC_BITRATE=256k
set BASE_VIDEO_GOP_LENGTH=5
set BASE_VIDEO_CRF=16
    
cd /d %~dp0
    
if exist "__aac_audio.mp4" (
    
    echo 检测到上一次编码残留下来的临时文件没删掉，可能上次编码没执行完呢。
    
    echo 如果你确定之前的编码已经结束了，那就把 __aac_audio.mp4 删掉。
    
    goto early-exit
    
) else (
    if exist "__base-video-repetend.mp4" (
    
        echo 检测到上一次编码残留下来的临时文件没删掉，可能上次编码没执行完呢。
    
        echo 如果你确定之前的编码已经结束了，那就把 __base-video-repetend.mp4 删掉。
    
        goto early-exit
    )
)
    
if not exist "%COVER_PATH%" (
    
    echo 封面图片文件 %COVER_PATH% 不存在，请检查设置是否有误。
    
    goto early-exit
)
    
ffmpeg -f lavfi -i "sine=frequency=440:duration=0.001" -c:a libfdk_aac -b:a "%AAC_BITRATE%" __test_fdk_compatibility.aac
if %errorlevel% neq 0 (
    del /f __test_fdk_compatibility.aac
    set AAC_ENCODER=aac
) else (
    del /f __test_fdk_compatibility.aac
    set AAC_ENCODER=libfdk_aac
)
    
if exist "%AAC_AUDIO_PATH%" (
    set VERIFIED_AAC_SOURCE=%AAC_AUDIO_PATH%
) else (
    if not exist "%ORIGINAL_AUDIO_VIDEO_PATH%" (
    
        echo 音频文件 %ORIGINAL_AUDIO_VIDEO_PATH% 不存在，请检查设置是否有误。
    
        goto early-exit
    )
    
    ffmpeg -y -i "%ORIGINAL_AUDIO_VIDEO_PATH%" -map 0:a:0 -c:a %AAC_ENCODER% -b:a "%AAC_BITRATE%" __aac_audio.mp4
    if %errorlevel% neq 0 goto show-error
    
    set VERIFIED_AAC_SOURCE=__aac_audio.mp4
)
    
rem 以下 vf 部分参考了博客：https://fireattack.wordpress.com/2019/09/19/convert-image-to-video-using-ffmpeg/
    
ffmpeg -y -loop 1 -i "%COVER_PATH%" -map 0:v:0 -c:v libx264 -preset:v veryfast -crf:v "%BASE_VIDEO_CRF%" -vf "format=pix_fmts=rgb24,scale=out_color_matrix=bt709:out_range=tv,format=pix_fmts=yuv420p" -x264opts "keyint=999999:min-keyint=999999:no-scenecut:bframes=0" -t "%BASE_VIDEO_GOP_LENGTH%" -r "%FRAME_RATE%" -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv __base-video-repetend.mp4
if %errorlevel% neq 0 goto show-error
    
ffmpeg -y -i "%VERIFIED_AAC_SOURCE%" -stream_loop -1 -i __base-video-repetend.mp4 -map 1:v:0 -map 0:a:0 -c:v copy -c:a copy -shortest -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 -color_range tv "%FINAL_FILENAME%.mp4"
if %errorlevel% neq 0 goto show-error
    
if exist "__aac_audio.mp4" (
    del /f __aac_audio.mp4 
)
del /f __base-video-repetend.mp4
    
:end
echo.
    
echo 编码成功完成。
    
exit /b
    
    
:early-exit
echo.
pause
exit /b
    
    
:show-error
if exist "__aac_audio.mp4" (
    del /f __aac_audio.mp4 
)
if exist "__base-video-repetend.mp4" (
    del /f __base-video-repetend.mp4
)
    
echo.
    
echo 操作出错！压制未成功完成。
    
echo.
    
pause
exit /b
    