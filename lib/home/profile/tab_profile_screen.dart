// ignore_for_file: must_be_immutable

import 'package:auto_size_text_plus/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/config.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/home/home_screen.dart';
import 'package:trace/home/profile/profile_screen.dart';
import 'package:trace/home/relations/close_friends.dart';
import 'package:trace/home/settings/settings_screen.dart';
import 'package:trace/ui/button_widget.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helpers/quick_help.dart';
import '../../models/UserModel.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../about/about_us_screen.dart';
import '../agency/agency_screen.dart';
import '../agency/agent_screen.dart';
import '../agency/my_agent_sreen.dart';
import '../coins/refill_coins_screen.dart';
import '../coins_and_points/coins_and_points_screen.dart';
import '../coins_and_points/points_screen.dart';
import '../contact_us/contact_us_screen.dart';
import '../fan_club/fan_club_screen.dart';
import '../feedback/my_feedback_screen.dart';
import '../guardian_vip/guardian_and_vip_store_screen.dart';
import '../help/help_screen.dart';
import '../host_center/host_center_screen.dart';
import '../invitation/invitation_screen.dart';
import '../level/level_screen.dart';
import '../mvp/mvp_screen.dart';
import '../my_moments/my_moments_screen.dart';
import '../my_obtained_items/my_obtained_items.dart';
import '../relations/followers_screen.dart';
import '../relations/visits_screen.dart';
import '../report/report_screen.dart';
import '../reward/reward_screen.dart';
import '../store/store_screen.dart';
import '../task_rules/task_rules_screen.dart';
import '../upload_live_photo/upload_live_photo_screen.dart';
import '../wallet/wallet_screen.dart';
import '../withdraw/witthdraw_screen.dart';

class TabProfileScreen extends StatefulWidget {
  UserModel? currentUser;
  static String route = "user/profile";
  SharedPreferences? preferences;

  TabProfileScreen({this.preferences, this.currentUser, Key? key})
      : super(key: key);

  @override
  State<TabProfileScreen> createState() => _TabProfileScreenState();
}

class _TabProfileScreenState extends State<TabProfileScreen> {
  final CarouselController _controller = CarouselController();
  int current = 0;

  var numbersCaptions = [
    "tab_profile.followings_".tr(),
    "tab_profile.followers_".tr(),
    "profile_list_menu.moments_".tr(),
  ];

  var coinsCaption = [
    "tab_profile.coins_".tr(),
    "tab_profile.p_coin".tr(),
    "tab_profile.points_".tr(),
  ];

  var slideBanner = [
    "assets/images/slide_image_1.png",
    "assets/images/slide_image_2.png",
    "assets/images/slide_image_3.png",
    "assets/images/slide_image_4.png",
  ];

  var firstOptionsCaption = [
    "tab_profile.reward_".tr(),
    "tab_profile.rank_".tr(),
    "tab_profile.store_".tr(),
    "tab_profile.invite_".tr(),
    "tab_profile.medal_".tr(),
    "tab_profile.fans_club".tr(),
    "tab_profile.auth_".tr(),
  ];

  var firstOptionsIcons = [
    "assets/images/ic_tab_profile_reward.png",
    "assets/images/ic_tab_profile_rank.png",
    "assets/images/ic_tab_profile_store.png",
    "assets/images/ic_tab_invite.png",
    "assets/images/ic_tab_profile_medal.png",
    "assets/images/ic_tab_profile_fans.png",
    "assets/images/ic_tab_profile_auth.png",
  ];

  var agentOptionsIcons = [
    "assets/images/ic_tab_profile_agent.png",
    "assets/images/ic_tab_profile_add_host.png",
    "assets/images/ic_tab_profile_coins_trading.png",
    "assets/images/ic_tab_profile_official_services.png",
  ];

  var agentOptionsCaption = [
    "agents_menu.agent_".tr(),
    "agents_menu.add_host".tr(),
    "agents_menu.coins_trading".tr(),
    "agents_menu.official_services".tr(),
  ];

  var secondOptionsCaption = [
    "tab_profile.guardian_".tr(),
    "tab_profile.help_".tr(),
    "tab_profile.my_agency".tr(),
    "tab_profile.level_complete".tr(),
    "tab_profile.about_".tr(),
    "tab_profile.settings_".tr(),
    "tab_profile.follow_us".tr()
  ];

  var secondOptionsLightIcons = [
    "assets/images/ic_profil_tab_guardian.png",
    "assets/images/ic_profil_tab_help.png",
    "assets/images/ic_tab_profile_agency.png",
    "assets/images/ic_tab_profile_level.png",
    "assets/images/ic_tab_profile_about.png",
    "assets/images/ic_tab_profile_settings.png",
    "assets/images/ic_tab_profile_follow.png",
  ];

  var secondOptionsDarkIcons = [
    "assets/svg/ic_guardian_dark.svg",
    "assets/svg/help.svg",
    "assets/svg/ic_agent_dark.svg",
    "assets/svg/ic_level_dark.svg",
    "assets/svg/ic_about_dark.svg",
    "assets/svg/ic_config_dark.svg",
    "assets/svg/ic_facebook_dark.svg"
  ];

  var coinsImageUrls = [
    "assets/images/icon_jinbi.png",
    "assets/images/icon_ppbi_do_task.png",
    "assets/images/ic_jifen_wode.webp",
  ];

  var coinsActionsTexts = [
    "tab_profile.top_up".tr(),
    "tab_profile.receive_".tr(),
    "tab_profile.withdraw_".tr(),
  ];

  bool showTempAlert = false;

  showTemporaryAlert() {
    setState(() {
      showTempAlert = true;
    });
    hideTemporaryAlert();
  }

  hideTemporaryAlert() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showTempAlert = false;
      });
    });
  }

  Widget agencyScreen() {
    if (widget.currentUser!.getAgencyRole == UserModel.agencyClientRole) {
      return MyAgentScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      );
    } else if (widget.currentUser!.getAgencyRole == UserModel.agencyAgentRole) {
      return AgentScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      );
    } else {
      return AgencyScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      );
    }
  }

  var coinsActionsButtonsBgColors = [
    kOrangeColor,
    kPrimaryColor,
    earnCashColor,
  ];

  var firstOptionsScreens = [];
  var secondOptionsScreens = [];
  var agentOptionsScreens = [];
  var listMenuScreens = [];

  var personalIcons = [
    "assets/images/my_icon_message.png",
    "assets/images/my_icon_bag.png",
    "assets/images/my_icon_store.png",
    "assets/images/my_icon_home.png",
    "assets/images/my_icon_lv.png",
    "assets/images/my_icon_check.png",
    "assets/images/my_icon_manor.png",
    "assets/images/icon_medal_default.png",
  ];

  var personalTitle = [
    "personal_menu.messages_".tr(),
    "personal_menu.Backpacks_".tr(),
    "personal_menu.shop_".tr(),
    "personal_menu.family_".tr(),
    "personal_menu.level_".tr(),
    "personal_menu.check_in".tr(),
    "personal_menu.farm_".tr(),
    "personal_menu.badges_".tr(),
  ];

  var privilegesIcons = [
    "assets/images/my_icon_member.png",
    "assets/images/my_icon_vip.png",
    "assets/images/my_icon_guard.png",
    "assets/images/my_icon_love.png",
  ];

  var privilegesTitle = [
    "profile_list_menu.mvp_".tr(),
    "profile_list_menu.vip_".tr(),
    "profile_list_menu.my_guardian".tr(),
    "profile_list_menu.fan_club".tr(),
  ];

  var listMenuTitle = [
    "profile_list_menu.host_center".tr(),
    //"profile_list_menu.batter_of_glory".tr(),
    "profile_list_menu.who_viewed_me".tr(),
    "profile_list_menu.view_record".tr(),
    "profile_list_menu.customer_service".tr(),
    "profile_list_menu.help_center".tr(),
    "profile_list_menu.feed_back".tr(),
    "profile_list_menu.contact_us".tr(),
  ];

  var colors = [Colors.redAccent, Colors.amber, Colors.deepPurpleAccent];

  final Uri url =
      Uri.parse("https://www.facebook.com/profile.php?id=100063582998530");

  Future<void> goToFacebookPage() async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);

    agentOptionsScreens = [
      MVPScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      GuardianAndVipStoreScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 1,
      ),
      GuardianAndVipStoreScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 0,
      ),
      FanClubScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    listMenuScreens = [
      HostCenterScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      /*HostCenterScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),*/
      VisitScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 0,
      ),
      VisitScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 1,
      ),
      ReportScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      HelpScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      ReportScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      ContactUsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    var numbersCaptionsScreens = [
      FollowersScreen(
        currentUser: widget.currentUser,
        isFollowers: false,
      ),
      FollowersScreen(
        currentUser: widget.currentUser,
        isFollowers: true,
      ),
      MyMomentsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      VisitScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    firstOptionsScreens = [
      HomeScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialTabIndex: 3,
      ),
      MyObtainedItems(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      StoreScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      InvitationScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      LevelScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      UploadLivePhoto(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      MyFeedbackScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      TaskRulesScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    secondOptionsScreens = [
      GuardianAndVipStoreScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 0,
      ),
      HelpScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      agencyScreen(),
      LevelScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      AboutUsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      SettingsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      null
    ];

    var numbers = [
      widget.currentUser!.getFollowing!.length,
      widget.currentUser!.getFollowers!.length,
      widget.currentUser!.getPostIdList!.length,
    ];

    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leadingWidth: 0.1,
            title: ContainerCorner(
              width: size.width / 1.2,
              child: TextWithTap(
                widget.currentUser!.getFullName!,
                fontSize: size.width / 17,
                fontWeight: FontWeight.w900,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  UserModel? user =
                      await QuickHelp.goToNavigatorScreenForResult(
                          context,
                          SettingsScreen(
                            currentUser: widget.currentUser,
                            preferences: widget.preferences,
                          ));
                  if (user != null) {
                    setState(() {
                      widget.currentUser = user;
                    });
                  }
                },
                icon: Image.asset(
                  "assets/images/profile_icon_set.png",
                  height: 25,
                  width: 25,
                ),
              )
            ],
          ),
          body: ListView(
            padding: EdgeInsets.only(left: 15, right: 15),
            children: [
              GestureDetector(
                onTap: () {
                  QuickHelp.goToNavigatorScreen(
                    context,
                    ProfileScreen(
                      currentUser: widget.currentUser,
                      preferences: widget.preferences,
                    ),
                  );
                },
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    QuickActions.avatarWidget(
                      widget.currentUser!,
                      width: size.width / 3,
                      height: size.width / 3,
                      margin: EdgeInsets.only(top: 15, bottom: 15),
                      hideAvatarFrame: true,
                    ),
                    if(widget.currentUser!.getAvatarFrame != null && widget.currentUser!.getCanUseAvatarFrame!)
                      ContainerCorner(
                        borderWidth: 0,
                        width: size.width / 2.2,
                        height: size.width / 2.2,
                        child: CachedNetworkImage(
                          imageUrl: widget.currentUser!.getAvatarFrame!.url!,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(image: imageProvider, fit: BoxFit.fill),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWithTap(
                    "tab_profile.id_".tr(),
                    fontSize: size.width / 33,
                    fontWeight: FontWeight.w900,
                    color: kGrayColor,
                  ),
                  TextWithTap(
                    widget.currentUser!.getUid!.toString(),
                    fontSize: size.width / 33,
                    marginLeft: 3,
                    marginRight: 3,
                    color: kGrayColor,
                  ),
                  GestureDetector(
                    onTap: () {
                      QuickHelp.copyText(
                          textToCopy: "${widget.currentUser!.getUid!}");
                      showTemporaryAlert();
                    },
                    child: Icon(
                      Icons.copy,
                      color: kGrayColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  ContainerCorner(
                    height: 30,
                    width: size.width,
                    color: kPrimaryColor.withOpacity(0.2),
                    borderRadius: 8,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.asset(
                              "assets/images/un_set_avatar_icon.png",
                              height: size.width / 7,
                              width: size.width / 7,
                            ),
                            TextWithTap(
                              "profile_list_menu.my_app_avatar"
                                  .tr(namedArgs: {"app_name": Config.appName}),
                              marginBottom: 5,
                              marginLeft: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        ContainerCorner(
                          color: kPrimaryColor,
                          borderRadius: 50,
                          borderWidth: 0,
                          marginBottom: 3,
                          child: TextWithTap(
                            "enter_".tr(),
                            color: Colors.white,
                            fontSize: 10,
                            alignment: Alignment.center,
                            marginLeft: 8,
                            marginRight: 8,
                            marginTop: 5,
                            marginBottom: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  numbersCaptions.length,
                  (index) => captionAndNumber(
                    caption: numbersCaptions[index],
                    screenToGo: numbersCaptionsScreens[index],
                    number: numbers[index],
                    visitor: index == 2 ? true : false,
                  ),
                ),
              ),
              ContainerCorner(
                color: isDark ? kContentColorLightTheme : Colors.white,
                borderRadius: 10,
                borderWidth: 0,
                shadowColor: kGrayColor,
                shadowColorOpacity: isDark ? 0.3 : 0.1,
                marginTop: 20,
                marginBottom: 20,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () async{
                        UserModel? user = await
                        QuickHelp.goToNavigatorScreenForResult(
                          context,
                          WalletScreen(
                            currentUser: widget.currentUser,
                            preferences: widget.preferences,
                          ),
                        );
                        if(user != null){
                          setState(() {
                            widget.currentUser = user;
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextWithTap(
                            "profile_list_menu.wallet_".tr(),
                            alignment: Alignment.topLeft,
                            marginBottom: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/coin_bling.webp",
                                height: 15,
                                width: 15,
                              ),
                              TextWithTap(
                                QuickHelp.checkFundsWithString(
                                    amount:
                                        "${widget.currentUser!.getCredits}"),
                                marginLeft: 8,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    ContainerCorner(
                      height: 30,
                      width: 0.2,
                      color: kGrayColor,
                    ),
                    TextButton(
                      onPressed: () {
                        QuickHelp.goToNavigatorScreen(
                          context,
                          PointsScreen(
                            currentUser: widget.currentUser,
                            preferences: widget.preferences,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextWithTap(
                            "profile_list_menu.mission_center".tr(),
                            marginBottom: 5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/ubean_bling.webp",
                                height: 15,
                                width: 15,
                              ),
                              TextWithTap(
                                QuickHelp.checkFundsWithString(
                                    amount: "${widget.currentUser!.getPCoins}"),
                                marginLeft: 8,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TextWithTap(
                "personal_".tr(),
                fontSize: size.width / 22,
                fontWeight: FontWeight.w900,
              ),
              ContainerCorner(
                color: isDark ? kContentColorLightTheme : Colors.white,
                borderRadius: 10,
                width: size.width,
                height: 200,
                marginTop: 10,
                child: GridView.count(
                  crossAxisCount: 4,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(
                    personalTitle.length,
                    (index) {
                      return options(
                        caption: personalTitle[index],
                        screenTogo: firstOptionsScreens[index],
                        iconURL: personalIcons[index],
                      );
                    },
                  ),
                ),
              ),
              TextWithTap(
                "privileges_".tr(),
                fontSize: size.width / 22,
                fontWeight: FontWeight.w900,
              ),
              ContainerCorner(
                color: isDark ? kContentColorLightTheme : Colors.white,
                borderRadius: 10,
                width: size.width,
                height: 90,
                marginTop: 10,
                child: GridView.count(
                  crossAxisCount: 4,
                  physics: NeverScrollableScrollPhysics(),
                  children: List.generate(
                    privilegesTitle.length,
                    (index) {
                      return options(
                        caption: privilegesTitle[index],
                        screenTogo: agentOptionsScreens[index],
                        iconURL: privilegesIcons[index],
                        width: size.width / 14,
                        height: size.width / 14,
                      );
                    },
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                    listMenuTitle.length,
                    (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ButtonWidget(
                            onTap: () => QuickHelp.goToNavigatorScreen(
                                context, listMenuScreens[index]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWithTap(
                                  listMenuTitle[index],
                                  marginBottom: 16,
                                  fontSize: size.width / 18,
                                  color: isDark? Colors.white : kContentColorLightTheme,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Visibility(
                                      visible: index == 4,
                                      child: Image.asset(
                                        "assets/images/im_service_icon.png",
                                        height: 18,
                                        width: 18,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 15,
                                      color: kGrayColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
        Visibility(
          visible: showTempAlert,
          child: ContainerCorner(
            color: Colors.black.withOpacity(0.5),
            height: 50,
            marginRight: 50,
            marginLeft: 50,
            borderRadius: 50,
            width: size.width / 2,
            shadowColor: kGrayColor,
            shadowColorOpacity: 0.3,
            child: TextWithTap(
              "copied_".tr(),
              color: Colors.white,
              marginBottom: 5,
              marginTop: 5,
              marginLeft: 20,
              marginRight: 20,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              alignment: Alignment.center,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget oldBody() {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    var coinsNumbers = [
      widget.currentUser!.getCredits,
      widget.currentUser!.getPCoins,
      widget.currentUser!.getDiamonds,
    ];

    var numbers = [
      widget.currentUser!.getFollowing!.length,
      widget.currentUser!.getFollowers!.length,
      widget.currentUser!.getCloseFriends!.length,
      widget.currentUser!.getVisitors!.length,
    ];

    var numbersCaptionsScreens = [
      FollowersScreen(
        currentUser: widget.currentUser,
        isFollowers: false,
      ),
      FollowersScreen(
        currentUser: widget.currentUser,
        isFollowers: true,
      ),
      CloseFriendsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
      VisitScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    var coinsAndPointsScreen = [
      CoinsAndPointsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 0,
      ),
      CoinsAndPointsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
        initialIndex: 1,
      ),
      PointsScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    var coinsAndPointsScreenOperation = [
      RefillCoinsScreen(
        currentUser: widget.currentUser,
      ),
      RewardScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences!,
      ),
      WithDrawScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? kContentDarkShadow : kGrayWhite,
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    title: Visibility(
                      visible: innerBoxIsScrolled,
                      child: TextWithTap(
                        widget.currentUser!.getFullName!,
                      ),
                    ),
                    backgroundColor:
                        isDark ? kContentColorLightTheme : kGrayWhite,
                    floating: false,
                    primary: true,
                    pinned: true,
                    snap: false,
                    elevation: 0,
                    stretch: true,
                    expandedHeight: size.width / 3,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      collapseMode: CollapseMode.parallax,
                      background: Padding(
                        padding: EdgeInsets.only(
                            left: 20, right: 20, top: size.width / 7),
                        child: header(),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Builder(builder: (BuildContext context) {
              return CustomScrollView(
                slivers: [
                  SliverOverlapInjector(
                    // This is the flip side of the SliverOverlapAbsorber above.
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 15,
                              right: 15,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: List.generate(
                                    numbersCaptions.length,
                                    (index) => captionAndNumber(
                                      caption: numbersCaptions[index],
                                      screenToGo: numbersCaptionsScreens[index],
                                      number: numbers[index],
                                      visitor: index == 3 ? true : false,
                                    ),
                                  ),
                                ),
                                ContainerCorner(
                                  imageDecoration: "assets/images/vip_bar.png",
                                  height: 40,
                                  fit: BoxFit.fill,
                                  radiusTopRight: 10,
                                  radiusTopLeft: 10,
                                  marginTop: 20,
                                  borderWidth: 0,
                                  onTap: () {
                                    QuickHelp.goToNavigatorScreen(
                                        context,
                                        GuardianAndVipStoreScreen(
                                          currentUser: widget.currentUser,
                                          preferences: widget.preferences,
                                        ));
                                  },
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Image.asset(
                                          "assets/images/VIP.png",
                                          fit: BoxFit.fitHeight,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          TextWithTap(
                                            "tab_profile.noble_privileges".tr(),
                                            fontSize: size.width / 40,
                                            color: kRoseVipClair,
                                          ),
                                          ContainerCorner(
                                            borderRadius: 50,
                                            marginRight: 15,
                                            marginLeft: 10,
                                            marginTop: 10,
                                            marginBottom: 10,
                                            colors: [kRoseVip, kRoseVipClair],
                                            child: Center(
                                              child: TextWithTap(
                                                "tab_profile.open_".tr(),
                                                fontSize: size.width / 40,
                                                marginRight: 15,
                                                marginLeft: 15,
                                                color: kColdVip,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                ContainerCorner(
                                  color: isDark
                                      ? kContentColorLightTheme
                                      : Colors.white,
                                  radiusBottomRight: 10,
                                  radiusBottomLeft: 10,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: List.generate(
                                      coinsCaption.length,
                                      (index) => coinsAndPoints(
                                        caption: coinsCaption[index],
                                        number: coinsNumbers[index]!,
                                        imageUrl: coinsImageUrls[index],
                                        bgColor:
                                            coinsActionsButtonsBgColors[index],
                                        actionText: coinsActionsTexts[index],
                                        screenToGo: coinsAndPointsScreen[index],
                                        screenOperation:
                                            coinsAndPointsScreenOperation[
                                                index],
                                      ),
                                    ),
                                  ),
                                ),
                                ContainerCorner(
                                  color: isDark
                                      ? kContentColorLightTheme
                                      : Colors.white,
                                  borderRadius: 10,
                                  width: size.width,
                                  height: 200,
                                  marginTop: 10,
                                  child: GridView.count(
                                    crossAxisCount: 4,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: List.generate(
                                      firstOptionsCaption.length,
                                      (index) {
                                        return options(
                                          caption: firstOptionsCaption[index],
                                          screenTogo:
                                              firstOptionsScreens[index],
                                          iconURL: firstOptionsIcons[index],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                sliders(),
                                Visibility(
                                  visible: widget.currentUser!.getAgencyRole ==
                                      UserModel.agencyAgentRole,
                                  child: ContainerCorner(
                                    color: isDark
                                        ? kContentColorLightTheme
                                        : Colors.white,
                                    borderRadius: 10,
                                    width: size.width,
                                    height: 90,
                                    marginTop: 10,
                                    child: GridView.count(
                                      crossAxisCount: 4,
                                      physics: NeverScrollableScrollPhysics(),
                                      children: List.generate(
                                        agentOptionsCaption.length,
                                        (index) {
                                          return options(
                                            caption: agentOptionsCaption[index],
                                            screenTogo:
                                                agentOptionsScreens[index],
                                            iconURL: agentOptionsIcons[index],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                ContainerCorner(
                                  color: isDark
                                      ? kContentColorLightTheme
                                      : Colors.white,
                                  borderRadius: 10,
                                  width: size.width,
                                  height: 200,
                                  marginTop: 10,
                                  child: GridView.count(
                                    crossAxisCount: 4,
                                    physics: NeverScrollableScrollPhysics(),
                                    children: List.generate(
                                      secondOptionsCaption.length,
                                      (index) {
                                        return secondOptions(
                                          caption: secondOptionsCaption[index],
                                          screenTogo:
                                              secondOptionsScreens[index],
                                          iconURL:
                                              secondOptionsLightIcons[index],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Visibility(
            visible: showTempAlert,
            child: ContainerCorner(
              color: Colors.black.withOpacity(0.5),
              height: 50,
              marginRight: 50,
              marginLeft: 50,
              borderRadius: 50,
              width: size.width / 2,
              shadowColor: kGrayColor,
              shadowColorOpacity: 0.3,
              child: TextWithTap(
                "copied_".tr(),
                color: Colors.white,
                marginBottom: 5,
                marginTop: 5,
                marginLeft: 20,
                marginRight: 20,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                alignment: Alignment.center,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String vipIconUrl() {
    if (widget.currentUser!.isDiamondVip!) {
      return "assets/images/icon_vip_3.webp";
    } else if (widget.currentUser!.isSuperVip!) {
      return "assets/images/icon_vip_2.webp";
    } else if (widget.currentUser!.isNormalVip!) {
      return "assets/images/icon_vip_1.webp";
    } else {
      return "assets/images/icon_vip_0.png";
    }
  }

  Widget vipIconType() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: GestureDetector(
        onTap: () {
          QuickHelp.goToNavigatorScreen(
              context,
              GuardianAndVipStoreScreen(
                currentUser: widget.currentUser,
                preferences: widget.preferences,
              ));
        },
        child: Image.asset(
          vipIconUrl(),
          height: 15,
        ),
      ),
    );
  }

  Widget options({
    required String caption,
    required String iconURL,
    required Widget screenTogo,
    double? width,
    double? height,
  }) {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      onTap: () async {
        UserModel? user =
            await QuickHelp.goToNavigatorScreenForResult(context, screenTogo);
        if (user != null) {
          setState(() {
            widget.currentUser = user;
          });
        }
      },
      child: Column(
        children: [
          Image.asset(
            iconURL,
            width: width ?? size.width / 8,
            height: height ?? size.width / 8,
            //color: kTra,
          ),
          TextWithTap(
            caption,
            marginTop: 10,
            color: kGrayColor,
            fontSize: size.width / 38,
          ),
        ],
      ),
    );
  }

  Widget secondOptions({
    required String caption,
    required String iconURL,
    Widget? screenTogo,
  }) {
    Size size = MediaQuery.of(context).size;
    bool isDark = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      onTap: () async {
        if (screenTogo != null) {
          UserModel? user =
              await QuickHelp.goToNavigatorScreenForResult(context, screenTogo);
          if (user != null) {
            setState(() {
              widget.currentUser = user;
            });
          }
        } else {
          goToFacebookPage();
        }
      },
      child: Column(
        children: [
          isDark
              ? Image.asset(
                  iconURL,
                  width: size.width / 14,
                  height: size.width / 14,
                  //color: kTra,
                )
              : Image.asset(
                  iconURL,
                  width: size.width / 14,
                  height: size.width / 14,
                ),
          TextWithTap(
            caption,
            marginTop: 10,
            fontSize: size.width / 38,
          ),
        ],
      ),
    );
  }

  Widget sliders() {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      marginTop: 10,
      child: CarouselSlider.builder(
        options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 1.0,
            autoPlayAnimationDuration: const Duration(milliseconds: 200),
            aspectRatio: 50 / 9,
            autoPlayCurve: Curves.linear,
            onPageChanged: (index, reason) {
              setState(() {
                current = index;
              });
            }),
        carouselController: _controller,
        itemCount: slideBanner.length,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
          return ContainerCorner(
            width: size.width,
            borderRadius: 8,
            child: Image.asset(
              slideBanner[itemIndex],
            ),
          );
        },
      ),
    );
  }

  Widget coinsAndPoints(
      {required String caption,
      required int number,
      required String imageUrl,
      required Color bgColor,
      required String actionText,
      required Widget screenToGo,
      required Widget screenOperation}) {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      marginTop: 15,
      marginBottom: 15,
      onTap: () {
        QuickHelp.goToNavigatorScreen(context, screenToGo);
      },
      child: Column(
        children: [
          TextWithTap(
            QuickHelp.checkFundsWithString(amount: number.toString()),
            fontWeight: FontWeight.w600,
            marginBottom: 10,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imageUrl,
                width: size.width / 30,
                height: size.width / 30,
                //color: kTra,
              ),
              TextWithTap(
                caption,
                color: kGrayColor,
                fontSize: size.width / 34,
                marginLeft: 2,
              ),
            ],
          ),
          ContainerCorner(
            borderWidth: 0,
            borderRadius: 50,
            marginTop: 10,
            color: bgColor.withOpacity(0.2),
            onTap: () async {
              UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
                context,
                screenOperation,
              );
              if (user != null) {
                widget.currentUser = user;
                setState(() {});
              }
            },
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 6),
              child: AutoSizeText(
                actionText,
                maxFontSize: 14.0,
                minFontSize: 5.0,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: bgColor,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget captionAndNumber({
    required String caption,
    required int number,
    bool? visitor,
    required Widget screenToGo,
  }) {
    Size size = MediaQuery.of(context).size;
    bool isVisitor = visitor ?? false;
    return ContainerCorner(
      onTap: () => QuickHelp.goToNavigatorScreen(context, screenToGo),
      child: Column(
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            clipBehavior: Clip.none,
            children: [
              TextWithTap(
                number.toString(),
                fontWeight: FontWeight.w600,
                marginBottom: 4,
                fontSize: 15,
              ),
              Visibility(
                visible: isVisitor,
                child: Positioned(
                  top: 0,
                  right: -5,
                  child: ContainerCorner(
                    height: 5,
                    width: 5,
                    color: Colors.red,
                    borderRadius: 50,
                  ),
                ),
              )
            ],
          ),
          TextWithTap(
            caption,
            color: kGrayColor,
            fontSize: size.width / 35,
          ),
        ],
      ),
    );
  }

  Widget header() {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      marginBottom: 25,
      onTap: () => QuickHelp.goToNavigatorScreen(
        context,
        ProfileScreen(
          currentUser: widget.currentUser,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuickActions.avatarWidget(widget.currentUser!,
                  width: size.width / 6, height: size.width / 6),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextWithTap(
                          widget.currentUser!.getFullName!,
                          fontSize: size.width / 23,
                          fontWeight: FontWeight.w600,
                          marginBottom: 4,
                          marginRight: 4,
                        ),
                        vipIconType(),
                      ],
                    ),
                    Row(
                      children: [
                        QuickActions.getGender(
                          currentUser: widget.currentUser!,
                          context: context,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        QuickActions.giftReceivedLevel(
                          receivedGifts: widget.currentUser!.getDiamondsTotal!,
                          width: 35,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        QuickActions.wealthLevel(
                          credit: widget.currentUser!.getCreditsSent!,
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
                        GestureDetector(
                          onTap: () {
                            QuickHelp.copyText(
                                textToCopy: "${widget.currentUser!.getUid!}");
                            showTemporaryAlert();
                          },
                          child: Icon(
                            Icons.copy,
                            color: kGrayColor,
                            size: 20,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: kGrayColor,
            size: size.width / 30,
          ),
        ],
      ),
    );
  }
}
