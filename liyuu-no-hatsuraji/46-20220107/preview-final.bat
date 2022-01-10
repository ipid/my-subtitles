
@echo off
chcp 65001

call settings.bat
set VAPOURSYNTH_VIDEO_MODE=final
start video.vpy
