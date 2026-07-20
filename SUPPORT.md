# Motion Preview Support

[简体中文](#简体中文) | [English](#english)

## 简体中文

Motion Preview 是一款面向 macOS 的本地多媒体资源预览工具。如果使用过程中遇到问题，请先查看下面的兼容性说明和常见解决方法。

### 系统要求

- macOS 10.15 或更高版本
- 部分视频格式需要当前 macOS 提供对应的系统解码器

### 支持的资源

| 类型 | 格式 |
| --- | --- |
| 动画 | SVGA、Lottie JSON、GIF、WebP、APNG |
| 图片 | PNG、JPG、JPEG、BMP、HEIC |
| 矢量图片 | SVG |
| 视频 | MP4、MOV、M4V、WebM（取决于系统解码能力） |

### 常见问题

#### 文件无法打开

确认文件扩展名属于支持范围，并检查文件是否完整、是否仍位于原来的路径。Lottie 文件必须是有效的 Lottie JSON；普通 JSON 文件不会作为动画打开。

#### WebM 无法播放

Motion Preview 使用 macOS 系统视频后端，不内置 FFmpeg。WebM 是否能够播放取决于系统版本和文件使用的编码格式。建议在无法播放时将视频转换为 MP4、MOV 或 M4V 后重试。

#### 动画或视频显示为空白

关闭当前资源窗口后重新打开文件。如果问题仍然存在，请确认该文件能在其他播放器中正常解码，并在反馈中附上格式、尺寸和编码信息。请勿提交包含敏感内容的原始资源。

#### Inspector 没有显示

点击资源窗口标题栏右侧的 Inspector 图标，或通过 **View > Show Inspector** 打开。Inspector 会根据当前文件类型显示不同的信息和画布选项。

#### Finder 打开后没有出现资源窗口

确认 Motion Preview 已被设置为该文件类型的打开应用。退出应用后重新使用 Finder 的“打开方式”操作；如果文件位于受权限保护的位置，也可以先将文件移动到本地普通目录后重试。

### 反馈问题

请在 [GitHub Issues](https://github.com/dev-wwj/svga_viewer/issues) 提交问题，并尽量包含：

- Motion Preview 版本号
- macOS 版本和 Mac 芯片类型
- 文件格式、尺寸及大致文件大小
- 可稳定复现问题的操作步骤
- 错误提示或截图

### 隐私

Motion Preview 在本机读取和解码资源，不会将预览文件上传到服务器。提交问题前，请从截图、日志和示例资源中移除个人信息、文件路径或其他敏感数据。详情请参阅[隐私政策](PRIVACY.md)。

## English

Motion Preview is a local media asset viewer for macOS. If something does not work as expected, review the compatibility notes and troubleshooting steps below.

### System Requirements

- macOS 10.15 or later
- Some video formats require a compatible decoder provided by the installed macOS version

### Supported Resources

| Category | Formats |
| --- | --- |
| Animation | SVGA, Lottie JSON, GIF, WebP, APNG |
| Images | PNG, JPG, JPEG, BMP, HEIC |
| Vector images | SVG |
| Video | MP4, MOV, M4V, WebM (subject to system decoder support) |

### Troubleshooting

#### A file does not open

Confirm that its extension is supported and that the file is complete and still available at its original path. A Lottie file must contain valid Lottie JSON data; ordinary JSON files are not opened as animations.

#### WebM does not play

Motion Preview uses the macOS system video backend and does not bundle FFmpeg. WebM playback depends on the macOS version and the codec used by the file. If decoding fails, convert the resource to MP4, MOV, or M4V and try again.

#### An animation or video is blank

Close the resource window and reopen the file. If the problem continues, verify that another player can decode it and include the format, dimensions, and codec details in your report. Do not attach source files that contain sensitive material.

#### The Inspector is not visible

Select the Inspector icon on the right side of the resource window title bar, or choose **View > Show Inspector**. The available fields and canvas options depend on the current file type.

#### Finder does not open a resource window

Confirm that Motion Preview is selected as the opening application for the file type. Quit the app and try Finder's Open With action again. For files in protected locations, moving the file to a regular local folder may also resolve access issues.

### Report an Issue

Open a report in [GitHub Issues](https://github.com/dev-wwj/svga_viewer/issues) and include:

- Motion Preview version
- macOS version and Mac chip type
- File format, dimensions, and approximate size
- Clear steps that reproduce the problem
- Any error message or screenshot

### Privacy

Motion Preview reads and decodes resources locally and does not upload preview files to a server. Before submitting an issue, remove personal information, file paths, and other sensitive data from screenshots, logs, or sample files. See the [Privacy Policy](PRIVACY.md) for details.
