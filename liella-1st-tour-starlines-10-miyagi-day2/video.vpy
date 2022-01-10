import vapoursynth as vs
from vapoursynth import core

clip = core.ffms2.Source(r'【宫城Day2】小百合聊吉他背后的故事.mp4')
clip = core.xyvsf.TextSub(clip, r'【宫城Day2】小百合聊吉他背后的故事.ass')
clip.set_output()
