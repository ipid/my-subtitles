from vapoursynth import core
import vapoursynth as vs
import os

clip = core.ffms2.Source(os.environ['VIDEO_PATH'].strip())

if (sub_path := os.environ.get('SUBTITLE_PATH', '').strip()) != '':
    clip = core.xyvsf.TextSub(clip, sub_path)

if (sub_path := os.environ.get('SUBTITLE_VSFM_PATH', '').strip()) != '':
    clip = core.vsfm.TextSubMod(clip, sub_path)

clip.set_output()
