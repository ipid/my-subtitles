# VapourSynth 一图流工具链

本脚本是为了方便制作「一图流」字幕而设计的。

<br>

## 事先准备

目前本脚本只支持 Windows 系统。请先安装 VapourSynth，然后安装必要的依赖包：

```bash
vsrepo install xyvsf vsfm imwri ffms2
```

<br>

## 使用方法

基本的使用步骤为：

1. 按照下文中的说明，修改 settings.bat；
2. 双击 encode-base.bat，生成一图流视频。
3. 双击 encode-final.bat，将字幕压制到视频中。
4. 双击 preview-final.bat，可使用播放器预览压制后视频的效果。

<br>

注意，你也可以在生成一图流视频后，使用消极压制等工具来压制字幕，所以并非一定要使用 encode-final 来压制字幕。encode-final 适用于需要使用 VSFilterMod 的场合。

<br>

## settings.bat 修改说明

| 配置项                    | 说明                                                         |
| ------------------------- | ------------------------------------------------------------ |
| FINAL_FILENAME            | 压制出的最终文件的名字。对 encode-base 无效                  |
| ORIGINAL_AUDIO_VIDEO_PATH | 音频文件的路径，可以是任何格式，只要 ffmpeg 支持即可。本脚本会将该音频编码为 AAC 音频格式。 |
| AAC_AUDIO_PATH            | 如果下载下来的视频 / 音频文件已经是 AAC 编码，则可以直接将视频或音频文件的路径填到这里。（ **例:**  从 YouTube 下载时格式选择了 AAC；某网站上下载的广播原本就是 AAC 编码）<br /> **注:** 当该路径不存在时，脚本会把 ORIGINAL_AUDIO_VIDEO_PATH 所指向的音频文件编码为 AAC，并输出到该路径。 |
| COVER_PATH                | 「一图流」图片的路径。                                       |
| SUBTITLE_PATH             | 字幕文件的路径，该字幕文件会使用 xy-VSFilter 压制到视频中。该字段与 SUBTITLE_VSFM_PATH 是独立的。 |
| SUBTITLE_VSFM_PATH        | 字幕文件的路径，该字幕文件会使用 VSFilterMod 压制到视频中。该字段与 SUBTITLE_PATH 是独立的，你可以将必须使用 VSFilterMod 的字幕轴独立出来，放到另一个 .ass 文件里。 |
| BASE_VIDEO_GOP_LENGTH     | 一图流视频的 GoP（Group of Pictures）长度（单位：秒）。该值越大，则压出的视频大小就越接近音频大小（即视频部分几乎不占空间），但是 Aegisub 等软件打开时就越卡。 **建议设为 5 到 10 即可** ，实践证明在该范围内生成的视频大小较合理，且易于打开。 |
| BASE_VIDEO_CRF            | 压制一图流视频、最终视频时的 CRF（质量分数）参数。           |




