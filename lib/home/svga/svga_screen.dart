import 'package:flutter/material.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';
import 'package:trace/utils/colors.dart';

import '../../helpers/quick_help.dart';

class SvgaScreen extends StatefulWidget {
  @override
  _SvgaScreenState createState() => _SvgaScreenState();
}

class _SvgaScreenState extends State<SvgaScreen> with SingleTickerProviderStateMixin {
  SVGAAnimationController? animationController;

  @override
  void initState() {
    this.animationController = SVGAAnimationController(vsync: this);
    this.loadAnimation();
    super.initState();
  }

  @override
  void dispose() {
    this.animationController!.dispose();
    super.dispose();
  }

  void loadAnimation() async {
    final videoItem = await SVGAParser.shared.decodeFromURL(
        "https://github.com/yyued/SVGA-Samples/blob/master/angel.svga?raw=true");
    this.animationController!.videoItem = videoItem;
    this
        .animationController
        !.repeat() // Try to use .forward() .reverse()
        .whenComplete(() => this.animationController!.videoItem = null);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(color: isDark ? Colors.white : kContentColorLightTheme,),
      ),
      body: Container(
        child: SVGAImage(this.animationController!),
      ),
    );
  }
}
