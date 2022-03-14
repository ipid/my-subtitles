
@echo off
chcp 65001

set OUT_VERSION=字幕-v1

set VIDEO_PATH=互动片段1-题面.mp4
set SUBTITLE_PATH=1.ass
set OUT_FILENAME=片段1-题面
call encode.bat

set VIDEO_PATH=互动片段2-答对.mp4
set SUBTITLE_PATH=2.ass
set OUT_FILENAME=片段2-答对
call encode.bat

set VIDEO_PATH=互动片段3-答错.mp4
set SUBTITLE_PATH=3.ass
set OUT_FILENAME=片段3-答错
call encode.bat

set VIDEO_PATH=互动片段4-答案.mp4
set SUBTITLE_PATH=4.ass
set OUT_FILENAME=片段4-答案
call encode.bat
