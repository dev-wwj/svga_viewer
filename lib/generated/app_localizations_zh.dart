// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Motion Preview';

  @override
  String get recent => '最近打开';

  @override
  String get noRecent => '暂无最近资源';

  @override
  String get aboutDescription => '轻量的本地动图与媒体资源预览工具。';

  @override
  String get inspector => '检查器';

  @override
  String get noSelection => '未选择资源';

  @override
  String get resource => '资源';

  @override
  String get name => '名称';

  @override
  String get type => '类型';

  @override
  String get extension => '扩展名';

  @override
  String get source => '来源';

  @override
  String get path => '路径';

  @override
  String get status => '状态';

  @override
  String get ready => '就绪';

  @override
  String get format => '格式';

  @override
  String get fileSize => '文件大小';

  @override
  String get modified => '修改时间';

  @override
  String get animation => '动画';

  @override
  String get video => '视频';

  @override
  String get image => '图片';

  @override
  String get vectorImage => '矢量图片';

  @override
  String get animatedImage => '动图';

  @override
  String get dimensions => '尺寸';

  @override
  String get frames => '帧数';

  @override
  String get frameRate => '帧率';

  @override
  String get duration => '时长';

  @override
  String get codec => '编码';

  @override
  String get viewBox => 'ViewBox';

  @override
  String get capabilities => '能力';

  @override
  String get timeline => '时间轴';

  @override
  String get frameStep => '逐帧';

  @override
  String get speed => '速度';

  @override
  String get loop => '循环';

  @override
  String get available => '支持';

  @override
  String get canvas => '画布';

  @override
  String get customColor => '自定义颜色';

  @override
  String get checkerboard => '棋盘格';

  @override
  String get lightBackground => '浅色背景';

  @override
  String get darkBackground => '深色背景';

  @override
  String get customBackground => '自定义背景';

  @override
  String get showInspector => '显示检查器';

  @override
  String get hideInspector => '隐藏检查器';

  @override
  String get fitWindow => '适应窗口';

  @override
  String get actualSize => '实际尺寸';

  @override
  String get open => '打开';

  @override
  String get newWindow => '新建窗口';

  @override
  String get closeWindow => '关闭窗口';

  @override
  String get file => '文件';

  @override
  String get view => '视图';

  @override
  String get playback => '播放';

  @override
  String get playPause => '播放/暂停';

  @override
  String get previousFrame => '上一帧';

  @override
  String get nextFrame => '下一帧';

  @override
  String get play => '播放';

  @override
  String get pause => '暂停';

  @override
  String get disableLoop => '关闭循环';

  @override
  String get enableLoop => '开启循环';

  @override
  String get chooseColor => '选择自定义画布颜色';

  @override
  String get unsupportedResource => '不支持此资源类型。';

  @override
  String get resourceCouldNotOpen => '无法打开此资源。';

  @override
  String imageDecodingFailed(Object error) {
    return '图片解码失败：$error';
  }

  @override
  String svgDecodingFailed(Object error) {
    return 'SVG 解码失败：$error';
  }

  @override
  String svgaDecodingFailed(Object error) {
    return 'SVGA 解码失败：$error';
  }

  @override
  String lottieDecodingFailed(Object error) {
    return 'Lottie 解码失败：$error';
  }

  @override
  String get webmUnsupported => '当前 macOS 版本不支持此 WebM 编码。';

  @override
  String videoDecodingFailed(Object error) {
    return '视频解码失败：$error';
  }

  @override
  String get locate => '重新定位…';

  @override
  String get guide => '使用指南';

  @override
  String get tip1 => '将本APP设置为svga | lottie默认程序';

  @override
  String get tip2 => '点击查找本地svga | lottie图片';

  @override
  String get tip3 => '拖动 SVGA | Lottie 文件到此窗口';
}
