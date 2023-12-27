// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/setup.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/helpers/quick_cloud.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/home/coins/coins_payment_widget.dart';
import 'package:trace/home/live/live_preview.dart';
import 'package:trace/home/live/live_streaming_screen.dart';
import 'package:trace/home/profile/profile_edit.dart';
import 'package:trace/models/GiftsSentModel.dart';
import 'package:trace/models/LiveStreamingModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/LiveMessagesModel.dart';
import '../../models/ReportModel.dart';
import '../../ui/button_with_icon.dart';
import '../following/following_screen.dart';
import '../live_application/live_application_scrren.dart';
import '../location_screen.dart';
import '../message/message_screen.dart';
import '../rank/rank_screen.dart';
import '../reels/reels_home_screen.dart';
import '../search/search_creen.dart';

// ignore: must_be_immutable
class LiveScreen extends StatefulWidget {
  static String route = "/home/live/all";

  UserModel? currentUser;
  SharedPreferences? preferences;

  LiveScreen({Key? key, this.currentUser, required this.preferences})
      : super(key: key);

  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  int tabsLength = 3;

  int tabTypeLive = 0;
  int tabTypeParty = 1;
  int tabTypeVideo = 2;

  late TabController _tabController;
  int tabIndex = 2;

  int numberOfColumns = 2;

  bool isFirstTime = false;

  List<dynamic> liveResults = <dynamic>[];
  late QueryBuilder<LiveStreamingModel> queryBuilder;

  var _future;

  AnimationController? animationController;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController.unbounded(vsync: this);

    QuickHelp.saveCurrentRoute(route: LiveScreen.route);

    _tabController = TabController(
        vsync: this, length: tabsLength, initialIndex: tabTypeVideo)
      ..addListener(() {
        setState(() {
          tabIndex = _tabController.index;
        });

        updateLives();
      });

    updateLives();
  }

  updateLives() {
    _future = _loadLive(tabIndex);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  Future<void> checkPermission(bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) async {
    if (QuickHelp.isAndroidPlatform()) {
      PermissionStatus status = await Permission.storage.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission android');

      checkStatus(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else if (QuickHelp.isIOSPlatform()) {
      PermissionStatus status = await Permission.photos.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission ios');

      checkStatus(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else {
      print('Permission other device');
      _gotoLiveScreen(isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    }
  }

  void checkStatus(PermissionStatus status, PermissionStatus status2,
      PermissionStatus status3, bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) {
    if (status.isDenied || status2.isDenied || status3.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.

      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access".tr(),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          message: "permissions.photo_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);

            // You can request multiple permissions at once.
            Map<Permission, PermissionStatus> statuses = await [
              Permission.camera,
              Permission.photos,
              Permission.storage,
              Permission.microphone,
            ].request();


            if (statuses[Permission.camera]!.isGranted &&
                statuses[Permission.photos]!.isGranted ||
                statuses[Permission.storage]!.isGranted ||
                statuses[Permission.microphone]!.isGranted) {
              _gotoLiveScreen(isBroadcaster,
                  channel: channel, liveStreamingModel: liveStreamingModel);
            }
          });
    } else if (status.isPermanentlyDenied ||
        status2.isPermanentlyDenied ||
        status3.isPermanentlyDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access_denied".tr(),
          confirmButtonText: "permissions.okay_settings".tr().toUpperCase(),
          message: "permissions.photo_access_denied_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () {
            QuickHelp.hideLoadingDialog(context);

            openAppSettings();
          });
    } else if (status.isGranted && status2.isGranted && status3.isGranted) {
      //_uploadPhotos(ImageSource.gallery);
      _gotoLiveScreen(isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    }

    print('Permission $status');
    print('Permission $status2');
    print('Permission $status3');
  }

  _gotoLiveScreen(bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) async {
    if (widget.currentUser!.getAvatar == null) {
      QuickHelp.showDialogLivEend(
        context: context,
        dismiss: true,
        title: 'live_streaming.photo_needed'.tr(),
        confirmButtonText: 'live_streaming.add_photo'.tr(),
        message: 'live_streaming.photo_needed_explain'.tr(),
        onPressed: () {
          QuickHelp.goBackToPreviousPage(context);
          QuickHelp.goToNavigatorScreen(
              context,
              ProfileEdit(
                currentUser: widget.currentUser,
              ));
        },
      );
    } else if (widget.currentUser!.getGeoPoint == null) {
      QuickHelp.showDialogLivEend(
        context: context,
        dismiss: true,
        title: 'live_streaming.location_needed'.tr(),
        confirmButtonText: 'live_streaming.add_location'.tr(),
        message: 'live_streaming.location_needed_explain'.tr(),
        onPressed: () async {
          QuickHelp.goBackToPreviousPage(context);
          //QuickHelp.goToNavigator(context, LocationScreen.route, arguments: widget.currentUser);

          UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
              context,
              LocationScreen(
                currentUser: widget.currentUser,
              ));
          if (user != null) {
            widget.currentUser = user;
          }
        },
      );
    } else {
      if (isBroadcaster) {
        QuickHelp.goToNavigatorScreen(
            context, LivePreviewScreen(currentUser: widget.currentUser!));
      } else {
        if (liveStreamingModel!.getPrivate! && !widget.currentUser!.isAdmin!) {
          if (!liveStreamingModel.getPrivateViewersId!
              .contains(widget.currentUser!.objectId!)) {
            openPayPrivateLiveSheet(liveStreamingModel);
          } else {
            QuickHelp.goToNavigatorScreen(
                context,
                LiveStreamingScreen(
                  channelName: channel!,
                  isBroadcaster: false,
                  currentUser: widget.currentUser!,
                  preferences: widget.preferences,
                  mUser: liveStreamingModel.getAuthor,
                  isUserInvited: liveStreamingModel.getInvitedPartyUid!
                      .contains(widget.currentUser!.getUid!),
                  mLiveStreamingModel: liveStreamingModel,
                ),
            );
          }
        } else {
          QuickHelp.goToNavigatorScreen(
              context,
              LiveStreamingScreen(
                channelName: channel!,
                isBroadcaster: false,
                currentUser: widget.currentUser!,
                preferences: widget.preferences,
                mUser: liveStreamingModel.getAuthor,
                isUserInvited: liveStreamingModel.getInvitedPartyUid!
                    .contains(widget.currentUser!.getUid!),
                mLiveStreamingModel: liveStreamingModel,
              ),
          );
        }
      }
    }
  }

  goToLiveApplicationScreen() async{
    UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
      context, LiveApplicationScreen(
      currentUser: widget.currentUser,
      preferences: widget.preferences,),
    );
    if(user != null) {
      widget.currentUser = user;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);
    bool isDarkMode = QuickHelp.isDarkMode(context);
    return Scaffold(
      extendBodyBehindAppBar: tabIndex == 2,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TabBar(
          isScrollable: true,
          enableFeedback: false,
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: kTransparentColor,
          unselectedLabelColor: kTabIconDefaultColor,
          indicatorWeight: 0.1,
          labelPadding: EdgeInsets.symmetric(horizontal: 7.0),
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide.none,
          ),
          automaticIndicatorColorAdjustment: false,
          labelColor: isDark ? Colors.white : Colors.black,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          unselectedLabelStyle: TextStyle(fontSize: 24),
          tabs: [
            TextWithTap(
              "live_streaming.live_".tr(),
              fontWeight: FontWeight.w900,
            ),
            TextWithTap(
                "live_streaming.party_btn".tr(),
                fontWeight: FontWeight.w900,
            ),
            TextWithTap(
                "tab_feed.video_".tr(),
                fontWeight: FontWeight.w900,
            ),
          ],
        ),
        backgroundColor: kTransparentColor,
        actions: [
          IconButton(
            onPressed: () => QuickHelp.goToNavigatorScreen(
              context,
              SearchPage(
                preferences: widget.preferences,
                currentUser: widget.currentUser,
              ),
            ),
            icon: SvgPicture.asset(
              isDarkMode
                  ? "assets/svg/ic_search_for_dark_mode.svg"
                  : "assets/svg/ic_search_for_light_mode.svg",
              height: 25,
              width: 25,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () => QuickHelp.goToNavigatorScreen(
                  context,
                  RankScreen(
                    currentUser: widget.currentUser,
                    preferences: widget.preferences,
                  )),
              icon: SvgPicture.asset(
                "assets/svg/ic_rank.svg",
                height: 25,
                width: 25,
              ),
            ),
          ),
        ],
        //bottom:
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          initQuery(tabTypeLive),
          FollowingScreen(
            currentUser: widget.currentUser,
            preferences: widget.preferences,
          ),
          ReelsHomeScreen(
            currentUser: widget.currentUser != null
                ? widget.currentUser
                : widget.currentUser,
            preferences: widget.preferences,
          ),
        ],
        //children: List.generate(tabsLength, (index) => initQuery(index)),
      ),
    );
  }

  Future<void> _loadLiveUpdate() async {
    ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      if (apiResponse.results != null) {
        setState(() {
          liveResults.clear();
          liveResults.addAll(apiResponse.results!);
        });

        return Future(() => null);
      }
    } else {
      return Future(() => null);
    }
    return null;
  }

  Future<dynamic> _loadLive(int? category) async {
    QueryBuilder<UserModel> queryUsers = QueryBuilder(UserModel.forQuery());
    queryUsers.whereValueExists(UserModel.keyUserStatus, true);
    queryUsers.whereEqualTo(UserModel.keyUserStatus, true);

    queryBuilder = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);
    queryBuilder.whereValueExists(LiveStreamingModel.keyAuthor, true);
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyLiveType, LiveStreamingModel.liveVideo);
    queryBuilder.whereDoesNotMatchQuery(
        LiveStreamingModel.keyAuthor, queryUsers);

    /*if (category == tabTypeLive) {
      queryBuilder.whereContainedIn(
          LiveStreamingModel.keyAuthorId, widget.currentUser!.getFollowing!);
    } else if (category == tabTypeParty) {
      // Nearby
      if (widget.currentUser!.getGeoPoint != null) {
        queryBuilder.whereWithinKilometers(LiveStreamingModel.keyLiveGeoPoint,
            widget.currentUser!.getGeoPoint!, Setup.maxDistanceToNearBy);
        queryBuilder.orderByDescending(LiveStreamingModel.keyLiveGeoPoint);
      }
    } else if (category == tabTypeVideo) {
      // New
      queryBuilder.whereEqualTo(LiveStreamingModel.keyFirstLive, true);
      queryBuilder.orderByDescending(LiveStreamingModel.keyCreatedAt);
    }*/

    queryBuilder.setLimit(25);
    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift
    ]);

    ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      if (apiResponse.results != null) {
        //setupLiveQuery();

        setState(() {
          liveResults.clear();
        });

        return apiResponse.results;
      } else {
        return [];
      }
    } else {
      return null;
    }
  }

  Widget initQuery(int category) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.all(2),
      child: Column(
        children: [
          if(category == tabTypeParty)
            ContainerCorner(
              width: size.width,
              borderWidth: 0,
              height: 30,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ContainerCorner(
                            height: 55,
                            width: 80,
                            marginLeft: 10,
                            borderWidth: 0,
                            borderRadius: 50,
                            color: kPrimaryColor.withOpacity(0.2),
                            child: Center(
                              child: TextWithTap(
                                "live_streaming.popular_".tr(),
                                color: kPrimaryColor,),),
                          ),
                          ContainerCorner(
                            height: 55,
                            //width: 80,
                            marginLeft: 10,
                            borderWidth: 0,
                            borderRadius: 50,
                            color: kPrimaryColor.withOpacity(0.2),
                            child: Row(children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Image.asset("assets/images/phili.png"),
                              ),
                              TextWithTap(
                                "Philippines",
                                color: kPrimaryColor,
                                marginRight: 10,
                                //marginLeft: ,
                              )
                            ],),
                          ),
                          ContainerCorner(
                            height: 55,
                            width: 80,
                            marginLeft: 10,
                            borderWidth: 0,
                            borderRadius: 50,
                            color: kPrimaryColor.withOpacity(0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset("assets/images/flags.png"),
                            ),
                          ),
                          ContainerCorner(
                            height: 55,
                            width: 80,
                            marginLeft: 10,
                            borderWidth: 0,
                            borderRadius: 50,
                            color: kPrimaryColor.withOpacity(0.2),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Image.asset("assets/images/asiz.png"),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: (){},
                    icon: Icon(Icons.menu, color: kPrimaryColor,),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder(
                future: _future,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.custom(
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      childrenDelegate: SliverChildBuilderDelegate(
                        childCount: 8,
                            (BuildContext context, int index) {
                          return FadeShimmer(
                            height: 60,
                            width: 60,
                            radius: 4,
                            fadeTheme: QuickHelp.isDarkModeNoContext()
                                ? FadeTheme.dark
                                : FadeTheme.light,
                          );
                        },
                      ),
                    );
                  } else if (snapshot.hasData) {
                    liveResults = snapshot.data! as List<dynamic>;

                    if (liveResults.isNotEmpty) {
                      return RefreshIndicator(
                        key: _refreshIndicatorKey,
                        color: Colors.white,
                        backgroundColor: kPrimaryColor,
                        strokeWidth: 2.0,
                        onRefresh: () {
                          _refreshIndicatorKey.currentState?.show(atTop: true);
                          return _loadLiveUpdate();
                        },
                        child: GridView.custom(
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          childrenDelegate: SliverChildBuilderDelegate(
                            childCount: liveResults.length,
                                (BuildContext context, int index) {
                              final LiveStreamingModel liveStreaming =
                              liveResults[index] as LiveStreamingModel;
                              return GestureDetector(
                                onLongPress: () {
                                  if (liveStreaming.getAuthorId !=
                                      widget.currentUser!.objectId) {
                                    openSheet(
                                        liveStreaming.getAuthor!, liveStreaming);
                                  }
                                },
                                onTap: () {
                                  checkPermission(false,
                                      channel: liveStreaming.getStreamingChannel,
                                      liveStreamingModel: liveStreaming);
                                },
                                child: Stack(children: [
                                  ContainerCorner(
                                    color: kTransparentColor,
                                    child: QuickActions.photosWidget(
                                        liveStreaming.getImage!.url!,
                                        borderRadius: 5),
                                  ),
                                  Positioned(
                                    top: 0,
                                    child: ContainerCorner(
                                      radiusTopLeft: 5,
                                      radiusTopRight: 5,
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width /
                                          numberOfColumns) -
                                          5,
                                      alignment: Alignment.center,
                                      colors: [
                                        Colors.black,
                                        Colors.black.withOpacity(0.05)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      child: ContainerCorner(
                                        color: kTransparentColor,
                                        marginLeft: 10,
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svg/ic_small_viewers.svg",
                                                  height: 18,
                                                ),
                                                TextWithTap(
                                                  liveStreaming.getViewersCount
                                                      .toString(),
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  marginRight: 15,
                                                  marginLeft: 5,
                                                ),
                                                SvgPicture.asset(
                                                  "assets/svg/ic_diamond.svg",
                                                  height: 24,
                                                ),
                                                TextWithTap(
                                                  liveStreaming
                                                      .getAuthor!.getDiamondsTotal!
                                                      .toString(),
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  marginLeft: 3,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Visibility(
                                    visible: liveStreaming.getPrivate!,
                                    child: Center(
                                      child: Icon(
                                        Icons.vpn_key,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    child: ContainerCorner(
                                      radiusBottomLeft: 5,
                                      radiusBottomRight: 5,
                                      height: 40,
                                      width: (MediaQuery.of(context).size.width /
                                          numberOfColumns) -
                                          5,
                                      alignment: Alignment.center,
                                      colors: [
                                        Colors.black,
                                        Colors.black.withOpacity(0.05)
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      child: Row(
                                        children: [
                                          QuickActions.avatarWidget(
                                              liveStreaming.getAuthor!,
                                              height: 30,
                                              width: 30,
                                              margin: EdgeInsets.only(
                                                  left: 5, bottom: 5)),
                                          Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              TextWithTap(
                                                liveStreaming.getAuthor!.getFullName!,
                                                color: Colors.white,
                                                overflow: TextOverflow.ellipsis,
                                                marginLeft: 10,
                                              ),
                                              Visibility(
                                                visible: liveStreaming
                                                    .getStreamingTags!.isNotEmpty,
                                                child: TextWithTap(
                                                  liveStreaming.getStreamingTags!,
                                                  color: Colors.white,
                                                  overflow: TextOverflow.ellipsis,
                                                  marginLeft: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      return ContainerCorner(
                        width: size.width,
                        height: size.height,
                        borderWidth: 0,
                        child: Center(
                            child: Image.asset(
                              "assets/images/szy_kong_icon.png",
                              height: size.width / 2,
                            )),
                      );
                    }
                  } else {
                    return ContainerCorner(
                      width: size.width,
                      height: size.height,
                      borderWidth: 0,
                      child: Center(
                          child: Image.asset(
                            "assets/images/szy_kong_icon.png",
                            height: size.width / 2,
                          )),
                    );
                  }
                }),
          ),
        ],
      ),
    );

    /*if(_isLoading){

      return GridView.custom(
        physics: const AlwaysScrollableScrollPhysics(),
        primary: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        childrenDelegate: SliverChildBuilderDelegate(
          childCount: 8, (BuildContext context, int index) {
          return FadeShimmer(
            height: 60,
            width: 60,
            radius: 4,
            fadeTheme: QuickHelp.isDarkModeNoContext() ? FadeTheme.dark : FadeTheme.light,
          );
        },
        ),
      );

    } else if(liveResults.isNotEmpty) {

      return RefreshIndicator(
        key: _refreshIndicatorKey,
        color: Colors.white,
        backgroundColor: kPrimaryColor,
        strokeWidth: 2.0,
        onRefresh: () {
          _refreshIndicatorKey.currentState?.show(atTop: true);
          return _loadLiveUpdate(tabIndex);
        },
        child: StaggeredGridView.countBuilder(
          crossAxisCount: 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          itemCount: liveResults.length,
          itemBuilder: (BuildContext context, int index) {

            if (liveResults[index] is LiveStreamingModel){

              final LiveStreamingModel liveStreaming = liveResults[index] as LiveStreamingModel;
              return GestureDetector(
                onTap: (){
                  checkPermission(false, channel: liveStreaming.getStreamingChannel, liveStreamingModel: liveStreaming);
                },
                child: Stack(children: [
                  ContainerCorner(
                    color: kTransparentColor,
                    child: QuickActions.photosWidget(liveStreaming.getImage!.url!, borderRadius: 5),
                  ),
                  Positioned(
                    top: 0,
                    child: ContainerCorner(
                      radiusTopLeft: 5,
                      radiusTopRight: 5,
                      height: 40,
                      width: (MediaQuery.of(context).size.width / numberOfColumns) - 5,
                      alignment: Alignment.center,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.05)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      child: ContainerCorner(
                        color: kTransparentColor,
                        marginLeft: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/svg/ic_small_viewers.svg",
                                  height: 18,
                                ),
                                TextWithTap(liveStreaming.getViewersCount.toString(),
                                  color: Colors.white,
                                  fontSize: 14,
                                  marginRight: 15,
                                  marginLeft: 5,
                                ),
                                SvgPicture.asset(
                                  "assets/svg/ic_diamond.svg",
                                  height: 24,
                                ),
                                TextWithTap(
                                  liveStreaming.getAuthor!.getDiamondsTotal!.toString(),
                                  color: Colors.white,
                                  fontSize: 14,
                                  marginLeft: 3,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: liveStreaming.getPrivate!,
                    child: Center(
                      child: Icon(Icons.vpn_key, color: Colors.white, size: 35,),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: ContainerCorner(
                      radiusBottomLeft: 5,
                      radiusBottomRight: 5,
                      height: 40,
                      width: (MediaQuery.of(context).size.width / numberOfColumns) - 5,
                      alignment: Alignment.center,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.05)
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      child: Row(
                        children: [
                          QuickActions.avatarWidget(
                              liveStreaming.getAuthor!, height: 30, width: 30,
                              margin: EdgeInsets.only(left: 5, bottom: 5)
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWithTap(
                                liveStreaming.getAuthor!.getFullName!,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                                marginLeft: 10,
                              ),
                              Visibility(
                                visible: liveStreaming.getStreamingTags!.isNotEmpty,
                                child: TextWithTap(
                                  liveStreaming.getStreamingTags!,
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                  marginLeft: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              );

            } else {

              return FutureBuilder(
                  future: getNativeAdTest(context: context),
                  builder: (BuildContext context, snapshot) {
                    if (snapshot.hasData) {
                      AdWidget ad = snapshot.data as AdWidget;

                      final Container adContainer = Container(
                        alignment: Alignment.center,
                        color: Colors.white,
                        child: ad,
                      );

                      return adContainer;

                    } else {
                      return Container(
                          alignment: Alignment.topCenter,
                          margin: const EdgeInsets.only(top: 20),
                          child: const CircularProgressIndicator(
                            value: 0.8,
                          ));
                    }
                  });
            }
          },
          staggeredTileBuilder: (int index){

            if (liveResults[index] is LiveStreamingModel){ //if (index % _kAdIndex == 0) {
              return StaggeredTile.count(1, 1);
            } else {
              return StaggeredTile.count(2, 3);
            }

          },
        ),
      );

    } else {

      return Center(
        child: Padding(
          padding:  EdgeInsets.all(8.0),
          child: QuickActions.noContentFound(
            "live_streaming.no_live_title".tr(),
            "live_streaming.no_live_explain".tr(),
            "assets/svg/ic_tab_live_default.svg",
          ),
        ),
      );
    }*/
  }

  String distanceValue(double distance) {
    //QuickHelp.distanceInKilometersTo(liveStreaming.getStreamingGeoPoint!, widget.currentUser!.getGeoPoint!)
    if (distance >= 1.0) {
      return "${num.parse(distance.toStringAsFixed(2))} km";
    } else {
      return "${num.parse((distance * 1000).toStringAsFixed(2))} m";
    }
  }

  void openPayPrivateLiveSheet(LiveStreamingModel live) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showPayPrivateLiveBottomSheet(live);
        });
  }

  Widget _showPayPrivateLiveBottomSheet(LiveStreamingModel live) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    appBar: AppBar(
                      toolbarHeight: 35.0,
                      backgroundColor: kTransparentColor,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      actions: [
                        IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close)),
                      ],
                    ),
                    backgroundColor: kTransparentColor,
                    body: Column(
                      children: [
                        Center(
                            child: TextWithTap(
                              "live_streaming.private_live".tr(),
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 25,
                              marginBottom: 15,
                            )),
                        Center(
                          child: TextWithTap(
                            "live_streaming.private_live_explain".tr(),
                            color: Colors.white,
                            fontSize: 16,
                            marginLeft: 20,
                            marginRight: 20,
                            marginTop: 20,
                          ),
                        ),
                        Expanded(
                            child: Lottie.network(
                                live.getPrivateGift!.getFile!.url!,
                                width: 150,
                                height: 150,
                                animate: true,
                                repeat: true)),
                        ContainerCorner(
                          color: kTransparentColor,
                          marginTop: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                "assets/svg/ic_coin_with_star.svg",
                                width: 24,
                                height: 24,
                              ),
                              TextWithTap(
                                live.getPrivateGift!.getCoins.toString(),
                                color: Colors.white,
                                fontSize: 18,
                                marginLeft: 5,
                              )
                            ],
                          ),
                        ),
                        ContainerCorner(
                          borderRadius: 10,
                          height: 50,
                          width: 150,
                          color: kPrimaryColor,
                          onTap: () {
                            if (widget.currentUser!.getCredits! >=
                                live.getPrivateGift!.getCoins!) {
                              _payForPrivateLive(live);
                              //sendGift(live);
                            } else {
                              CoinsFlowPayment(
                                context: context,
                                currentUser: widget.currentUser!,
                                showOnlyCoinsPurchase: true,
                                onCoinsPurchased: (coins) {
                                  print(
                                      "onCoinsPurchased: $coins new: ${widget.currentUser!.getCredits}");

                                  if (widget.currentUser!.getCredits! >=
                                      live.getPrivateGift!.getCoins!) {
                                    _payForPrivateLive(live);
                                    //sendGift(live);
                                  }
                                },
                              );
                            }
                          },
                          marginTop: 15,
                          marginBottom: 40,
                          child: Center(
                            child: TextWithTap(
                              "live_streaming.pay_for_live".tr(),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  _payForPrivateLive(LiveStreamingModel live) async {
    QuickHelp.showLoadingDialog(context);

    GiftsSentModel giftsSentModel = new GiftsSentModel();
    giftsSentModel.setAuthor = widget.currentUser!;
    giftsSentModel.setAuthorId = widget.currentUser!.objectId!;

    giftsSentModel.setReceiver = live.getAuthor!;
    giftsSentModel.setReceiverId = live.getAuthor!.objectId!;

    giftsSentModel.setGift = live.getPrivateGift!;
    giftsSentModel.setGiftId = live.getPrivateGift!.objectId!;
    giftsSentModel.setCounterDiamondsQuantity = live.getPrivateGift!.getCoins!;

    await giftsSentModel.save();

    QuickHelp.saveReceivedGifts(receiver: live.getAuthor!, author: widget.currentUser!, gift: live.getPrivateGift!);
    QuickHelp.saveCoinTransaction(
      receiver: live.getAuthor!,
      author: widget.currentUser!,
      amountTransacted: live.getPrivateGift!.getCoins!,
    );

    ParseResponse response = await QuickCloudCode.sendGift(
        author: live.getAuthor!,
        credits: live.getPrivateGift!.getCoins!,
        preferences: widget.preferences!);

    if (response.success) {
      updateCurrentUserCredit(
          live.getPrivateGift!.getCoins!, live, giftsSentModel);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  updateCurrentUserCredit(
      int coins, LiveStreamingModel live, GiftsSentModel sentModel) async {
    widget.currentUser!.removeCredit = coins;
    ParseResponse userResponse = await widget.currentUser!.save();
    if (userResponse.success) {
      widget.currentUser = userResponse.results!.first as UserModel;

      sendMessage(live, sentModel);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  sendMessage(LiveStreamingModel live, GiftsSentModel giftsSentModel) async {
    live.addDiamonds = QuickHelp.getDiamondsForReceiver(
        live.getPrivateGift!.getCoins!, widget.preferences!);
    await live.save();

    LiveMessagesModel liveMessagesModel = new LiveMessagesModel();
    liveMessagesModel.setAuthor = widget.currentUser!;
    liveMessagesModel.setAuthorId = widget.currentUser!.objectId!;

    liveMessagesModel.setLiveStreaming = live;
    liveMessagesModel.setLiveStreamingId = live.objectId!;

    liveMessagesModel.setGiftSent = giftsSentModel;
    liveMessagesModel.setGiftSentId = giftsSentModel.objectId!;
    liveMessagesModel.setGiftId = giftsSentModel.getGiftId!;

    liveMessagesModel.setMessage = "";
    liveMessagesModel.setMessageType = LiveMessagesModel.messageTypeGift;

    ParseResponse response = await liveMessagesModel.save();
    if (response.success) {
      QuickHelp.goToNavigatorScreen(
          context,
          LiveStreamingScreen(
            channelName: live.getStreamingChannel!,
            isBroadcaster: false,
            preferences: widget.preferences,
            currentUser: widget.currentUser!,
            mUser: live.getAuthor,
            mLiveStreamingModel: live,
          ));
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  Widget tabsRows(String title, int position, Widget icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tabIndex == position) icon,
        SizedBox(width: 6),
        Text(title.tr()),
      ],
    );
  }

  void openSheet(UserModel author, LiveStreamingModel live) async {
    showModalBottomSheet(
        context: (context),
        //isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showPostOptionsAndReportAuthor(author, live);
        });
  }

  Widget _showPostOptionsAndReportAuthor(
      UserModel author, LiveStreamingModel live) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: ContainerCorner(
        radiusTopRight: 20.0,
        radiusTopLeft: 20.0,
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: !widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.report_live".tr(),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                radiusTopLeft: 25.0,
                radiusTopRight: 25.0,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () {
                  openReportMessage(author, live, true);
                },
              ),
            ),
            Visibility(
                visible: !widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: !widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.report_live_user"
                    .tr(namedArgs: {"name": author.getFullName!}),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () {
                  openReportMessage(author, live, false);
                },
              ),
            ),
            Visibility(
                visible: !widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.live_option_suspend".tr(),
                textColor: Colors.black,
                fontSize: 18,
                radiusTopLeft: 25.0,
                radiusTopRight: 25.0,
                fontWeight: FontWeight.w500,
                iconURL: "assets/svg/ic_blocked_menu.svg",
                onTap: () => _suspendUser(live),
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
              ),
            ),
            Visibility(visible: widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.live_option_terminate".tr(),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () {
                  _terminateLive(live);
                },
              ),
            ),
            Visibility(visible: widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.live_option_change".tr(),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () => _changePicture(live, terminate: false),
              ),
            ),
            Visibility(visible: widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.live_option_change_terminate".tr(),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () => _changePicture(live, terminate: true),
              ),
            ),
            Visibility(visible: widget.currentUser!.isAdmin!, child: Divider()),
            Visibility(
              visible: widget.currentUser!.isAdmin!,
              child: ButtonWithIcon(
                text: "live_streaming.live_option_chat".tr(),
                iconURL: "assets/svg/ic_blocked_menu.svg",
                height: 60,
                backgroundColor: Colors.white,
                mainAxisAlignment: MainAxisAlignment.start,
                textColor: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                onTap: () {
                  _gotToChat(widget.currentUser!, live.getAuthor!);
                },
              ),
            ),
            Visibility(visible: widget.currentUser!.isAdmin!, child: Divider()),
          ],
        ),
      ),
    );
  }

  void openReportMessage(UserModel author,
      LiveStreamingModel liveStreamingModel, bool isStreamer) async {
    showModalBottomSheet(
      context: (context),
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return _showReportMessageBottomSheet(
            author, liveStreamingModel, isStreamer);
      },
    );
  }

  Widget _showReportMessageBottomSheet(
      UserModel author, LiveStreamingModel streamingModel, bool isStreamer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
      ),
      child: ContainerCorner(
        radiusTopRight: 20.0,
        radiusTopLeft: 20.0,
        color: QuickHelp.isDarkMode(context)
            ? kContentColorLightTheme
            : Colors.white,
        child: Column(
          children: [
            ContainerCorner(
              color: kGreyColor1,
              width: 50,
              marginTop: 5,
              borderRadius: 50,
              marginBottom: 10,
            ),
            TextWithTap(
              isStreamer
                  ? "live_streaming.report_live".tr()
                  : "live_streaming.report_live_user"
                  .tr(namedArgs: {"name": author.getFirstName!}),
              fontWeight: FontWeight.w900,
              fontSize: 20,
              marginBottom: 50,
            ),
            Column(
              children: List.generate(
                  QuickHelp.getReportCodeMessageList().length, (index) {
                String code = QuickHelp.getReportCodeMessageList()[index];

                return TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    print("Message: " + QuickHelp.getReportMessage(code));
                    _saveReport(QuickHelp.getReportMessage(code), author,
                        live: isStreamer ? streamingModel : null);
                  },
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWithTap(
                            QuickHelp.getReportMessage(code),
                            color: kGrayColor,
                            fontSize: 15,
                            marginBottom: 5,
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: kGrayColor,
                          ),
                        ],
                      ),
                      Divider(
                        height: 1.0,
                      )
                    ],
                  ),
                );
              }),
            ),
            ContainerCorner(
              marginTop: 30,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: TextWithTap(
                  "cancel".tr().toUpperCase(),
                  color: kGrayColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _saveReport(String reason, UserModel? user,
      {LiveStreamingModel? live}) async {
    QuickHelp.showLoadingDialog(context);

    ParseResponse response = await QuickActions.report(
        type: ReportModel.reportTypeLiveStreaming,
        message: reason,
        accuser: widget.currentUser!,
        accused: user!,
        liveStreamingModel: live);
    if (response.success) {
      QuickHelp.hideLoadingDialog(context);

      QuickHelp.showAppNotificationAdvanced(
          context: context,
          user: widget.currentUser,
          title: "live_streaming.report_done".tr(),
          message: "live_streaming.report_done_explain".tr(),
          isError: false);
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "live_streaming.report_live_error".tr(),
          isError: true);
    }
  }

  _terminateLive(LiveStreamingModel live) {
    QuickHelp.goBackToPreviousPage(context);

    QuickHelp.showDialogWithButtonCustom(
      context: context,
      title: "live_streaming.live_option_terminate".tr(),
      message: "live_streaming.live_option_terminate_ask".tr(),
      cancelButtonText: "no".tr(),
      confirmButtonText: "live_streaming.live_option_terminate_ask_yes".tr(),
      onPressed: () => _confirmTerminateLive(live),
    );
  }

  _suspendUser(LiveStreamingModel live) {
    QuickHelp.goBackToPreviousPage(context);

    QuickHelp.showDialogWithButtonCustom(
      context: context,
      title: "feed.suspend_user_alert".tr(),
      message: "feed.suspend_user_message".tr(),
      cancelButtonText: "no".tr(),
      confirmButtonText: "feed.yes_suspend".tr(),
      onPressed: () => _confirmSuspendUser(live),
    );
  }

  _confirmSuspendUser(LiveStreamingModel live) async {
    QuickHelp.goBackToPreviousPage(context);

    QuickHelp.showLoadingDialog(context);

    live.setTerminatedByAdmin = true;
    live.setStreaming = false;
    await live.save();

    ParseResponse parseResponse =
    await QuickCloudCode.suspendUSer(objectId: live.getAuthor!.objectId!);
    if (parseResponse.success) {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "suspended".tr(),
        message: "feed.user_suspended".tr(),
        user: live.getAuthor,
        isError: null,
      );
    } else {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "feed.user_not_suspended".tr(),
        user: live.getAuthor,
        isError: true,
      );
    }
  }

  _confirmTerminateLive(LiveStreamingModel live) async {
    QuickHelp.goBackToPreviousPage(context);

    QuickHelp.showLoadingDialog(context);

    live.setTerminatedByAdmin = true;
    ParseResponse parseResponse = await live.save();

    if (parseResponse.success) {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "live_streaming.live_option_terminate".tr(),
        message: "live_streaming.live_option_terminated".tr(),
        user: live.getAuthor,
        isError: null,
      );
    } else {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "live_streaming.live_option_not_terminated".tr(),
        user: live.getAuthor,
        isError: true,
      );
    }
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickHelp.goToNavigatorScreen(
        context,
        MessageScreen(
            currentUser: currentUser,
            mUser: mUser,
            preferences: widget.preferences));
  }

  _changePicture(LiveStreamingModel live, {bool? terminate = false}) {
    QuickHelp.goBackToPreviousPage(context);

    QuickHelp.showDialogWithButtonCustom(
      context: context,
      title: "live_streaming.live_option_change".tr(),
      message: terminate == true
          ? "live_streaming.live_option_change_photo_ask".tr()
          : "live_streaming.live_option_change_photo_normal_ask".tr(),
      cancelButtonText: "no".tr(),
      confirmButtonText: "live_streaming.live_option_change_photo_ask_yes".tr(),
      onPressed: () => _confirmChangePicture(live, terminate),
    );
  }

  _confirmChangePicture(LiveStreamingModel live, terminate) async {
    QuickHelp.goBackToPreviousPage(context);
    QuickHelp.showLoadingDialog(context);

    List<String> keywords = [];

    if (live.getAuthor!.getGender! == UserModel.keyGenderMale) {
      keywords = ["sexy male", "male model"];
    } else if (live.getAuthor!.getGender! == UserModel.keyGenderFemale) {
      keywords = ["sexy female", "female model"];
    } else {
      keywords = ["model", "sexy"];
    }

    var faker = Faker();
    String imageUrl = faker.image
        .image(width: 640, height: 640, keywords: keywords, random: true);

    File avatar = await QuickHelp.downloadFile(imageUrl, "avatar.jpeg") as File;

    if (terminate) {
      live.setTerminatedByAdmin = true;
      live.setStreaming = false;
      await live.save();
    } else {
      ParseFileBase parseFile;
      if (QuickHelp.isWebPlatform()) {
        //Seems weird, but this lets you get the data from the selected file as an Uint8List very easily.
        ParseWebFile file =
        ParseWebFile(null, name: "avatar.jpeg", url: avatar.path);
        await file.download();
        parseFile = ParseWebFile(file.file, name: file.name);
      } else {
        parseFile = ParseFile(File(avatar.path));
      }

      live.setImage = parseFile;
      await live.save();
    }

    ParseResponse parseResponse = await QuickCloudCode.changePicture(
        user: live.getAuthor!, parseFile: avatar.readAsBytesSync());
    if (parseResponse.success) {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "live_streaming.live_option_change".tr(),
        message: "live_streaming.live_option_changed_photo".tr(),
        user: live.getAuthor,
        isError: null,
      );
    } else {
      QuickHelp.goBackToPreviousPage(context);

      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "live_streaming.live_option_not_changed_photo".tr(),
        user: live.getAuthor,
        isError: true,
      );
    }
  }
}