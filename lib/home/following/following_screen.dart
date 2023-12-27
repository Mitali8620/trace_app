import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/setup.dart';
import 'package:trace/home/live/live_preview.dart';
import 'package:trace/home/live/live_streaming_screen.dart';
import 'package:trace/home/location_screen.dart';
import 'package:trace/home/profile/profile_edit.dart';
import 'package:trace/models/LiveStreamingModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../helpers/quick_cloud.dart';
import '../../models/GiftsSentModel.dart';
import '../../models/LiveMessagesModel.dart';
import '../audio_live/audio_live_screen.dart';
import '../coins/coins_payment_widget.dart';
import '../live/live_party_screen.dart';
import '../live_application/live_application_scrren.dart';
import '../search/search_creen.dart';

// ignore: must_be_immutable
class FollowingScreen extends StatefulWidget {
  static const String route = '/home/following';

  UserModel? currentUser;
  SharedPreferences? preferences;

  FollowingScreen({this.currentUser, required this.preferences});

  @override
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen>
    with TickerProviderStateMixin {

  int numberOfColumns = 2;

  List<dynamic> liveResults = <dynamic>[];
  var _future;

  int tabsLength = 2;

  int tabTypeFollowing = 0;
  int tabTypeParty = 1;

  AnimationController? _animationController;

  late TabController _tabController;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  late QueryBuilder<LiveStreamingModel> queryBuilder;

  @override
  void initState() {
    QuickHelp.saveCurrentRoute(route: FollowingScreen.route);

    _animationController = AnimationController.unbounded(vsync: this);

    _tabController = TabController(
        vsync: this, length: tabsLength, initialIndex: tabTypeParty)
      ..addListener(() {
        setState(() {
          tabIndex = _tabController.index;
        });

        updateLives();
      });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  updateLives() {
    print("LiveIndex: $tabIndex");
    _future = _loadLive(tabIndex);
  }

  goToLiveApplicationScreen() async {
    UserModel? user = await QuickHelp.goToNavigatorScreenForResult(
      context,
      LiveApplicationScreen(
        currentUser: widget.currentUser,
        preferences: widget.preferences,
      ),
    );
    if (user != null) {
      widget.currentUser = user;
    }
  }

  @override
  Widget build(BuildContext context) {
    QuickHelp.setWebPageTitle(context, "page_title.following_title".tr());
    return Scaffold(
      body: audioRooms(),
    );
  }

  Widget audioRooms() {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift,
      LiveStreamingModel.keyAudioHostsList,
    ]);

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyLiveType, LiveStreamingModel.liveAudio);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);
    queryBuilder.whereValueExists(LiveStreamingModel.keyAuthor, true);
    queryBuilder.orderByDescending(LiveStreamingModel.keyAuthorTotalDiamonds);

    return Padding(
      padding: EdgeInsets.only(right: 2, left: 2),
      child: ParseLiveGridWidget<LiveStreamingModel>(
        query: queryBuilder,
        crossAxisCount: numberOfColumns,
        reverse: false,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        lazyLoading: false,
        childAspectRatio: 1.0,
        shrinkWrap: true,
        listenOnAllSubItems: true,
        listeningIncludes: [
          LiveStreamingModel.keyAuthor,
          LiveStreamingModel.keyAuthorInvited,
        ],
        duration: Duration(seconds: 0),
        animationController: _animationController,
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<LiveStreamingModel> snapshot) {
          if (snapshot.hasData) {
            LiveStreamingModel liveStreaming = snapshot.loadedData!;

            return GestureDetector(
              onTap: () {
                if (liveStreaming.getRemovedUserIds!
                    .contains(widget.currentUser!.objectId)) {
                  QuickHelp.showAppNotificationAdvanced(
                    title: "audio_chat.cannot_access_room_title".tr(),
                    context: context,
                    message: "audio_chat.cannot_access_room_explain".tr(),
                  );
                } else {
                  checkPermissionAudio(false,
                      channel: liveStreaming.getStreamingChannel,
                      liveStreamingModel: liveStreaming);
                }
              },
              child: Stack(children: [
                ContainerCorner(
                  color: kTransparentColor,
                  child: QuickActions.photosWidget(liveStreaming.getImage!.url!,
                      borderRadius: 5),
                ),
                Positioned(
                  top: 0,
                  child: ContainerCorner(
                    radiusTopLeft: 5,
                    radiusTopRight: 5,
                    height: 40,
                    width:
                        (MediaQuery.of(context).size.width / numberOfColumns) -
                            5,
                    alignment: Alignment.center,
                    colors: [Colors.black, Colors.black.withOpacity(0.05)],
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
                              TextWithTap(
                                liveStreaming.getViewersCount.toString(),
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
                                liveStreaming.getAuthor!.getDiamondsTotal!
                                    .toString(),
                                color: Colors.white,
                                fontSize: 14,
                                marginLeft: 3,
                              ),
                            ],
                          ),
                          /*if(category == tabTypeNearby)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.white, size: 15,),
                              TextWithTap(
                                distanceValue(QuickHelp.distanceInKilometersTo(liveStreaming.getStreamingGeoPoint!, widget.currentUser!.getGeoPoint!)).toString(),
                              color: Colors.white,
                                marginRight: 3,
                              ),
                            ],
                          )*/
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
                    width:
                        (MediaQuery.of(context).size.width / numberOfColumns) -
                            5,
                    alignment: Alignment.center,
                    colors: [Colors.black, Colors.black.withOpacity(0.05)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    child: Row(
                      children: [
                        QuickActions.avatarWidget(liveStreaming.getAuthor!,
                            height: 30,
                            width: 30,
                            margin: EdgeInsets.only(left: 5, bottom: 5)),
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
                              visible:
                                  liveStreaming.getStreamingTags!.isNotEmpty,
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
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        queryEmptyElement: QuickActions.noContentFound(context),
        gridLoadingElement: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<void> checkPermissionAudio(bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) async {
    if (QuickHelp.isAndroidPlatform()) {
      PermissionStatus status = await Permission.storage.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission android');

      checkStatusAudio(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else if (QuickHelp.isIOSPlatform()) {
      PermissionStatus status = await Permission.photos.status;
      PermissionStatus status2 = await Permission.camera.status;
      PermissionStatus status3 = await Permission.microphone.status;
      print('Permission ios');

      checkStatusAudio(status, status2, status3, isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    } else {
      print('Permission other device');
      _gotoLiveScreenAudio(isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    }
  }

  void checkStatusAudio(PermissionStatus status, PermissionStatus status2,
      PermissionStatus status3, bool isBroadcaster,
      {String? channel, LiveStreamingModel? liveStreamingModel}) {
    if (status.isDenied || status2.isDenied || status3.isDenied) {
      QuickHelp.showDialogPermission(
          context: context,
          title: "permissions.photo_access".tr(),
          confirmButtonText: "permissions.okay_".tr().toUpperCase(),
          message: "permissions.photo_access_explain"
              .tr(namedArgs: {"app_name": Setup.appName}),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(context);
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
              _gotoLiveScreenAudio(isBroadcaster,
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
      _gotoLiveScreenAudio(isBroadcaster,
          channel: channel, liveStreamingModel: liveStreamingModel);
    }

    print('Permission $status');
    print('Permission $status2');
    print('Permission $status3');
  }

  _gotoLiveScreenAudio(bool isBroadcaster,
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
              ),
          );
        },
      );
    } else {
      if(liveStreamingModel!.getPartyType == LiveStreamingModel.liveVideo) {
        QuickHelp.goToNavigatorScreen(
          context,
          VideoPartyScreen(
            channelName: channel!,
            isBroadcaster: false,
            currentUser: widget.currentUser!,
            mUser: liveStreamingModel.getAuthor,
            isUserInvited: liveStreamingModel.getInvitedPartyUid!
                .contains(widget.currentUser!.getUid!),
            mLiveStreamingModel: liveStreamingModel,
            preferences: widget.preferences,
          ),
        );
      }else{
        QuickHelp.goToNavigatorScreen(
          context,
          AudioLiveScreen(
            channelName: channel!,
            isBroadcaster: false,
            currentUser: widget.currentUser!,
            mUser: liveStreamingModel.getAuthor,
            isUserInvited: liveStreamingModel.getInvitedPartyUid!
                .contains(widget.currentUser!.getUid!),
            mLiveStreamingModel: liveStreamingModel,
            preferences: widget.preferences,
          ),
        );
      }

    }
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

    if (category == tabTypeFollowing) {
      queryBuilder.whereContainedIn(
          LiveStreamingModel.keyAuthorId, widget.currentUser!.getFollowing!);
    }

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

  Widget initQuery(int category) {
    return Container(
      margin: EdgeInsets.all(2),
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
                              //openSheet(liveStreaming.getAuthor!, liveStreaming);
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
                return QuickActions.noContentFound(context);
              }
            } else {
              return QuickActions.noContentFound(context);
            }
          }),
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

            //if (await Permission.camera.request().isGranted) {
            // Either the permission was already granted before or the user just granted it.
            //}

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
            context,
            LivePreviewScreen(
              currentUser: widget.currentUser!,
              liveTypeIndex: 1,
            ));
      } else {
        if (liveStreamingModel!.getPrivate!) {
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
                  mUser: liveStreamingModel.getAuthor,
                  preferences: widget.preferences,
                  mLiveStreamingModel: liveStreamingModel,
                ));
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
                mLiveStreamingModel: liveStreamingModel,
              ));
        }
      }
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

    QuickHelp.saveReceivedGifts(
        receiver: live.getAuthor!,
        author: widget.currentUser!,
        gift: live.getPrivateGift!);
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
            currentUser: widget.currentUser!,
            mUser: live.getAuthor,
            preferences: widget.preferences,
            mLiveStreamingModel: live,
          ));
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }
}
