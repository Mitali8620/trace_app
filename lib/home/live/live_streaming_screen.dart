// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/helpers/quick_cloud.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/helpers/send_notifications.dart';
import 'package:trace/home/coins/coins_payment_widget.dart';
import 'package:trace/home/home_screen.dart';
import 'package:trace/models/GiftSendersGlobalModel.dart';
import 'package:trace/models/GiftSendersModel.dart';
import 'package:trace/models/GiftsModel.dart';
import 'package:trace/models/GiftsSentModel.dart';
import 'package:trace/models/LeadersModel.dart';
import 'package:trace/models/LiveMessagesModel.dart';
import 'package:trace/models/LiveStreamingModel.dart';
import 'package:trace/models/NotificationsModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/button_with_gradient.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:trace/utils/shared_manager.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:wakelock/wakelock.dart';

import '../../app/setup.dart';
import '../../models/LiveViewersModel.dart';
import '../../models/ReportModel.dart';
import '../../services/dynamic_link_service.dart';
import '../live_end/live_end_report_screen.dart';
import '../live_end/live_end_screen.dart';

// ignore: must_be_immutable
class LiveStreamingScreen extends StatefulWidget {
  String channelName;
  bool isBroadcaster;
  bool isUserInvited;
  UserModel currentUser;
  UserModel? mUser;
  LiveStreamingModel? mLiveStreamingModel;
  final GiftsModel? giftsModel;
  SharedPreferences? preferences;

  static String route = "/home/live/streaming";

  LiveStreamingScreen(
      {Key? key,
      required this.channelName,
      required this.isBroadcaster,
      this.isUserInvited = false,
      required this.currentUser,
      this.mUser,
      this.mLiveStreamingModel,
      required this.preferences,
      this.giftsModel})
      : super(key: key);

  @override
  _LiveStreamingScreenState createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen>
    with TickerProviderStateMixin {
  final _users = <int>[];

  List<dynamic> viewersLast = [];

  final joinedLiveUsers = [];
  final usersToInvite = [];

  late RtcEngine _engine;
  bool muted = false;
  bool liveMessageSent = false;
  late int streamId;
  late LiveStreamingModel liveStreamingModel;
  bool liveEnded = false;
  bool following = false;
  bool liveJoined = false;
  LiveQuery liveQuery = LiveQuery();
  Subscription? subscription;
  String liveCounter = "0";
  String diamondsCounter = "0";
  String mUserDiamonds = "";
  AnimationController? _animationController;
  int bottomSheetCurrentIndex = 0;
  bool liveEndAlerted = false;
  String liveMessageObjectId = "";
  String liveGiftReceivedUrl = "";

  bool warningShows = false;
  bool isPrivateLive = false;
  bool initGift = false;

  bool coHostAvailable = false;
  int coHostUid = 0;
  bool invitationSent = false;

  bool isBroadcaster = false;
  bool isUserInvited = false;

  late AudioPlayer player;

  List<dynamic>? invitedUserParty = [];
  List<dynamic>? invitedUserPartyShowing = [];
  List<dynamic>? invitedUserPartyAudioMuted = [];
  List<dynamic>? invitedUserPartyVideoMuted = [];
  List<dynamic>? invitedUserPartyListPending = [];
  List<dynamic>? invitedUserPartyListLivePending = [];

  bool invitationIsShowing = false;
  bool paymentPopUpIsShowing = false;

  int invitedToPartyBigIndex = 0;
  int invitedToPartyUidSelected = 0;

  TextEditingController textEditingController = TextEditingController();

  late FocusNode? chatTextFieldFocusNode;
  GiftsModel? selectedGif;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();
  String callDuration = "00:00";

  int tabsLength = 2;
  int tabIndex = 0;
  late TabController _tabController;

  ScrollController _scrollController = new ScrollController();

  void initializeSelectedGif(GiftsModel gift) {
    setState(() {
      selectedGif = gift;
    });
  }

  getDefaultGiftPrice() async {
    QueryBuilder<GiftsModel> queryGift = QueryBuilder<GiftsModel>(GiftsModel());
    queryGift.whereEqualTo(
        GiftsModel.keyGiftCategories, GiftsModel.giftCategoryTypeClassic);
    queryGift.setLimit(1);

    ParseResponse response = await queryGift.query();
    if (response.success) {
      initializeSelectedGif(response.results as GiftsModel);
      setState(() {
        selectedGif = response.results as GiftsModel;
        print("Selected gif by default");
      });
    } else {
      print("deu errado");
    }
  }

  startTimerToEndLive(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (!isLiveJoined()) {
        if (isBroadcaster) {
          QuickHelp.showDialogLivEend(
            context: context,
            dismiss: false,
            title: 'live_streaming.cannot_stream'.tr(),
            confirmButtonText: 'live_streaming.finish_live'.tr(),
            message: 'live_streaming.cannot_stream_ask'.tr(),
            onPressed: () {
              //QuickHelp.goToPageWithClear(context, HomeScreen(userModel: currentUser)),
              QuickHelp.goBackToPreviousPage(context);
              QuickHelp.goBackToPreviousPage(context);
              //_onCallEnd(context),
            },
          );
        } else {
          if (!mounted) return;
          setState(() {
            liveEnded = true;
          });
          _stopWatchTimer.onResetTimer();
          //_stopWatchTimer.onExecute.add(StopWatchExecute.reset);
          liveStreamingModel.setStreaming = false;
          liveStreamingModel.save();
        }
      }
    });
  }

  startTimerToConnectLive(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (!liveJoined && mounted) {
        QuickHelp.showAppNotification(
          context: context,
          title: "can_not_try".tr(),
        );
        QuickHelp.goBackToPreviousPage(context);
      }
    });
  }

  @override
  void dispose() {
    Wakelock.disable();
    // clear users
    _users.clear();
    // destroy sdk and leave channel
    _engine.destroy();
    _tabController.dispose();

    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    subscription = null;

    textEditingController.dispose();

    _secureScreen(false);
    player.dispose();

    super.dispose();
  }

  final DynamicLinkService dynamicLinkService = DynamicLinkService();
  String linkToShare = "";

  createLink(String postId) async {
    QuickHelp.showLoadingDialog(context);

    Uri? uri = await dynamicLinkService
        .createDynamicLink(postId, DynamicLinkService.keyLinkLive);

    if (uri != null) {
      QuickHelp.hideLoadingDialog(context);
      setState(() {
        linkToShare = uri.toString();
      });
      shareLink();
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "settings_screen.app_could_not_gen_uri".tr(),
          user: widget.currentUser);
    }
  }

  shareLink() async {
    Share.share(linkToShare);
  }

  @override
  void initState() {
    QuickHelp.saveCurrentRoute(route: LiveStreamingScreen.route);

    _tabController =
        TabController(vsync: this, length: tabsLength, initialIndex: tabIndex)
          ..addListener(() {
            setState(() {
              tabIndex = _tabController.index;
            });
          });

    if (widget.mLiveStreamingModel != null) {
      liveStreamingModel = widget.mLiveStreamingModel!;
      liveMessageObjectId = liveStreamingModel.objectId!;
    }

    isBroadcaster = widget.isBroadcaster;
    isUserInvited = widget.isUserInvited;
    // Add Invited list
    invitedUserParty = liveStreamingModel.getInvitedPartyUid!;

    // Add Preview list
    invitedUserPartyShowing = liveStreamingModel.getInvitedPartyUid!;

    setState(() {
      if (isBroadcaster) {
        invitedToPartyUidSelected = widget.currentUser.getUid!;
        invitedUserPartyShowing!.remove(widget.currentUser.getUid!);
      } else if (isUserInvited) {
        invitedToPartyUidSelected = widget.currentUser.getUid!;
        invitedUserPartyShowing!.remove(widget.currentUser.getUid);
      } else {
        invitedToPartyUidSelected = widget.mUser!.getUid!;
        invitedUserPartyShowing!.remove(widget.mUser!.getUid!);
      }
    });

    /////////////////////////////////////////////////

    liveEndAlerted = false;

    if (!isBroadcaster) {
      setState(() {
        mUserDiamonds = widget.mUser!.getDiamondsTotal.toString();
      });

      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          viewersLast = liveStreamingModel.getViewersId!;
        });
      });
    }
    initializeAgora();
    //context.read<CallsProvider>().setUserBusy(true);

    _stopWatchTimer.onStartTimer();
    // _stopWatchTimer.onExecute.add(StopWatchExecute.start);

    chatTextFieldFocusNode = FocusNode();

    _animationController = AnimationController.unbounded(vsync: this);

    Wakelock.enable();
    _secureScreen(true);

    player = AudioPlayer();

    super.initState();
  }

  updateInviteList(List<dynamic> newList) {
    print("PreviewList Updated ${newList.length}");

    if (!mounted) return;

    if (newList.length == 0) {
      setState(() {
        invitedUserParty!.clear();
        invitedUserPartyShowing!.clear();
      });
    } else if (invitedUserParty != newList) {
      invitedUserParty = newList;
      invitedUserPartyShowing = newList;

      if (invitedUserPartyShowing!.contains(invitedToPartyUidSelected)) {
        invitedUserPartyShowing!.remove(invitedToPartyUidSelected);
      } else {
        if (isBroadcaster) {
          invitedToPartyUidSelected = widget.currentUser.getUid!;
          invitedUserPartyShowing!.remove(widget.currentUser.getUid!);
        } else if (isUserInvited) {
          invitedToPartyUidSelected = widget.currentUser.getUid!;
          invitedUserPartyShowing!.remove(widget.currentUser.getUid);
        } else {
          invitedToPartyUidSelected = widget.mUser!.getUid!;
          invitedUserPartyShowing!.remove(widget.mUser!.getUid!);
        }
      }

      //this.setState(() {});
    }
  }

  bool _showChat = false;
  bool _hideSendButton = false;
  bool visibleKeyBoard = false;
  bool visibleAudianceKeyBoard = false;

  void showChatState() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  void toggleSendButton(bool active) {
    setState(() {
      _hideSendButton = active;
    });
  }

  String liveTitle = "live_streaming.live_".tr();

  Future<void> initializeAgora() async {
    startTimerToConnectLive(context, 10);

    await _initAgoraRtcEngine();

    if (!isBroadcaster &&
        widget.currentUser.getFollowing!.contains(widget.mUser!.objectId)) {
      following = true;
    }

    /* if (isBroadcaster){
      streamId = (await _engine.createDataStream(false, false))!;
    }*/

    _engine.setEventHandler(RtcEngineEventHandler(
      rtmpStreamingEvent: (string, rtmpEvent) {
        print('AgoraLive rtmpStreamingEvent: $string, event: $rtmpEvent');
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          startTimerToEndLive(context, 5);

          if (isBroadcaster && uid == widget.currentUser.getUid) {
            print(
                'AgoraLive isBroadcaster: $channel, uid: $uid,  elapsed $elapsed');
          }
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        print(
            'AgoraLive firstRemoteVideoFrame: $uid $width, $height, time: $elapsed');
      },
      firstLocalVideoFrame: (width, height, elapsed) {
        print(
            'AgoraLive firstLocalVideoFrame: $width, $height, time: $elapsed');

        if (isBroadcaster && !liveJoined) {
          createLive(liveStreamingModel);

          setState(() {
            liveJoined = true;
          });
        }
      },
      error: (ErrorCode errorCode) {
        print('AgoraLive error $errorCode');

        // JoinChannelRejected
        if (errorCode == ErrorCode.JoinChannelRejected) {
          _engine.leaveChannel();
          QuickHelp.goToPageWithClear(
              context,
              HomeScreen(
                currentUser: widget.currentUser,
                preferences: widget.preferences,
              ));
        }
      },
      leaveChannel: (stats) {
        setState(() {
          print('AgoraLive onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          _users.add(uid);
          liveJoined = true;
          joinedLiveUsers.add(uid);
        });

        print('AgoraLive userJoined: $uid');
        updateViewers(uid, widget.currentUser.objectId!);
      },
      userOffline: (uid, elapsed) {
        if (!isBroadcaster) {
          setState(() {
            print('AgoraLive userOffline: $uid');
            _users.remove(uid);

            if (uid == widget.mUser!.getUid) {
              liveEnded = true;
              liveJoined = false;
            }
          });
        }
      },
    ));

    await _engine.joinChannel(
      null,
      widget.channelName,
      widget.currentUser.objectId,
      widget.currentUser.getUid!,
    );
  }

  Future<void> _initAgoraRtcEngine() async {
    // Create RTC client instance

    RtcEngineContext context = RtcEngineContext(
        SharedManager().getStreamProviderKey(widget.preferences));
    _engine = await RtcEngine.createWithContext(context);

    if (isBroadcaster || isUserInvited) {
      await _engine.startPreview();
    } else {
      addOrUpdateLiveViewers();
      widget.mLiveStreamingModel!.addReachedPeople =
          widget.currentUser.objectId!;
      widget.mLiveStreamingModel!.save();
    }

    await _engine.enableVideo();

    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);

    await _engine.setVideoEncoderConfiguration(VideoEncoderConfiguration(
      mirrorMode: VideoMirrorMode.Disabled,
      frameRate: VideoFrameRate.Fps15,
      dimensions: VideoDimensions(width: 640, height: 480),
    ));

    if (isBroadcaster || isUserInvited) {
      await _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      await _engine.setClientRole(ClientRole.Audience);
    }
  }

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    if (isPrivateLive) {
      if (liveStreamingModel.getAuthorId != widget.currentUser.objectId) {
        openPayPrivateLiveSheet(liveStreamingModel);
      }
    }
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () => closeAlert(),
      child: GestureDetector(
        onTap: () {
          if (FocusScope.of(context).hasFocus) {
            FocusScope.of(context).unfocus();
            showChatState();
            setState(() {
              visibleKeyBoard = false;
              visibleAudianceKeyBoard = false;
            });
          }
        },
        child: Scaffold(
          backgroundColor: kTransparentColor,
          extendBody: true,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: kTransparentColor,
            leadingWidth: 0,
            title: Visibility(
              visible: isLiveJoined() && !liveEnded,
              child: Row(
                children: [
                  ContainerCorner(
                    height: 30,
                    borderRadius: 50,
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ContainerCorner(
                              marginRight: 5,
                              color: Colors.black.withOpacity(0.5),
                              child: QuickActions.avatarWidget(
                                  widget.mLiveStreamingModel!.getAuthor!,
                                  width: 35,
                                  height: 35),
                              borderRadius: 50,
                              height: 40,
                              width: 40,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  width: 65,
                                  child: TextScroll(
                                    widget.mLiveStreamingModel!.getAuthor!
                                        .getFullName!,
                                    mode: TextScrollMode.endless,
                                    velocity: Velocity(
                                        pixelsPerSecond: Offset(30, 0)),
                                    delayBefore: Duration(seconds: 1),
                                    pauseBetween: Duration(milliseconds: 150),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.left,
                                    selectable: true,
                                    intervalSpaces: 5,
                                    numberOfReps: 9999,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    Flexible(
                                      child: ContainerCorner(
                                        width: 30,
                                        height: 12,
                                        borderWidth: 0,
                                        marginLeft: 3,
                                        marginBottom: 1,
                                        child: countViewers(),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                        Visibility(
                          visible: !isBroadcaster,
                          child: ContainerCorner(
                            marginLeft: 15,
                            marginRight: 6,
                            color:
                                following ? Colors.blueAccent : kPrimaryColor,
                            child: ContainerCorner(
                                color: kTransparentColor,
                                marginAll: 5,
                                height: 23,
                                width: 23,
                                child: Center(
                                  child: Icon(
                                    following
                                        ? Icons.done
                                        : Icons.person_add_alt,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                )),
                            borderRadius: 50,
                            height: 23,
                            width: 23,
                            onTap: () {
                              if (!following) {
                                followOrUnfollow();
                                sendMessage(LiveMessagesModel.messageTypeFollow,
                                    "", widget.currentUser);
                              }
                            },
                          ),
                        ),
                        ContainerCorner(
                          marginLeft: isBroadcaster ? 15 : 3,
                          marginRight: 6,
                          color: Colors.white,
                          borderRadius: 50,
                          height: 23,
                          width: 23,
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Lottie.asset(
                                "assets/lotties/ic_live_animation.json"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ContainerCorner(
                      width: size.width / 3.3,
                      marginLeft: 5,
                      height: 36,
                      child: getTopGifters(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Visibility(
                visible: isLiveJoined() && !liveEnded,
                child: ContainerCorner(
                  height: 35,
                  width: 35,
                  borderRadius: 50,
                  color: Colors.black.withOpacity(0.5),
                  onTap: () => openBottomSheet(_showListOfViewers()),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset("assets/svg/ic_users_online.svg"),
                  ),
                ),
              ),
              Visibility(
                visible: isLiveJoined() && !liveEnded,
                child: ContainerCorner(
                  borderRadius: 50,
                  marginRight: 5,
                  marginLeft: 5,
                  color: Colors.white,
                  height: 35,
                  width: 35,
                  child: IconButton(
                    onPressed: () => closeAlert(),
                    icon: Icon(
                      Icons.close,
                      color: Colors.red,
                      weight: 900,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: body(),
          bottomNavigationBar: Visibility(
            visible: !liveEnded && isLiveJoined(),
            child: ContainerCorner(
              borderWidth: 0,
              width: size.width,
              marginBottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ContainerCorner(
                    height: 35,
                    width: 35,
                    borderWidth: 0,
                    borderRadius: 50,
                    marginLeft: 15,
                    color: Colors.white,
                    onTap: () {
                      chatTextFieldFocusNode!.requestFocus();
                      showChatState();
                      setState(() {
                        visibleAudianceKeyBoard = true;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Lottie.asset(
                        "assets/lotties/ic_comment.json",
                        repeat: false,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ContainerCorner(
                        height: 35,
                        width: 35,
                        borderWidth: 0,
                        borderRadius: 50,
                        marginRight: 15,
                        color: Colors.white,
                        onTap: () => openSettingSheet(),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child:
                              Lottie.asset("assets/lotties/ic_menu_grid.json"),
                        ),
                      ),
                      ContainerCorner(
                        height: 35,
                        width: 35,
                        borderWidth: 0,
                        borderRadius: 50,
                        marginRight: 15,
                        color: Colors.white,
                        onTap: () {
                          if(widget.mLiveStreamingModel != null) {
                            createLink(widget.mLiveStreamingModel!.objectId!);
                          }else{
                            createLink(liveStreamingModel.objectId!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child:
                          Lottie.asset("assets/lotties/ic_share_live.json"),
                        ),
                      ),
                      Visibility(
                        visible: !isBroadcaster,
                        child: ContainerCorner(
                          height: 35,
                          width: 35,
                          borderWidth: 0,
                          borderRadius: 50,
                          marginRight: 15,
                          color: Colors.white,
                          onTap: () {
                            CoinsFlowPayment(
                              context: context,
                              currentUser: widget.currentUser,
                              onCoinsPurchased: (coins) {
                                print(
                                    "onCoinsPurchased: $coins new: ${widget.currentUser.getCredits}");
                              },
                              onGiftSelected: (gift) {
                                print("onGiftSelected called ${gift.getCoins}");
                                sendGift(gift);

                                //QuickHelp.goBackToPreviousPage(context);
                                QuickHelp.showAppNotificationAdvanced(
                                  context: context,
                                  user: widget.currentUser,
                                  title: "live_streaming.gift_sent_title".tr(),
                                  message:
                                      "live_streaming.gift_sent_explain".tr(
                                    namedArgs: {
                                      "name": widget.mUser!.getFirstName!
                                    },
                                  ),
                                  isError: false,
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Lottie.asset("assets/lotties/ic_gift.json"),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: isBroadcaster,
                        child: ContainerCorner(
                          height: 35,
                          width: 35,
                          borderWidth: 0,
                          borderRadius: 50,
                          marginRight: 15,
                          color: Colors.white,
                          onTap: () {
                            _onToggleMute();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: muted
                                ? Icon(Icons.mic_off, color: Colors.red)
                                : Lottie.asset(
                                    "assets/lotties/ic_activated_mic.json"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getTopGifters() {
    QueryBuilder<GiftsSenderModel> query =
        QueryBuilder<GiftsSenderModel>(GiftsSenderModel());

    query.includeObject([
      GiftsSenderModel.keyAuthor,
    ]);

    query.whereEqualTo(
        GiftsSenderModel.keyLiveId, widget.mLiveStreamingModel!.objectId);
    query.setLimit(3);
    query.orderByDescending(GiftsSenderModel.keyDiamonds);

    return ParseLiveListWidget<GiftsSenderModel>(
      query: query,
      reverse: false,
      lazyLoading: false,
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      duration: const Duration(milliseconds: 200),
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<GiftsSenderModel> snapshot) {
        if (snapshot.hasData) {
          GiftsSenderModel giftSender = snapshot.loadedData!;

          return ContainerCorner(
            height: 30,
            width: 30,
            borderWidth: 0,
            borderRadius: 50,
            marginRight: 7,
            child: QuickActions.avatarWidget(
              giftSender.getAuthor!,
              height: 30,
              width: 30,
            ),
          );
        } else {
          return const SizedBox();
        }
      },
      listLoadingElement: const SizedBox(),
    );
  }

  Widget countViewers() {
    QueryBuilder<LiveViewersModel> query =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());

    query.whereEqualTo(
        LiveViewersModel.keyLiveId, widget.mLiveStreamingModel!.objectId);
    query.whereEqualTo(LiveViewersModel.keyWatching, true);
    query.whereEqualTo(LiveViewersModel.keyLiveAuthorId,
        widget.mLiveStreamingModel!.getAuthorId);

    var viewers = [];
    int? indexToRemove;

    return ParseLiveListWidget<LiveViewersModel>(
      query: query,
      scrollController: _scrollController,
      reverse: false,
      lazyLoading: false,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      duration: const Duration(milliseconds: 200),
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<LiveViewersModel> snapshot) {
        if (snapshot.failed) {
          return showViewersCount(amountText: "${viewers.length}");
        }

        if (snapshot.hasData) {
          LiveViewersModel liveViewer = snapshot.loadedData!;

          if (!viewers.contains(liveViewer.getAuthorId)) {
            if (liveViewer.getWatching!) {
              viewers.add(liveViewer.getAuthorId);

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                return await _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 5),
                    curve: Curves.easeInOut);
              });
            }
          } else {
            if (!liveViewer.getWatching!) {
              for (int i = 0; i < viewers.length; i++) {
                if (viewers[i] == liveViewer.getAuthorId) {
                  indexToRemove = i;
                }
              }

              viewers.removeAt(indexToRemove!);
            }
          }

          return showViewersCount(
              amountText: "${QuickHelp.convertToK(viewers.length)}");
        } else {
          return showViewersCount(amountText: "${viewers.length}");
        }
      },
      listLoadingElement: showViewersCount(amountText: "${viewers.length}"),
      queryEmptyElement: showViewersCount(amountText: "${viewers.length}"),
    );
  }

  Widget showViewersCount({required String amountText}) {
    return TextWithTap(
      amountText,
      color: Colors.white,
      fontSize: 9,
      marginLeft: 3,
    );
  }

  Widget commentTextField() {
    return ContainerCorner(
      marginBottom: _showChat ? MediaQuery.of(context).viewInsets.bottom : 0,
      marginLeft: 10,
      marginRight: 10,
      child: Row(
        children: [
          Expanded(
            child: ContainerCorner(
              color: Colors.white,
              borderRadius: 50,
              marginBottom: 0,
              height: 42,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  focusNode: chatTextFieldFocusNode,
                  maxLines: 2,
                  controller: textEditingController,
                  decoration: InputDecoration(
                    hintText: "comment_post.leave_comment".tr(),
                    hintStyle: TextStyle(color: kGrayColor),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          ContainerCorner(
            marginLeft: 10,
            marginBottom: 0,
            color: kBlueColor1,
            child: ContainerCorner(
              color: kTransparentColor,
              marginAll: 5,
              height: 30,
              width: 30,
              child: SvgPicture.asset(
                "assets/svg/ic_send_message.svg",
                color: Colors.white,
                height: 10,
                width: 30,
              ),
            ),
            borderRadius: 50,
            height: 45,
            width: 45,
            onTap: () {
              if (textEditingController.text.isNotEmpty) {
                sendMessage(LiveMessagesModel.messageTypeComment,
                    textEditingController.text, widget.currentUser);
                setState(() {
                  textEditingController.text = "";
                  visibleAudianceKeyBoard = false;
                });

                if (FocusScope.of(context).hasFocus) {
                  FocusScope.of(context).unfocus();
                  showChatState();
                  setState(() {
                    visibleKeyBoard = false;
                    visibleAudianceKeyBoard = false;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  onViewerLeave() async {
    QueryBuilder<LiveViewersModel> queryLiveViewers =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());

    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthor, widget.currentUser);
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthorId, widget.currentUser.objectId);

    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyLiveId, liveStreamingModel.objectId!);

    ParseResponse parseResponse = await queryLiveViewers.query();
    if (parseResponse.success) {
      if (parseResponse.result != null) {
        LiveViewersModel liveViewers =
            parseResponse.results!.first! as LiveViewersModel;

        liveViewers.setWatching = false;
        await liveViewers.save();
      }
    }
  }

  addOrUpdateLiveViewers() async {
    QueryBuilder<LiveViewersModel> queryLiveViewers =
        QueryBuilder<LiveViewersModel>(LiveViewersModel());

    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthor, widget.currentUser);
    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyAuthorId, widget.currentUser.objectId);

    queryLiveViewers.whereEqualTo(
        LiveViewersModel.keyLiveId, liveStreamingModel.objectId!);

    ParseResponse parseResponse = await queryLiveViewers.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        LiveViewersModel liveViewers =
            parseResponse.results!.first! as LiveViewersModel;

        liveViewers.setWatching = true;

        await liveViewers.save();
      } else {
        LiveViewersModel liveViewersModel = LiveViewersModel();

        liveViewersModel.setAuthor = widget.currentUser;
        liveViewersModel.setAuthorId = widget.currentUser.objectId!;

        liveViewersModel.setWatching = true;

        liveViewersModel.setLiveAuthorId =
            widget.mLiveStreamingModel!.getAuthorId!;
        liveViewersModel.setLiveId = liveStreamingModel.objectId!;

        await liveViewersModel.save();
      }
    }
  }

  Widget body() {
    Size size = MediaQuery.sizeOf(context);
    return Center(
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _getRenderViews(),
              Visibility(
                visible: !isLiveJoined(),
                child: getLoadingScreen(),
              ),
            ],
          ),
          Visibility(
              visible: invitedUserParty!.isNotEmpty && isLiveJoined(),
              child: draggable(),
          ),
          Visibility(
            visible: liveGiftReceivedUrl.isNotEmpty,
            child: Lottie.network(
              liveGiftReceivedUrl,
              width: size.width / 1.3,
              height: size.width / 1.3,
              animate: true,
              repeat: true,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Visibility(
              visible: isLiveJoined() && !liveEnded,
              child: ContainerCorner(
                height: size.height / 2,
                width: size.width,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    liveMessages(),
                    ContainerCorner(
                      borderWidth: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showChat)
            Visibility(
              visible: isLiveJoined() && !liveEnded,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: commentTextField(),
              ),
            ),
        ],
      ),
    );
  }

  bool isLiveJoined() {
    if (liveJoined) {
      return true;
    } else {
      return false;
    }
  }

  bool visibleToolbar() {
    if (isBroadcaster) {
      return true;
    } else if (!isBroadcaster && liveEnded) {
      return false;
    } else {
      return false;
    }
  }

  requestLive() {
    sendMessage(LiveMessagesModel.messageTypeCoHost, "", widget.currentUser);
  }

  closeAlert() {
    if (!isBroadcaster) {
      //context.read<CallsProvider>().setUserBusy(false);
      saveLiveUpdate();
    } else {
      if (liveJoined == false && liveEnded == true) {
        QuickHelp.goToPageWithClear(
            context,
            HomeScreen(
              currentUser: widget.currentUser,
              preferences: widget.preferences,
            ));
      } else {
        QuickHelp.showDialogWithButtonCustom(
          context: context,
          title: "account_settings.logout_user_sure".tr(),
          message: 'live_streaming.finish_live_ask'.tr(),
          cancelButtonText: "cancel".tr(),
          confirmButtonText: "confirm_".tr(),
          onPressed: () {
            QuickHelp.goBackToPreviousPage(context);
            _onCallEnd(context);
          },
        );
      }
    }
  }

  closeAdminAlert() {
    QuickHelp.showAppNotificationAdvanced(
      context: context,
      title: 'live_streaming.live_admin_terminated'.tr(),
      message: 'live_streaming.live_admin_terminated_explain'.tr(),
    );

    _onCallEnd(context);
    Future.delayed(Duration(seconds: 2), () {
      QuickHelp.goToNavigatorScreen(
          context,
          HomeScreen(
            preferences: widget.preferences,
            currentUser: widget.currentUser,
          ),
          back: false,
          finish: true);
    });
  }

  Widget _getRenderViews() {
    if (invitedToPartyUidSelected == widget.currentUser.getUid!) {
      return RtcLocalView.SurfaceView(
        zOrderMediaOverlay: true,
        zOrderOnTop: true,
      );
    } else {
      return RtcRemoteView.SurfaceView(
        channelId: widget.channelName,
        uid: invitedToPartyUidSelected,
      );
    }
  }

  inviteCoBroadcaster() {}

  Widget getLoadingScreen() {
    Size size = MediaQuery.of(context).size;
    if (liveEnded) {
      if (isBroadcaster) {
        return LiveEndReportScreen(
          currentUser: widget.currentUser,
          preferences: widget.preferences,
          live: widget.mLiveStreamingModel,
        );
      } else {
        return LiveEndScreen(
          liveAuthor: widget.mLiveStreamingModel!.getAuthor,
          currentUser: widget.currentUser,
          preferences: widget.preferences,
        );
      }
    } else {
      return ContainerCorner(
        borderWidth: 0,
        height: size.height,
        width: size.width,
        color: QuickHelp.isDarkMode(context)
            ? kContentColorLightTheme
            : kContentColorDarkTheme,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Lottie.asset(
            "assets/lotties/ic_live_animation.json",
            width: size.width / 3.5,
            height: size.width / 3.5,
          ),
          TextWithTap(
            "coins_and_points_screen.live_streaming".tr(),
            textAlign: TextAlign.center,
            alignment: Alignment.center,
          ),
        ]),
        //color: Colors.blue,
      );
    }
  }

  void followOrUnfollow() async {
    if (widget.currentUser.getFollowing!.contains(widget.mUser!.objectId)) {
      widget.currentUser.removeFollowing = widget.mUser!.objectId!;
      widget.mLiveStreamingModel!.removeFollower = widget.currentUser.objectId!;

      setState(() {
        following = false;
      });
    } else {
      widget.currentUser.setFollowing = widget.mUser!.objectId!;
      widget.mLiveStreamingModel!.addFollower = widget.currentUser.objectId!;

      setState(() {
        following = true;
      });
    }

    await widget.currentUser.save();
    widget.mLiveStreamingModel!.save();

    ParseResponse parseResponse = await QuickCloudCode.followUser(
        isFollowing: false,
        author: widget.currentUser,
        receiver: widget.mUser!);

    if (parseResponse.success) {
      QuickActions.createOrDeleteNotification(widget.currentUser, widget.mUser!,
          NotificationsModel.notificationTypeFollowers);
    }
  }

  void _onCallEnd(BuildContext context) {
    saveLiveUpdate();
    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    if (mounted) {
      setState(() {
        liveEnded = true;
        liveJoined = false;
      });
    }
  }

  /*void saveLiveUpdate() async {
    if (isBroadcaster) {
      liveStreamingModel.setStreaming = false;
      await liveStreamingModel.save();
      _engine.leaveChannel();
    } else {
      QuickHelp.showLoadingDialog(context);

      if (liveJoined) {
        liveStreamingModel.removeViewersCount = 1;
        liveStreamingModel.removeInvitedPartyUid = widget.currentUser.getUid!;

        await _engine.leaveChannel();
      }

      ParseResponse response = await liveStreamingModel.save();
      if (response.success) {
        QuickHelp.hideLoadingDialog(context);

        QuickHelp.goToPageWithClear(
            context, HomeScreen(currentUser: widget.currentUser, preferences: widget.preferences,));
      } else {
        QuickHelp.hideLoadingDialog(context);
        QuickHelp.goToPageWithClear(
            context, HomeScreen(currentUser: widget.currentUser, preferences: widget.preferences,));
      }
    }
  }*/

  void saveLiveUpdate() async {
    if (isBroadcaster) {
      liveStreamingModel.setStreaming = false;
      await liveStreamingModel.save();
      _engine.leaveChannel();
    } else {
      if (widget.currentUser.isAdmin!) {
        await _engine.leaveChannel();

        QuickHelp.goToPageWithClear(
            context,
            HomeScreen(
              currentUser: widget.currentUser,
              preferences: widget.preferences,
            ));
      } else {
        QuickHelp.showLoadingDialog(context);
        onViewerLeave();
        if (liveJoined) {
          liveStreamingModel.removeViewersCount = 1;
          liveStreamingModel.removeInvitedPartyUid = widget.currentUser.getUid!;

          await _engine.leaveChannel();
        }

        ParseResponse response = await liveStreamingModel.save();
        if (response.success) {
          QuickHelp.hideLoadingDialog(context);

          QuickHelp.goToPageWithClear(
              context,
              HomeScreen(
                currentUser: widget.currentUser,
                preferences: widget.preferences,
              ));
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.goToPageWithClear(
              context,
              HomeScreen(
                currentUser: widget.currentUser,
                preferences: widget.preferences,
              ));
        }
      }
    }
  }

  void _onToggleMute({StateSetter? setState}) {
    bool mute = !muted;

    if (setState != null) {
      setState(() {
        muted = mute;
      });
    }

    this.setState(() {
      muted = mute;
    });

    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    //_engine.sendStreamMessage(streamId, "mute user blet");
    _engine.switchCamera();
  }

  /*updateViewers(int uid, String objectId) async {

    if(!isUserInvited){
      liveStreamingModel.addViewersCount = 1;
      liveStreamingModel.setViewersId = objectId;
      liveStreamingModel.setViewers = uid;
    }

    if (liveStreamingModel.getPrivate!) {
      liveStreamingModel.setPrivateViewersId = objectId;
    }

    ParseResponse parseResponse = await liveStreamingModel.save();
    if (parseResponse.success) {
      setState(() {
        liveCounter = liveStreamingModel.getViewersCount.toString();
        diamondsCounter = liveStreamingModel.getDiamonds.toString();
        viewersLast = liveStreamingModel.getViewersId!;
      });

      sendMessage(LiveMessagesModel.messageTypeJoin, "", widget.currentUser);

      setupCounterLive(liveStreamingModel.objectId!);
      setupCounterLiveUser();
      setupLiveMessage(liveStreamingModel.objectId!);
    }
  }*/

  createLive(LiveStreamingModel liveStreamingModel) async {
    liveStreamingModel.setStreaming = true;
    liveStreamingModel.addInvitedPartyUid = [widget.currentUser.getUid];

    ParseResponse parseResponse = await liveStreamingModel.save();
    if (parseResponse.success) {
      setupCounterLive(liveStreamingModel.objectId!);
      setupCounterLiveUser();
      setupLiveMessage(liveStreamingModel.objectId!);

      SendNotifications.sendPush(
          widget.currentUser, widget.currentUser, SendNotifications.typeLive,
          objectId: liveStreamingModel.objectId!);
    }
  }

  updateViewers(int uid, String objectId) async {
    if (widget.currentUser.isAdmin!) {
      setState(() {
        liveCounter = liveStreamingModel.getViewersCount.toString();
        diamondsCounter = liveStreamingModel.getDiamonds.toString();
        viewersLast = liveStreamingModel.getViewersId!;
      });

      setupCounterLive(liveStreamingModel.objectId!);
      setupCounterLiveUser();
      setupLiveMessage(liveStreamingModel.objectId!);
    } else {
      if (!isUserInvited) {
        liveStreamingModel.addViewersCount = 1;
        liveStreamingModel.setViewersId = objectId;
        liveStreamingModel.setViewers = uid;
      }

      if (liveStreamingModel.getPrivate!) {
        liveStreamingModel.setPrivateViewersId = objectId;
      }

      ParseResponse parseResponse = await liveStreamingModel.save();
      if (parseResponse.success) {
        setState(() {
          liveCounter = liveStreamingModel.getViewersCount.toString();
          diamondsCounter = liveStreamingModel.getDiamonds.toString();
          viewersLast = liveStreamingModel.getViewersId!;
        });

        sendMessage(LiveMessagesModel.messageTypeJoin, "", widget.currentUser);

        setupCounterLive(liveStreamingModel.objectId!);
        setupCounterLiveUser();
        setupLiveMessage(liveStreamingModel.objectId!);
      }
    }
  }

  void openBottomSheet(Widget widget, {bool isDismissible = true}) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: isDismissible,
        isDismissible: isDismissible,
        builder: (context) {
          return widget;
        });
  }

  Widget _showUserSettings(UserModel user, bool isStreamer) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.2,
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
                  child: Column(
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ContainerCorner(
                        color: Colors.white,
                        height: 5,
                        width: 50,
                        borderRadius: 20,
                        marginTop: 10,
                        marginBottom: 20,
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            openReportMessage(
                                user, liveStreamingModel, isStreamer);
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: SvgPicture.asset(
                                  "assets/svg/ic_blocked_menu.svg",
                                  color: Colors.white,
                                ),
                              ),
                              TextWithTap(
                                "report_".tr(),
                                color: Colors.white,
                                fontSize: 18,
                                marginLeft: 5,
                              )
                            ],
                          )),
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

  void follow(UserModel mUser) async {
    QuickHelp.showLoadingDialog(context);

    ParseResponse parseResponseUser;

    widget.currentUser.setFollowing = mUser.objectId!;
    parseResponseUser = await widget.currentUser.save();

    if (parseResponseUser.success) {
      if (parseResponseUser.results != null) {
        QuickHelp.hideLoadingDialog(context);

        setState(() {
          widget.currentUser = parseResponseUser.results!.first as UserModel;
        });
      }
    }

    ParseResponse parseResponse;
    parseResponse = await QuickCloudCode.followUser(
        isFollowing: false, author: widget.currentUser, receiver: mUser);

    if (parseResponse.success) {
      QuickActions.createOrDeleteNotification(widget.currentUser, mUser,
          NotificationsModel.notificationTypeFollowers);
    }
  }

  Widget _showListOfPeopleToBeInvited() {
    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());
    query.whereContainedIn(UserModel.keyObjectId,
        this.liveStreamingModel.getViewersId as List<dynamic>);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    backgroundColor: kTransparentColor,
                    appBar: AppBar(
                      backgroundColor: kTransparentColor,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                        ),
                      ),
                      actions: [
                        ContainerCorner(
                          height: 20,
                          width: 100,
                          borderRadius: 10,
                          marginRight: 20,
                          marginTop: 10,
                          marginBottom: 10,
                          onTap: () {
                            _privatizeLive(selectedGif!,
                                viewersInLiveId: usersToInvite);
                          },
                          child: Center(
                              child: TextWithTap(
                            "live_streaming.go_live".tr(),
                            color: Colors.white,
                            fontSize: 15,
                          )),
                          colors: [kWarninngColor, kPrimaryColor],
                        ),
                      ],
                      automaticallyImplyLeading: false,
                    ),
                    body: ParseLiveListWidget<UserModel>(
                      query: query,
                      reverse: false,
                      lazyLoading: false,
                      shrinkWrap: true,
                      duration: Duration(milliseconds: 30),
                      childBuilder: (BuildContext context,
                          ParseLiveListElementSnapshot<UserModel> snapshot) {
                        if (snapshot.hasData) {
                          UserModel user = snapshot.loadedData as UserModel;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (usersToInvite.contains(user.objectId)) {
                                  usersToInvite.remove(user.objectId);
                                } else {
                                  usersToInvite.add(user.objectId);
                                }
                              });
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: ContainerCorner(
                                    child: Row(
                                      children: [
                                        QuickActions.avatarWidget(
                                          user,
                                          width: 50,
                                          height: 50,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWithTap(
                                              user.getFullName!,
                                              marginLeft: 15,
                                              color: Colors.white,
                                            ),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(left: 10),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  /*ContainerCorner(
                                                    marginRight: 10,
                                                    child: Row(
                                                      children: [
                                                        SvgPicture.asset(
                                                          "assets/svg/ic_diamond.svg",
                                                          height: 24,
                                                        ),
                                                        TextWithTap(
                                                          user.getDiamondsTotal.toString(),
                                                          fontSize: 14,
                                                          marginLeft: 3,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ],
                                                    ),
                                                  ),*/
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                usersToInvite.contains(user.objectId)
                                    ? Icon(
                                        Icons.check_circle,
                                        color: kPrimaryColor,
                                      )
                                    : Icon(
                                        Icons.radio_button_unchecked,
                                        color: kPrimaryColor,
                                      ),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                      queryEmptyElement: QuickActions.noContentFound(context),
                      listLoadingElement: Center(
                        child: CircularProgressIndicator(),
                      ),
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

  Widget _showTheUser(UserModel user, bool isStreamer) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Scaffold(
                      backgroundColor: kTransparentColor,
                      appBar: AppBar(
                        backgroundColor: kTransparentColor,
                        leading: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                          ),
                        ),
                        actions: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              openBottomSheet(
                                  _showUserSettings(user, isStreamer));
                            },
                            icon: SvgPicture.asset(
                              "assets/svg/ic_post_config.svg",
                              color: Colors.white,
                            ),
                          ),
                        ],
                        automaticallyImplyLeading: false,
                      ),
                      body: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: ContainerCorner(
                              height: 25,
                              width: MediaQuery.of(context).size.width,
                              marginLeft: 10,
                              marginRight: 10,
                              child: FittedBox(
                                  child: TextWithTap(
                                user.getFullName!,
                                color: Colors.white,
                              )),
                            ),
                          ),
                          TextWithTap(
                            QuickHelp.getGender(user),
                            color: Colors.white,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ContainerCorner(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/svg/ic_diamond.svg",
                                      width: 20,
                                      height: 20,
                                    ),
                                    TextWithTap(
                                      user.getDiamonds.toString(),
                                      color: Colors.white,
                                      marginLeft: 5,
                                    )
                                  ],
                                ),
                              ),
                              ContainerCorner(
                                marginLeft: 15,
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/svg/ic_followers_active.svg",
                                      width: 20,
                                      height: 20,
                                    ),
                                    TextWithTap(
                                      user.getFollowers!.length.toString(),
                                      color: Colors.white,
                                      marginLeft: 5,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          ContainerCorner(
                            width: MediaQuery.of(context).size.width - 100,
                            height: 60,
                            borderRadius: 50,
                            marginRight: 10,
                            marginBottom: 20,
                            onTap: () {
                              if (widget.currentUser.getFollowing!
                                  .contains(user.objectId)) {
                                return;
                              }

                              Navigator.of(context).pop();

                              if (isStreamer) {
                                followOrUnfollow();
                              } else {
                                follow(user);
                              }
                            },
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.currentUser.getFollowing!
                                      .contains(user.objectId)
                                  ? Colors.black.withOpacity(0.8)
                                  : kPrimaryColor,
                              widget.currentUser.getFollowing!
                                      .contains(user.objectId)
                                  ? Colors.black.withOpacity(0.8)
                                  : kSecondaryColor
                            ],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextWithTap(
                                  widget.currentUser.getFollowing!
                                          .contains(user.objectId)
                                      ? ""
                                      : "+",
                                  fontSize: 28,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                ),
                                TextWithTap(
                                  widget.currentUser.getFollowing!
                                          .contains(user.objectId)
                                      ? "live_streaming.following_".tr()
                                      : "live_streaming.live_follow".tr(),
                                  fontSize: 18,
                                  color: Colors.white,
                                  marginLeft: 5,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -30,
                      left: 1,
                      right: 1,
                      child: Center(
                        child: QuickActions.avatarWidget(user,
                            width: 70, height: 70),
                      ),
                    )
                  ]),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  setupCounterLiveUser() async {
    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());

    if (isBroadcaster) {
      query.whereEqualTo(UserModel.keyObjectId, widget.currentUser.objectId);
    } else {
      query.whereEqualTo(UserModel.keyObjectId, widget.mUser!.objectId);
    }

    subscription = await liveQuery.client.subscribe(query);

    subscription!.on(LiveQueryEvent.update, (user) async {
      print('*** UPDATE ***');

      if (isBroadcaster) {
        widget.currentUser = user as UserModel;
      } else {
        widget.mUser = user as UserModel;
      }

      if (!isBroadcaster) {
        setState(() {
          mUserDiamonds = widget.mUser!.getDiamondsTotal!.toString();
          viewersLast = liveStreamingModel.getViewersId!;
        });
      }
    });

    subscription!.on(LiveQueryEvent.enter, (user) {
      print('*** ENTER ***');

      if (isBroadcaster) {
        widget.currentUser = user as UserModel;
      } else {
        widget.mUser = user as UserModel;
      }

      if (!isBroadcaster) {
        setState(() {
          mUserDiamonds = widget.mUser!.getDiamondsTotal!.toString();
          viewersLast = liveStreamingModel.getViewersId!;
        });
      }
    });
  }

  setupCounterLive(String objectId) async {
    QueryBuilder<LiveStreamingModel> query =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    query.whereEqualTo(LiveStreamingModel.keyObjectId, objectId);
    query.includeObject([
      LiveStreamingModel.keyPrivateLiveGift,
      LiveStreamingModel.keyGiftSenders,
      LiveStreamingModel.keyGiftSendersAuthor,
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyInvitedPartyLive,
      LiveStreamingModel.keyInvitedPartyLiveAuthor,
    ]);

    subscription = await liveQuery.client.subscribe(query);

    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel value) async {
      print('*** UPDATE ***');
      liveStreamingModel = value;
      liveStreamingModel = value;

      if (value.isLiveCancelledByAdmin == true &&
          isBroadcaster &&
          liveEndAlerted == false) {
        print('*** UPDATE *** is isLiveCancelledByAdmin: ${value.getPrivate}');
        closeAdminAlert();

        liveEndAlerted = true;
        return;
      }

      updateInviteList(value.getInvitedPartyUid!);

      if (!mounted) return;

      if (isBroadcaster) {
        setState(() {
          liveCounter = value.getViewersCount.toString();
          diamondsCounter = value.getDiamonds.toString();
        });
      }

      QueryBuilder<LiveStreamingModel> query2 =
          QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
      query2.whereEqualTo(LiveStreamingModel.keyObjectId, objectId);
      query2.includeObject([
        LiveStreamingModel.keyPrivateLiveGift,
        LiveStreamingModel.keyGiftSenders,
        LiveStreamingModel.keyGiftSendersAuthor,
        LiveStreamingModel.keyAuthor,
        LiveStreamingModel.keyInvitedPartyLive,
        LiveStreamingModel.keyInvitedPartyLiveAuthor,
      ]);
      ParseResponse response = await query2.query();

      if (response.success) {
        LiveStreamingModel updatedLive =
            response.results!.first as LiveStreamingModel;

        if (updatedLive.getPrivate == true && !isBroadcaster) {
          print('*** UPDATE *** is Private: ${updatedLive.getPrivate}');

          /*if (!updatedLive.getPrivateViewersId!
              .contains(widget.currentUser.objectId)) {
            openPayPrivateLiveSheet(updatedLive);
          }*/

          if (!updatedLive.getPrivateViewersId!
                  .contains(widget.currentUser.objectId) &&
              !widget.currentUser.isAdmin!) {
            if (!paymentPopUpIsShowing) {
              paymentPopUpIsShowing = true;
              openPayPrivateLiveSheet(updatedLive);
            }
          }
        } else if (updatedLive.getInvitationLivePending != null) {
          print('*** UPDATE *** is not Private: ${updatedLive.getPrivate}');

          /*if (!invitationIsShowing) {
            openBottomSheet(
              _showInvitation(updatedLive.getInvitationLivePending!),
              isDismissible: false,
            );
          }*/

          if (updatedLive.getInvitedPartyUid!
              .contains(widget.currentUser.objectId)) {
            if (!invitationIsShowing) {
              invitationIsShowing = true;

              openBottomSheet(
                _showInvitation(updatedLive.getInvitationLivePending!),
                isDismissible: false,
              );
            }
          }
        }
      }
    });

    subscription!.on(LiveQueryEvent.enter, (LiveStreamingModel value) {
      print('*** ENTER ***');

      liveStreamingModel = value;
      liveStreamingModel = value;

      if (!mounted) return;
      setState(() {
        liveCounter = liveStreamingModel.getViewersCount.toString();
        diamondsCounter = liveStreamingModel.getDiamonds.toString();
      });
    });
  }

  void openSettingSheet() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showSettingsBottomSheet();
        });
  }

  Widget streamerBottom() {
    //return Container(color: Colors.green,);

    return Container(
      //color: kRedColor1,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            liveMessages(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ContainerCorner(
                  marginRight: 10,
                  marginLeft: 10,
                  //height: MediaQuery.of(context).size.height,
                  color: Colors.black.withOpacity(0.5),
                  child: ContainerCorner(
                    color: kTransparentColor,
                    marginAll: 8,
                    height: 30,
                    width: 30,
                    child: Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  borderRadius: 50,
                  height: 50,
                  width: 50,
                  onTap: () => openSettingSheet(),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: TextField(
                                onTap: () {
                                  setState(() {
                                    visibleKeyBoard = true;
                                  });
                                },
                                controller: textEditingController,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: kGreyColor1.withOpacity(0.5),
                                  ),
                                  hintText:
                                      "live_streaming.live_tape_here".tr(),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ContainerCorner(
                  marginLeft: 10,
                  marginRight: 10,
                  color: Colors.black.withOpacity(0.5),
                  child: ContainerCorner(
                    color: kTransparentColor,
                    marginAll: 8,
                    height: 30,
                    width: 30,
                    child: SvgPicture.asset(
                      "assets/svg/ic_send_message.svg",
                      color: Colors.white,
                      height: 10,
                      width: 30,
                    ),
                  ),
                  borderRadius: 50,
                  height: 50,
                  width: 50,
                  onTap: () {
                    if (textEditingController.text.isNotEmpty) {
                      sendMessage(LiveMessagesModel.messageTypeComment,
                          textEditingController.text, widget.currentUser);
                      textEditingController.clear();

                      if (FocusScope.of(context).hasFocus) {
                        FocusScope.of(context).unfocus();
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget audianceBottom() {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                liveMessages(),
                if (_showChat) chatInputField(),
              ],
            ),
            Visibility(
              visible: !_showChat,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ContainerCorner(
                    marginAll: 5,
                    color: Colors.black.withOpacity(0.5),
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginAll: 8,
                      height: 30,
                      width: 30,
                      child: SvgPicture.asset(
                        "assets/svg/ic_tab_chat_default.svg",
                        color: Colors.white,
                        height: 10,
                        width: 30,
                      ),
                    ),
                    borderRadius: 50,
                    height: 50,
                    width: 50,
                    onTap: () {
                      chatTextFieldFocusNode!.requestFocus();
                      showChatState();
                      setState(() {
                        visibleAudianceKeyBoard = true;
                      });
                    },
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      ContainerCorner(
                                        marginRight: 10,
                                        marginLeft: 6,
                                        color: Colors.black.withOpacity(0.5),
                                        child: QuickActions.avatarWidget(
                                          widget.mUser!,
                                        ),
                                        borderRadius: 50,
                                        height: 40,
                                        width: 40,
                                        onTap: () => openBottomSheet(
                                            _showTheUser(widget.mUser!, true)),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextWithTap(
                                            widget.mUser!.getFullName!,
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SvgPicture.asset(
                                                "assets/svg/ic_diamond.svg",
                                                height: 20,
                                              ),
                                              TextWithTap(
                                                mUserDiamonds,
                                                color: Colors.white,
                                                fontSize: 13,
                                                marginLeft: 3,
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  ContainerCorner(
                                    marginLeft: 10,
                                    marginRight: 6,
                                    colors: [
                                      following
                                          ? Colors.black.withOpacity(0.4)
                                          : kPrimaryColor,
                                      following
                                          ? Colors.black.withOpacity(0.4)
                                          : kPrimaryColor
                                    ],
                                    child: ContainerCorner(
                                        color: kTransparentColor,
                                        marginAll: 5,
                                        height: 30,
                                        width: 30,
                                        child: Icon(
                                          following ? Icons.done : Icons.add,
                                          color: Colors.white,
                                          size: 24,
                                        )),
                                    borderRadius: 50,
                                    height: 40,
                                    width: 40,
                                    onTap: () {
                                      if (!following) {
                                        followOrUnfollow();
                                        sendMessage(
                                            LiveMessagesModel.messageTypeFollow,
                                            "",
                                            widget.currentUser);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ContainerCorner(
                    marginAll: 5,
                    color: Colors.white,
                    child: ContainerCorner(
                      color: kTransparentColor,
                      marginAll: 8,
                      height: 30,
                      width: 30,
                      child: SvgPicture.asset(
                        "assets/svg/ic_menu_gifters.svg",
                        color: Colors.black,
                        height: 10,
                        width: 30,
                      ),
                    ),
                    borderRadius: 50,
                    height: 50,
                    width: 50,
                    onTap: () {
                      CoinsFlowPayment(
                        context: context,
                        currentUser: widget.currentUser,
                        onCoinsPurchased: (coins) {
                          print(
                              "onCoinsPurchased: $coins new: ${widget.currentUser.getCredits}");
                        },
                        onGiftSelected: (gift) {
                          print("onGiftSelected called ${gift.getCoins}");
                          sendGift(gift);

                          //QuickHelp.goBackToPreviousPage(context);
                          QuickHelp.showAppNotificationAdvanced(
                            context: context,
                            user: widget.currentUser,
                            title: "live_streaming.gift_sent_title".tr(),
                            message: "live_streaming.gift_sent_explain".tr(
                              namedArgs: {"name": widget.mUser!.getFirstName!},
                            ),
                            isError: false,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getGiftsPrices(StateSetter setState) {
    QueryBuilder<GiftsModel> giftQuery = QueryBuilder<GiftsModel>(GiftsModel());
    giftQuery.whereValueExists(GiftsModel.keyGiftCategories, true);
    giftQuery.whereEqualTo(
        GiftsModel.keyGiftCategories, GiftsModel.giftCategoryTypeClassic);

    return ContainerCorner(
      color: kTransparentColor,
      child: ParseLiveGridWidget<GiftsModel>(
        query: giftQuery,
        crossAxisCount: 4,
        reverse: false,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        lazyLoading: false,
        //childAspectRatio: 1.0,
        shrinkWrap: true,
        listenOnAllSubItems: true,
        listeningIncludes: [
          LiveStreamingModel.keyAuthor,
          LiveStreamingModel.keyAuthorInvited,
        ],
        duration: Duration(seconds: 0),
        animationController: _animationController,
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<GiftsModel> snapshot) {
          GiftsModel gift = snapshot.loadedData!;

          if (initGift) {
            setState(() {
              selectedGif = gift;
            });
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedGif = gift;
              });
            },
            child: Column(
              children: [
                Lottie.network(gift.getFile!.url!,
                    width: 60, height: 60, animate: true, repeat: true),
                ContainerCorner(
                  color: kTransparentColor,
                  marginTop: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/svg/ic_coin_with_star.svg",
                        width: 18,
                        height: 18,
                      ),
                      TextWithTap(
                        gift.getCoins.toString(),
                        color: Colors.white,
                        fontSize: 14,
                        marginLeft: 5,
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        queryEmptyElement: QuickActions.noContentFound(context),
        gridLoadingElement: Container(
          margin: EdgeInsets.only(top: 50),
          alignment: Alignment.topCenter,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget showGiftToBePaidOnPremiumBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Column(
                  children: [
                    ContainerCorner(
                      borderRadius: 10,
                      width: 170,
                      height: 250,
                      marginBottom: 20,
                      colors: [kPrimaryColor, kWarninngColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
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
                              "live_streaming.premium_price".tr(),
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              marginBottom: 15,
                            )),
                            Center(
                              child: TextWithTap(
                                "live_streaming.premium_price_explain".tr(),
                                color: Colors.white,
                                fontSize: 12,
                                marginLeft: 10,
                              ),
                            ),
                            if (selectedGif != null)
                              Lottie.network(selectedGif!.getFile!.url!,
                                  width: 90,
                                  height: 97,
                                  animate: true,
                                  repeat: true),
                            Expanded(
                              child: ContainerCorner(
                                borderRadius: 10,
                                height: 30,
                                width: 100,
                                color: kPrimaryColor,
                                onTap: () {
                                  if (selectedGif != null) {
                                    if (liveStreamingModel.getViewersCount! >
                                        0) {
                                      Navigator.pop(context);
                                      openBottomSheet(
                                          _showListOfPeopleToBeInvited());
                                    } else {
                                      _privatizeLive(selectedGif!);
                                    }
                                  } else {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/svg/sad.svg",
                                                  height: 70,
                                                  width: 70,
                                                ),
                                                TextWithTap(
                                                  "live_streaming.select_price"
                                                      .tr(),
                                                  textAlign: TextAlign.center,
                                                  color: Colors.red,
                                                  marginTop: 20,
                                                ),
                                                SizedBox(
                                                  height: 35,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    ContainerCorner(
                                                      child: TextButton(
                                                        child: TextWithTap(
                                                          "cancel"
                                                              .tr()
                                                              .toUpperCase(),
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                      color: kRedColor1,
                                                      borderRadius: 10,
                                                      marginLeft: 5,
                                                      width: 125,
                                                    ),
                                                    Expanded(
                                                      child: ContainerCorner(
                                                        child: TextButton(
                                                          child: TextWithTap(
                                                            "get_money.try_again"
                                                                .tr()
                                                                .toUpperCase(),
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                        ),
                                                        color: kGreenColor,
                                                        borderRadius: 10,
                                                        marginRight: 5,
                                                        width: 125,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          );
                                        });
                                  }
                                },
                                marginTop: 15,
                                marginBottom: 5,
                                child: Center(
                                  child: TextWithTap(
                                    "live_streaming.premium_btn".tr(),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ContainerCorner(
                        color: Colors.black.withOpacity(0.5),
                        radiusTopLeft: 25.0,
                        radiusTopRight: 25.0,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 3,
                        child: Scaffold(
                          appBar: AppBar(
                            backgroundColor: kTransparentColor,
                            elevation: 0,
                            automaticallyImplyLeading: false,
                            title: TextWithTap(
                              "live_streaming.gif_prices".tr(),
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            centerTitle: true,
                          ),
                          backgroundColor: kTransparentColor,
                          body: getGiftsPrices(
                              setState), //getClassicGifts(setState)
                        ),
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ),
    );
  }

  _privatizeLive(GiftsModel gift, {List? viewersInLiveId}) async {
    QuickHelp.showLoadingDialog(context);

    liveStreamingModel.setPrivate = true;
    liveStreamingModel.setPrivateLivePrice = gift;

    if (viewersInLiveId != null) {
      if (viewersInLiveId.length > 0) {
        liveStreamingModel.setPrivateListViewersId = viewersInLiveId;
      }
    }

    ParseResponse response = await liveStreamingModel.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      Navigator.pop(context);

      setState(() {
        isPrivateLive = true;
        liveTitle = "live_streaming.private_live".tr();
      });
    }
  }

  unPrivatizeLive(GiftsModel gift) async {
    QuickHelp.showLoadingDialog(context);

    liveStreamingModel.setPrivate = false;
    //liveStreamingModel.removePrice = liveStreamingModel.getPrivateLivePrice!;

    ParseResponse response = await liveStreamingModel.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      setState(() {
        isPrivateLive = false;
        liveTitle = "live_streaming.live_".tr();
      });
    }
  }

  Widget _showSettingsBottomSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
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
                  child: Column(
                    children: [
                      ContainerCorner(
                        color: Colors.white,
                        width: 50,
                        borderRadius: 20,
                        height: 5,
                        marginTop: 10,
                      ),
                      ContainerCorner(
                        borderRadius: 10,
                        marginTop: 10,
                        color: Colors.black.withOpacity(0.3),
                        child: StreamBuilder<int>(
                          stream: _stopWatchTimer.secondTime,
                          initialData: 0,
                          builder: (context, snap) {
                            final value = snap.data;
                            callDuration = QuickHelp.formatTime(value!);
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8),
                                  child: TextWithTap(
                                    QuickHelp.formatTime(value),
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 20),
                        child: TextButton(
                          onPressed: () => _onSwitchCamera(),
                          child: Row(
                            children: [
                              Icon(
                                Icons.switch_camera,
                                color: Colors.white,
                                size: 20,
                              ),
                              TextWithTap(
                                "live_streaming.switch_camera".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: TextButton(
                          onPressed: () => _onToggleMute(setState: setState),
                          child: Row(
                            children: [
                              ContainerCorner(
                                borderRadius: 40,
                                width: 26,
                                height: 26,
                                color: muted
                                    ? Colors.red
                                    : Colors.grey.withOpacity(0.4),
                                child: Icon(
                                  muted ? Icons.mic_off_rounded : Icons.mic,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              TextWithTap(
                                muted
                                    ? "live_streaming.toggle_audio_no_mute".tr()
                                    : "live_streaming.toggle_audio_mute".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),
                      /* Padding(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: TextButton(
                          onPressed: (){
                            Navigator.of(context).pop();
                            openBottomSheet(startBeauty());
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_vintage_sharp,
                                color: Colors.white,
                                size: 20,
                              ),
                              TextWithTap(
                                "live_streaming.live_beauty".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),*/
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            openBottomSheet(_inviteToParty());
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.white,
                                size: 20,
                              ),
                              TextWithTap(
                                "live_streaming.start_party_title".tr(),
                                color: Colors.white,
                                marginLeft: 10,
                                fontSize: 18,
                              )
                            ],
                          ),
                        ),
                      ),
                      /*Padding(
                        padding: EdgeInsets.only(left: 10, top: 5),
                        child: TextButton(
                          onPressed: () {
                            if (isPrivateLive) {
                              Navigator.of(context).pop();
                              _unPrivatizeLive(selectedGif!);
                            } else {
                              _getDefaultGiftPrice();
                              Navigator.of(context).pop();
                              openBottomSheet(
                                  _showGiftToBePaidOnPremiumBottomSheet());
                            }
                          },
                          child: Visibility(
                            visible: invitedUserPartyShowing!.isEmpty,
                            child: Row(
                              children: [
                                ContainerCorner(
                                  borderRadius: 40,
                                  width: 26,
                                  height: 26,
                                  color: isPrivateLive
                                      ? Colors.red
                                      : Colors.grey.withOpacity(0.4),
                                  child: Icon(
                                    isPrivateLive
                                        ? Icons.public
                                        : Icons.vpn_key_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                TextWithTap(
                                  isPrivateLive
                                      ? "live_streaming.unset_private_live".tr()
                                      : "live_streaming.privatize_live".tr(),
                                  color: Colors.white,
                                  marginLeft: 10,
                                  fontSize: 18,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),*/
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

  Widget chatInputField() {
    return Container(
      margin: EdgeInsets.only(
          bottom: visibleAudianceKeyBoard
              ? MediaQuery.of(context).viewInsets.bottom
              : 1),
      padding: EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 20 / 2,
      ),
      decoration: BoxDecoration(
        color: kTransparentColor,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 32,
            color: Color(0xFF087949).withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * 0.75,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      onChanged: (text) {
                        if (text.isNotEmpty) {
                          toggleSendButton(true);
                        } else {
                          toggleSendButton(false);
                        }
                      },
                      focusNode: chatTextFieldFocusNode,
                      maxLines: 2,
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: "comment_post.leave_comment".tr(),
                        hintStyle: TextStyle(color: Colors.white),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_hideSendButton)
            ContainerCorner(
              marginLeft: 10,
              color: kBlueColor1,
              child: ContainerCorner(
                color: kTransparentColor,
                marginAll: 5,
                height: 30,
                width: 30,
                child: SvgPicture.asset(
                  "assets/svg/ic_send_message.svg",
                  color: Colors.white,
                  height: 10,
                  width: 30,
                ),
              ),
              borderRadius: 50,
              height: 45,
              width: 45,
              onTap: () {
                if (textEditingController.text.isNotEmpty) {
                  sendMessage(LiveMessagesModel.messageTypeComment,
                      textEditingController.text, widget.currentUser);
                  setState(() {
                    textEditingController.text = "";
                    visibleAudianceKeyBoard = false;
                  });

                  if (FocusScope.of(context).hasFocus) {
                    FocusScope.of(context).unfocus();
                    showChatState();
                    setState(() {
                      visibleKeyBoard = false;
                      visibleAudianceKeyBoard = false;
                    });
                  }

                  toggleSendButton(false);
                }
              },
            ),
        ],
      ),
    );
  }

  sendMessage(
    String messageType,
    String message,
    UserModel author, {
    GiftsSentModel? giftsSent,
  }) async {
    if (messageType == LiveMessagesModel.messageTypeGift) {
      liveStreamingModel.addDiamonds = QuickHelp.getDiamondsForReceiver(
        giftsSent!.getDiamondsQuantity!,
        widget.preferences!,
      );

      liveStreamingModel.setCoHostAuthorUid = author.getUid!;
      liveStreamingModel.addAuthorTotalDiamonds =
          QuickHelp.getDiamondsForReceiver(
        giftsSent.getDiamondsQuantity!,
        widget.preferences!,
      );
      await liveStreamingModel.save();

      addOrUpdateGiftSender(giftsSent.getGift!);

      await QuickCloudCode.sendGift(
          preferences: widget.preferences,
          author: widget.mUser!,
          credits: giftsSent.getDiamondsQuantity!);
    }

    LiveMessagesModel liveMessagesModel = new LiveMessagesModel();
    liveMessagesModel.setAuthor = author;
    liveMessagesModel.setAuthorId = author.objectId!;

    liveMessagesModel.setLiveStreaming = liveStreamingModel;
    liveMessagesModel.setLiveStreamingId = liveStreamingModel.objectId!;

    if (giftsSent != null) {
      liveMessagesModel.setGiftSent = giftsSent;
      liveMessagesModel.setGiftSentId = giftsSent.objectId!;
      liveMessagesModel.setGiftId = giftsSent.getGiftId!;
    }

    if (messageType == LiveMessagesModel.messageTypeCoHost) {
      liveMessagesModel.setCoHostAuthor = widget.currentUser;
      liveMessagesModel.setCoHostAuthorUid = widget.currentUser.getUid!;
      liveMessagesModel.setCoHostAvailable = false;
    }

    liveMessagesModel.setMessage = message;
    liveMessagesModel.setMessageType = messageType;
    await liveMessagesModel.save();
  }

  Widget liveMessages() {
    if (isBroadcaster && liveMessageSent == false) {
      /* SendNotifications.sendPush(
          widget.currentUser, widget.currentUser, SendNotifications.typeLive,
          objectId: liveStreamingModel.objectId!);*/
      sendMessage(
          LiveMessagesModel.messageTypeSystem,
          "live_streaming.live_streaming_created_message".tr(),
          widget.currentUser);
      liveMessageSent = true;
    }

    QueryBuilder<LiveMessagesModel> queryBuilder =
        QueryBuilder<LiveMessagesModel>(LiveMessagesModel());
    queryBuilder.whereEqualTo(
        LiveMessagesModel.keyLiveStreamingId, liveMessageObjectId);
    queryBuilder.includeObject([
      LiveMessagesModel.keySenderAuthor,
      LiveMessagesModel.keyLiveStreaming,
      LiveMessagesModel.keyGiftSent,
      LiveMessagesModel.keyGiftSentGift
    ]);
    queryBuilder.orderByDescending(LiveMessagesModel.keyCreatedAt);

    var size = MediaQuery.of(context).size;
    return ContainerCorner(
      color: kTransparentColor,
      marginLeft: 10,
      marginRight: 10,
      height: 300,
      width: size.width / 1.3,
      marginBottom: 60,
      //color: kTransparentColor,
      child: ParseLiveListWidget<LiveMessagesModel>(
        query: queryBuilder,
        reverse: true,
        key: Key(liveMessageObjectId),
        duration: Duration(microseconds: 500),
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<LiveMessagesModel> snapshot) {
          if (snapshot.failed) {
            return Text('not_connected'.tr());
          } else if (snapshot.hasData) {
            LiveMessagesModel liveMessage = snapshot.loadedData!;

            bool isMe =
                liveMessage.getAuthorId == widget.currentUser.objectId &&
                    liveMessage.getLiveStreaming!.getAuthorId! ==
                        widget.currentUser.objectId;

            return getMessages(liveMessage, isMe);
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Widget getMessages(LiveMessagesModel liveMessages, bool isMe) {
    if (isMe) {
      return messageAvatar(
        "live_streaming.you_".tr(),
        liveMessages.getMessageType == LiveMessagesModel.messageTypeSystem
            ? "live_streaming.live_streaming_created_message".tr()
            : liveMessages.getMessage!,
        liveMessages.getAuthor!.getAvatar!.url!,
      );
    } else {
      if (liveMessages.getMessageType == LiveMessagesModel.messageTypeSystem) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "live_streaming.live_streaming_created_message".tr(),
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeJoin) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "live_streaming.live_streaming_watching".tr(),
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeComment) {
        return messageAvatar(
          nameOrYou(liveMessages),
          liveMessages.getMessage!,
          liveMessages.getAuthor!.getAvatar!.url!,
          user: liveMessages.getAuthor,
        );
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeFollow) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "live_streaming.new_follower".tr(),
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeGift) {
        return messageGift(
            nameOrYou(liveMessages),
            "live_streaming.new_gift".tr(),
            liveMessages.getGiftSent!.getGift!.getFile!.url!,
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeCoHost) {
        return isBroadcaster ||
                widget.currentUser.objectId == liveMessages.getAuthorId
            ? messageCoHost(
                nameOrYou(liveMessages),
                "live_streaming.ask_permition".tr(),
                liveMessages.getAuthor!,
                liveMessages,
                liveMessages.getAuthor!.getAvatar!.url!,
                liveMessages.getLiveStreaming!)
            : Container();
      } else {
        return messageAvatar(nameOrYou(liveMessages), liveMessages.getMessage!,
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      }
    }
  }

  String nameOrYou(LiveMessagesModel liveMessage) {
    if (liveMessage.getAuthorId == widget.currentUser.objectId) {
      return "live_streaming.you_".tr();
    } else {
      return liveMessage.getAuthor!.getFullName!;
    }
  }

  Widget messageCoHost(String title, String message, UserModel cohostAuthor,
      LiveMessagesModel messagesModel, avatarUrl, LiveStreamingModel live) {
    return ContainerCorner(
      borderRadius: 50,
      marginBottom: 5,
      colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.02)],
      child: Row(
        children: [
          ContainerCorner(
            width: 40,
            height: 40,
            color: kRedColor1,
            borderRadius: 50,
            marginRight: 10,
            marginLeft: 10,
            child: QuickActions.photosWidgetCircle(avatarUrl,
                width: 10, height: 10, boxShape: BoxShape.circle),
          ),
          Flexible(
            child: Column(
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: kWarninngColor,
                    ),
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ])),
              ],
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Visibility(
            visible: hostButtonCondition(cohostAuthor, messagesModel),
            child: ContainerCorner(
              colors: [kWarninngColor, kPrimaryColor],
              borderRadius: 10,
              width: 100,
              height: 40,
              child: TextButton(
                  onPressed: () =>
                      acceptCoHost(cohostAuthor, messagesModel, live),
                  child: TextWithTap(
                    hostButton(cohostAuthor, messagesModel),
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  acceptCoHost(UserModel userModel, LiveMessagesModel message,
      LiveStreamingModel live) async {
    if (isBroadcaster) {
      QuickHelp.showLoadingDialog(context);

      live.setCoHostUID = userModel.getUid!;
      ParseResponse response = await liveStreamingModel.save();

      if (response.success && !message.getCoHostAuthorAvailable!) {
        message.setCoHostAvailable = true;
        message.setCoHostAuthorUid = userModel.getUid!;
        message.setCoHostAuthor = userModel;

        await message.save();

        QuickHelp.hideLoadingDialog(context);
      }
    } else {
      if (message.getCoHostAuthorAvailable! && !coHostAvailable) {
        await _engine.enableLocalVideo(true);
        await _engine.setClientRole(ClientRole.Broadcaster);

        setState(() {
          coHostAvailable = true;
          //coHostUid = currentUser!.getUid!;
          //coHostUser = currentUser;
        });
      }
    }
  }

  Widget messageAvatar(String title, String message, avatarUrl,
      {UserModel? user}) {
    return ContainerCorner(
      borderRadius: 50,
      marginBottom: 5,
      colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.02)],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContainerCorner(
            width: 30,
            height: 30,
            color: kRedColor1,
            borderRadius: 50,
            marginRight: 10,
            onTap: () {
              if (user != null &&
                  user.objectId != widget.currentUser.objectId!) {
                openBottomSheet(_showTheUser(user, false));
              }
            },
            child: QuickActions.photosWidgetCircle(avatarUrl,
                width: 10, height: 10, boxShape: BoxShape.circle),
          ),
          Flexible(
            child: Column(
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: kWarninngColor,
                    ),
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messageNoAvatar(String title, String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: RichText(
          text: TextSpan(children: [
        TextSpan(
          text: title,
          style: TextStyle(
            color: kWarninngColor,
          ),
        ),
        TextSpan(text: " "),
        TextSpan(
          text: message,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ])),
    );
  }

  Widget messageGift(String title, String message, String giftUrl, avatarUrl,
      {UserModel? user}) {
    return ContainerCorner(
      borderRadius: 50,
      marginBottom: 5,
      onTap: () {
        if (user != null && user.objectId != widget.currentUser.objectId!) {
          openBottomSheet(_showTheUser(user, false));
        }
      },
      colors: [Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.02)],
      child: Row(
        children: [
          ContainerCorner(
            width: 40,
            height: 40,
            color: kRedColor1,
            borderRadius: 50,
            marginRight: 10,
            marginLeft: 10,
            child: QuickActions.photosWidgetCircle(avatarUrl,
                width: 10, height: 10, boxShape: BoxShape.circle),
          ),
          Flexible(
            child: Column(
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                    text: title,
                    style: TextStyle(
                      color: kWarninngColor,
                    ),
                  ),
                  TextSpan(text: " "),
                  TextSpan(
                    text: message,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ])),
              ],
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Container(
              width: 50,
              height: 50,
              child: Lottie.network(giftUrl,
                  width: 30, height: 30, animate: true, repeat: true)),
        ],
      ),
    );
  }

  String hostButton(UserModel author, LiveMessagesModel message) {
    if (isBroadcaster) {
      if (message.getCoHostAuthorAvailable!) {
        return "live_streaming.accepted_btn".tr();
      } else {
        return "live_streaming.accept_btn".tr();
      }
    } else if (message.getAuthor!.objectId! == widget.currentUser.objectId) {
      if (message.getCoHostAuthorAvailable!) {
        return "live_streaming.join_now_btn".tr();
      } else {
        return "live_streaming.pending_btn".tr();
      }
    } else {
      return "";
    }
  }

  bool hostButtonCondition(UserModel author, LiveMessagesModel message) {
    if (isBroadcaster) {
      return true;
    } else if (message.getAuthor!.objectId! == widget.currentUser.objectId) {
      return true;
    } else {
      return false;
    }
  }

  sendGift(GiftsModel giftsModel) async {
    /*setState(() {
      usersWhoSentGift.add(widget.currentUser);
    });*/

    //liveStreamingModel.setGifSenderImage = widget.currentUser.getAvatar!;

    GiftsSentModel giftsSentModel = new GiftsSentModel();
    giftsSentModel.setAuthor = widget.currentUser;
    giftsSentModel.setAuthorId = widget.currentUser.objectId!;

    giftsSentModel.setReceiver = widget.mUser!;
    giftsSentModel.setReceiverId = widget.mUser!.objectId!;

    giftsSentModel.setGift = giftsModel;
    giftsSentModel.setGiftId = giftsModel.objectId!;
    giftsSentModel.setCounterDiamondsQuantity = giftsModel.getCoins!;
    await giftsSentModel.save();

    QuickHelp.saveReceivedGifts(
        receiver: widget.mUser!, author: widget.currentUser, gift: giftsModel);
    QuickHelp.saveCoinTransaction(
      receiver: widget.mUser!,
      author: widget.currentUser,
      amountTransacted: giftsModel.getCoins!,
    );

    QueryBuilder<LeadersModel> queryBuilder =
        QueryBuilder<LeadersModel>(LeadersModel());
    queryBuilder.whereEqualTo(
        LeadersModel.keyAuthorId, widget.currentUser.objectId!);
    ParseResponse parseResponse = await queryBuilder.query();

    if (parseResponse.success) {
      updateCurrentUser(giftsSentModel.getDiamondsQuantity!);

      if (parseResponse.results != null) {
        LeadersModel leadersModel =
            parseResponse.results!.first as LeadersModel;
        leadersModel.incrementDiamondsQuantity =
            giftsSentModel.getDiamondsQuantity!;
        leadersModel.setGiftsSent = giftsSentModel;
        await leadersModel.save();
      } else {
        LeadersModel leadersModel = LeadersModel();
        leadersModel.setAuthor = widget.currentUser;
        leadersModel.setAuthorId = widget.currentUser.objectId!;
        leadersModel.incrementDiamondsQuantity =
            giftsSentModel.getDiamondsQuantity!;
        leadersModel.setGiftsSent = giftsSentModel;
        await leadersModel.save();
      }

      sendMessage(LiveMessagesModel.messageTypeGift, "", widget.currentUser,
          giftsSent: giftsSentModel);
    } else {
      //QuickHelp.goBackToPreviousPage(context);
    }
  }

  updateCurrentUser(int coins) async {
    widget.currentUser.removeCredit = coins;
    ParseResponse response = await widget.currentUser.save();
    if (response.success && response.results != null) {
      widget.currentUser = response.results!.first as UserModel;
    }
  }

  void openPayPrivateLiveSheet(LiveStreamingModel live) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        isDismissible: false,
        builder: (context) {
          return _showPayPrivateLiveBottomSheet(live);
        });
  }

  Widget _showPayPrivateLiveBottomSheet(LiveStreamingModel live) {
    return Container(
      color: Color.fromRGBO(0, 0, 0, 0.001),
      child: GestureDetector(
        onTap: () {},
        child: DraggableScrollableSheet(
          initialChildSize: 0.89,
          minChildSize: 0.1,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return StatefulBuilder(builder: (context, setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
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
                          onPressed: () {
                            Navigator.of(context).pop();
                            closeAlert();
                          },
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
                          if (widget.currentUser.getCredits! >=
                              live.getPrivateGift!.getCoins!) {
                            _payForPrivateLive(live);
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(top: 15.0),
                                          child: CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.white,
                                            child: SvgPicture.asset(
                                              "assets/svg/sad.svg",
                                              color: kRedColor1,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "live_streaming.not_enough_coins"
                                              .tr(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 35,
                                        ),
                                        ButtonWithGradient(
                                          borderRadius: 100,
                                          text: "live_streaming.get_credit_btn"
                                              .tr(),
                                          marginLeft: 15,
                                          marginRight: 15,
                                          height: 50,
                                          beginColor: kWarninngColor,
                                          endColor: kPrimaryColor,
                                          onTap: () {
                                            Navigator.pop(context);
                                            //Navigator.pop(context);
                                            CoinsFlowPayment(
                                              context: context,
                                              currentUser: widget.currentUser,
                                              showOnlyCoinsPurchase: true,
                                              onCoinsPurchased: (coins) {
                                                print(
                                                    "onCoinsPurchased: $coins new: ${widget.currentUser.getCredits}");
                                                Navigator.pop(context);
                                              },
                                              onGiftSelected: (gift) {
                                                print(
                                                    "onGiftSelected called ${gift.getCoins}");
                                              },
                                            );
                                            //Navigator.pop(context);
                                            //Navigator.pop(context);
                                          },
                                        ),
                                        SizedBox(height: 20),
                                      ],
                                    ),
                                  );
                                });
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
    );
  }

  updateCurrentUserCredit(int coins) async {
    widget.currentUser.removeCredit = coins;
    ParseResponse response = await widget.currentUser.save();
    if (response.success) {
      widget.currentUser = response.results!.first as UserModel;
    }
  }

  _payForPrivateLive(LiveStreamingModel live) async {
    QuickHelp.showLoadingDialog(context);

    sendGift(live.getPrivateGift!);
    live.setPrivateViewersId = widget.currentUser.objectId!;
    ParseResponse response = await live.save();

    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      Navigator.pop(context);
    }
  }

  _secureScreen(bool isSecureScreen) async {
    if (isSecureScreen) {
      if (QuickHelp.isAndroidPlatform()) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      }
    } else {
      if (QuickHelp.isAndroidPlatform()) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      }
    }
  }

  addOrUpdateGiftSender(GiftsModel giftsModel) async {
    QueryBuilder<GiftsSenderModel> queryGiftSender =
        QueryBuilder<GiftsSenderModel>(GiftsSenderModel());

    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyAuthorId, widget.currentUser);
    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyReceiverId, widget.mUser!.objectId);
    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyLiveId, liveStreamingModel.objectId!);

    ParseResponse parseResponse = await queryGiftSender.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        GiftsSenderModel giftsSenderModel =
            parseResponse.results!.first! as GiftsSenderModel;
        giftsSenderModel.addDiamonds = giftsModel.getCoins!;
        await giftsSenderModel.save();

        liveStreamingModel.addGiftsSenders = giftsSenderModel;
        liveStreamingModel.save();
      } else {
        GiftsSenderModel giftsSenderModel = GiftsSenderModel();
        giftsSenderModel.setAuthor = widget.currentUser;
        giftsSenderModel.setAuthorId = widget.currentUser.objectId!;
        giftsSenderModel.setAuthorName = widget.currentUser.getFullName!;

        giftsSenderModel.setReceiver = widget.mUser!;
        giftsSenderModel.setReceiverId = widget.mUser!.objectId!;

        giftsSenderModel.addDiamonds = giftsModel.getCoins!;

        giftsSenderModel.setLiveId = liveStreamingModel.objectId!;
        await giftsSenderModel.save();

        liveStreamingModel.addGiftsSenders = giftsSenderModel;
        liveStreamingModel.save();
      }
    }

    addOrUpdateGiftSenderGlobal(giftsModel);
  }

  addOrUpdateGiftSenderGlobal(GiftsModel giftsModel) async {
    QueryBuilder<GiftsSenderGlobalModel> queryGiftSender =
        QueryBuilder<GiftsSenderGlobalModel>(GiftsSenderGlobalModel());

    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyAuthorId, widget.currentUser);
    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyReceiverId, widget.mUser!.objectId);

    ParseResponse parseResponse = await queryGiftSender.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        GiftsSenderGlobalModel giftsSenderModel =
            parseResponse.results!.first! as GiftsSenderGlobalModel;
        giftsSenderModel.addDiamonds = giftsModel.getCoins!;
        await giftsSenderModel.save();
      } else {
        GiftsSenderGlobalModel giftsSenderModel = GiftsSenderGlobalModel();
        giftsSenderModel.setAuthor = widget.currentUser;
        giftsSenderModel.setAuthorId = widget.currentUser.objectId!;
        giftsSenderModel.setAuthorName = widget.currentUser.getFullName!;

        giftsSenderModel.setReceiver = widget.mUser!;
        giftsSenderModel.setReceiverId = widget.mUser!.objectId!;

        giftsSenderModel.addDiamonds = giftsModel.getCoins!;

        await giftsSenderModel.save();
      }
    }
  }

  setupGiftSendersLiveQuery() async {
    QueryBuilder<GiftsSenderModel> queryGiftSender =
        QueryBuilder<GiftsSenderModel>(GiftsSenderModel());
    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyLiveId, liveStreamingModel.objectId!);
    queryGiftSender.includeObject(
        [GiftsSenderModel.keyAuthor, GiftsSenderModel.keyAuthor]);

    subscription = await liveQuery.client.subscribe(queryGiftSender);

    subscription!.on(LiveQueryEvent.update, (GiftsSenderModel value) async {
      print('*** UPDATE ***');

      setState(() {});
    });

    subscription!.on(LiveQueryEvent.enter, (GiftsSenderModel value) {
      print('*** ENTER ***');

      setState(() {});
    });
  }

  void openReportMessage(UserModel author,
      LiveStreamingModel liveStreamingModel, bool isStreamer) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showReportMessageBottomSheet(
              author, liveStreamingModel, isStreamer);
        });
  }

  Widget _showReportMessageBottomSheet(
      UserModel author, LiveStreamingModel streamingModel, bool isStreamer) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.45,
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
                              : "live_streaming.report_live_user".tr(
                                  namedArgs: {"name": author.getFirstName!}),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          marginBottom: 50,
                        ),
                        Column(
                          children: List.generate(
                              QuickHelp.getReportCodeMessageList().length,
                              (index) {
                            String code =
                                QuickHelp.getReportCodeMessageList()[index];

                            return TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                print("Message: " +
                                    QuickHelp.getReportMessage(code));
                                _saveReport(
                                    QuickHelp.getReportMessage(code), author,
                                    live: isStreamer ? streamingModel : null);
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
              });
            },
          ),
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
        accuser: widget.currentUser,
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

  Widget _showListOfViewers() {
    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());
    query.whereContainedIn(UserModel.keyObjectId,
        this.liveStreamingModel.getViewersId as List<dynamic>); //globalList

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.67,
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
                    backgroundColor: kTransparentColor,
                    appBar: AppBar(
                      backgroundColor: kTransparentColor,
                      title: TextWithTap(
                        isBroadcaster
                            ? "live_streaming.live_viewers".tr().toUpperCase()
                            : "live_streaming.live_viewers_gift"
                                .tr()
                                .toUpperCase(),
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      centerTitle: true,
                      leading: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                        ),
                      ),
                    ),
                    body: ParseLiveListWidget<UserModel>(
                      query: query,
                      reverse: false,
                      lazyLoading: false,
                      shrinkWrap: true,
                      duration: Duration(milliseconds: 30),
                      childBuilder: (BuildContext context,
                          ParseLiveListElementSnapshot<UserModel> snapshot) {
                        if (snapshot.hasData) {
                          UserModel user = snapshot.loadedData as UserModel;

                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 7, left: 10, right: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ContainerCorner(
                                    onTap: () {
                                      if (widget.currentUser.objectId! ==
                                          user.objectId!) {
                                        return;
                                      }

                                      Navigator.of(context).pop();
                                      openBottomSheet(
                                          _showTheUser(user, false));
                                    },
                                    child: Row(
                                      children: [
                                        QuickActions.avatarWidget(
                                          user,
                                          width: 45,
                                          height: 45,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            TextWithTap(
                                              user.getFullName!,
                                              marginLeft: 10,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                            Visibility(
                                              visible:
                                                  user.getCreditsSent != null,
                                              //visible:  giftSenderList.contains(user.objectId),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    left: 10, right: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ContainerCorner(
                                                      marginTop: 5,
                                                      child: Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                            "assets/svg/ic_coin_with_star.svg",
                                                            height: 16,
                                                          ),
                                                          TextWithTap(
                                                            user.getCreditsSent
                                                                .toString(),
                                                            //giftSenderAuthor[].getDiamonds.toString(),
                                                            fontSize: 13,
                                                            marginLeft: 5,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: widget.currentUser.objectId! !=
                                      user.objectId!,
                                  child: ContainerCorner(
                                    marginLeft: 10,
                                    marginRight: 6,
                                    color: widget.currentUser.getFollowing!
                                            .contains(user.objectId)
                                        ? Colors.black.withOpacity(0.4)
                                        : kPrimaryColor,
                                    child: ContainerCorner(
                                        color: kTransparentColor,
                                        marginAll: 5,
                                        height: 35,
                                        width: 35,
                                        child: Center(
                                          child: Icon(
                                            widget.currentUser.getFollowing!
                                                    .contains(user.objectId)
                                                ? Icons.done
                                                : Icons.add,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        )),
                                    borderRadius: 50,
                                    height: 35,
                                    width: 35,
                                    onTap: () {
                                      if (widget.currentUser.getFollowing!
                                          .contains(user.objectId)) {
                                        return;
                                      }

                                      follow(user);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                      queryEmptyElement: QuickActions.noContentFound(context),
                      listLoadingElement: Center(
                        child: CircularProgressIndicator(),
                      ),
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

  Widget getViewersLastPictures() {
    QueryBuilder<UserModel> query = QueryBuilder(UserModel.forQuery());
    query.whereContainedIn(UserModel.keyObjectId, viewersLast);
    //query.whereContainedIn(UserModel.keyObjectId, ["t8KGbvirOd", "jJLCZ5efFA", "Q4ZcU9qRVR", "jnDvDdTyRA"]);
    query.setLimit(3);
    query.orderByAscending(UserModel.keyUpdatedAt);

    return GestureDetector(
      onTap: () => openBottomSheet(_showListOfViewers()),
      child: ParseLiveListWidget<UserModel>(
        shrinkWrap: true,
        query: query,
        reverse: true,
        lazyLoading: false,
        scrollDirection: Axis.horizontal,
        duration: Duration(milliseconds: 30),
        childBuilder: (BuildContext context,
            ParseLiveListElementSnapshot<UserModel> snapshot) {
          if (snapshot.hasData) {
            UserModel user = snapshot.loadedData as UserModel;

            return QuickActions.photosWidgetCircle(user.getAvatar!.url!,
                width: 30, height: 30, boxShape: BoxShape.circle);
          } else {
            return Container();
          }
        },
        listLoadingElement: Center(
          child: Container(),
        ),
      ),
    );
  }

  Widget _inviteToParty() {
    int numberOfColumns = 3;

    QueryBuilder<UserModel> queryFriends = QueryBuilder(UserModel.forQuery());
    queryFriends.whereContainedIn(UserModel.keyObjectId,
        widget.currentUser.getFollowing as List<dynamic>);

    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

    queryBuilder.includeObject([
      LiveStreamingModel.keyAuthor,
      LiveStreamingModel.keyAuthorInvited,
      LiveStreamingModel.keyPrivateLiveGift,
      LiveStreamingModel.keyGiftSenders,
      LiveStreamingModel.keyGiftSendersAuthor
    ]);

    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyStreamingPrivate, isPrivateLive);
    queryBuilder.whereNotEqualTo(
        LiveStreamingModel.keyAuthorUid, widget.currentUser.getUid);
    queryBuilder.whereNotContainedIn(
        LiveStreamingModel.keyAuthor, widget.currentUser.getBlockedUsers!);
    queryBuilder.whereValueExists(LiveStreamingModel.keyAuthor, true);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerFloat,
                    floatingActionButtonAnimator:
                        FloatingActionButtonAnimator.scaling,
                    floatingActionButton: Visibility(
                      visible: invitedUserPartyListPending!.isNotEmpty,
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          inviteUserNow();
                        },
                        child: ContainerCorner(
                          onTap: () {
                            Navigator.of(context).pop();
                            inviteUserNow();
                          },
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
                    ),
                    backgroundColor: kTransparentColor,
                    appBar: AppBar(
                      leading: Visibility(
                        visible: false,
                        child: Container(),
                      ),
                      backgroundColor: kTransparentColor,
                      title: Column(
                        children: [
                          ContainerCorner(
                            color: Colors.white,
                            width: 50,
                            borderRadius: 20,
                            height: 5,
                            marginTop: 10,
                            marginBottom: 10,
                          ),
                          TextWithTap(
                            "live_streaming.start_party".tr().toUpperCase(),
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      centerTitle: true,
                    ),
                    body: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWithTap(
                            "live_streaming.menu_for_you".tr(),
                            color: Colors.white,
                            fontSize: 16,
                            marginTop: 20,
                            marginLeft: 10,
                            marginBottom: 10,
                          ),
                          Expanded(
                            flex: 2,
                            child: ParseLiveGridWidget<LiveStreamingModel>(
                              query: queryBuilder,
                              crossAxisCount: numberOfColumns,
                              reverse: false,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                              lazyLoading: false,
                              childAspectRatio: 1.0,
                              shrinkWrap: true,
                              primary: true,
                              duration: Duration(seconds: 0),
                              animationController: _animationController,
                              childBuilder: (BuildContext context,
                                  ParseLiveListElementSnapshot<
                                          LiveStreamingModel>
                                      snapshot) {
                                if (snapshot.hasData) {
                                  LiveStreamingModel liveStreaming =
                                      snapshot.loadedData!;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (invitedUserPartyListPending!
                                            .contains(liveStreaming
                                                .getAuthor!.getUid)) {
                                          invitedUserPartyListPending!.remove(
                                              liveStreaming.getAuthor!.getUid);
                                          invitedUserPartyListLivePending!
                                              .remove(liveStreaming);
                                        } else {
                                          if (invitedUserPartyListPending!
                                                      .length +
                                                  invitedUserParty!.length >
                                              2) {
                                            QuickHelp
                                                .showAppNotificationAdvanced(
                                              context: this.context,
                                              title:
                                                  "live_streaming.invite_limit_title"
                                                      .tr(),
                                              message:
                                                  "live_streaming.invite_limit"
                                                      .tr(namedArgs: {
                                                "limit": 3.toString()
                                              }),
                                              isError: true,
                                            );

                                            return;
                                          }

                                          invitedUserPartyListPending!.add(
                                              liveStreaming.getAuthor!.getUid);
                                          invitedUserPartyListLivePending!
                                              .add(liveStreaming);
                                        }
                                      });
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
                                          width: (MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              numberOfColumns),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    SvgPicture.asset(
                                                      "assets/svg/ic_small_viewers.svg",
                                                      height: 12,
                                                      width: 12,
                                                    ),
                                                    TextWithTap(
                                                      liveStreaming
                                                          .getViewersCount
                                                          .toString(),
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      marginRight: 5,
                                                      marginLeft: 5,
                                                    ),
                                                    SvgPicture.asset(
                                                      "assets/svg/ic_diamond.svg",
                                                      height: 14,
                                                      width: 14,
                                                    ),
                                                    TextWithTap(
                                                      liveStreaming.getAuthor!
                                                          .getDiamondsTotal!
                                                          .toString(),
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      marginLeft: 3,
                                                    ),
                                                  ],
                                                ),
                                                Icon(
                                                  invitedUserPartyListPending!
                                                          .contains(
                                                              liveStreaming
                                                                  .getAuthor!
                                                                  .getUid)
                                                      ? Icons
                                                          .radio_button_checked
                                                      : Icons
                                                          .radio_button_unchecked,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
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
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        child: TextWithTap(
                                          liveStreaming
                                              .getAuthor!.getFirstName!,
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          alignment: Alignment.center,
                                          marginBottom: 5,
                                          marginLeft: 5,
                                        ),
                                      ),
                                    ]),
                                  );
                                } else {
                                  return Container();
                                }
                              },
                              gridLoadingElement: Center(
                                child: CircularProgressIndicator(),
                              ),
                              queryEmptyElement:
                                  QuickActions.noContentFound(context),
                            ),
                          ),
                        ],
                      ),
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

  Widget startBeauty() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    backgroundColor: kTransparentColor,
                    appBar: AppBar(
                      backgroundColor: kTransparentColor,
                      automaticallyImplyLeading: false,
                      title: Column(
                        children: [
                          ContainerCorner(
                            color: Colors.white,
                            width: 50,
                            borderRadius: 20,
                            height: 5,
                            marginTop: 10,
                            marginBottom: 10,
                          ),
                          TextWithTap(
                            "live_streaming.live_beauty_makeup"
                                .tr()
                                .toUpperCase(),
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      centerTitle: true,
                    ),
                    body: SafeArea(
                      child: Container(
                        color: Colors.black,
                      ),
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

  inviteUserNow() async {
    QuickHelp.showLoadingDialog(context);

    if (invitedUserPartyListLivePending != null &&
        invitedUserPartyListLivePending!.length > 0) {
      for (LiveStreamingModel live in invitedUserPartyListLivePending!) {
        live.setInvitationLivePending = liveStreamingModel;
        await live.save();
      }
    }

    liveStreamingModel.addInvitedPartyUid = invitedUserPartyListPending!;
    ParseResponse response = await liveStreamingModel.save();

    if (response.success) {
      invitedUserPartyListPending!.clear();
      invitedUserPartyListLivePending!.clear();

      QuickHelp.hideLoadingDialog(context);
    } else {
      QuickHelp.hideLoadingDialog(context);
    }
  }

  Widget getRenderInviteView() {
    return Column(
      children: List.generate(invitedUserPartyShowing!.length, (index) {
        int userSelected = invitedUserPartyShowing![index];

        return ContainerCorner(
          //color: Colors.black,
          width: MediaQuery.of(context).size.width / 3.5,
          height: MediaQuery.of(context).size.width / 2.5,
          shadowColor: Colors.black,
          shadowColorOpacity: 0.2,
          blurRadius: 20,
          spreadRadius: 2,
          borderRadius: 10,
          marginBottom: 5,
          onTap: () {
            if (isBroadcaster || isUserInvited) {
              invitedUserPartyShowing!.add(invitedToPartyUidSelected);
              invitedToPartyUidSelected = userSelected;
              invitedUserPartyShowing!.remove(userSelected);

              setState(() {});
            } else {
              setState(() {
                print("Preview clicked $userSelected");

                invitedUserPartyShowing!.add(invitedToPartyUidSelected);
                invitedToPartyUidSelected = userSelected;
                invitedUserPartyShowing!.remove(userSelected);
              });
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: invitedUserPartyShowing!.isNotEmpty
                ? Stack(
                    children: [
                      if (userSelected == widget.currentUser.getUid)
                        RtcLocalView.SurfaceView(
                          channelId: widget.channelName,
                        )
                      else
                        RtcRemoteView.SurfaceView(
                          channelId: widget.channelName,
                          uid: userSelected,
                        ),
                      Visibility(
                        visible: isBroadcaster,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                ContainerCorner(
                                  marginAll: 10,
                                  borderRadius: 40,
                                  width: 26,
                                  height: 26,
                                  onTap: () {
                                    if (userSelected ==
                                        widget.currentUser.getUid) {
                                      _onToggleMute();
                                    } else {
                                      muteInvitedUserAudio(userSelected);
                                    }
                                  },
                                  color: getMuteColor(userSelected),
                                  child: Icon(
                                    getMuteIcon(userSelected),
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                Visibility(
                                  visible:
                                      userSelected != widget.currentUser.getUid,
                                  child: ContainerCorner(
                                    marginRight: 10,
                                    marginLeft: 10,
                                    borderRadius: 40,
                                    width: 26,
                                    height: 26,
                                    onTap: () {
                                      muteInvitedUserVideo(userSelected);
                                    },
                                    color: invitedUserPartyVideoMuted!
                                            .contains(userSelected)
                                        ? Colors.red
                                        : Colors.grey.withOpacity(0.4),
                                    child: Icon(
                                      invitedUserPartyVideoMuted!
                                              .contains(userSelected)
                                          ? Icons.videocam_off
                                          : Icons.videocam,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Visibility(
                              visible:
                                  userSelected != widget.currentUser.getUid,
                              child: ContainerCorner(
                                marginAll: 10,
                                borderRadius: 40,
                                width: 26,
                                height: 26,
                                onTap: () {
                                  liveStreamingModel.removeInvitedPartyUid =
                                      userSelected;
                                  liveStreamingModel.save();
                                },
                                color: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Container(),
          ),
        );
      }),
    );
  }

  Widget getPreviewList() {
    print("PreviewList getPreviewList ${invitedUserPartyShowing!.length}");

    return ContainerCorner(
      alignment: Alignment.topRight,
      color: Colors.red,
      width: MediaQuery.of(this.context).size.width,
      height: MediaQuery.of(this.context).size.width,
      child: ListView.builder(
          shrinkWrap: true,
          key: Key(QuickHelp.generateShortUId().toString()),
          itemCount: invitedUserParty!.length,
          itemBuilder: (BuildContext context, int index) {
            int userSelected = invitedUserParty![index];

            return ContainerCorner(
              //color: Colors.black,
              width: MediaQuery.of(context).size.width / 3.5,
              height: MediaQuery.of(context).size.width / 2.5,
              shadowColor: Colors.black,
              shadowColorOpacity: 0.2,
              blurRadius: 20,
              spreadRadius: 2,
              borderRadius: 10,
              marginBottom: 5,
              onTap: () {
                if (isBroadcaster || isUserInvited) {
                  invitedUserPartyShowing!.add(invitedToPartyUidSelected);
                  invitedToPartyUidSelected = userSelected;
                  invitedUserPartyShowing!.remove(userSelected);

                  setState(() {});
                } else {
                  setState(() {
                    print("Preview clicked $userSelected");

                    invitedUserPartyShowing!.add(invitedToPartyUidSelected);
                    invitedToPartyUidSelected = userSelected;
                    invitedUserPartyShowing!.remove(userSelected);
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: invitedUserPartyShowing!.isNotEmpty
                    ? Stack(
                        children: [
                          if (userSelected == widget.currentUser.getUid)
                            RtcLocalView.SurfaceView(
                              channelId: widget.channelName,
                            )
                          else
                            RtcRemoteView.SurfaceView(
                              channelId: widget.channelName,
                              uid: userSelected,
                            ),
                          Visibility(
                            visible: isBroadcaster,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    ContainerCorner(
                                      marginAll: 10,
                                      borderRadius: 40,
                                      width: 26,
                                      height: 26,
                                      onTap: () {
                                        if (userSelected ==
                                            widget.currentUser.getUid) {
                                          _onToggleMute();
                                        } else {
                                          muteInvitedUserAudio(userSelected);
                                        }
                                      },
                                      color: getMuteColor(userSelected),
                                      child: Icon(
                                        getMuteIcon(userSelected),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    Visibility(
                                      visible: userSelected !=
                                          widget.currentUser.getUid,
                                      child: ContainerCorner(
                                        marginRight: 10,
                                        marginLeft: 10,
                                        borderRadius: 40,
                                        width: 26,
                                        height: 26,
                                        onTap: () {
                                          muteInvitedUserVideo(userSelected);
                                        },
                                        color: invitedUserPartyVideoMuted!
                                                .contains(userSelected)
                                            ? Colors.red
                                            : Colors.grey.withOpacity(0.4),
                                        child: Icon(
                                          invitedUserPartyVideoMuted!
                                                  .contains(userSelected)
                                              ? Icons.videocam_off
                                              : Icons.videocam,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ContainerCorner(
                                  marginAll: 10,
                                  borderRadius: 40,
                                  width: 26,
                                  height: 26,
                                  onTap: () {
                                    liveStreamingModel.removeInvitedPartyUid =
                                        userSelected;
                                    liveStreamingModel.save();
                                  },
                                  color: Colors.red,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(),
              ),
            );
          }),
    );
  }

  Color getMuteColor(int uid) {
    if (uid == widget.currentUser.getUid) {
      return muted ? Colors.red : Colors.grey.withOpacity(0.4);
    } else {
      return invitedUserPartyAudioMuted!.contains(uid)
          ? Colors.red
          : Colors.grey.withOpacity(0.4);
    }
  }

  IconData getMuteIcon(int uid) {
    if (uid == widget.currentUser.getUid) {
      return muted ? Icons.mic_off_rounded : Icons.mic_none_rounded;
    } else {
      return invitedUserPartyAudioMuted!.contains(uid)
          ? Icons.mic_off_rounded
          : Icons.mic_none_rounded;
    }
  }

  Widget draggable() {
    //print("PreviewList draggable ${invitedUserPartyShowing!.length}");

    //return getPreviewList();
    return Positioned(
        top: 10,
        right: 10,
        child: Container(
          margin: EdgeInsets.only(
              top: QuickHelp.isIOSPlatform() ? 100 : 90, right: 10),
          child: getRenderInviteView(),
        ));
  }

  muteInvitedUserVideo(int uid) {
    if (invitedUserPartyVideoMuted!.contains(uid)) {
      setState(() {
        invitedUserPartyVideoMuted!.remove(uid);
      });

      _engine.muteRemoteVideoStream(uid, false);
    } else {
      setState(() {
        invitedUserPartyVideoMuted!.add(uid);
      });

      _engine.muteRemoteVideoStream(uid, true);
    }
  }

  muteInvitedUserAudio(int uid) {
    if (invitedUserPartyAudioMuted!.contains(uid)) {
      setState(() {
        invitedUserPartyAudioMuted!.remove(uid);
      });

      _engine.muteRemoteAudioStream(uid, false);
    } else {
      setState(() {
        invitedUserPartyAudioMuted!.add(uid);
      });

      _engine.muteRemoteAudioStream(uid, true);
    }
  }

  //////////////////// INVITE ///////////////////

  Widget _showInvitation(LiveStreamingModel live) {
    UserModel user = live.getAuthor!;

    invitationIsShowing = true;

    return GestureDetector(
      onTap: () {},
      child: Container(
        color: Color.fromRGBO(0, 0, 0, 0.001),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Stack(clipBehavior: Clip.none, children: [
                    Scaffold(
                      backgroundColor: kTransparentColor,
                      appBar: AppBar(
                        backgroundColor: kTransparentColor,
                        automaticallyImplyLeading: false,
                      ),
                      body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: ContainerCorner(
                                height: 25,
                                width: MediaQuery.of(context).size.width,
                                marginLeft: 10,
                                marginRight: 10,
                                child: FittedBox(
                                    child: TextWithTap(
                                  user.getFullName!,
                                  color: Colors.white,
                                )),
                              ),
                            ),
                            SizedBox(
                              height: 30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ContainerCorner(
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/svg/ic_diamond.svg",
                                        width: 20,
                                        height: 20,
                                      ),
                                      TextWithTap(
                                        user.getDiamonds.toString(),
                                        color: Colors.white,
                                        marginLeft: 5,
                                      )
                                    ],
                                  ),
                                ),
                                ContainerCorner(
                                  marginLeft: 15,
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/svg/ic_followers_active.svg",
                                        width: 20,
                                        height: 20,
                                      ),
                                      TextWithTap(
                                        user.getFollowers!.length.toString(),
                                        color: Colors.white,
                                        marginLeft: 5,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Center(
                              child: TextWithTap(
                                "live_streaming.invitation_msg".tr(),
                                color: Colors.white,
                                marginTop: 15,
                                fontSize: 14,
                                marginBottom: 15,
                                marginLeft: 20,
                                marginRight: 20,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ContainerCorner(
                                  child: TextButton(
                                    child: TextWithTap(
                                      "live_streaming.deny_".tr().toUpperCase(),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    onPressed: () {
                                      invitationIsShowing = false;

                                      refuseInvitation(live);
                                    },
                                  ),
                                  color: kRedColor1,
                                  borderRadius: 10,
                                  marginRight: 10,
                                  width: 125,
                                ),
                                ContainerCorner(
                                  child: TextButton(
                                    child: TextWithTap(
                                      "live_streaming.participate_"
                                          .tr()
                                          .toUpperCase(),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    onPressed: () {
                                      invitationIsShowing = false;

                                      acceptInvitation(live);
                                    },
                                  ),
                                  color: kGreenColor,
                                  borderRadius: 10,
                                  marginLeft: 10,
                                  width: 125,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -30,
                      left: 1,
                      right: 1,
                      child: Center(
                        child: QuickActions.avatarWidget(user,
                            width: 70, height: 70),
                      ),
                    )
                  ]),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  acceptInvitation(LiveStreamingModel live) async {
    QuickHelp.hideLoadingDialog(context);

    widget.channelName = live.getStreamingChannel!;

    liveStreamingModel.removeInvitationLivePending();
    liveStreamingModel.setStreaming = false;

    await liveStreamingModel.save();

    widget.mUser = live.getAuthor;
    widget.isBroadcaster = false;
    widget.isUserInvited = true;

    isBroadcaster = false;
    isUserInvited = true;

    live.fetch().then((value) {
      LiveStreamingModel liveUpdated = value as LiveStreamingModel;

      liveStreamingModel = liveUpdated;
      //liveStreamingModel = liveUpdated;

      invitedUserParty = liveStreamingModel.getInvitedPartyUid!;
      invitedUserPartyShowing = liveStreamingModel.getInvitedPartyUid!;

      invitedUserPartyShowing!.remove(widget.currentUser.getUid);

      liveMessageObjectId = liveUpdated.objectId!;
      setState(() {});
    });

    await _engine.leaveChannel();
    await _engine.joinChannel(null, live.getStreamingChannel!,
        widget.currentUser.objectId, widget.currentUser.getUid!);

    liveQuery.client.unSubscribe(subscription!);

    updateViewers(
      widget.currentUser.getUid!,
      widget.currentUser.objectId!,
    );
  }

  refuseInvitation(LiveStreamingModel live) async {
    QuickHelp.hideLoadingDialog(context);
    QuickHelp.showAppNotificationAdvanced(
      user: live.getAuthor,
      title: "live_streaming.invitation_refused_title".tr(),
      message: "live_streaming.invitation_refused_explain"
          .tr(namedArgs: {"name": live.getAuthor!.getFirstName!}),
      isError: true,
      context: context,
    );

    liveStreamingModel.removeInvitationLivePending();
    await liveStreamingModel.save();

    live.removeInvitedPartyUid = widget.currentUser.getUid!;
    await live.save();
  }

  setupLiveMessage(String objectId) async {
    print("Gifts Live init");

    QueryBuilder<LiveMessagesModel> queryBuilder =
        QueryBuilder<LiveMessagesModel>(LiveMessagesModel());
    queryBuilder.whereEqualTo(
        LiveMessagesModel.keyLiveStreamingId, liveMessageObjectId);
    queryBuilder.whereEqualTo(
        LiveMessagesModel.keyMessageType, LiveMessagesModel.messageTypeGift);

    queryBuilder.includeObject(
        [LiveMessagesModel.keyGiftSent, LiveMessagesModel.keyGiftSentGift]);

    subscription = await liveQuery.client.subscribe(queryBuilder);

    subscription!.on(LiveQueryEvent.create,
        (LiveMessagesModel liveMessagesModel) async {
      showGift(liveMessagesModel.getGiftId!);
    });
  }

  showGift(String objectId) async {
    await player.setAsset("assets/audio/shake_results.mp3");

    QueryBuilder<GiftsModel> queryBuilder =
        QueryBuilder<GiftsModel>(GiftsModel());
    queryBuilder.whereEqualTo(GiftsModel.keyObjectId, objectId);
    ParseResponse parseResponse = await queryBuilder.query();

    if (parseResponse.success) {
      GiftsModel gift = parseResponse.results!.first! as GiftsModel;

      this.setState(() {
        liveGiftReceivedUrl = gift.getFile!.url!;
      });

      player.play();

      Future.delayed(Duration(seconds: Setup.maxSecondsToShowBigGift), () {
        this.setState(() {
          liveGiftReceivedUrl = "";
        });

        player.stop();
      });
    }
  }
}
