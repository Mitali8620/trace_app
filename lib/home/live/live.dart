// ignore_for_file: deprecated_member_use

import 'dart:ffi';

import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/constants.dart';
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
import '../location_screen.dart';

// ignore: must_be_immutable
class LiveScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;

  LiveScreen({Key? key, this.currentUser, this.preferences}) : super(key: key);

  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  int tabsLength = 5;

  int tabTypeForYou = 0;
  int tabTypeNearby = 1;
  int tabTypeNew = 2;
  int tabTypePopular = 3;
  int tabTypeAudio = 4;

  late TabController _tabController;
  int tabIndex = 0;

  int numberOfColumns = 2;

  List<dynamic> liveResults = <dynamic>[];
  late QueryBuilder<LiveStreamingModel> queryBuilder;

  var _future;

  static final _kAdIndex = 3;

  late List<Object> adsList;

  AnimationController? _animationController;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _tabController = TabController(
        vsync: this, length: tabsLength, initialIndex: tabTypeForYou)
      ..addListener(() {
        setState(() {
          tabIndex = _tabController.index;
        });

        updateLives();
      });

    updateLives();
  }

  updateLives() {
    _refreshIndicatorKey.currentState?.show(atTop: true);

    print("LiveIndex: $tabIndex");
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
                  preferences: null,
                  currentUser: widget.currentUser!,
                  mUser: liveStreamingModel.getAuthor,
                  isUserInvited: liveStreamingModel.getInvitedPartyUid!
                      .contains(widget.currentUser!.getUid!),
                  mLiveStreamingModel: liveStreamingModel,
                ));
          }
        } else {
          QuickHelp.goToNavigatorScreen(
              context,
              LiveStreamingScreen(
                channelName: channel!,
                isBroadcaster: false,
                preferences: null,
                currentUser: widget.currentUser!,
                mUser: liveStreamingModel.getAuthor,
                isUserInvited: liveStreamingModel.getInvitedPartyUid!
                    .contains(widget.currentUser!.getUid!),
                mLiveStreamingModel: liveStreamingModel,
              ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: tabIndex == 4
          ? FloatingActionButton(
              onPressed: () => checkPermission(true),
              child: ContainerCorner(
                onTap: () => checkPermission(true),
                height: 60,
                width: 60,
                colors: [kPrimaryColor, kSecondaryColor],
                borderRadius: 40,
                shadowColor: kPrimaryColor,
                shadowColorOpacity: 0.3,
                setShadowToBottom: true,
                blurRadius: 10,
                spreadRadius: 3,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    "assets/svg/ic_microphone.svg",
                    color: Colors.white,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            )
          : FloatingActionButton(
              onPressed: () => checkPermission(true),
              child: ContainerCorner(
                onTap: () => checkPermission(true),
                height: 60,
                width: 60,
                colors: [kPrimaryColor, kSecondaryColor],
                borderRadius: 40,
                shadowColor: kPrimaryColor,
                shadowColorOpacity: 0.3,
                setShadowToBottom: true,
                blurRadius: 10,
                spreadRadius: 3,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    "assets/svg/ic_tab_live_selected.svg",
                    color: Colors.white,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ),
      appBar: AppBar(
        centerTitle: true,
        title: TabBar(
          isScrollable: true,
          enableFeedback: false,
          controller: _tabController,
          indicatorColor: Colors.transparent,
          unselectedLabelColor: kTabIconDefaultColor,
          labelColor: kTabIconSelectedColor,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          labelPadding: EdgeInsets.only(right: 14),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            tabsRows("live_streaming.menu_for_you", tabTypeForYou,
                SvgPicture.asset("assets/svg/ic_followers_active.svg")),
            tabsRows(
                "live_streaming.menu_nearby",
                tabTypeNearby,
                Icon(
                  Icons.location_on,
                  size: 18,
                )),
            tabsRows(
                "live_streaming.menu_new",
                tabTypeNew,
                Icon(
                  Icons.new_releases,
                  size: 16,
                )),
            /*tabsRows(
                "live_streaming.menu_popular",
                tabTypePopular,
                SvgPicture.asset(
                  "assets/svg/ic_tab_following_selected.svg",
                  color: kPrimaryColor,
                  height: 20,
                  width: 20,
                )),*/
            tabsRows(
                "audio_chat.audio_chat",
                tabTypeAudio,
                SvgPicture.asset(
                  "assets/svg/ic_tab_following_selected.svg",
                  color: kPrimaryColor,
                  height: 20,
                  width: 20,
                )),
          ],
        ),
        backgroundColor: kTransparentColor,
        //bottom:
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          initQuery(tabTypeForYou),
          initQuery(tabTypeNearby),
          initQuery(tabTypeNew),
          initQuery(tabTypePopular),
          audioMessages(),
        ],
        //children: List.generate(tabsLength, (index) => initQuery(index)),
      ),
    );
  }

  Widget audioMessages() {
    return Column(
      children: [
        Expanded(
          child: audioRooms(),
        ),
      ],
    );
  }

  Widget audioRooms() {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift,
      LiveStreamingModel.keyAudioHostsList
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
                  checkPermission(false,
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

  Future<Void?> _loadLiveUpdate(int? category) async {
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
    //disposeLiveQuery();

    queryBuilder = QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);
    queryBuilder.whereValueExists(LiveStreamingModel.keyAuthor, true);

    if (category == tabTypeForYou) {
      //queryBuilder.orderByDescending(keyVarCreatedAt);
      queryBuilder.orderByDescending(LiveStreamingModel.keyAuthorTotalDiamonds);
    } else if (category == tabTypeNearby) {
      // Nearby
      if (widget.currentUser!.getGeoPoint != null) {
        queryBuilder.whereWithinKilometers(LiveStreamingModel.keyLiveGeoPoint,
            widget.currentUser!.getGeoPoint!, Setup.maxDistanceToNearBy);
        queryBuilder.orderByDescending(LiveStreamingModel.keyLiveGeoPoint);
      }
    } else if (category == tabTypeNew) {
      // New
      queryBuilder.whereEqualTo(LiveStreamingModel.keyFirstLive, true);
      queryBuilder.orderByDescending(LiveStreamingModel.keyCreatedAt);
    } else if (category == tabTypePopular) {
      // Popular
      queryBuilder.whereGreaterThanOrEqualsTo(
          LiveStreamingModel.keyStreamingDiamonds,
          Setup.minimumDiamondsToPopular);
      queryBuilder.orderByDescending(LiveStreamingModel.keyAuthorTotalDiamonds);
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

        return apiResponse.results;
      } else {
        return [];
      }
    } else {
      return null;
    }
  }

  /*Future<void> _loadMoreAsset() async {

    final List<AssetEntity> entities = await _path!.getAssetListPaged(
      page: _page + 1,
      size: _sizePerPage,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      liveResults.addAll(entities);
      _hasMoreToLoad = liveResults.length < _totalEntitiesCount;
      _isLoadingMore = false;
    });
  }*/

  dynamic getAds() {
    if (QuickHelp.isIOSPlatform()) {
      BannerAd bannerAd = BannerAd(
        adUnitId: Constants.getAdmobLiveBannerUnit(),
        size: AdSize.banner,
        request: AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {},
          onAdFailedToLoad: (ad, error) {
            // Releases an ad resource when it fails to load
            ad.dispose();
            print(
                'Ad load failed (code=${error.code} message=${error.message})');
          },
        ),
      );

      return bannerAd;
    } else {
      NativeAd nativeAd = NativeAd.fromAdManagerRequest(
        adUnitId: Constants.getAdmobFeedNativeUnit(),
        factoryId: 'gridTile',
        //request: AdRequest(),
        listener: NativeAdListener(
          onAdClosed: (ad) {
            print('Ad onAdClosed');
          },
          onAdImpression: (ad) {
            print('Ad onAdImpression');
          },
          onAdOpened: (ad) {
            print('Ad onAdOpened');
          },
          onAdLoaded: (ad) {
            print('Ad onAdLoaded');
          },
          onAdWillDismissScreen: (ad) {
            print('Ad onAdWillDismissScreen');
            ad.dispose();
          },
          onAdFailedToLoad: (ad, error) {
            // Releases an ad resource when it fails to load
            ad.dispose();
            print(
                'Ad load failed (code=${error.code} message=${error.message})');
          },
        ),
        adManagerRequest: AdManagerAdRequest(),
      );

      return nativeAd;
    }
  }

  static Future<Widget> getNativeAdTest({
    required BuildContext context,
  }) async {
    // bool isAdLoaded = false;
    NativeAd _listAd = NativeAd(
      adUnitId: Constants.getAdmobFeedNativeUnit(),
      factoryId: "gridTile",
      request: const AdRequest(),
      listener: NativeAdListener(onAdLoaded: (ad) {
        //isAdLoaded = true;
      }, onAdFailedToLoad: (ad, error) {
        // _listAd.dispose();
      }),
    );
    await _listAd.load();
    await Future.delayed(const Duration(seconds: 1));
    return AdWidget(
      ad: _listAd,
      key: Key(_listAd.hashCode.toString()),
    );
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
                      //highlightColor: Color(0xffF9F9FB),
                      //baseColor: Color(0xffE6E8EB),
                    );
                  },
                ),
              );
            } else if (snapshot.hasData) {
              liveResults = snapshot.data! as List<dynamic>;

              /*adsList = List.from(liveResults);

              for(int i = 1; i<=2; i++){

                var min = 1;
                var rm = new Random();

                if(liveResults.length == 1){

                  adsList.insert(1, getAds()..load());

                } else {
                  var rannumpos = min + rm.nextInt(liveResults.length - 2);
                  adsList.insert(rannumpos, getAds()..load());
                }

              }*/

              if (liveResults.isNotEmpty) {
                /*return StaggeredGridView.countBuilder(
                  crossAxisCount: 4,
                  itemCount: 8,
                  itemBuilder: (BuildContext context, int index) => new Container(
                      color: Colors.green,
                      child: new Center(
                        child: new CircleAvatar(
                          backgroundColor: Colors.white,
                          child: new Text('$index'),
                        ),
                      )),
                  staggeredTileBuilder: (int index) =>
                  new StaggeredTile.count(2, index.isEven ? 2 : 1),
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0,
                );*/

                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  color: Colors.white,
                  backgroundColor: kPrimaryColor,
                  strokeWidth: 2.0,
                  onRefresh: () {
                    _refreshIndicatorKey.currentState?.show(atTop: true);
                    return _loadLiveUpdate(tabIndex);
                  },
                  child: AlignedGridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    itemCount: liveResults.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index % _kAdIndex == 0) {
                        return FutureBuilder(
                            future: getNativeAdTest(context: context),
                            builder: (BuildContext context, snapshot) {
                              if (snapshot.hasData) {
                                AdWidget ad = snapshot.data as AdWidget;

                                final Container adContainer = Container(
                                  //width: MediaQuery.of(context).size.width,
                                  //height: MediaQuery.of(context).size.width /2,
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
                      } else {
                        final LiveStreamingModel liveStreaming =
                            liveResults[index] as LiveStreamingModel;
                        return GestureDetector(
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
                      }
                    },
                    /*staggeredTileBuilder: (int index){

                      if (index % _kAdIndex == 0) {
                        return StaggeredTile.count(2, 2);
                      } else {
                        return StaggeredTile.count(1, 1);
                      }

                    },*/
                  ),
                  /*child: GridView.custom(
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      repeatPattern: QuiltedGridRepeatPattern.inverted,
                      pattern: const [
                        QuiltedGridTile(1, 1),
                        //QuiltedGridTile(2, 1),
                        //QuiltedGridTile(1, 1),
                      ],
                    ),
                    */ /*gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),*/ /*
                    childrenDelegate: SliverChildBuilderDelegate(
                      //childCount: liveResults.length + (_ad != null ? 1 : 0),
                      //childCount: liveResults.length,
                      childCount: adsList.length,
                          (BuildContext context, int index) {

                        if(adsList[index] is LiveStreamingModel){
                          final LiveStreamingModel liveStreaming = adsList[index] as LiveStreamingModel;
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

                        } else if(adsList[index] is NativeAd){

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(5.0),
                            child: Container(
                              child: AdWidget(ad: adsList[index] as NativeAd,),
                              //child: AdWidget(ad: _ad!),
                              //height: 72.0,
                              height: MediaQuery.of(context).size.width /2,
                              key: UniqueKey(),
                              alignment: Alignment.center,
                            ),
                          );

                        } else if(adsList[index] is BannerAd){

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(5.0),
                            child: Container(
                              child: AdWidget(ad: adsList[index] as NativeAd,),
                              //child: AdWidget(ad: _ad!),
                              //height: 72.0,
                              height: MediaQuery.of(context).size.width /2,
                              key: UniqueKey(),
                              alignment: Alignment.center,
                            ),
                          );
                        }


                            */ /* if (index == postsResults.length - 8 &&
                            !_isLoadingMore && _hasMoreToLoad) {

                          _loadMoreAsset();
                        }*/ /*
                     },
                      findChildIndexCallback: (Key key) {
                        // Re-use elements.
                        if (key is ValueKey<int>) {
                          return key.value;
                        }
                        return null;
                      },
                    ),
                  ),*/
                );
              } else {
                return QuickActions.noContentFound(context);
              }
            } else {
              return QuickActions.noContentFound(context);
            }
          }),
    );
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
            preferences: null,
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
}
