# Motion Preview Privacy Policy

**Effective date: July 20, 2026**

[简体中文](#简体中文) | [English](#english)

## 简体中文

Motion Preview（以下简称“本应用”）是一款在 macOS 本机运行的多媒体资源预览工具。本隐私政策说明本应用如何处理你选择打开的文件及相关信息。

### 隐私摘要

- 本应用不要求注册账户。
- 本应用不收集或出售个人信息。
- 本应用不包含广告、用户分析、行为追踪或第三方崩溃上报 SDK。
- 预览资源仅在你的 Mac 上读取和解码，不会由本应用上传到服务器。
- 最近打开记录、界面偏好和文件访问书签仅保存在本机。

### 本应用处理的信息

#### 你选择的文件

只有在你通过 Finder、“打开”面板或拖放操作明确选择资源后，本应用才会获得该文件或目录的只读访问权限。应用会在本机读取资源内容，以完成格式识别、预览、播放和元信息展示。

元信息可能包括文件名、路径、扩展名、文件大小、修改时间、画面尺寸、帧数、帧率、时长、视频编码格式和 SVG ViewBox。上述信息不会由本应用传输到外部服务器。

#### 保存在本机的应用数据

为提供最近打开、界面偏好和文件恢复功能，本应用可能在 macOS 应用容器内保存：

- 最近打开的最多 12 个资源的标识符、文件名、路径、扩展名和打开来源
- 当前画布背景、自定义背景颜色和 Inspector 显示状态
- 用于在后续启动时重新获得只读访问权限的 macOS 安全作用域书签

安全作用域文件访问会在相关资源窗口关闭时停止。书签记录可能继续保存在本机，以支持最近打开或重新定位功能。

### 网络与第三方服务

本应用的发布版本不使用网络连接上传资源或应用数据，也不集成广告、分析、追踪或云同步服务。视频和图片由 Flutter 组件及 macOS AVFoundation 等系统框架在本机解码。

当你主动打开本政策、技术支持页面或 GitHub Issues 等外部链接时，浏览器和对应网站会根据各自的隐私政策处理访问数据；该处理不由 Motion Preview 控制。

通过 Mac App Store 下载或更新应用时，Apple 可能根据其自身政策处理购买、设备和诊断信息。这些数据不会提供给本应用用于追踪你。

### 数据保留与删除

本地偏好、最近打开记录和安全作用域书签会保留在应用容器中，直到应用数据被清除。你可以通过 macOS 删除 Motion Preview 的应用数据来移除这些记录。删除原始资源窗口或关闭应用不会删除你磁盘上的源文件，本应用不会修改源文件内容。

如果你向 GitHub Issues 主动提交错误报告、截图、日志或示例文件，这些内容由你决定提供，并受 GitHub 的服务条款和隐私政策约束。提交前请移除个人信息、完整文件路径和其他敏感内容。

### 儿童隐私

本应用不收集任何用户的个人信息，也不会针对儿童进行数据收集、广告投放或行为分析。

### 政策更新

如果应用的数据处理方式发生变化，本政策将同步更新，并修改顶部的生效日期。涉及新增数据收集或网络传输的重大变化会在发布说明或应用页面中明确说明。

### 联系我们

如对本隐私政策有疑问，请通过 [Motion Preview GitHub Issues](https://github.com/dev-wwj/svga_viewer/issues) 联系项目维护者。请勿在公开问题中发布个人信息或敏感资源。

## English

Motion Preview (the “App”) is a media asset viewer that runs locally on macOS. This Privacy Policy explains how the App handles files you choose to open and related information.

### Privacy Summary

- The App does not require an account.
- The App does not collect or sell personal information.
- The App contains no advertising, analytics, behavioral tracking, or third-party crash reporting SDKs.
- Preview resources are read and decoded on your Mac and are not uploaded by the App.
- Recent items, interface preferences, and file access bookmarks are stored locally.

### Information Processed by the App

#### Files You Select

The App receives read-only access to a file or directory only after you explicitly select it through Finder, an Open panel, or drag and drop. Resource content is read locally to identify the format, render a preview, play media, and display metadata.

Metadata may include the file name, path, extension, size, modification date, dimensions, frame count, frame rate, duration, video codec, and SVG ViewBox. The App does not transmit this information to an external server.

#### Data Stored Locally

To provide Recent items, interface preferences, and file restoration, the App may store the following in its macOS app container:

- Identifiers, file names, paths, extensions, and opening sources for up to 12 recent resources
- Canvas background, custom background color, and Inspector visibility preferences
- macOS security-scoped bookmarks used to restore read-only access to files you selected

Security-scoped access stops when the related resource window closes. Bookmark records may remain stored locally to support Recent items and file relocation.

### Network Access and Third Parties

The release version of the App does not use a network connection to upload resources or app data and does not integrate advertising, analytics, tracking, or cloud synchronization services. Images and video are decoded locally using Flutter components and macOS system frameworks such as AVFoundation.

If you choose to open this policy, the support page, GitHub Issues, or another external link, your browser and the destination website process access data under their own privacy policies. Motion Preview does not control that processing.

When you download or update the App through the Mac App Store, Apple may process purchase, device, and diagnostic information under Apple's own policies. That information is not provided to the App for user tracking.

### Retention and Deletion

Local preferences, recent item records, and security-scoped bookmarks remain in the app container until the App's local data is cleared. You can remove these records by deleting Motion Preview's app data through macOS. Closing a resource window or the App does not delete source files from your disk, and the App does not modify source file contents.

If you voluntarily submit a bug report, screenshot, log, or sample file through GitHub Issues, you decide what to provide, and GitHub's terms and privacy policy apply. Remove personal information, full file paths, and sensitive content before submitting a public issue.

### Children's Privacy

The App does not collect personal information from any user and does not perform child-directed data collection, advertising, or behavioral analytics.

### Changes to This Policy

If the App's data practices change, this policy will be updated and the effective date at the top will be revised. Material changes involving new data collection or network transmission will be disclosed in release notes or on the App's product page.

### Contact

For privacy questions, contact the project maintainers through [Motion Preview GitHub Issues](https://github.com/dev-wwj/svga_viewer/issues). Do not post personal information or sensitive resources in a public issue.
