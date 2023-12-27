// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/quick_help.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';

class InviteAgentScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  InviteAgentScreen({this.currentUser, this.preferences, Key? key}) : super(key: key);

  @override
  State<InviteAgentScreen> createState() => _InviteAgentScreenState();
}

class _InviteAgentScreenState extends State<InviteAgentScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: isDark ? Colors.white : kContentColorLightTheme,
        ),
        centerTitle: true,
        title: TextWithTap(
          "invite_agent_screen.invite_agent".tr(),
          fontWeight: FontWeight.w900,
        ),
      ),
      body: ContainerCorner(
        height: size.height,
        width: size.width,
        borderWidth: 0,
        imageDecoration: "assets/images/bg_invite_agent.png",
        child: TextWithTap(
          "Chancilson Smart",
          color: Colors.white,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
