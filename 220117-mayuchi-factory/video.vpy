import vapoursynth as vs
from vapoursynth import core

clip = core.ffms2.Source(r'220117-mayuchi-factory.mp4')
clip = core.xyvsf.TextSub(clip, r'220117-mayuchi-factory.ass')
clip.set_output()
