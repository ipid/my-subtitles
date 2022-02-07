import vapoursynth as vs
from vapoursynth import core

clip = core.ffms2.Source(r'导出.mp4')
clip = core.xyvsf.TextSub(clip, r'220206-nijigasaki-global-live.ass')
clip.set_output()
