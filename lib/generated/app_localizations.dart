import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Motion Preview'**
  String get appTitle;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent resources'**
  String get noRecent;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A lightweight local previewer for motion and media assets.'**
  String get aboutDescription;

  /// No description provided for @inspector.
  ///
  /// In en, this message translates to:
  /// **'Inspector'**
  String get inspector;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No selection'**
  String get noSelection;

  /// No description provided for @resource.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get resource;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @extension.
  ///
  /// In en, this message translates to:
  /// **'Extension'**
  String get extension;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get fileSize;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @vectorImage.
  ///
  /// In en, this message translates to:
  /// **'Vector image'**
  String get vectorImage;

  /// No description provided for @animatedImage.
  ///
  /// In en, this message translates to:
  /// **'Animated image'**
  String get animatedImage;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @frames.
  ///
  /// In en, this message translates to:
  /// **'Frames'**
  String get frames;

  /// No description provided for @frameRate.
  ///
  /// In en, this message translates to:
  /// **'Frame rate'**
  String get frameRate;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @codec.
  ///
  /// In en, this message translates to:
  /// **'Codec'**
  String get codec;

  /// No description provided for @viewBox.
  ///
  /// In en, this message translates to:
  /// **'ViewBox'**
  String get viewBox;

  /// No description provided for @capabilities.
  ///
  /// In en, this message translates to:
  /// **'Capabilities'**
  String get capabilities;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @frameStep.
  ///
  /// In en, this message translates to:
  /// **'Frame step'**
  String get frameStep;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @loop.
  ///
  /// In en, this message translates to:
  /// **'Loop'**
  String get loop;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @canvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get canvas;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @checkerboard.
  ///
  /// In en, this message translates to:
  /// **'Checkerboard'**
  String get checkerboard;

  /// No description provided for @lightBackground.
  ///
  /// In en, this message translates to:
  /// **'Light background'**
  String get lightBackground;

  /// No description provided for @darkBackground.
  ///
  /// In en, this message translates to:
  /// **'Dark background'**
  String get darkBackground;

  /// No description provided for @customBackground.
  ///
  /// In en, this message translates to:
  /// **'Custom background'**
  String get customBackground;

  /// No description provided for @showInspector.
  ///
  /// In en, this message translates to:
  /// **'Show Inspector'**
  String get showInspector;

  /// No description provided for @hideInspector.
  ///
  /// In en, this message translates to:
  /// **'Hide Inspector'**
  String get hideInspector;

  /// No description provided for @fitWindow.
  ///
  /// In en, this message translates to:
  /// **'Fit to Window'**
  String get fitWindow;

  /// No description provided for @actualSize.
  ///
  /// In en, this message translates to:
  /// **'Actual Size'**
  String get actualSize;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @newWindow.
  ///
  /// In en, this message translates to:
  /// **'New Window'**
  String get newWindow;

  /// No description provided for @closeWindow.
  ///
  /// In en, this message translates to:
  /// **'Close Window'**
  String get closeWindow;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @playPause.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get playPause;

  /// No description provided for @previousFrame.
  ///
  /// In en, this message translates to:
  /// **'Previous Frame'**
  String get previousFrame;

  /// No description provided for @nextFrame.
  ///
  /// In en, this message translates to:
  /// **'Next Frame'**
  String get nextFrame;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @disableLoop.
  ///
  /// In en, this message translates to:
  /// **'Disable loop'**
  String get disableLoop;

  /// No description provided for @enableLoop.
  ///
  /// In en, this message translates to:
  /// **'Enable loop'**
  String get enableLoop;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose custom canvas color'**
  String get chooseColor;

  /// No description provided for @unsupportedResource.
  ///
  /// In en, this message translates to:
  /// **'This resource type is not supported.'**
  String get unsupportedResource;

  /// No description provided for @resourceCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'The resource could not be opened.'**
  String get resourceCouldNotOpen;

  /// No description provided for @imageDecodingFailed.
  ///
  /// In en, this message translates to:
  /// **'Image decoding failed: {error}'**
  String imageDecodingFailed(Object error);

  /// No description provided for @svgDecodingFailed.
  ///
  /// In en, this message translates to:
  /// **'SVG decoding failed: {error}'**
  String svgDecodingFailed(Object error);

  /// No description provided for @svgaDecodingFailed.
  ///
  /// In en, this message translates to:
  /// **'SVGA decoding failed: {error}'**
  String svgaDecodingFailed(Object error);

  /// No description provided for @lottieDecodingFailed.
  ///
  /// In en, this message translates to:
  /// **'Lottie decoding failed: {error}'**
  String lottieDecodingFailed(Object error);

  /// No description provided for @webmUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This WebM encoding is not supported by this macOS version.'**
  String get webmUnsupported;

  /// No description provided for @videoDecodingFailed.
  ///
  /// In en, this message translates to:
  /// **'Video decoding failed: {error}'**
  String videoDecodingFailed(Object error);

  /// No description provided for @locate.
  ///
  /// In en, this message translates to:
  /// **'Locate…'**
  String get locate;

  /// No description provided for @guide.
  ///
  /// In en, this message translates to:
  /// **'Usage Guide'**
  String get guide;

  /// No description provided for @tip1.
  ///
  /// In en, this message translates to:
  /// **'Set this app as the default program for SVGA | Lottie files.'**
  String get tip1;

  /// No description provided for @tip2.
  ///
  /// In en, this message translates to:
  /// **'Click to browse local SVGA | Lottie Animation.'**
  String get tip2;

  /// No description provided for @tip3.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop SVGA | Lottie files onto this window.'**
  String get tip3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
