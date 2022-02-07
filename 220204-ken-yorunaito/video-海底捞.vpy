import vapoursynth as vs
from vapoursynth import core

clip = core.ffms2.Source(r'【生肉】向健叔安利海底捞的鲤鱼姐.mp4')
clip = core.xyvsf.TextSub(clip, r'【生肉】向健叔安利海底捞的鲤鱼姐.ass')
clip.set_output()
