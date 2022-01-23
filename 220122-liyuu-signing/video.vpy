import vapoursynth as vs
from vapoursynth import core

clip = core.ffms2.Source(r'220122-liyuu-signing.mp4')
clip = core.xyvsf.TextSub(clip, r'220122-liyuu-signing.ass')
clip.set_output()
