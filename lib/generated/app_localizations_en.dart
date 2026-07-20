// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Motion Preview';

  @override
  String get recent => 'Recent';

  @override
  String get noRecent => 'No recent resources';

  @override
  String get aboutDescription =>
      'A lightweight local previewer for motion and media assets.';

  @override
  String get inspector => 'Inspector';

  @override
  String get noSelection => 'No selection';

  @override
  String get resource => 'Resource';

  @override
  String get name => 'Name';

  @override
  String get type => 'Type';

  @override
  String get extension => 'Extension';

  @override
  String get source => 'Source';

  @override
  String get path => 'Path';

  @override
  String get status => 'Status';

  @override
  String get ready => 'Ready';

  @override
  String get format => 'Format';

  @override
  String get fileSize => 'File size';

  @override
  String get modified => 'Modified';

  @override
  String get animation => 'Animation';

  @override
  String get video => 'Video';

  @override
  String get image => 'Image';

  @override
  String get vectorImage => 'Vector image';

  @override
  String get animatedImage => 'Animated image';

  @override
  String get dimensions => 'Dimensions';

  @override
  String get frames => 'Frames';

  @override
  String get frameRate => 'Frame rate';

  @override
  String get duration => 'Duration';

  @override
  String get codec => 'Codec';

  @override
  String get viewBox => 'ViewBox';

  @override
  String get capabilities => 'Capabilities';

  @override
  String get timeline => 'Timeline';

  @override
  String get frameStep => 'Frame step';

  @override
  String get speed => 'Speed';

  @override
  String get loop => 'Loop';

  @override
  String get available => 'Available';

  @override
  String get canvas => 'Canvas';

  @override
  String get customColor => 'Custom color';

  @override
  String get checkerboard => 'Checkerboard';

  @override
  String get lightBackground => 'Light background';

  @override
  String get darkBackground => 'Dark background';

  @override
  String get customBackground => 'Custom background';

  @override
  String get showInspector => 'Show Inspector';

  @override
  String get hideInspector => 'Hide Inspector';

  @override
  String get fitWindow => 'Fit to Window';

  @override
  String get actualSize => 'Actual Size';

  @override
  String get open => 'Open';

  @override
  String get newWindow => 'New Window';

  @override
  String get closeWindow => 'Close Window';

  @override
  String get file => 'File';

  @override
  String get view => 'View';

  @override
  String get playback => 'Playback';

  @override
  String get playPause => 'Play/Pause';

  @override
  String get previousFrame => 'Previous Frame';

  @override
  String get nextFrame => 'Next Frame';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get disableLoop => 'Disable loop';

  @override
  String get enableLoop => 'Enable loop';

  @override
  String get chooseColor => 'Choose custom canvas color';

  @override
  String get unsupportedResource => 'This resource type is not supported.';

  @override
  String get resourceCouldNotOpen => 'The resource could not be opened.';

  @override
  String imageDecodingFailed(Object error) {
    return 'Image decoding failed: $error';
  }

  @override
  String svgDecodingFailed(Object error) {
    return 'SVG decoding failed: $error';
  }

  @override
  String svgaDecodingFailed(Object error) {
    return 'SVGA decoding failed: $error';
  }

  @override
  String lottieDecodingFailed(Object error) {
    return 'Lottie decoding failed: $error';
  }

  @override
  String get webmUnsupported =>
      'This WebM encoding is not supported by this macOS version.';

  @override
  String videoDecodingFailed(Object error) {
    return 'Video decoding failed: $error';
  }

  @override
  String get locate => 'Locate…';

  @override
  String get guide => 'Usage Guide';

  @override
  String get tip1 =>
      'Set this app as the default program for SVGA | Lottie files.';

  @override
  String get tip2 => 'Click to browse local SVGA | Lottie Animation.';

  @override
  String get tip3 => 'Drag and drop SVGA | Lottie files onto this window.';
}
