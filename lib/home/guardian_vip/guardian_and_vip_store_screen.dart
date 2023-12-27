// ignore_for_file: must_be_immutable

import 'package:auto_size_text_plus/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/button_widget.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';

import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../ui/container_with_corner.dart';
import '../choose_guardian/choose_guardian_screen.dart';
import '../coins/coins_payment_widget.dart';
import '../privilege/privilege_setting_screen.dart';
import '../profile/user_profile_screen.dart';

class GuardianAndVipStoreScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  int? initialIndex;

  GuardianAndVipStoreScreen(
      {this.initialIndex, this.preferences, this.currentUser, Key? key})
      : super(key: key);

  @override
  State<GuardianAndVipStoreScreen> createState() =>
      _GuardianAndVipStoreScreenState();
}

class _GuardianAndVipStoreScreenState extends State<GuardianAndVipStoreScreen>
    with TickerProviderStateMixin {
  int tabIndex = 1;

  int tabsLength = 2;

  int vipTabsLength = 3;
  int vipTabsInitialIndex = 0;
  int vipTabsIndex = 0;

  int tabGuardian = 0;
  int tabVip = 1;

  int guardianTextIndex = 0;

  int guardianSliverPricePerMonth = 150000;
  int guardianGoldPricePerMonth = 300000;
  int guardianKingPricePerMonth = 1500000;

  int normalVipPricePerMonth = 95000;
  int superVipPricePerMonth = 450000;
  int diamondVipPricePerMonth = 1000000;

  int normalVipValueReceiveCoins = 105000;
  int normalVipValueLiveFloat = 15000;
  int normalVipValuePlatformSpeaker = 60000;
  int normalVipValuePlatformFloat = 60000;

  int superVipValueReceiveCoins = 480000;
  int superVipValueLiveFloat = 30000;
  int superVipValuePlatformSpeaker = 60000;
  int superVipValuePlatformFloat = 60000;

  int diamondVipValueReceiveCoins = 1050000;
  int diamondVipValueLiveFloat = 75000;
  int diamondVipValuePlatformSpeaker = 120000;
  int diamondVipValuePlatformFloat = 120000;

  int receiveCoinValue() {
    if (vipTabsIndex == 0) {
      return normalVipValueReceiveCoins;
    } else if (vipTabsIndex == 1) {
      return superVipValueReceiveCoins;
    } else if (vipTabsIndex == 2) {
      return diamondVipValueReceiveCoins;
    }
    return 0;
  }

  int selectedVipTypeAmount() {
    if (vipTabsIndex == 0) {
      return normalVipPricePerMonth;
    } else if (vipTabsIndex == 1) {
      return superVipPricePerMonth;
    } else if (vipTabsIndex == 2) {
      return diamondVipPricePerMonth;
    }
    return 0;
  }

  int liveFloatValue() {
    if (vipTabsIndex == 0) {
      return normalVipValueLiveFloat;
    } else if (vipTabsIndex == 1) {
      return superVipValueLiveFloat;
    } else if (vipTabsIndex == 2) {
      return diamondVipValueLiveFloat;
    }
    return 0;
  }

  int platSpeakerValue() {
    if (vipTabsIndex == 0) {
      return normalVipValuePlatformSpeaker;
    } else if (vipTabsIndex == 1) {
      return superVipValuePlatformSpeaker;
    } else if (vipTabsIndex == 2) {
      return diamondVipValuePlatformSpeaker;
    }
    return 0;
  }

  int platFloatValue() {
    if (vipTabsIndex == 0) {
      return normalVipValuePlatformFloat;
    } else if (vipTabsIndex == 1) {
      return superVipValuePlatformFloat;
    } else if (vipTabsIndex == 2) {
      return diamondVipValuePlatformFloat;
    }
    return 0;
  }

  UserModel? userToGuard;

  int selectedGuardianPrice() {
    if (selectedGuardianType[0] == 0) {
      return guardianSliverPricePerMonth;
    } else if (selectedGuardianType[0] == 1) {
      return guardianGoldPricePerMonth;
    } else if (selectedGuardianType[0] == 2) {
      return guardianKingPricePerMonth;
    }
    return 0;
  }

  String guardianActivateButtonTexts() {
    if (selectedGuardianType[0] == 0) {
      return "guardian_and_vip_screen.activated_sliver".tr();
    } else if (selectedGuardianType[0] == 1) {
      return "guardian_and_vip_screen.activated_gold".tr();
    } else if (selectedGuardianType[0] == 2) {
      return "guardian_and_vip_screen.activated_king".tr();
    }
    return "";
  }

  String vipOpenButtonTexts() {
    if (vipTabsIndex == 0) {
      return "guardian_and_vip_screen.open_normal_vip".tr();
    } else if (vipTabsIndex == 1) {
      return "guardian_and_vip_screen.open_super_vip".tr();
    } else if (vipTabsIndex == 2) {
      return "guardian_and_vip_screen.open_diamond_vip".tr();
    }
    return "";
  }

  List<Color> guardianActivateButtonColors() {
    if (selectedGuardianType[0] == 0) {
      return [kBlueColor, kBlueColor];
    } else if (selectedGuardianType[0] == 1) {
      return [kOrangeColor, kOrangeColor];
    } else if (selectedGuardianType[0] == 2) {
      return [kPrimaryColor, kSecondaryColor];
    }
    return [kTransparentColor, kTransparentColor];
  }

  List<Color> vipOpenButtonColors() {
    if (vipTabsIndex == 0) {
      return [kBlueColor, kBlueColor];
    } else if (vipTabsIndex == 1) {
      return [kOrangeColor, kOrangeColor];
    } else if (vipTabsIndex == 2) {
      return [kPrimaryColor, kSecondaryColor];
    }
    return [kTransparentColor, kTransparentColor];
  }

  Color guardianPrivilegeIconsColors() {
    if (selectedGuardianType[0] == 0) {
      return kBlueColor.withOpacity(0.1);
    } else if (selectedGuardianType[0] == 1) {
      return kOrangeColor.withOpacity(0.1);
    } else if (selectedGuardianType[0] == 2) {
      return kPrimaryColor.withOpacity(0.1);
    }
    return kTransparentColor;
  }

  var selectedIndexedTitles = ["guardian_and_vip_screen.buy_guardian".tr()];

  var indexedGuardianTitles = [
    "guardian_and_vip_screen.buy_guardian".tr(),
    "guardian_and_vip_screen.my_guardian".tr(),
    "guardian_and_vip_screen.guard_me".tr(),
  ];

  var vipTabsTitles = [
    "guardian_and_vip_screen.normal_vip".tr(),
    "guardian_and_vip_screen.super_vip".tr(),
    "guardian_and_vip_screen.diamond_vip".tr(),
  ];

  String selectedVipTypeText() {
    if (vipTabsIndex == 0) {
      return vipTabsTitles[0];
    } else if (vipTabsIndex == 1) {
      return vipTabsTitles[1];
    } else if (vipTabsIndex == 2) {
      return vipTabsTitles[2];
    }
    return "";
  }

  var guardianImages = [
    "assets/images/icon_sh_1.png",
    "assets/images/icon_sh_2.png",
    "assets/images/icon_sh_3.png",
  ];

  var guardianImagesExplain = [
    "guardian_and_vip_screen.guardian_silver".tr(),
    "guardian_and_vip_screen.guardian_gold".tr(),
    "guardian_and_vip_screen.guardian_king".tr(),
  ];

  var guardianPrivilegesTexts = [
    "guardian_and_vip_screen.raking_forward".tr(),
    "guardian_and_vip_screen.distinguished_logo".tr(),
    "guardian_and_vip_screen.entry_effects".tr(),
    "guardian_and_vip_screen.exclusive_bubble".tr(),
  ];

  var goldIconsUrl = [
    "assets/images/ic_gold_rank.png",
    "assets/images/ic_gold_distinct.png",
    "assets/images/ic_gold_entry.png",
    "assets/images/ic_gold_exclusive.png",
  ];

  var silverIconsUrl = [
    "assets/images/ic_silver_rank.png",
    "assets/images/ic_silver_distinct.png",
    "assets/images/ic_silver_entry.png",
    "assets/images/ic_silver_exclusive.png",
  ];

  var kingIconsUrl = [
    "assets/images/ic_king_rank.png",
    "assets/images/ic_king_distinct.png",
    "assets/images/ic_king_entry.png",
    "assets/images/ic_king_exclusive.png",
  ];

  var vipExclusivePrivilegeFirstSixTitles = [
    "guardian_and_vip_screen.receive_coin".tr(),
    "guardian_and_vip_screen.live_float_tag".tr(),
    "guardian_and_vip_screen.platform_speaker".tr(),
    "guardian_and_vip_screen.platform_float_tag".tr(),
    "guardian_and_vip_screen.ranking_forward".tr(),
    "guardian_and_vip_screen.distinguished_logo".tr(),
  ];

  var normalVipOffersPerDay = ["+3,500/d", "+1/d", "+1/d", "+1/d", "", ""];
  var superVipOffersPerDay = ["+16,000/d", "+2/d", "+1/d", "+1/d", "", ""];
  var diamondVipOffersPerDay = ["+35,000/d", "+5/d", "+2/d", "+2/d", "", ""];

  var vipLiveExclusiveInvisibleTitles = [
    "guardian_and_vip_screen.live_translation".tr(),
    "guardian_and_vip_screen.exclusive_data_card".tr(),
    "guardian_and_vip_screen.invisible_visitor".tr(),
  ];

  var vipLiveExclusiveInvisibleExplains = [
    "guardian_and_vip_screen.live_translation_explain".tr(),
    "guardian_and_vip_screen.exclusive_data_card_explain".tr(),
    "guardian_and_vip_screen.invisible_visitor_explain".tr(),
  ];

  var vipMysteriousMysteryEntryTitles = [
    "guardian_and_vip_screen.mysterious_man".tr(),
    "guardian_and_vip_screen.mystery_man".tr(),
    "guardian_and_vip_screen.entry_special_effect".tr(),
  ];

  var vipMysteriousMysteryEntryExplains = [
    "guardian_and_vip_screen.mysterious_man_explain".tr(),
    "guardian_and_vip_screen.mystery_man_explain".tr(),
    "guardian_and_vip_screen.entry_special_effect_explain".tr(),
  ];

  var vipExclusivePreventVipTitles = [
    "guardian_and_vip_screen.exclusive_message_background".tr(),
    "guardian_and_vip_screen.prevent_being_kicked".tr(),
    "guardian_and_vip_screen.vip_customer_service".tr(),
  ];

  var vipExclusivePreventVipExplains = [
    "guardian_and_vip_screen.exclusive_message_background_explain".tr(),
    "guardian_and_vip_screen.prevent_being_kicked_explain".tr(),
    "guardian_and_vip_screen.vip_customer_service_explain".tr(),
  ];

  var normalVipIconsUrls = [
    "assets/images/ic_normal_receive.png",
    "assets/images/ic_normal_live.png",
    "assets/images/ic_normal_platform.png",
    "assets/images/ic_normal_float.png",
    "assets/images/ic_normal_ranking.png",
    "assets/images/ic_normal_distinct.png",
  ];

  var normalLiveRowIconsUrls = [
    "assets/images/ic_normal_translation.png",
    "assets/images/ic_standard_exclusive.png",
    "assets/images/ic_standard_invisible.png",
  ];

  var normalMysteryRowIconsUrls = [
    "assets/images/ic_standard_mysterious.png",
    "assets/images/ic_standard_mystery.png",
    "assets/images/ic_standard_entry.png",
  ];

  var normalMessageRowIconsUrls = [
    "assets/images/ic_standard_message.png",
    "assets/images/ic_standard_prevent.png",
    "assets/images/ic_standard_service.png",
  ];

  var superFirstSixIconsUrls = [
    "assets/images/ic_super_receive.png",
    "assets/images/ic_super_live.png",
    "assets/images/ic_super_speaker.png",
    "assets/images/ic_super_float_tag.png",
    "assets/images/ic_super_rank.png",
    "assets/images/ic_super_distinct.png",
  ];

  var superLiveRowIconsUrls = [
    "assets/images/ic_super_translate.png",
    "assets/images/ic_super_exclusive.png",
    "assets/images/ic_super_visitor.png",
  ];

  var superMysteryRowIconsUrls = [
    "assets/images/ic_standard_mysterious.png",
    "assets/images/ic_standard_mystery.png",
    "assets/images/ic_standard_entry.png",
  ];

  var superMessageRowIconsUrls = [
    "assets/images/ic_standard_message.png",
    "assets/images/ic_standard_prevent.png",
    "assets/images/ic_standard_service.png",
  ];

  var diamondFirstSixIconsUrls = [
    "assets/images/ic_diamond_receive_coin.png",
    "assets/images/ic_diamond_float.png",
    "assets/images/ic_diamond_platform.png",
    "assets/images/ic_diamond_float_tag.png",
    "assets/images/ic_diamond_ranking.png",
    "assets/images/ic_diamond_distinct.png",
  ];

  var diamondLiveRowIconsUrls = [
    "assets/images/ic_diamond_translate.png",
    "assets/images/ic_diamond_exclusive.png",
    "assets/images/ic_diamond_invisible.png",
  ];

  var diamondMysteryRowIconsUrls = [
    "assets/images/ic_diamond_mysterious.png",
    "assets/images/ic_diamond_mystery.png",
    "assets/images/ic_diamond_entry.png",
  ];

  var diamondMessageRowIconsUrls = [
    "assets/images/ic_diamond_message.png",
    "assets/images/ic_diamond_prevent.png",
    "assets/images/ic_diamond_service.png",
  ];

  var vipExclusivePrivilegeFirstSixExplain = [];

  List guardianIcons() {
    if (selectedGuardianType[0] == 0) {
      return silverIconsUrl;
    } else if (selectedGuardianType[0] == 1) {
      return goldIconsUrl;
    } else if (selectedGuardianType[0] == 2) {
      return kingIconsUrl;
    }
    return [];
  }

  var guardianExplainColors = [silverColor, goldGrayColor, kingColor];
  var selectedGuardianType = [0];
  var guardianPeriod = [1, 3, 6, 12];
  var selectedGuardianPeriod = [1];

  late TabController generalTabControl;
  late TabController vipTabControl;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      tabIndex = widget.initialIndex!;
    } else {
      tabIndex = 1;
    }

    vipTabControl = TabController(
        vsync: this, length: vipTabsLength, initialIndex: vipTabsInitialIndex)
      ..addListener(() {
        setState(() {
          vipTabsIndex = vipTabControl.index;
        });
      });

    generalTabControl = TabController(
        vsync: this,
        length: tabsLength,
        initialIndex: widget.initialIndex ?? tabVip)
      ..addListener(() {
        setState(() {
          tabIndex = generalTabControl.index;
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    generalTabControl.dispose();
    vipTabControl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);

    vipExclusivePrivilegeFirstSixExplain = [
      "guardian_and_vip_screen.value_".tr(namedArgs: {
        "amount":
            QuickHelp.checkFundsWithString(amount: "${receiveCoinValue()}")
      }),
      "guardian_and_vip_screen.value_".tr(namedArgs: {
        "amount": QuickHelp.checkFundsWithString(amount: "${liveFloatValue()}")
      }),
      "guardian_and_vip_screen.value_".tr(namedArgs: {
        "amount":
            QuickHelp.checkFundsWithString(amount: "${platSpeakerValue()}"),
      }),
      "guardian_and_vip_screen.value_".tr(namedArgs: {
        "amount": QuickHelp.checkFundsWithString(amount: "${platFloatValue()}")
      }),
      "guardian_and_vip_screen.ranking_forward_explain".tr(),
      "guardian_and_vip_screen.distinguished_logo_explain".tr(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkGrayColor,
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: Colors.white,
        ),
        centerTitle: true,
        title: TabBar(
          isScrollable: true,
          enableFeedback: false,
          controller: generalTabControl,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: kTransparentColor,
          unselectedLabelColor: kGrayColor,
          indicatorWeight: 2.0,
          labelPadding: EdgeInsets.symmetric(
            horizontal: 7.0,
          ),
          automaticIndicatorColorAdjustment: false,
          labelColor: Colors.white,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(50)),
            insets: EdgeInsets.symmetric(
              horizontal: 15.0,
            ),
          ),
          labelStyle: TextStyle(fontSize: 18),
          unselectedLabelStyle: TextStyle(fontSize: 16),
          tabs: [
            TextWithTap(
              "guardian_and_vip_screen.guardian_".tr(),
              marginBottom: 7,
            ),
            TextWithTap(
              "guardian_and_vip_screen.vip_".tr(),
              marginBottom: 7,
            ),
          ],
        ),
        actions: [
          Visibility(
            visible: tabIndex == 1,
            child: IconButton(
                onPressed: () {
                  QuickHelp.goToNavigatorScreen(
                    context,
                    PrivilegeSettingScreen(
                      currentUser: widget.currentUser,
                      preferences: widget.preferences,
                    ),
                  );
                },
                icon: Image.asset(
                  "assets/images/ic_go_privilege_setting.png",
                  height: 25,
                )),
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(tabIndex == 1 ? 70.0 : 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ContainerCorner(
                height: 35,
                width: size.width,
                borderWidth: 0,
                color: darkGrayColor,
                child: appBarBottom(),
              ),
              Visibility(
                visible: tabIndex == 1,
                child: Row(
                  children: [
                    QuickActions.avatarBorder(
                      widget.currentUser!,
                      width: 40,
                      height: 40,
                      borderMargin: EdgeInsets.only(left: 15),
                      borderColor: Colors.white,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWithTap(
                          widget.currentUser!.getFullName!,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          marginLeft: 10,
                        ),
                        TextWithTap(
                          "guardian_and_vip_screen.enjoy_vip_privilege".tr(),
                          color: kGrayColor,
                          fontSize: 9,
                          marginTop: 5,
                          marginLeft: 10,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: generalTabControl,
        children: [
          IndexedStack(
            index: guardianTextIndex,
            children: [
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  ContainerCorner(
                    borderWidth: 0,
                    width: size.width,
                    color: darkGrayColor,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(guardianImagesExplain.length,
                              (index) {
                            return guardianTypes(
                              imageUrl: guardianImages[index],
                              text: guardianImagesExplain[index],
                              color: guardianExplainColors[index],
                              index: index,
                            );
                          }),
                        ),
                        guardianPeriods(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextWithTap(
                              "guardian_and_vip_screen.coins_needed".tr(),
                              color: Colors.white,
                              fontSize: 12,
                              marginTop: 20,
                              marginBottom: 20,
                            ),
                            TextWithTap(
                              QuickHelp.checkFundsWithString(
                                  amount:
                                      "${selectedGuardianPrice() * selectedGuardianPeriod[0]}"),
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              marginTop: 20,
                              marginRight: 20,
                              marginBottom: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TextWithTap(
                    "guardian_and_vip_screen.want_guard_him".tr(),
                    fontSize: 17,
                    marginTop: 10,
                    marginLeft: 10,
                    marginBottom: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      showUserToGuard(),
                      ContainerCorner(
                        height: 30,
                        borderRadius: 50,
                        marginRight: 10,
                        color: kPrimaryColor.withOpacity(0.3),
                        child: ButtonWidget(
                          onTap: () async {
                            UserModel? user =
                                await QuickHelp.goToNavigatorScreenForResult(
                              context,
                              ChooseGuardianScreen(
                                currentUser: widget.currentUser,
                                preferences: widget.preferences,
                                isSending: false,
                              ),
                            );
                            if (user != null) {
                              userToGuard = user;
                              setState(() {});
                            }
                          },
                          child: TextWithTap(
                            "guardian_and_vip_screen.select_".tr(),
                            color: kPrimaryColor,
                            marginLeft: 5,
                            marginRight: 5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextWithTap(
                    "guardian_and_vip_screen.guardian_privileges".tr(),
                    fontSize: 17,
                    marginTop: 10,
                    marginLeft: 10,
                    marginBottom: 15,
                  ),
                  ContainerCorner(
                    radiusBottomRight: 10,
                    radiusBottomLeft: 10,
                    marginRight: 15,
                    marginLeft: 15,
                    width: size.width,
                    borderWidth: 0,
                    height: 250,
                    marginTop: 10,
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: NeverScrollableScrollPhysics(),
                      children: List.generate(
                        guardianPrivilegesTexts.length,
                        (index) {
                          return ContainerCorner(
                            borderRadius: 10,
                            color: isDark ? kContentDarkShadow : kGrayWhite,
                            child: Column(
                              children: [
                                ContainerCorner(
                                  borderRadius: 50,
                                  height: 40,
                                  width: 40,
                                  color: guardianPrivilegeIconsColors(),
                                  marginTop: 10,
                                  marginBottom: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(guardianIcons()[index]),
                                  ),
                                ),
                                AutoSizeText(
                                  guardianPrivilegesTexts[index],
                                  maxFontSize: 14,
                                  minFontSize: 12,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white
                                        : kContentDarkShadow,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  TextWithTap(
                    "guardian_and_vip_screen.number_host_guard_me"
                        .tr(namedArgs: {
                      "amount":
                          widget.currentUser!.getMyGuardians!.length.toString()
                    }),
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.bold,
                    marginLeft: 10,
                    marginTop: 20,
                  ),
                  peopleIGuard(),
                ],
              ),
              ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  TextWithTap(
                    "guardian_and_vip_screen.number_people_guarding_me"
                        .tr(namedArgs: {
                      "amount": widget.currentUser!.getPeopleGuardingMe!.length
                          .toString()
                    }),
                    fontSize: size.width / 22,
                    fontWeight: FontWeight.bold,
                    marginLeft: 10,
                    marginTop: 20,
                  ),
                  peopleGuardingMe(),
                ],
              ),
            ],
          ),
          ContainerCorner(
            width: size.width,
            height: size.height,
            borderWidth: 0,
            child: TabBarView(
              controller: vipTabControl,
              children: [
                vipTypeInfo(
                  vipTypeImageUrl: "assets/images/normal_vip_image.png",
                  vipTypeName: "guardian_and_vip_screen.normal_vip".tr(),
                  pricePerMonth: normalVipPricePerMonth,
                  privilegeAmount: 7,
                  listOfDailyOffers: normalVipOffersPerDay,
                  firstSixExplains: vipExclusivePrivilegeFirstSixExplain,
                  vipTypeColor: kBlueColor.withOpacity(0.1),
                  firstSixIconsUrl: normalVipIconsUrls,
                  liveRowIconsUrl: normalLiveRowIconsUrls,
                  mysteryRowIconsUrl: normalMysteryRowIconsUrls,
                  messageRowIconsUrl: normalMessageRowIconsUrls,
                ),
                vipTypeInfo(
                  vipTypeImageUrl: "assets/images/super_vip_image.png",
                  vipTypeName: "guardian_and_vip_screen.normal_vip".tr(),
                  pricePerMonth: superVipPricePerMonth,
                  privilegeAmount: 9,
                  listOfDailyOffers: superVipOffersPerDay,
                  firstSixExplains: vipExclusivePrivilegeFirstSixExplain,
                  vipTypeColor: kOrangeColor.withOpacity(0.1),
                  firstSixIconsUrl: superFirstSixIconsUrls,
                  liveRowIconsUrl: superLiveRowIconsUrls,
                  mysteryRowIconsUrl: superMysteryRowIconsUrls,
                  messageRowIconsUrl: superMessageRowIconsUrls,
                ),
                vipTypeInfo(
                  vipTypeImageUrl: "assets/images/diamond_vip_image.png",
                  vipTypeName: "guardian_and_vip_screen.normal_vip".tr(),
                  pricePerMonth: diamondVipPricePerMonth,
                  privilegeAmount: 7,
                  listOfDailyOffers: diamondVipOffersPerDay,
                  firstSixExplains: vipExclusivePrivilegeFirstSixExplain,
                  vipTypeColor: kPrimaryColor.withOpacity(0.1),
                  firstSixIconsUrl: diamondFirstSixIconsUrls,
                  liveRowIconsUrl: diamondLiveRowIconsUrls,
                  mysteryRowIconsUrl: diamondMysteryRowIconsUrls,
                  messageRowIconsUrl: diamondMessageRowIconsUrls,
                )
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: buttons(),
    );
  }

  Widget vipTypeInfo(
      {required String vipTypeImageUrl,
      required String vipTypeName,
      required int pricePerMonth,
      required int privilegeAmount,
      required List listOfDailyOffers,
      required List firstSixExplains,
      required List firstSixIconsUrl,
      required List liveRowIconsUrl,
      required List mysteryRowIconsUrl,
      required List messageRowIconsUrl,
      required Color vipTypeColor,
      required}) {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ContainerCorner(
          color: darkGrayColor,
          height: 140,
          borderWidth: 0,
          width: size.width,
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 30, right: 30),
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Image.asset(vipTypeImageUrl),
                    Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              vipTypeName,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              marginLeft: 30,
                              marginBottom: 10,
                              marginTop: 40,
                              color: Colors.white,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextWithTap(
                                  QuickHelp.checkFundsWithString(
                                    amount: "$pricePerMonth",
                                  ),
                                  color: Colors.white,
                                  marginLeft: 30,
                                ),
                                SvgPicture.asset(
                                  "assets/svg/ic_coin_with_star.svg",
                                  width: size.width / 35,
                                  height: size.width / 35,
                                ),
                                TextWithTap(
                                  "/M",
                                  color: Colors.white,
                                )
                              ],
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              )),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ContainerCorner(
              height: 1.5,
              width: 40,
              color: kGrayColor.withOpacity(0.5),
              marginTop: 20,
            ),
            TextWithTap(
              "guardian_and_vip_screen.vip_exclusive_privileges"
                  .tr(namedArgs: {"amount": "$privilegeAmount/15"}),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              alignment: Alignment.center,
              marginTop: 20,
              marginLeft: 10,
              marginRight: 10,
            ),
            ContainerCorner(
              height: 1.5,
              width: 40,
              color: kGrayColor.withOpacity(0.5),
              marginTop: 20,
            ),
          ],
        ),
        ContainerCorner(
          radiusBottomRight: 10,
          radiusBottomLeft: 10,
          marginRight: 15,
          marginLeft: 15,
          width: size.width,
          borderWidth: 0,
          height: 265,
          marginTop: 10,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              vipExclusivePrivilegeFirstSixTitles.length,
              (index) {
                return ContainerCorner(
                  borderRadius: 10,
                  color: isDark ? kContentDarkShadow : kGrayWhite,
                  child: Column(
                    children: [
                      ContainerCorner(
                        borderRadius: 50,
                        height: 40,
                        width: 40,
                        color: vipTypeColor,
                        marginTop: 10,
                        marginBottom: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(firstSixIconsUrl[index]),
                        ),
                      ),
                      AutoSizeText(
                        vipExclusivePrivilegeFirstSixTitles[index],
                        maxFontSize: 11.0,
                        minFontSize: 9.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : kContentDarkShadow,
                        ),
                        maxLines: 2,
                      ),
                      Visibility(
                        visible: listOfDailyOffers[index].isNotEmpty,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Visibility(
                              visible: index < 1,
                              child: SvgPicture.asset(
                                "assets/svg/ic_coin_with_star.svg",
                                width: size.width / 37,
                                height: size.width / 37,
                              ),
                            ),
                            TextWithTap(
                              listOfDailyOffers[index],
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: index < 4,
                            child: SvgPicture.asset(
                              "assets/svg/ic_coin_with_star.svg",
                              width: size.width / 37,
                              height: size.width / 37,
                            ),
                          ),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AutoSizeText(
                                  firstSixExplains[index],
                                  maxFontSize: 9.0,
                                  minFontSize: 5.0,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: kGrayColor,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        ContainerCorner(
          radiusBottomRight: 10,
          radiusBottomLeft: 10,
          marginRight: 15,
          marginLeft: 15,
          width: size.width,
          borderWidth: 0,
          height: 145,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              vipLiveExclusiveInvisibleTitles.length,
              (index) {
                return ContainerCorner(
                  borderRadius: 10,
                  color: isDark ? kContentDarkShadow : kGrayWhite,
                  child: Column(
                    children: [
                      ContainerCorner(
                        borderRadius: 50,
                        height: 40,
                        width: 40,
                        color: (privilegeAmount == 7 && index < 1) ||
                                privilegeAmount == 9
                            ? vipTypeColor
                            : kGrayColor.withOpacity(0.09),
                        marginTop: 10,
                        marginBottom: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(liveRowIconsUrl[index]),
                        ),
                      ),
                      AutoSizeText(
                        vipLiveExclusiveInvisibleTitles[index],
                        maxFontSize: 11.0,
                        minFontSize: 9.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : kContentDarkShadow,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: AutoSizeText(
                          vipLiveExclusiveInvisibleExplains[index],
                          maxFontSize: 9.0,
                          minFontSize: 5.0,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            color: kGrayColor,
                          ),
                          maxLines: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        ContainerCorner(
          radiusBottomRight: 10,
          radiusBottomLeft: 10,
          marginRight: 15,
          marginLeft: 15,
          width: size.width,
          borderWidth: 0,
          marginTop: 3,
          height: 195,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.6,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              vipMysteriousMysteryEntryTitles.length,
              (index) {
                return ContainerCorner(
                  borderRadius: 10,
                  color: isDark ? kContentDarkShadow : kGrayWhite,
                  child: Column(
                    children: [
                      ContainerCorner(
                        borderRadius: 50,
                        height: 40,
                        width: 40,
                        color: privilegeAmount == 15
                            ? vipTypeColor
                            : kGrayColor.withOpacity(0.09),
                        marginTop: 10,
                        marginBottom: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(mysteryRowIconsUrl[index]),
                        ),
                      ),
                      AutoSizeText(
                        vipMysteriousMysteryEntryTitles[index],
                        maxFontSize: 11.0,
                        minFontSize: 9.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : kContentDarkShadow,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: AutoSizeText(
                          vipMysteriousMysteryEntryExplains[index],
                          maxFontSize: 9.0,
                          minFontSize: 5.0,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            color: kGrayColor,
                          ),
                          maxLines: 9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        ContainerCorner(
          radiusBottomRight: 10,
          radiusBottomLeft: 10,
          marginRight: 15,
          marginLeft: 15,
          width: size.width,
          borderWidth: 0,
          marginTop: 3,
          height: 195,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            physics: NeverScrollableScrollPhysics(),
            children: List.generate(
              vipExclusivePreventVipTitles.length,
              (index) {
                return ContainerCorner(
                  borderRadius: 10,
                  color: isDark ? kContentDarkShadow : kGrayWhite,
                  child: Column(
                    children: [
                      ContainerCorner(
                        borderRadius: 50,
                        height: 40,
                        width: 40,
                        color: privilegeAmount == 15
                            ? vipTypeColor
                            : kGrayColor.withOpacity(0.09),
                        marginTop: 10,
                        marginBottom: 10,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(messageRowIconsUrl[index]),
                        ),
                      ),
                      AutoSizeText(
                        vipExclusivePreventVipTitles[index],
                        maxFontSize: 11.0,
                        minFontSize: 9.0,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : kContentDarkShadow,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: AutoSizeText(
                          vipExclusivePreventVipExplains[index],
                          maxFontSize: 9.0,
                          minFontSize: 5.0,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            color: kGrayColor,
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget peopleGuardingMe() {
    Size size = MediaQuery.of(context).size;

    QueryBuilder<UserModel> queryBuilder =
        QueryBuilder<UserModel>(UserModel.forQuery());
    queryBuilder.whereContainedIn(
        UserModel.keyObjectId, widget.currentUser!.getPeopleGuardingMe!);

    return ParseLiveListWidget<UserModel>(
      query: queryBuilder,
      reverse: false,
      lazyLoading: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.zero,
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<UserModel> snapshot) {
        if (snapshot.hasData) {
          UserModel user = snapshot.loadedData!;

          return Padding(
            padding: EdgeInsets.all(8.0),
            child: ContainerCorner(
              onTap: () => QuickHelp.goToNavigatorScreen(
                  context,
                  UserProfileScreen(
                    currentUser: widget.currentUser,
                    mUser: user,
                    isFollowing: false,
                    preferences: widget.preferences,
                  )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuickActions.avatarWidget(user,
                          width: size.width / 6, height: size.width / 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              user.getFullName!,
                              fontSize: size.width / 23,
                              fontWeight: FontWeight.w600,
                              marginBottom: 4,
                            ),
                            Row(
                              children: [
                                QuickActions.getGender(
                                    currentUser: user, context: context),
                                const SizedBox(
                                  width: 5,
                                ),
                                QuickActions.giftReceivedLevel(
                                  receivedGifts: user.getDiamondsTotal!,
                                  width: 35,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                QuickActions.wealthLevel(
                                  credit: user.getCreditsSent!,
                                  width: 35,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextWithTap(
                                  "tab_profile.id_".tr(),
                                  fontSize: size.width / 33,
                                  fontWeight: FontWeight.w900,
                                ),
                                TextWithTap(
                                  widget.currentUser!.getUid!.toString(),
                                  fontSize: size.width / 33,
                                  marginLeft: 3,
                                  marginRight: 3,
                                ),
                                Icon(
                                  Icons.copy,
                                  color: kGrayColor,
                                  size: size.width / 30,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      },
      listLoadingElement: QuickHelp.appLoading(),
      queryEmptyElement: ContainerCorner(
        borderWidth: 0,
        width: size.width,
        height: size.height / 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/szy_kong_icon.png",
              height: size.width / 2,
              width: size.width / 2,
            ),
            TextWithTap(
              "guardian_and_vip_screen.no_one_guard_you_title".tr(),
            ),
            TextWithTap(
              "guardian_and_vip_screen.no_one_guard_you_explain".tr(),
              color: kGrayColor,
              fontSize: 12,
              marginTop: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget peopleIGuard() {
    Size size = MediaQuery.of(context).size;

    QueryBuilder<UserModel> queryBuilder =
        QueryBuilder<UserModel>(UserModel.forQuery());
    queryBuilder.whereContainedIn(
        UserModel.keyObjectId, widget.currentUser!.getMyGuardians!);

    return ParseLiveListWidget<UserModel>(
      query: queryBuilder,
      reverse: false,
      lazyLoading: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.zero,
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<UserModel> snapshot) {
        if (snapshot.hasData) {
          UserModel user = snapshot.loadedData!;

          return Padding(
            padding: EdgeInsets.all(8.0),
            child: ContainerCorner(
              onTap: () => QuickHelp.goToNavigatorScreen(
                  context,
                  UserProfileScreen(
                    currentUser: widget.currentUser,
                    mUser: user,
                    isFollowing: false,
                    preferences: widget.preferences,
                  )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuickActions.avatarWidget(user,
                          width: size.width / 6, height: size.width / 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              user.getFullName!,
                              fontSize: size.width / 23,
                              fontWeight: FontWeight.w600,
                              marginBottom: 4,
                            ),
                            Row(
                              children: [
                                QuickActions.getGender(
                                    currentUser: user, context: context),
                                const SizedBox(
                                  width: 5,
                                ),
                                QuickActions.giftReceivedLevel(
                                  receivedGifts: user.getDiamondsTotal!,
                                  width: 35,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                QuickActions.wealthLevel(
                                  credit: user.getCreditsSent!,
                                  width: 35,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextWithTap(
                                  "tab_profile.id_".tr(),
                                  fontSize: size.width / 33,
                                  fontWeight: FontWeight.w900,
                                ),
                                TextWithTap(
                                  widget.currentUser!.getUid!.toString(),
                                  fontSize: size.width / 33,
                                  marginLeft: 3,
                                  marginRight: 3,
                                ),
                                Icon(
                                  Icons.copy,
                                  color: kGrayColor,
                                  size: size.width / 30,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Container();
        }
      },
      listLoadingElement: QuickHelp.appLoading(),
      queryEmptyElement: ContainerCorner(
        borderWidth: 0,
        width: size.width,
        height: size.height / 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/szy_kong_icon.png",
              height: size.width / 2,
              width: size.width / 2,
            ),
            TextWithTap(
              "guardian_and_vip_screen.you_have_no_guard_title".tr(),
            ),
            TextWithTap(
              "guardian_and_vip_screen.you_have_no_guard_explain".tr(),
              color: kGrayColor,
              fontSize: 12,
              marginTop: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget buttons() {
    Size size = MediaQuery.of(context).size;
    if (guardianTextIndex == 0 && tabIndex == 0) {
      return ContainerCorner(
        width: size.width,
        marginBottom: 20,
        marginTop: 5,
        colors: guardianActivateButtonColors(),
        height: 55,
        marginLeft: 20,
        marginRight: 20,
        borderRadius: 50,
        onTap: () {
          if (userToGuard == null) {
            QuickHelp.showAppNotificationAdvanced(
              title: "error".tr(),
              message: "choose_guardian_screen.choose_guardian".tr(),
              context: context,
            );
          } else if (widget.currentUser!.getCredits! <
              selectedGuardianPeriod[0] * selectedGuardianPrice()) {
            QuickHelp.showAppNotificationAdvanced(
              title: "error".tr(),
              message: "guardian_and_vip_screen.coins_not_enough".tr(),
              context: context,
            );
          } else {
            activateGuardian();
          }
        },
        child: Center(
          child: TextWithTap(
            guardianActivateButtonTexts(),
            color: Colors.white,
          ),
        ),
      );
    } else if (tabIndex == 1) {
      return ContainerCorner(
        width: size.width,
        marginBottom: 20,
        marginTop: 5,
        colors: vipOpenButtonColors(),
        height: 55,
        marginLeft: 20,
        marginRight: 20,
        borderRadius: 50,
        onTap: () => confirmVipTypeJoining(),
        child: Center(
          child: TextWithTap(
            vipOpenButtonTexts(),
            color: Colors.white,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget showUserToGuard() {
    if (userToGuard != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActions.avatarWidget(
            userToGuard!,
            height: 30,
            width: 30,
            margin: EdgeInsets.only(left: 15),
          ),
          TextWithTap(
            userToGuard!.getUsername!,
            fontSize: 16,
            marginLeft: 5,
          ),
        ],
      );
    } else {
      return const SizedBox();
    }
  }

  Widget guardianPeriods() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(guardianPeriod.length, (index) {
        bool contains = selectedGuardianPeriod.contains(guardianPeriod[index]);
        return ContainerCorner(
          borderRadius: 8,
          borderColor: contains ? Colors.white : kGrayColor,
          height: 35,
          borderWidth: contains ? 2 : 1,
          marginLeft: index == 0 ? 10 : 0,
          marginRight: index == 3 ? 10 : 0,
          marginTop: 20,
          onTap: () {
            setState(() {
              selectedGuardianPeriod.clear();
              selectedGuardianPeriod.add(guardianPeriod[index]);
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 5, left: 5),
            child: Center(
              child: AutoSizeText(
                "guardian_and_vip_screen.amount_mouths"
                    .tr(namedArgs: {"amount": "${guardianPeriod[index]}"}),
                maxFontSize: 15,
                minFontSize: 13,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: kGrayColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget guardianTypes(
      {required String imageUrl,
      required String text,
      required Color color,
      required int index}) {
    Size size = MediaQuery.of(context).size;
    bool contains = selectedGuardianType.contains(index);
    return ContainerCorner(
      borderColor: contains ? Colors.white : kGrayColor,
      borderRadius: 10,
      borderWidth: contains ? 2 : 1,
      width: size.width / 3.5,
      marginRight: index == 2 ? 15 : 0,
      marginLeft: index == 0 ? 15 : 0,
      height: 130,
      onTap: () {
        setState(() {
          selectedGuardianType.clear();
          selectedGuardianType.add(index);
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 5,
          ),
          Image.asset(
            imageUrl,
            height: size.width / 5.5,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3, top: 5),
            child: AutoSizeText(
              text,
              maxFontSize: 16,
              minFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: color,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget appBarBottom() {
    if (tabIndex == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(indexedGuardianTitles.length, (index) {
          bool contains =
              selectedIndexedTitles.contains(indexedGuardianTitles[index]);
          return TextWithTap(
            indexedGuardianTitles[index],
            color: contains ? Colors.white : kGrayColor,
            fontSize: contains ? 16 : 14,
            onTap: () {
              setState(() {
                selectedIndexedTitles.clear();
                selectedIndexedTitles.add(indexedGuardianTitles[index]);
                guardianTextIndex = index;
              });
            },
          );
        }),
      );
    } else if (tabIndex == 1) {
      return TabBar(
          isScrollable: true,
          enableFeedback: false,
          controller: vipTabControl,
          dividerColor: kTransparentColor,
          unselectedLabelColor: kGrayColor,
          dragStartBehavior: DragStartBehavior.down,
          indicatorWeight: 0.0,
          labelPadding: EdgeInsets.symmetric(
            horizontal: 7.0,
          ),
          automaticIndicatorColorAdjustment: false,
          labelColor: Colors.white,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(fontSize: 16),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          tabs: List.generate(vipTabsTitles.length, (index) {
            return TextWithTap(vipTabsTitles[index]);
          }));
    } else {
      return const SizedBox();
    }
  }

  confirmVipTypeJoining() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, newState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextWithTap(
                    "guardian_and_vip_screen.spend_amount_to_join_vip"
                        .tr(namedArgs: {
                      "amount": selectedVipTypeAmount().toString(),
                      "vip_type": selectedVipTypeText(),
                    }),
                    fontWeight: FontWeight.w900,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: TextWithTap(
                          "cancel".tr(),
                          color: kGrayColor,
                          marginRight: 15,
                          marginLeft: 15,
                        ),
                        onPressed: () =>
                            QuickHelp.goBackToPreviousPage(context),
                      ),
                      TextButton(
                        child: TextWithTap(
                          "confirm_".tr(),
                          color: kPrimaryColor,
                          marginRight: 20,
                          marginLeft: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        onPressed: () {
                          if (widget.currentUser!.getCredits! <
                              selectedVipTypeAmount()) {
                            CoinsFlowPayment(
                              context: context,
                              showOnlyCoinsPurchase: true,
                              currentUser: widget.currentUser!,
                              onCoinsPurchased: (coins) {},
                            );
                          } else {
                            activateVipPlan();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }

  activateVipPlan() async {
    QuickHelp.showLoadingDialog(context);
    widget.currentUser!.removeCredit = selectedVipTypeAmount();
    if (vipTabsIndex == 0) {
      widget.currentUser!.setNormalVip = QuickHelp.getUntilDateFromDays(30);
    } else if (vipTabsIndex == 1) {
      widget.currentUser!.setSuperVip = QuickHelp.getUntilDateFromDays(30);
    } else if (vipTabsIndex == 2) {
      widget.currentUser!.setDiamondVip = QuickHelp.getUntilDateFromDays(30);
    }
    ParseResponse response = await widget.currentUser!.save();
    if (response.success && response.results != null) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
        title: "done".tr(),
        context: context,
        isError: false,
        message: "main_activated".tr(),
      );
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
        title: "error".tr(),
        context: context,
        message: "report_screen.report_failed_explain".tr(),
      );
    }
  }

  activateGuardian() async {
    QuickHelp.showLoadingDialog(context);
    widget.currentUser!.removeCredit =
        selectedGuardianPeriod[0] * selectedGuardianPrice();
    widget.currentUser!.removeMyGuardians = userToGuard!.objectId!;
    widget.currentUser!.removeMyGuardians = userToGuard!.objectId!;

    if (guardianTextIndex == 0) {
      widget.currentUser!.setGuardianOfSilver =
          QuickHelp.getUntilDateFromDays(selectedGuardianPeriod[0] * 30);
    } else if (guardianTextIndex == 1) {
      widget.currentUser!.setGuardianOfGold =
          QuickHelp.getUntilDateFromDays(selectedGuardianPeriod[0] * 30);
    } else if (guardianTextIndex == 2) {
      widget.currentUser!.setGuardianOfKing =
          QuickHelp.getUntilDateFromDays(selectedGuardianPeriod[0] * 30);
    }

    ParseResponse response = await widget.currentUser!.save();
    if (response.success && response.results != null) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
        title: "done".tr(),
        context: context,
        isError: false,
        message: "main_activated".tr(),
      );
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
        title: "error".tr(),
        context: context,
        message: "report_screen.report_failed_explain".tr(),
      );
    }
  }
}
