import 'dart:async';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'generated/l10n.dart';

class SvgaWidget extends StatefulWidget {
  const SvgaWidget({super.key});
  @override
  State<StatefulWidget> createState() => _SvgaWidgetState();
}

class _SvgaWidgetState extends State<SvgaWidget>
    with SingleTickerProviderStateMixin {
  static const EventChannel _eventChannel = EventChannel("com.push.data");
  StreamSubscription? _streamSubscription;
  late SVGAAnimationController animationController;
  MovieEntity? videoItem;
  void _enableEventReceiver() {
    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(_listen,
        onError: (dynamic error) {
      print("-------error:${error.message}");
    }, cancelOnError: true);
  }

  void _disableEventReceiver() {
    if (_streamSubscription != null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    animationController = SVGAAnimationController(vsync: this);
    super.initState();
    _enableEventReceiver();
    loadAnimation(null);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _disableEventReceiver();
  }

  /*
  * 加载本地资源
  * */
  void loadAnimation(MovieEntity? videoItem) async {
    // final videoItem = await SVGAParser.shared.decodeFromURL(
    //     "https://github.com/yyued/SVGA-Samples/blob/master/angel.svga?raw=true");
    // final videoItem =
    //     await SVGAParser.shared.decodeFromAssets('images/loading.svga');
    if (videoItem == null) {
      return;
    }
    print("----------------------");
    print(videoItem.params.viewBoxWidth);
    print(videoItem.params.viewBoxHeight);
    print("-----------------------");
    windowManager.setSize(Size(max(300, videoItem.params.viewBoxWidth),
        max(300, videoItem.params.viewBoxHeight)));
    this.videoItem = videoItem;
    animationController.videoItem = videoItem;
    animationController
        .repeat() // Try to use .forward() .reverse()
        .whenComplete(() => animationController.videoItem = null);
    setState(() {});
  }

  final TextStyle textStyle = const TextStyle(
    color: Color.fromARGB(200, 255, 255, 255),
    fontSize: 16,
    fontWeight: FontWeight.w400
  );

  @override
  Widget build(BuildContext context) {
    if (videoItem == null) {
      return _add();
    } else {
      return Stack(
        children: [
          Positioned(
              top: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text("w:${videoItem!.params.viewBoxWidth}", style: textStyle,),
                  Text("H:${videoItem!.params.viewBoxHeight}",style: textStyle),
                  Text("fps:${videoItem!.params.fps}", style: textStyle),
                  Text("frame:${videoItem!.params.frames}",style: textStyle),
                ],
              )),
          Center(
            child: SVGAImage(
              animationController,
              fit: BoxFit.fitWidth,
            ),
          )
        ],
      );
    }
  }

  Widget _add() {
    return Material(
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.blue, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: GestureDetector(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Text(
                    S.of(context).guide,
                    style: const TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                  const SizedBox(
                    height: 60,
                  ),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      ListTile(
                        leading: const Icon(
                          Icons.looks_one,
                          color: Colors.black38,
                        ),
                        title: Text(
                          S.of(context).tip1,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.looks_two,
                          color: Colors.black38,
                        ),
                        title: Text(
                          S.of(context).tip2,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.looks_3,
                          color: Colors.black38,
                        ),
                        title: Text(
                          S.of(context).tip3,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _listen(event) async {
    if (event == null) {
      return;
    }
    var data = event.cast<int>();
    var videoItem = await SVGAParser.shared.decodeFromBuffer(data);
    loadAnimation(videoItem);
  }

  void open() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'SVGA',
      extensions: <String>['svga', 'SVGA'],
    );
    final XFile file =
        (await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup])) as XFile;
    Uint8List data = await file.readAsBytes();
    var videoItem = await SVGAParser.shared.decodeFromBuffer(data.cast<int>());
    loadAnimation(videoItem);
  }

  // Future<void> createNewWindow() async {
  //   final newWindow = await Window
  // }
}
