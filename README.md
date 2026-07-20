# Motion Preview

macOS 优先的 Flutter 轻量多媒体预览器。每个资源使用独立窗口打开，窗口按图片/视频资源尺寸在屏幕范围内初始化；支持 SVGA、Lottie、图片/动画图片、SVG 和 MP4/MOV/M4V。WebM 仅使用系统解码能力，失败时显示可恢复错误。

## 文档

- [项目说明](DOCUMENTATION.md)
- [项目知识图谱](KNOWLEDGE_GRAPH.md)
- [技术支持 / Support](SUPPORT.md)
- [产品介绍 / Marketing](MARKETING.md)
- [隐私政策 / Privacy Policy](PRIVACY.md)

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

仓库已启用本地 CodeGraph 索引。代码变更后运行 `codegraph sync .`，并可使用 `codegraph explore`、`codegraph node` 和 `codegraph impact` 查询调用关系与影响面。
