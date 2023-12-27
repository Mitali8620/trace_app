import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/app_bar.dart';
import 'package:trace/ui/button_with_gradient.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';

import '../../app/config.dart';
import '../../services/dynamic_link_service.dart';

// ignore: must_be_immutable
class ReferralScreen extends StatefulWidget {
  UserModel? currentUser;

  ReferralScreen({this.currentUser});

  static String route = "/menu/referral";

  @override
  _ReferralScreenState createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final DynamicLinkService _dynamicLinkService = DynamicLinkService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ToolBar(
      title: "page_title.referral_title".tr(),
      centerTitle: QuickHelp.isAndroidPlatform() ? false : true,
      leftButtonIcon: Icons.arrow_back_ios,
      onLeftButtonTap: () => QuickHelp.goBackToPreviousPage(context),
      child: SafeArea(
        child: body(),
      ),
    );
  }

  Widget body() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ContainerCorner(
                color: kTransparentColor,
                marginTop: 70,
                marginBottom: 40,
                child: Image.asset("assets/images/ic_coins_4000.png")),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextWithTap(
                "invite_friends.get_".tr(),
                color: Colors.black,
                marginRight: 5,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
              SvgPicture.asset(
                "assets/svg/dolar_diamond.svg",
                width: 40,
                height: 40,
              ),
              TextWithTap(
                "invite_friends.for_free".tr(),
                color: Colors.black,
                marginLeft: 5,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ],
          ),
          ContainerCorner(
            color: kTransparentColor,
            marginTop: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextWithTap(
                  "invite_friends.invite_friends".tr(),
                  fontSize: 16,
                  color: Colors.black,
                ),
                SvgPicture.asset(
                  "assets/svg/ic_diamond.svg",
                  width: 20,
                  height: 20,
                ),
                TextWithTap(
                  "invite_friends.ten_percent".tr(),
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ],
            ),
          ),
          ContainerCorner(
            color: kTransparentColor,
            marginTop: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextWithTap(
                  "invite_friends.earnings_as_gift".tr(),
                  fontSize: 16,
                  color: Colors.black,
                ),
                Image.asset(
                  "assets/images/ic_logo.png",
                  height: 30,
                  width: 30,
                )
              ],
            ),
          ),
          ButtonWithGradient(
            activeBoxShadow: true,
            shadowColorOpacity: 0.3,
            height: 40,
            marginTop: 60,
            text: "invite_friends.share_link".tr(),
            beginColor: kWarninngColor,
            endColor: kPrimaryColor,
            marginRight: 40,
            svgURL: "assets/svg/ic_tips_share.svg",
            marginLeft: 40,
            onTap: () {
              createLink();
              //QuickHelp.goToNavigatorScreen(context, InvitedUsers(currentUser: widget.currentUser,));
            },
            borderRadius: 50,
          ),
        ],
      ),
    );
  }

  createLink() async {
    QuickHelp.showLoadingDialog(context);

    Uri? uri = await _dynamicLinkService
        .createDynamicLink(widget.currentUser!.objectId, DynamicLinkService.keyLinkInvitation);

    if (uri != null) {
      QuickHelp.hideLoadingDialog(context);
      Share.share("settings_screen.share_app_url".tr(namedArgs: {"app_name": Config.appName, "url": uri.toString()}));
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "settings_screen.app_could_not_gen_uri".tr(),
          user: widget.currentUser);
    }
  }
}
