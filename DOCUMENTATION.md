# Motion Preview 项目说明

Motion Preview 是 macOS 优先的轻量多媒体预览器。每个资源使用独立窗口打开，窗口根据图片或视频尺寸在屏幕可用范围内初始化；窗口默认不显示属性栏，点击工具栏 Inspector 按钮后从右侧展开。

## 支持格式

- 动画：SVGA、Lottie JSON、GIF、WebP、APNG
- 图片：PNG、JPG/JPEG、BMP、HEIC
- 矢量：SVG
- 视频：MP4、MOV、M4V；WebM 仅尝试系统解码

普通 JSON 会先经过 Lottie 结构校验，不符合结构时显示不支持错误。

## 界面与交互

- 空状态仅保留应用图标和打开按钮
- 工具栏提供打开、适应窗口、实际尺寸、Inspector
- Inspector 默认收起，只从右侧显示名称、类型、路径、媒体元信息和画布背景
- Cmd+O 打开资源；多选、Finder 打开和目录拖入会为每个文件创建独立窗口
- Cmd+W 关闭当前资源窗口；Space 播放/暂停；左右方向键逐帧；Cmd+0/1/+/- 控制画布

## 架构

```text
macOS Finder / NSOpenPanel / DragContainer
        -> AppDelegate
        -> DocumentAccessManager（安全作用域书签）
        -> 每个 DocumentDescriptor 创建一个 FlutterEngine + NSWindow
        -> WorkspaceController（单窗口单资源状态）
        -> PreviewRegistry / PreviewAdapter
        -> PreviewHost（SVGA、Lottie、Raster、SVG、Video）
```

Dart 与 Swift 之间只传递路径描述符，不传输 Base64 文件内容：

```text
DocumentDescriptor {
  id, path, displayName, extension, source
}
```

通道为 `com.motionpreview.documents`（事件）和 `com.motionpreview.workspace`（方法）。关闭窗口时释放对应播放器、解码缓存和安全作用域访问。

## 开发与验证

```bash
flutter pub get
flutter analyze
flutter test
flutter build macos --debug
codegraph sync .
```
