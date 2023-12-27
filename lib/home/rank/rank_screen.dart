// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';
import '../profile/user_profile_screen.dart';

class RankScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;

  RankScreen({this.preferences, this.currentUser, Key? key}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with TickerProviderStateMixin {
  late TabController tabController;

  int tabIndex = 0;

  int tabsLength = 2;

  int hostIndexed = 0;
  int richIndexed = 0;

  var monToThuTheeFirstPlacesAmount = [1000000, 2000000, 500000];
  var friToSunTheeFirstPlacesAmount = [1500000, 3000000, 750000];
  int monToThuTotalAmount = 5260000;
  int friToSunTotalAmount = 7815000;

  List<Color> friToSunRequiredColors = [
    kSecondRanked,
    kFirstRanked,
    kThirdRanked
  ];
  List<Color> friToSunBorderColors = [
    kSecondRankedLight,
    kFirstRankedLight,
    kThirdRankedLight
  ];

  var classificationMedal = [
    "assets/images/rank_2_position.png",
    "assets/images/rank_1_position.png",
    "assets/images/rank_3_position.png",
  ];

  var intervalClassification = ["4:", "4-10", "16-20", "26-30"];
  var monToThuLeftPlacesAmounts = [200000, 120000, 40000, 10000];
  var friToSunLeftPlacesAmounts = [300000, 180000, 60000, 15000];
  var intervalClassificationPrime = ["5:", "11-15", "21-25", "31-40"];
  var monToThuRightPlacesAmounts = [160000, 80000, 20000, 5000];
  var friToSunRightPlacesAmounts = [240000, 120000, 30000, 0];

  @override
  void initState() {
    super.initState();

    tabController =
        TabController(vsync: this, length: tabsLength, initialIndex: tabIndex)
          ..addListener(() {
            setState(() {
              tabIndex = tabController.index;
            });
          });
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kTransparentColor,
        elevation: 1.5,
        centerTitle: true,
        title: TabBar(
          isScrollable: true,
          enableFeedback: false,
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: kTransparentColor,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorWeight: 2.0,
          labelPadding: EdgeInsets.symmetric(
            horizontal: 30.0,
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
              "rank_screen.host_".tr(),
              marginBottom: 7,
            ),
            TextWithTap(
              "rank_screen.rich_".tr(),
              marginBottom: 7,
            ),
          ],
        ),
        leading: BackButton(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: () => openRules(),
            icon: Icon(Icons.info_outline),
            color: Colors.white,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ContainerCorner(
                width: size.width,
                height: size.height,
                borderWidth: 0,
                child: Image.asset(
                  hostIndexed == 0
                      ? "assets/images/bg_rank_host.png"
                      : "assets/images/rank_fri_sun_bg.png",
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.fill,
                ),
              ),
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ContainerCorner(
                          color: hostIndexed == 0
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: 50,
                          borderWidth: 0,
                          height: 30,
                          marginRight: 15,
                          onTap: () {
                            setState(() {
                              hostIndexed = 0;
                            });
                          },
                          child: TextWithTap(
                            "rank_screen.mon_to_thu".tr(),
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            marginRight: 8,
                            fontWeight: hostIndexed == 0
                                ? FontWeight.w900
                                : FontWeight.w400,
                            marginLeft: 8,
                          ),
                        ),
                        ContainerCorner(
                          color: hostIndexed == 1
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: 50,
                          borderWidth: 0,
                          height: 30,
                          marginLeft: 15,
                          onTap: () {
                            setState(() {
                              hostIndexed = 1;
                            });
                          },
                          child: TextWithTap(
                            "rank_screen.fri_to_sun".tr(),
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            fontWeight: hostIndexed == 1
                                ? FontWeight.w900
                                : FontWeight.w400,
                            marginRight: 8,
                            marginLeft: 8,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 60,
                    ),
                    IndexedStack(
                      index: hostIndexed,
                      children: [
                        classificationInfo(
                          totalAmount: monToThuTotalAmount,
                          bgImageUrl:
                              "assets/images/bg_rich_mon_to_thu_ranked_users.png",
                          threeFirsPlacesAmount: monToThuTheeFirstPlacesAmount,
                          leftPlacesAmount: monToThuLeftPlacesAmounts,
                          rightPlacesAmount: monToThuRightPlacesAmounts,
                        ),
                        classificationInfo(
                          totalAmount: friToSunTotalAmount,
                          bgImageUrl:
                              "assets/images/bg_rich_fri_to_sun_ranked_users.png",
                          threeFirsPlacesAmount: friToSunTheeFirstPlacesAmount,
                          leftPlacesAmount: friToSunLeftPlacesAmounts,
                          rightPlacesAmount: friToSunRightPlacesAmounts,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ContainerCorner(
                width: size.width,
                height: size.height,
                borderWidth: 0,
                child: Image.asset(
                  "assets/images/bg_rank_rich.png",
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.fill,
                ),
              ),
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ContainerCorner(
                          color: richIndexed == 0
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.3),
                          borderWidth: 0,
                          marginRight: 15,
                          borderRadius: 50,
                          height: 30,
                          onTap: () {
                            setState(() {
                              richIndexed = 0;
                            });
                          },
                          child: TextWithTap(
                            "rank_screen.daily_".tr(),
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            fontWeight: richIndexed == 0
                                ? FontWeight.w900
                                : FontWeight.w400,
                            marginRight: 8,
                            marginLeft: 8,
                          ),
                        ),
                        ContainerCorner(
                          color: richIndexed == 1
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: 50,
                          borderWidth: 0,
                          height: 30,
                          marginLeft: 15,
                          onTap: () {
                            setState(() {
                              richIndexed = 1;
                            });
                          },
                          child: TextWithTap(
                            "rank_screen.monthly_".tr(),
                            fontWeight: richIndexed == 1
                                ? FontWeight.w900
                                : FontWeight.w400,
                            color: Colors.white,
                            textAlign: TextAlign.center,
                            alignment: Alignment.center,
                            marginRight: 8,
                            marginLeft: 8,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ContainerCorner(
                          marginTop: 30,
                          borderRadius: 10,
                          width: size.width,
                          height: size.height,
                          color: Colors.white,
                          marginLeft: 15,
                          marginRight: 15,
                          borderWidth: 0,
                          marginBottom: 30,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 15, top: 20, right: 15),
                            child: users(),
                          ),
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
    );
  }

  Widget users() {
    QueryBuilder<UserModel> queryBuilder =
        QueryBuilder<UserModel>(UserModel.forQuery());

    queryBuilder.whereGreaterThan(UserModel.keyDiamondsTotal, 10000000);

    Size size = MediaQuery.of(context).size;

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
                          width: size.width / 8, height: size.width / 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWithTap(
                              user.getFullName!,
                              fontSize: size.width / 25,
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
                                  width: 32,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                QuickActions.wealthLevel(
                                  credit: user.getCreditsSent!,
                                  width: 32,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/icon_jinbi.png",
                        height: 16,
                        width: 16,
                      ),
                      TextWithTap(
                        QuickHelp.checkFundsWithString(
                            amount: "${user.getDiamondsTotal!}"),
                        color: kContentColorLightTheme,
                        marginLeft: 3,
                      ),
                    ],
                  )
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
        width: size.width,
        height: size.height,
        borderWidth: 0,
        child: Center(
            child: Image.asset(
          "assets/images/szy_kong_icon.png",
          height: size.width / 2,
        )),
      ),
    );
  }

  Widget classificationInfo({
    required int totalAmount,
    required String bgImageUrl,
    required var threeFirsPlacesAmount,
    required var leftPlacesAmount,
    required var rightPlacesAmount,
  }) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      alignment: AlignmentDirectional.center,
      clipBehavior: Clip.none,
      children: [
        ContainerCorner(
          height: 300,
          width: size.width,
          marginLeft: 15,
          marginRight: 15,
          child: Image.asset(
            bgImageUrl,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: -27,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ContainerCorner(
                marginLeft: 30,
                marginRight: 30,
                width: size.width / 1.3,
                child: Image.asset(
                  "assets/images/rank_cart.png",
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        "assets/images/ic_jifen_wode.webp",
                        height: 16,
                        width: 16,
                      ),
                      TextWithTap(
                        QuickHelp.checkFundsWithString(amount: "$totalAmount"),
                        color: Colors.white,
                        fontSize: 13,
                        marginLeft: 3,
                        fontWeight: FontWeight.w900,
                        marginRight: 5,
                      ),
                    ],
                  ),
                  TextWithTap(
                    "2023-12-24",
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ],
              )
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  monToThuTheeFirstPlacesAmount.length,
                  (index) => ContainerCorner(
                    marginBottom: index == 1 ? 30 : 0,
                    marginRight: index == 1 ? 15 : 0,
                    marginLeft: index == 1 ? 15 : 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ContainerCorner(
                          width: size.width / 5,
                          child: Image.asset(
                            classificationMedal[index],
                          ),
                        ),
                        ContainerCorner(
                          borderRadius: 50,
                          borderWidth: 2,
                          color: friToSunRequiredColors[index],
                          borderColor: friToSunBorderColors[index],
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1, bottom: 1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 5,
                                ),
                                Image.asset(
                                  "assets/images/ic_jifen_wode.webp",
                                  height: 12,
                                  width: 12,
                                ),
                                TextWithTap(
                                  QuickHelp.checkFundsWithString(
                                      amount:
                                          "${threeFirsPlacesAmount[index]}"),
                                  color: Colors.white,
                                  fontSize: 11,
                                  marginLeft: 3,
                                  fontWeight: FontWeight.w900,
                                  marginRight: 5,
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ContainerCorner(
              width: size.width,
              marginLeft: 30,
              marginRight: 30,
              child: Table(
                children: List.generate(
                  4,
                  (index) => TableRow(children: [
                    ContainerCorner(
                      borderRadius: 50,
                      height: 23,
                      borderWidth: 0,
                      color: Colors.white.withOpacity(0.1),
                      marginBottom: 5,
                      marginRight: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextWithTap(
                              intervalClassification[index],
                              color: kRoseVip,
                              fontSize: 11,
                              marginRight: 8,
                            ),
                            Image.asset(
                              "assets/images/ic_jifen_wode.webp",
                              height: 12,
                              width: 12,
                            ),
                            TextWithTap(
                              QuickHelp.checkFundsWithString(
                                  amount: "${leftPlacesAmount[index]}"),
                              color: kRoseVip,
                              fontSize: 11,
                              marginRight: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ContainerCorner(
                      borderRadius: 50,
                      borderWidth: 0,
                      height: 23,
                      marginBottom: 5,
                      marginLeft: 3,
                      color: Colors.white.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1, bottom: 1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextWithTap(
                              intervalClassificationPrime[index],
                              color: kRoseVip,
                              fontSize: 11,
                              marginRight: 8,
                            ),
                            Image.asset(
                              "assets/images/ic_jifen_wode.webp",
                              height: 12,
                              width: 12,
                            ),
                            TextWithTap(
                              QuickHelp.checkFundsWithString(
                                  amount: "${rightPlacesAmount[index]}"),
                              color: kRoseVip,
                              fontSize: 11,
                              marginRight: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget richMonthlyRules() {
    var monToTheRules = [
      "rank_screen.ranked_in_last_month".tr(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ContainerCorner(
              height: 30,
              width: 30,
              borderRadius: 50,
              marginTop: 5,
              onTap: () => QuickHelp.hideLoadingDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.close,
                  color: kGrayColor,
                ),
              ),
            ),
          ],
        ),
        TextWithTap(
          "rank_screen.rules_".tr(),
          fontWeight: FontWeight.w900,
          alignment: Alignment.center,
          fontSize: 18,
        ),
        TextWithTap(
          "rank_screen.rich_monthly_ranking".tr(),
          marginTop: 10,
          fontSize: 12,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
              monToTheRules.length,
              (index) => TextWithTap(
                    monToTheRules[index],
                    fontSize: 12,
                  )),
        ),
        SizedBox(
          height: 15,
        ),
      ],
    );
  }

  Widget richDailyRules() {
    var monToTheRules = [
      "rank_screen.ranked_in_last_days".tr(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ContainerCorner(
              height: 30,
              width: 30,
              borderRadius: 50,
              marginTop: 5,
              onTap: () => QuickHelp.hideLoadingDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.close,
                  color: kGrayColor,
                ),
              ),
            ),
          ],
        ),
        TextWithTap(
          "rank_screen.rules_".tr(),
          fontWeight: FontWeight.w900,
          alignment: Alignment.center,
          fontSize: 18,
        ),
        TextWithTap(
          "rank_screen.rich_daily_ranking".tr(),
          marginTop: 10,
          fontSize: 12,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
              monToTheRules.length,
              (index) => TextWithTap(
                    monToTheRules[index],
                    fontSize: 12,
                  )),
        ),
        SizedBox(
          height: 15,
        ),
      ],
    );
  }

  Widget hostMonToThuRules() {
    var monToTheRules = [
      "rank_screen.daily_host_ranking_rule_1".tr(),
      "rank_screen.daily_host_ranking_rule_2".tr(),
      "rank_screen.daily_host_ranking_rule_3".tr(),
      "rank_screen.daily_host_ranking_rule_4".tr()
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ContainerCorner(
              height: 30,
              width: 30,
              borderRadius: 50,
              marginTop: 5,
              onTap: () => QuickHelp.hideLoadingDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.close,
                  color: kGrayColor,
                ),
              ),
            ),
          ],
        ),
        TextWithTap(
          "rank_screen.rules_".tr(),
          fontWeight: FontWeight.w900,
          alignment: Alignment.center,
          fontSize: 18,
        ),
        TextWithTap(
          "rank_screen.ranking_instruction".tr(),
          marginTop: 10,
          fontSize: 12,
        ),
        TextWithTap(
          "rank_screen.daily_host_ranking".tr(),
          marginTop: 3,
          fontSize: 12,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
              monToTheRules.length,
              (index) => TextWithTap(
                    monToTheRules[index],
                    fontSize: 12,
                  )),
        ),
        TextWithTap(
          "rank_screen.claim_requirement".tr(),
          marginTop: 20,
          fontSize: 12,
        ),
        TextWithTap(
          "rank_screen.daily_live_streaming".tr(),
          marginTop: 3,
          fontSize: 12,
          marginBottom: 15,
        ),
      ],
    );
  }

  Widget hostFriToSunRules() {
    var monToTheRules = [
      "rank_screen.ranking_from_fri_sun_rule_1".tr(),
      "rank_screen.daily_host_ranking_rule_2".tr(),
      "rank_screen.ranking_from_fri_sun_rule_3".tr(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ContainerCorner(
              height: 30,
              width: 30,
              borderRadius: 50,
              marginTop: 5,
              onTap: () => QuickHelp.hideLoadingDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Icon(
                  Icons.close,
                  color: kGrayColor,
                ),
              ),
            ),
          ],
        ),
        TextWithTap(
          "rank_screen.rules_".tr(),
          fontWeight: FontWeight.w900,
          alignment: Alignment.center,
          fontSize: 18,
        ),
        TextWithTap(
          "rank_screen.ranking_instruction".tr(),
          marginTop: 10,
          fontSize: 12,
        ),
        TextWithTap(
          "rank_screen.ranking_from_fri_sun".tr(),
          marginTop: 3,
          fontSize: 12,
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
              monToTheRules.length,
              (index) => TextWithTap(
                    monToTheRules[index],
                    fontSize: 12,
                  )),
        ),
        TextWithTap(
          "rank_screen.claim_requirement".tr(),
          marginTop: 20,
          fontSize: 12,
        ),
        TextWithTap(
          "rank_screen.total_live_from_fri_sun".tr(),
          marginTop: 3,
          fontSize: 12,
          marginBottom: 15,
        ),
      ],
    );
  }

  Widget showRulesAccordingTab() {
    if (tabIndex == 0) {
      if (hostIndexed == 0) {
        return hostMonToThuRules();
      } else {
        return hostFriToSunRules();
      }
    } else {
      if (richIndexed == 0) {
        return richDailyRules();
      } else {
        return richMonthlyRules();
      }
    }
  }

  void openRules() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        isDismissible: true,
        builder: (context) {
          return _showRules();
        });
  }

  Widget _showRules() {
    bool isDark = QuickHelp.isDarkMode(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return ContainerCorner(
                  borderWidth: 0,
                  color: Colors.black.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ContainerCorner(
                        //height: 350,
                        width: 250,
                        color: isDark ? kContentColorLightTheme : Colors.white,
                        borderRadius: 10,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 15,
                          ),
                          child: showRulesAccordingTab(),
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}
