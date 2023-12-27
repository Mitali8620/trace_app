// ignore_for_file: must_be_immutable

import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';

import '../../app/Config.dart';
import '../../helpers/quick_help.dart';
import '../../models/UserModel.dart';

class PrivilegeInfoScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  int? initialIndex;
  PrivilegeInfoScreen({
    this.initialIndex,
    this.currentUser,
    this.preferences,
    super.key,
  });

  @override
  State<PrivilegeInfoScreen> createState() => _PrivilegeInfoScreenState();
}

class _PrivilegeInfoScreenState extends State<PrivilegeInfoScreen> {

  var imagesExplains = [
    "assets/images/01_primeiro.png",
    "assets/images/02_segundo.png",
    "assets/images/03_terceiro.png",
    "assets/images/04_quatre.png",
    "assets/images/05_cinco.png",
    "assets/images/06_six.png",
    "assets/images/07_sept.png",
    "assets/images/08_oito.png",
    "assets/images/09_nove.png",
    "assets/images/10_dez.png",
    "assets/images/11_onze.png",
  ];

  var premiumTitle = [
    "wallet_screen.exclusive_social".tr(),
    "wallet_screen.level_up".tr(),
    "wallet_screen.family_privilege".tr(),
    "wallet_screen.enhances_presence".tr(),
    "wallet_screen.exclusive_vehicle".tr(),
    "wallet_screen.premium_badge".tr(),
    "wallet_screen.true_love".tr(),
    "wallet_screen.mini_background".tr(),
    "wallet_screen.status_symbol".tr(),
    "wallet_screen.exclusive_background".tr(),
    "wallet_screen.wealth_privileges".tr(),
  ];

  var textExplains = [
    "privilege_info_screen.more_record".tr(),
    "privilege_info_screen.gained_increase".tr(),
    "privilege_info_screen.more_progress".tr(),
    "privilege_info_screen.exclusive_comment".tr(),
    "privilege_info_screen.awesome_entrance".tr(),
    "privilege_info_screen.exclusive_frame".tr(),
    "privilege_info_screen.join_more_group".tr(),
    "privilege_info_screen.stream_bio".tr(),
    "privilege_info_screen.mvp_badge".tr(),
    "privilege_info_screen.party_room_wallpaper".tr(),
    "privilege_info_screen.claim_daily_diamonds".tr(),
  ];

  int carouselIndex = 0;
  CarouselController _controller = CarouselController();

  int diamondsToClaim = 10;


  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100)).then((value) {
      _controller.jumpToPage(widget.initialIndex ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kTransparentColor,
        leading: BackButton(
          color: Colors.white,
        ),
        title: TextWithTap(
            "privilege_info_screen.privilege_info".tr(),
          color: Colors.white,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ContainerCorner(
                imageDecoration: "assets/images/bg_privi_info_header.png",
                height: 530,
                width: size.width,
                borderWidth: 0,
                fit: BoxFit.fill,
              ),
              /*Image.asset(
                  "assets/images/bg_privi_info_header.png",
              ),*/
              ContainerCorner(
                borderWidth: 0,
                marginTop: size.width / 4,
                child: CarouselSlider.builder(
                  options: CarouselOptions(
                      autoPlay: true,
                      enlargeCenterPage: false,
                      viewportFraction: 1.8,
                      autoPlayAnimationDuration: const Duration(milliseconds: 400),
                      aspectRatio: 90 / 80,
                      autoPlayCurve: Curves.linear,
                      onPageChanged: (index, reason) {
                        setState(() {
                          carouselIndex = index;
                        });
                      }),
                  carouselController: _controller,
                  itemCount: imagesExplains.length,
                  itemBuilder:
                      (BuildContext context, int itemIndex, int pageViewIndex) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          imagesExplains[itemIndex],
                          height: size.width / 1.5,
                          width: size.width / 1.5,
                        ),
                        TextWithTap(
                          premiumTitle[itemIndex],
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size.width / 20,
                          marginTop: 30,
                          marginBottom: 10,
                        ),
                        TextWithTap(
                          textExplains[itemIndex],
                          color: Colors.white,
                        )
                      ],
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imagesExplains.asMap().entries.map((entry) {
                    return ContainerCorner(
                      width: 5.0,
                      height: 5.0,
                      marginRight: 5,
                      borderRadius: 50,
                      borderWidth: 0,
                      onTap: () => _controller.animateToPage(entry.key),
                      color: carouselIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          TextWithTap(
            "wallet_screen.notice_".tr(),
            color: kGrayColor,
            fontSize: 12,
            marginLeft: 15,
            marginBottom: 15,
            marginTop: 35,
          ),
          TextWithTap(
            "wallet_screen.notice_1".tr(namedArgs: {
              "app_name": Config.appName,
              "platform": platformName(),
            }),
            color: kGrayColor,
            fontSize: 12,
            marginLeft: 15,
            marginBottom: 25,
            marginRight: 15,
          ),
          TextWithTap(
            "wallet_screen.notice_2".tr(),
            color: kGrayColor,
            fontSize: 12,
            marginLeft: 15,
            marginBottom: 25,
            marginRight: 15,
          ),
          TextWithTap(
            "wallet_screen.notice_3"
                .tr(namedArgs: {"amount": "$diamondsToClaim"}),
            color: kGrayColor,
            fontSize: 12,
            marginLeft: 15,
            marginBottom: 25,
            marginRight: 15,
          ),
          SizedBox(
            height: 200,
          ),
        ],
      ),
    );
  }

  String platformName() {
    if (QuickHelp.isAndroidPlatform()) {
      return "wallet_screen.google_pay".tr();
    } else if (QuickHelp.isIOSPlatform()) {
      return "wallet_screen.apple_pay".tr();
    } else {
      return "";
    }
  }
}
