
@echo off
chcp 65001

call settings.bat
set ENCODE_VIDEO_MODE=final
start video.vpy
