from vapoursynth import core
import vapoursynth as vs
import os

# 读取易变参数
VIDEO_MODE = os.environ.get('ENCODE_VIDEO_MODE', '').strip()
if VIDEO_MODE not in {'base', 'final', 'original'}:
    raise ValueError('Env error: ENCODE_VIDEO_MODE is not `base`, `final` or `original`')

FPS_NUM = 30
WIDTH, HEIGHT = 1920, 1080

BASE_VIDEO_GOP_LENGTH = os.environ.get('BASE_VIDEO_GOP_LENGTH', '').strip()
try:
    BASE_VIDEO_GOP_LENGTH = int(BASE_VIDEO_GOP_LENGTH)
except:
    BASE_VIDEO_GOP_LENGTH = 5

if VIDEO_MODE == 'base':
    loop_length = FPS_NUM * 5
elif VIDEO_MODE == 'final':
    loop_length = FPS_NUM * 60 * 60
else:
    pass

if VIDEO_MODE == 'base' or VIDEO_MODE == 'final':
    clip = core.imwri.Read(os.environ['COVER_PATH'].strip())
elif VIDEO_MODE == 'original':
    clip = core.ffms2.Source(os.environ['ORIGINAL_AUDIO_VIDEO_PATH'].strip())
else:
    raise ValueError(f'不支持当前 VIDEO_MODE：{VIDEO_MODE}')

clip = core.resize.Bicubic(clip, width=WIDTH, height=HEIGHT, format=vs.YUV420P8, matrix_s='709', range_s='limited')

if VIDEO_MODE == 'base' or VIDEO_MODE == 'final':
    clip = core.std.Loop(clip, times=loop_length)
    clip = core.std.AssumeFPS(clip, fpsnum=FPS_NUM)

if VIDEO_MODE == 'final' or VIDEO_MODE == 'original':
    SUBTITLE_PATH = os.environ.get('SUBTITLE_PATH', '').strip()
    if SUBTITLE_PATH != '':
        clip = core.xyvsf.TextSub(clip, SUBTITLE_PATH)

    SUBTITLE_VSFM_PATH = os.environ.get('SUBTITLE_VSFM_PATH', '').strip()
    if SUBTITLE_VSFM_PATH != '':
        clip = core.vsfm.TextSubMod(clip, SUBTITLE_VSFM_PATH)

clip.set_output()
