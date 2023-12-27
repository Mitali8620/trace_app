// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/setup.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/helpers/quick_cloud.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/home/live/live_preview.dart';
import 'package:trace/home/live/live_streaming_screen.dart';
import 'package:trace/home/location_screen.dart';
import 'package:trace/home/message/message_screen.dart';
import 'package:trace/home/profile/profile_edit.dart';
import 'package:trace/models/HashTagsModel.dart';
import 'package:trace/models/LiveStreamingModel.dart';
import 'package:trace/models/NotificationsModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/app_bar.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';

// ignore: must_be_immutable
class SearchPage extends StatefulWidget {
  static String route = "Home/search";
  UserModel? currentUser;
  SharedPreferences? preferences;

  SearchPage({this.currentUser, required this.preferences});

  @override
  _SearchPageState createState() => _SearchPageState();
}

TextEditingController searchTextController = TextEditingController();
int numberOfColumns = 4;
AnimationController? _animationController;
List<dynamic> results = <dynamic>[];

List<dynamic> tags = <dynamic>[];

bool isSearchFieldFiled = false;
String searchText = "";
List<HashTagModel> tagsBySearch = <HashTagModel>[];

late TabController _tabController;

bool showFollowBtn = false;
bool showChatBtn = false;
int tabTypeAll = 0;
int tabTypeLive = 1;
int tabTypePeople = 2;
int tabTypeTags = 3;

int tabIndex = 0;

final List<Tab> tabs = <Tab>[
  Tab(
    child: TextWithTap(
      "search_screen.search_all".tr(),
      color: kGrayColor,
    ),
  ),
  Tab(
    child: TextWithTap(
      "search_screen.search_live".tr(),
      color: kGrayColor,
    ),
  ),
  Tab(
    child: TextWithTap(
      "search_screen.search_people".tr(),
      color: kGrayColor,
    ),
  ),
  Tab(
    child: TextWithTap(
      "search_screen.search_hashtags".tr(),
      color: kGrayColor,
    ),
  ),
];

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController.unbounded(vsync: this);
    _tabController = TabController(vsync: this, length: tabs.length)
      ..addListener(() {
        setState(() {
          tabIndex = _tabController.index;
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode focusScopeNode = FocusScope.of(context);
          if (!focusScopeNode.hasPrimaryFocus &&
              focusScopeNode.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: ToolBar(
          titleChild: ContainerCorner(
            color: kGreyColor1.withOpacity(0.4),
            height: 45,
            borderRadius: 50,
            child: TextField(
              controller: searchTextController,
              autocorrect: false,
              onChanged: (text) {
                if (text.isNotEmpty) {
                  setState(() {
                    searchText = text;
                    isSearchFieldFiled = true;
                  });
                } else {
                  setState(() {
                    isSearchFieldFiled = false;
                  });
                }
              },
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.search),
                ),
                border: InputBorder.none,
                hintText: "search_screen.hint_text".tr(),
                suffixIcon: GestureDetector(
                    onTap: () {
                      if (searchTextController.text.isNotEmpty) {
                        setState(() {
                          searchTextController.text = "";
                          isSearchFieldFiled = false;
                        });
                      }
                    },
                    child: Icon(Icons.close)),
              ),
            ),
          ),
          leftButtonWidget: BackButton(),
          child: SafeArea(
            child: DefaultTabController(
              length: numberOfColumns,
              child: Column(
                children: [
                  ContainerCorner(
                    child: TabBar(
                      indicatorColor: kPrimaryColor,
                      controller: _tabController,
                      indicatorPadding: EdgeInsets.only(top: 0),
                      automaticIndicatorColorAdjustment: false,
                      tabs: tabs,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      child: TabBarView(controller: _tabController, children: [
                        resumeAllTabs(),
                        searchLiveTab(),
                        searchUsers(),
                        hashTagsTab(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget resumeAllTabs() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: isSearchFieldFiled, //isSearchFieldFiled,
            child: ContainerCorner(
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerCorner(
                    marginTop: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWithTap(
                          "search_screen.broad_casting".tr(),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          marginLeft: 5,
                        ),
                        TextWithTap(
                          "search_screen.view_all".tr(),
                          color: kRedColor1,
                          decoration: TextDecoration.underline,
                          marginRight: 5,
                          onTap: () {
                            _tabController.animateTo((1));
                          },
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: loadHashTagsByGivenText(searchTextController.text),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        tags = snapshot.data as List<dynamic>;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(tags.length, (index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                searchLives(
                                    liveFilter: tags[index]["objectId"]),
                              ],
                            );
                          }),
                        );
                      } else {
                        return ContainerCorner(
                          child: Center(
                            child: TextWithTap("nothing found"),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          ContainerCorner(
            height: 60,
            width: MediaQuery.of(context).size.width,
            color: kGreyColor1.withOpacity(0.2),
            marginTop: 10,
            child: TextWithTap(
              "search_screen.search_suggestion".tr(),
              marginTop: 18,
              marginLeft: 10,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ContainerCorner(
            color: QuickHelp.isDarkMode(context)
                ? kContentColorLightTheme
                : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder(
                  future: loadHashTags(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      tags = snapshot.data as List<dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(tags.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWithTap(
                                "#" + tags[index]["hashtag"],
                                marginTop: 10,
                                marginLeft: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: suggestionsLives(
                                    hashTagId: tags[index]["objectId"],
                                    hashTag: tags[index]),
                              ),
                            ],
                          );
                        }),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ),
          ),
          Visibility(
            visible: isSearchFieldFiled,
            child: ContainerCorner(
              marginTop: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWithTap(
                    "search_screen.people".tr(),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    marginLeft: 5,
                  ),
                  TextWithTap(
                    "search_screen.view_all".tr(),
                    color: kRedColor1,
                    decoration: TextDecoration.underline,
                    marginRight: 5,
                    onTap: () {
                      _tabController.animateTo((2));
                    },
                  ),
                ],
              ),
            ),
          ),
          searchUsers(limitUsers: 6),
        ],
      ),
    );
  }

  Widget searchUsers({int? limitUsers}) {
    return Visibility(
      visible: isSearchFieldFiled,
      child: searchUser(searchTextController.text, limitUsers: limitUsers),
    );
  }

  Widget searchLiveTab() {
    return isSearchFieldFiled
        ? Visibility(
            visible: isSearchFieldFiled, //isSearchFieldFiled,
            child: ContainerCorner(
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FutureBuilder(
                      future:
                          loadHashTagsByGivenText(searchTextController.text),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          tags = snapshot.data as List<dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(tags.length, (index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  searchLives(
                                      liveFilter: tags[index]["objectId"]),
                                ],
                              );
                            }),
                          );
                        } else {
                          return ContainerCorner(
                            child: Center(
                              child: TextWithTap("nothing found"),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : suggestionLives();
  }

  Widget hashTagsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: isSearchFieldFiled, //isSearchFieldFiled,
            child: ContainerCorner(
              color: QuickHelp.isDarkMode(context)
                  ? kContentColorLightTheme
                  : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerCorner(
                    marginTop: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWithTap(
                          "search_screen.search_result".tr(),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          marginLeft: 5,
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder(
                    future: loadHashTagsByGivenText(searchTextController.text),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        tags = snapshot.data as List<dynamic>;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(tags.length, (index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                searchLives(
                                    liveFilter: tags[index]["objectId"]),
                              ],
                            );
                          }),
                        );
                      } else {
                        return ContainerCorner(
                          child: Center(
                            child: TextWithTap("nothing found"),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          ContainerCorner(
            height: 60,
            width: MediaQuery.of(context).size.width,
            color: kGreyColor1.withOpacity(0.2),
            marginTop: 10,
            child: TextWithTap(
              "search_screen.search_suggestion".tr(),
              marginTop: 18,
              marginLeft: 10,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ContainerCorner(
            color: QuickHelp.isDarkMode(context)
                ? kContentColorLightTheme
                : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder(
                  future: loadHashTags(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      tags = snapshot.data as List<dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(tags.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWithTap(
                                "#" + tags[index]["hashtag"],
                                marginTop: 10,
                                marginLeft: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: suggestionsLives(
                                    hashTagId: tags[index]["objectId"],
                                    hashTag: tags[index]),
                              ),
                            ],
                          );
                        }),
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
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
            context, LivePreviewScreen(currentUser: widget.currentUser!));
      } else {
        QuickHelp.goToNavigatorScreen(
            context,
            LiveStreamingScreen(
              channelName: channel!,
              isBroadcaster: false,
              currentUser: widget.currentUser!,
              mUser: liveStreamingModel!.getAuthor,
              mLiveStreamingModel: liveStreamingModel,
              preferences: widget.preferences,
            ));
      }
    }
  }

  Widget suggestionLives() {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
    ]);

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser!.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);

    return Visibility(
      visible: !isSearchFieldFiled,
      child: Padding(
        padding: EdgeInsets.only(right: 2, left: 2, top: 50),
        child: ParseLiveGridWidget<LiveStreamingModel>(
          query: queryBuilder,
          crossAxisCount: 3,
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
              return Stack(children: [
                ContainerCorner(
                  color: kTransparentColor,
                  child: QuickActions.photosWidget(liveStreaming.getImage!.url!,
                      borderRadius: 5),
                  onTap: () => checkPermission(false,
                      channel: liveStreaming.getStreamingChannel,
                      liveStreamingModel: liveStreaming),
                ),
                Positioned(
                  top: 0,
                  child: ContainerCorner(
                    radiusTopLeft: 5,
                    radiusTopRight: 5,
                    height: 40,
                    width: (MediaQuery.of(context).size.width / 3) - 5,
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
                          SvgPicture.asset(
                            "assets/svg/ic_small_viewers.svg",
                            height: 12,
                          ),
                          TextWithTap(
                            liveStreaming.getViewersCount.toString(),
                            color: Colors.white,
                            fontSize: 12,
                            marginRight: 15,
                            marginLeft: 5,
                          ),
                          SvgPicture.asset(
                            "assets/svg/ic_diamond.svg",
                            height: 15,
                          ),
                          TextWithTap(
                            liveStreaming.getDiamonds.toString(),
                            color: Colors.white,
                            fontSize: 14,
                            marginLeft: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: ContainerCorner(
                    radiusBottomLeft: 5,
                    radiusBottomRight: 5,
                    height: 40,
                    width: (MediaQuery.of(context).size.width / 3) - 5,
                    alignment: Alignment.center,
                    colors: [Colors.black, Colors.black.withOpacity(0.05)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    child: Column(
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
                  ),
                ),
              ]);
            } else {
              return Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
          },
          queryEmptyElement: QuickActions.noContentFound(context),
          gridLoadingElement: Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      ),
    );
  }

  Future<List<dynamic>?> loadHashTags() async {
    QueryBuilder<HashTagModel> queryBuilder =
        QueryBuilder<HashTagModel>(HashTagModel());
    queryBuilder.orderByDescending(HashTagModel.keyCount);
    queryBuilder.whereGreaterThanOrEqualsTo(HashTagModel.keyCount, 3);
    queryBuilder.whereEqualTo(HashTagModel.keyIsActive, true);
    queryBuilder.setLimit(3);

    ParseResponse response = await queryBuilder.query();

    if (response.success) {
      if (response.results != null) {
        print("HasTags count: ${response.results!.length}");
        return response.results;
      } else {
        return response.results; //as List<dynamic>;
      }
    } else {
      return response.error as dynamic;
    }
  }

  Future<List<dynamic>?> loadHashTagsByGivenText(String text,
      {int? limit}) async {
    QueryBuilder<HashTagModel> queryBuilder =
        QueryBuilder<HashTagModel>(HashTagModel());
    queryBuilder.whereContains(HashTagModel.keyTag, text);
    queryBuilder.orderByDescending(HashTagModel.keyCount);

    if (limit != null) {
      queryBuilder.setLimit(limit);
    } else {
      queryBuilder.setLimit(7);
    }

    ParseResponse response = await queryBuilder.query();

    if (response.success) {
      if (response.results != null) {
        print("HasTags count: ${response.results!.length}");
        return response.results;
      } else {
        return response.results;
      }
    } else {
      return response.error as dynamic;
    }
  }

  Future<List<dynamic>?> _loadLives({String? hashtagId}) async {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyHashTags,
    ]);

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyObjectId, widget.currentUser!.objectId);
    queryBuilder.whereValueExists(LiveStreamingModel.keyHashTagsId, true);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);

    if (hashtagId != null) {
      queryBuilder
          .whereContainedIn(LiveStreamingModel.keyHashTagsId, [hashtagId]);
    }

    ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      print("Lives count: ${apiResponse.results!.length}");
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as dynamic;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  Future<List<dynamic>?> _loadSearchLives({String? searchFilter}) async {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyHashTags,
    ]);

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyObjectId, widget.currentUser!.objectId);
    queryBuilder.whereValueExists(LiveStreamingModel.keyHashTagsId, true);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser!.getBlockedUsers!);

    if (searchFilter != null) {
      queryBuilder
          .whereContainedIn(LiveStreamingModel.keyHashTagsId, [searchFilter]);
      queryBuilder.setLimit(7);
    }

    ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      print("Lives count: ${apiResponse.results!.length}");
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as dynamic;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  Future<List<dynamic>?> _loadSearchUser(String? searchFilter,
      {int? limitUsers}) async {
    QueryBuilder<UserModel> queryBuilder =
        QueryBuilder<UserModel>(UserModel.forQuery());

    if (searchFilter != null) {
      queryBuilder.whereContains(
          UserModel.keyUsername, searchFilter.toLowerCase(),
          caseSensitive: false);
    }

    List<String> usersIds = [];

    for (UserModel userModel in widget.currentUser!.getBlockedUsers!) {
      usersIds.add(userModel.objectId!);
    }

    queryBuilder.whereNotEqualTo(
        UserModel.keyObjectId, widget.currentUser!.objectId!);
    queryBuilder.whereValueExists(UserModel.keyFullName, true);
    queryBuilder.whereValueExists(UserModel.keyAvatar, true);
    queryBuilder.whereNotContainedIn(UserModel.keyId, usersIds);

    if (limitUsers != null) {
      queryBuilder.setLimit(limitUsers);
    }

    ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success) {
      print("Lives count: ${apiResponse.results!.length}");
      if (apiResponse.results != null) {
        return apiResponse.results;
      } else {
        return AsyncSnapshot.nothing() as dynamic;
      }
    } else {
      return apiResponse.error as dynamic;
    }
  }

  Widget searchLives({String? liveFilter}) {
    return FutureBuilder(
        future: _loadSearchLives(
          searchFilter: liveFilter,
        ),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasData) {
            results = snapshot.data as List<dynamic>;
            return GridView.builder(
              itemCount: results.length,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemBuilder: (context, index) {
                if (index < 8) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 5),
                    child: Stack(children: [
                      ContainerCorner(
                        height: 120,
                        width: 120,
                        color: kTransparentColor,
                        child: QuickActions.photosWidget(
                            results[index].getImage!.url!,
                            borderRadius: 5),
                        onTap: () => checkPermission(false,
                            channel: results[index].getStreamingChannel,
                            liveStreamingModel: results[index]),
                      ),
                      Positioned(
                        top: 0,
                        child: ContainerCorner(
                          radiusTopLeft: 5,
                          radiusTopRight: 5,
                          height: 40,
                          width: 120,
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
                                SvgPicture.asset(
                                  "assets/svg/ic_small_viewers.svg",
                                  height: 12,
                                ),
                                TextWithTap(
                                  results[index].getViewersCount.toString(),
                                  color: Colors.white,
                                  fontSize: 12,
                                  marginRight: 15,
                                  marginLeft: 5,
                                ),
                                SvgPicture.asset(
                                  "assets/svg/ic_diamond.svg",
                                  height: 15,
                                ),
                                TextWithTap(
                                  results[index].getDiamonds.toString(),
                                  color: Colors.white,
                                  fontSize: 14,
                                  marginLeft: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: ContainerCorner(
                          radiusBottomLeft: 5,
                          radiusBottomRight: 5,
                          height: 40,
                          width: 120,
                          alignment: Alignment.center,
                          colors: [
                            Colors.black,
                            Colors.black.withOpacity(0.05)
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWithTap(
                                results[index].getAuthor!.getFullName!,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                                marginLeft: 10,
                              ),
                              Visibility(
                                visible:
                                    results[index].getStreamingTags!.isNotEmpty,
                                child: TextWithTap(
                                  results[index].getStreamingTags!,
                                  color: Colors.white,
                                  overflow: TextOverflow.ellipsis,
                                  marginLeft: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  );
                } else {
                  return Container();
                }
              },
            );
          } else {
            return Container();
          }
        });
  }

  Widget suggestionsLives({String? hashTagId, HashTagModel? hashTag}) {
    return FutureBuilder(
        future: _loadLives(
          hashtagId: hashTagId,
        ),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          if (snapshot.hasData) {
            results = snapshot.data as List<dynamic>;

            return Row(
              children: List.generate(results.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 5),
                  child: Stack(children: [
                    ContainerCorner(
                      height: 120,
                      width: 120,
                      color: kTransparentColor,
                      child: QuickActions.photosWidget(
                          results[index].getImage!.url!,
                          borderRadius: 5),
                      onTap: () => checkPermission(false,
                          channel: results[index].getStreamingChannel,
                          liveStreamingModel: results[index]),
                    ),
                    Positioned(
                      top: 0,
                      child: ContainerCorner(
                        radiusTopLeft: 5,
                        radiusTopRight: 5,
                        height: 40,
                        width: 120,
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
                              SvgPicture.asset(
                                "assets/svg/ic_small_viewers.svg",
                                height: 12,
                              ),
                              TextWithTap(
                                results[index].getViewersCount.toString(),
                                color: Colors.white,
                                fontSize: 12,
                                marginRight: 15,
                                marginLeft: 5,
                              ),
                              SvgPicture.asset(
                                "assets/svg/ic_diamond.svg",
                                height: 15,
                              ),
                              TextWithTap(
                                results[index].getDiamonds.toString(),
                                color: Colors.white,
                                fontSize: 14,
                                marginLeft: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: ContainerCorner(
                        radiusBottomLeft: 5,
                        radiusBottomRight: 5,
                        height: 40,
                        width: 120,
                        alignment: Alignment.center,
                        colors: [Colors.black, Colors.black.withOpacity(0.05)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextWithTap(
                              results[index].getAuthor!.getFullName!,
                              color: Colors.white,
                              overflow: TextOverflow.ellipsis,
                              marginLeft: 10,
                            ),
                            Visibility(
                              visible:
                                  results[index].getStreamingTags!.isNotEmpty,
                              child: TextWithTap(
                                results[index].getStreamingTags!,
                                color: Colors.white,
                                overflow: TextOverflow.ellipsis,
                                marginLeft: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                );
              }),
            );
          } else {
            hashTag!.setActive = false;
            hashTag.save();
            return Container();
          }
        });
  }

  Widget searchUser(String? userFilter, {int? limitUsers}) {
    QueryBuilder<UserModel> queryBuilder =
        QueryBuilder<UserModel>(UserModel.forQuery());

    List<String> usersIds = [];

    for (UserModel userModel in widget.currentUser!.getBlockedUsers!) {
      usersIds.add(userModel.objectId!);
    }

    queryBuilder.whereNotEqualTo(
        UserModel.keyObjectId, widget.currentUser!.objectId!);
    queryBuilder.whereValueExists(UserModel.keyFullName, true);
    queryBuilder.whereValueExists(UserModel.keyAvatar, true);
    queryBuilder.whereNotContainedIn(UserModel.keyId, usersIds);

    if (limitUsers != null) {
      queryBuilder.setLimit(limitUsers);
    }

    if (userFilter != null) {
      print("Search terms: $userFilter $searchText");
      queryBuilder.whereContains(UserModel.keyUsername, userFilter,
          caseSensitive: false);
    }

    return FutureBuilder(
        future: _loadSearchUser(userFilter, limitUsers: limitUsers),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          if (snapshot.hasData) {
            if (snapshot.data != null) {
              List<dynamic> results = snapshot.data as List<dynamic>;
              return SingleChildScrollView(
                child: Column(
                  children: List.generate(results.length, (index) {
                    showFollowBtn = !results[index]!
                        .getFollowers!
                        .contains(widget.currentUser!.objectId);
                    showChatBtn = !showFollowBtn;
                    return Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => QuickActions.showUserProfile(
                                context, widget.currentUser!, results[index], preferences: widget.preferences!),
                            child: QuickActions.avatarWidget(
                              results[index],
                              width: 50,
                              height: 50,
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => QuickActions.showUserProfile(
                                  context, widget.currentUser!, results[index], preferences: widget.preferences!),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWithTap(
                                        results[index]!.getFullName!,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        marginLeft: 10,
                                        color: QuickHelp.isDarkMode(context)
                                            ? Colors.white
                                            : Colors.black,
                                        marginTop: 5,
                                        marginRight: 5,
                                      ),
                                      ContainerCorner(
                                        color: kTransparentColor,
                                        marginLeft: 10,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ContainerCorner(
                                              marginRight: 10,
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svg/ic_diamond.svg",
                                                    height: 24,
                                                  ),
                                                  TextWithTap(
                                                    snapshot
                                                        .data[index].getDiamonds
                                                        .toString(),
                                                    fontSize: 14,
                                                    marginLeft: 3,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ContainerCorner(
                                              marginLeft: 10,
                                              child: Row(
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/svg/ic_tab_following_default.svg",
                                                    color: kRedColor1,
                                                    height: 18,
                                                  ),
                                                  TextWithTap(
                                                    snapshot.data[index]
                                                        .getFollowers.length
                                                        .toString(),
                                                    fontSize: 12,
                                                    marginRight: 15,
                                                    marginLeft: 5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: showFollowBtn,
                            child: ContainerCorner(
                              height: 40,
                              width: 40,
                              color: kRedColor1,
                              borderRadius: 50,
                              child: Padding(
                                padding: EdgeInsets.all(5),
                                child: SvgPicture.asset(
                                  "assets/svg/ic_tab_following_default.svg",
                                  color: Colors.white,
                                  width: 15,
                                  height: 15,
                                ),
                              ),
                              onTap: () => follow(results[index]),
                            ),
                          ),
                          Visibility(
                            visible: showChatBtn,
                            child: ContainerCorner(
                              width: 40,
                              height: 40,
                              borderRadius: 50,
                              onTap: () => _gotToChat(
                                  widget.currentUser!, snapshot.data[index]!),
                              color: kRedColor1,
                              child: ContainerCorner(
                                width: 10,
                                height: 10,
                                color: kTransparentColor,
                                child: Padding(
                                  padding: EdgeInsets.all(3),
                                  child: SvgPicture.asset(
                                    "assets/svg/ic_tab_chat_default.svg",
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            } else {
              return Container();
            }
          } else {
            return Container();
          }
        });
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickHelp.goToNavigator(context, MessageScreen.route, arguments: {
      "currentUser": currentUser,
      "mUser": mUser,
    });
  }

  void follow(UserModel user) async {
    ParseResponse parseResponse = await QuickCloudCode.followUser(
        isFollowing: false, author: widget.currentUser!, receiver: user);
    if (parseResponse.success) {
      QuickActions.createOrDeleteNotification(widget.currentUser!, user,
          NotificationsModel.notificationTypeFollowers);
    }
    setState(() {
      showFollowBtn = !showFollowBtn;
    });
  }
}
