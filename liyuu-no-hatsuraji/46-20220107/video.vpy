from vapoursynth import core
import vapoursynth as vs
import os

# 读取易变参数
VIDEO_MODE = os.environ.get('ENCODE_VIDEO_MODE', '').strip()
if VIDEO_MODE not in {'base', 'final'}:
    raise ValueError('Env error: ENCODE_VIDEO_MODE is not `base` or `final`')

FPS_NUM = 30
WIDTH, HEIGHT = 1920, 1080

if VIDEO_MODE == 'base':
    loop_length = FPS_NUM * 5
else:
    loop_length = FPS_NUM * 60 * 60

clip = core.imwri.Read(os.environ['COVER_PATH'].strip())
clip = core.resize.Bicubic(clip, width=WIDTH, height=HEIGHT, format=vs.YUV420P8, matrix_s='709', range_s='limited')
clip = core.std.Loop(clip, times=loop_length)
clip = core.std.AssumeFPS(clip, fpsnum=FPS_NUM)

if VIDEO_MODE == 'final':
    clip = core.xyvsf.TextSub(clip, os.environ['SUBTITLE_PATH'].strip())

clip.set_output()
