// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:wakelock/wakelock.dart';

import '../../app/setup.dart';
import '../../models/AudioChatUsersModel.dart';
import '../../models/LiveViewersModel.dart';
import '../../models/ReportModel.dart';
import '../../models/others/user_agora.dart';
import '../../services/dynamic_link_service.dart';
import '../../utils/shared_manager.dart';
import '../live_end/live_end_report_screen.dart';
import '../live_end/live_end_screen.dart';

// ignore: must_be_immutable
class VideoPartyScreen extends StatefulWidget {
  String channelName;
  bool isBroadcaster;
  bool isUserInvited;
  UserModel currentUser;
  UserModel? mUser;
  LiveStreamingModel? mLiveStreamingModel;
  final GiftsModel? giftsModel;
  SharedPreferences? preferences;

  VideoPartyScreen(
      {Key? key,
      required this.channelName,
      required this.isBroadcaster,
      this.isUserInvited = false,
      required this.currentUser,
      this.mUser,
      this.mLiveStreamingModel,
      this.giftsModel,
      this.preferences})
      : super(key: key);

  @override
  _VideoPartyScreenState createState() => _VideoPartyScreenState();
}

class _VideoPartyScreenState extends State<VideoPartyScreen>
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

  bool invitationIsShowing = false;

  int invitedToPartyBigIndex = 0;
  int invitedToPartyUidSelected = 0;

  AudioChatUsersModel? currentChatUser;

  TextEditingController textEditingController = TextEditingController();

  FocusNode chatTextFieldFocusNode = FocusNode();

  GiftsModel? selectedGif;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();
  String callDuration = "00:00";

  late QueryBuilder<AudioChatUsersModel> queryRoomUsersBuilder;

  KeyboardVisibilityController keyboardVisibilityController =
      KeyboardVisibilityController();

  final queryViewers = QueryBuilder(ParseObject(LiveViewersModel.keyTableName));

  ScrollController _scrollController = new ScrollController();

  Map<int, User> _userMap = new Map<int, User>();

  //bool _muted = false;
  int? localUid;

  getCurrentChatUser() async {
    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());
    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserId, widget.currentUser.objectId);
    queryBuilder.whereEqualTo(AudioChatUsersModel.keyCanTalk, true);
    ParseResponse response = await queryBuilder.query();
    if (response.success && response.results != null) {
      setState(() {
        currentChatUser = response.results!.first;
      });
    }
  }

  addUserToRoomList({required int seatIndex, required bool canTalk}) async {
    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());
    queryBuilder.whereEqualTo(AudioChatUsersModel.keySeatIndex, seatIndex);
    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId!);

    ParseResponse response = await queryBuilder.query();
    if (response.success && response.results != null) {
      AudioChatUsersModel audioChatUser = response.results!.first;

      audioChatUser.setLetTheRoom = false;
      audioChatUser.setCanUserTalk = canTalk;
      audioChatUser.setJoinedUser = widget.currentUser;
      audioChatUser.setJoinedUserId = widget.currentUser.objectId!;
      audioChatUser.setJoinedUserUid = widget.currentUser.getUid!;

      audioChatUser.save();
    }
  }

  checkCoHostPresenceBeforeAdd({required int seatIndex}) async {
    bool canTalk = false;
    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserId, widget.currentUser.objectId);

    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId!);

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserUID, widget.currentUser.getUid);

    ParseResponse response = await queryBuilder.query();

    if (response.success && response.results != null) {
      AudioChatUsersModel audioChatUser = response.results!.first;

      canTalk = audioChatUser.getCanUserTalk!;

      audioChatUser.removeJoinedUser();
      audioChatUser.removeJoinedUserId();
      audioChatUser.removeJoinedUserUid();
      audioChatUser.setCanUserTalk = false;
      ParseResponse responseFind = await audioChatUser.save();

      if (responseFind.success) {
        addUserToRoomList(
          seatIndex: seatIndex,
          canTalk: canTalk,
        );
      }
    } else {
      addUserToRoomList(
        seatIndex: seatIndex,
        canTalk: canTalk,
      );
    }
  }

  leaveRoomChair() async {
    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserId, widget.currentUser.objectId);

    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId!);

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserUID, widget.currentUser.getUid);

    ParseResponse response = await queryBuilder.query();

    if (response.success && response.results != null) {
      AudioChatUsersModel audioChatUser = response.results!.first;
      audioChatUser.removeJoinedUser();
      audioChatUser.removeJoinedUserId();
      audioChatUser.removeJoinedUserUid();
      audioChatUser.setCanUserTalk = false;
      audioChatUser.save();
    }
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

  removeUserFromChair({required AudioChatUsersModel audioChat}) async {
    muteRemoteUser(audioChat.getJoinedUser!);

    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserId, audioChat.getJoinedUserId);

    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId!);

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserUID, audioChat.getJoinedUserUid);

    ParseResponse response = await queryBuilder.query();

    if (response.success && response.results != null) {
      AudioChatUsersModel audioChatUser = response.results!.first;
      audioChatUser.removeJoinedUser();
      audioChatUser.removeJoinedUserId();
      audioChatUser.removeJoinedUserUid();
      audioChatUser.setCanUserTalk = false;
      audioChatUser.save();
    }
  }

  removeUserFromLive({required UserModel? user}) async {
    QueryBuilder<AudioChatUsersModel> queryBuilder =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());

    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserId, user!.objectId);
    queryBuilder.whereEqualTo(
        AudioChatUsersModel.keyJoinedUserUID, user.getUid);
    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLeftRoom, false);
    queryBuilder.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId);

    ParseResponse response = await queryBuilder.query();
    if (response.success && response.results != null) {
      AudioChatUsersModel audioChatUsers = response.results!.first;

      audioChatUsers.removeJoinedUser();
      audioChatUsers.removeJoinedUserId();
      audioChatUsers.removeJoinedUserUid();
      audioChatUsers.setCanUserTalk = false;
      audioChatUsers.save();
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
          setState(() {
            liveEnded = true;
          });
          _stopWatchTimer.onExecute.add(StopWatchExecute.reset);
          liveStreamingModel.setStreaming = false;
          liveStreamingModel.save();
        }
      }
    });
  }

  startTimerToConnectLive(BuildContext context, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      if (!liveJoined) {
        QuickHelp.showAppNotification(
          context: context,
          title: "can_not_try".tr(),
        );
        QuickHelp.goBackToPreviousPage(context);
      }
    });
  }

  @override
  void initState() {
    keyboardVisibilityController.onChange.listen((bool visible) {
      if (!visible) {
        setState(() {
          _showChat = false;
        });
        QuickHelp.removeFocusOnTextField(context);
      }
    });

    getCurrentChatUser();

    setState(() {
      if (isBroadcaster) {
        invitedToPartyUidSelected = widget.currentUser.getUid!;
        //invitedUserPartyShowing!.remove(widget.currentUser.getUid!);
      } else if (isUserInvited) {
        invitedToPartyUidSelected = widget.currentUser.getUid!;
        //invitedUserPartyShowing!.remove(widget.currentUser.getUid);
      } else {
        invitedToPartyUidSelected =
            widget.mLiveStreamingModel!.getAuthor!.getUid!;
        //invitedUserPartyShowing!.remove(widget.mUser!.getUid!);
      }
    });

    if (widget.mLiveStreamingModel != null) {
      liveStreamingModel = widget.mLiveStreamingModel!;
      liveMessageObjectId = liveStreamingModel.objectId!;
    }

    isBroadcaster = widget.isBroadcaster;
    isUserInvited = widget.isUserInvited;

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

    _stopWatchTimer.onExecute.add(StopWatchExecute.start);

    _animationController = AnimationController.unbounded(vsync: this);

    Wakelock.enable();
    _secureScreen(true);

    player = AudioPlayer();

    super.initState();
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
  void dispose() {
    Wakelock.disable();
    // clear users
    _users.clear();
    // destroy sdk and leave channel
    _engine.destroy();

    _userMap.clear();

    if (subscription != null) {
      liveQuery.client.unSubscribe(subscription!);
    }

    textEditingController.dispose();

    _secureScreen(false);
    player.dispose();

    super.dispose();
  }

  bool _showChat = false;
  bool visibleKeyBoard = false;
  bool visibleAudianceKeyBoard = false;

  void showChatState() {
    setState(() {
      _showChat = !_showChat;
    });
  }

  String liveTitle = "audio_chat.audio_chat".tr();

  Future<void> initializeAgora() async {
    startTimerToConnectLive(context, 10);

    await _initAgoraRtcEngine();

    if (!isBroadcaster &&
        widget.currentUser.getFollowing!.contains(widget.mUser!.objectId)) {
      following = true;
    }

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
          _userMap.clear();
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          _users.add(uid);
          _userMap.addAll({uid: User(uid, false)});
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
            _userMap.remove(uid);

            if (uid == widget.mUser!.getUid) {
              liveEnded = true;
              liveJoined = false;
            }
          });
        }
      },
    ));
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

  Future<void> _initAgoraRtcEngine() async {
    // Create RTC client instance

    RtcEngineContext context = RtcEngineContext(
        SharedManager().getStreamProviderKey(widget.preferences));
    _engine = await RtcEngine.createWithContext(context);

    if (isBroadcaster) {
      await _engine.startPreview();
    } else {
      addOrUpdateLiveViewers();
      _engine.muteLocalAudioStream(true);
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

    await _engine.setClientRole(ClientRole.Broadcaster);

    await _engine.joinChannel(
      null,
      widget.channelName,
      widget.currentUser.objectId!,
      widget.currentUser.getUid!,
    );

    print('AgoraLive Broadcaster');
  }

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () => closeAlert(),
      child: GestureDetector(
        onTap: () {
          showChatState();
          QuickHelp.removeFocusOnTextField(context);
          setState(() {
            _showChat = false;
          });
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
                child: IconButton(
                  onPressed: () => closeAlert(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    weight: 900,
                  ),
                ),
              ),
            ],
          ),
          body: ContainerCorner(
            marginBottom: 0,
            borderWidth: 0,
            height: size.height,
            width: size.width,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                ContainerCorner(
                  height: size.height,
                  width: size.width,
                  child: _getHostRenderViews(),
                ),
                ContainerCorner(
                  height: size.height,
                  width: size.width,
                  borderWidth: 0,
                  color: kContentColorLightTheme,
                ),
                ContainerCorner(
                  height: size.height,
                  width: size.width,
                  borderWidth: 0,
                  imageDecoration: "assets/images/audio_room_background.png",
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Visibility(
                      visible: isLiveJoined() && !liveEnded,
                      child: _getRenderViews(),
                    ),
                    Visibility(
                      visible: !isLiveJoined(),
                      child: ContainerCorner(
                        borderWidth: 0,
                        width: size.width,
                        height: size.height,
                        child: getLoadingScreen(),
                      ),
                    ),
                  ],
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
                if (_showChat)
                  Visibility(
                    visible: isLiveJoined() && !liveEnded,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: chatInputField(),
                    ),
                  ),
              ],
            ),
          ),
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
                      chatTextFieldFocusNode.requestFocus();
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
                            if (currentChatUser != null) {
                              openHostSettingsSheet(chatUser: currentChatUser!);
                            } else {
                              openSettingsSheet();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child:
                                Lottie.asset("assets/lotties/ic_menu_grid.json"),
                          ),
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

                                sendGift(
                                  giftsModel: gift,
                                  receiver:
                                      widget.mLiveStreamingModel!.getAuthor!,
                                );

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

  var basicOptionsCaption = [
    "audio_chat.message_".tr(),
    "audio_chat.sound_".tr(),
    "audio_chat.share_".tr(),
    "audio_chat.report_".tr(),
  ];

  var basicOptionsIcons = [
    "assets/svg/ic_reward.svg",
    "assets/svg/ic_rank.svg",
    "assets/svg/ic_store.svg",
    "assets/svg/ic_invite.svg",
  ];

  var playStyleOptionsCaption = [
    "audio_chat.rewards_".tr(),
    "audio_chat.store_".tr(),
    "audio_chat.vip_".tr(),
    "audio_chat.guardian_".tr()
  ];

  var playStyleOptionsIcons = [
    "assets/svg/ic_medal.svg",
    "assets/svg/ic_medal.svg",
    "assets/svg/ic_fans_club.svg",
    "assets/svg/ic_fans_club.svg"
  ];

  Widget options({required String caption, required String iconURL}) {
    Size size = MediaQuery.of(context).size;
    return ContainerCorner(
      marginTop: 5,
      marginBottom: 15,
      marginLeft: size.width / 13,
      marginRight: size.width / 20,
      child: Column(
        children: [
          SvgPicture.asset(
            iconURL,
            width: size.width / 13,
            height: size.width / 13,
            //color: kTra,
          ),
          TextWithTap(
            caption,
            marginTop: 10,
            color: Colors.white.withOpacity(0.7),
            fontSize: size.width / 38,
          ),
        ],
      ),
    );
  }

  void openSettingsSheet() async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.white.withOpacity(0.01),
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showSettingsSheet();
        });
  }

  Widget _showSettingsSheet() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: ContainerCorner(
        color: Colors.white.withOpacity(0.01),
        child: DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return StatefulBuilder(builder: (context, setState) {
              Size size = MediaQuery.of(context).size;
              return ContainerCorner(
                radiusTopRight: 20,
                radiusTopLeft: 20,
                color: Colors.black.withOpacity(0.8),
                child: Scaffold(
                  backgroundColor: kTransparentColor,
                  appBar: AppBar(
                    leadingWidth: size.width / 2,
                    automaticallyImplyLeading: false,
                    backgroundColor: kTransparentColor,
                    leading: TextWithTap(
                      "audio_chat.basic_tools".tr(),
                      color: Colors.white,
                      fontSize: 10,
                      marginLeft: 20,
                      marginTop: 10,
                    ),
                  ),
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          basicOptionsCaption.length,
                          (index) => options(
                              caption: basicOptionsCaption[index],
                              iconURL: basicOptionsIcons[index]),
                        ),
                      ),
                      TextWithTap(
                        "audio_chat.playstyle_".tr(),
                        color: Colors.white,
                        marginTop: 5,
                        marginBottom: 5,
                        fontSize: 10,
                        marginLeft: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          basicOptionsCaption.length,
                          (index) => options(
                              caption: playStyleOptionsCaption[index],
                              iconURL: playStyleOptionsIcons[index]),
                        ),
                      ),
                    ],
                  ),
                  //bottomNavigationBar: SafeArea(child: builderFooter(selectedBank: selectedBank)),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  void openHostSettingsSheet({required AudioChatUsersModel chatUser}) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.white.withOpacity(0.01),
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showHostSettingsSheet(chatUser: chatUser);
        });
  }

  Widget _showHostSettingsSheet({required AudioChatUsersModel chatUser}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: ContainerCorner(
        color: Colors.white.withOpacity(0.01),
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.1,
          maxChildSize: 1.0,
          builder: (_, controller) {
            return StatefulBuilder(builder: (context, setState) {
              Size size = MediaQuery.of(context).size;
              double btnSize = size.width / 7;
              return ContainerCorner(
                borderWidth: 0,
                color: Colors.black.withOpacity(0.3),
                child: Scaffold(
                  backgroundColor: kTransparentColor,
                  appBar: AppBar(
                    leadingWidth: size.width / 2,
                    automaticallyImplyLeading: false,
                    backgroundColor: kTransparentColor,
                  ),
                  body: ContainerCorner(
                    height: size.height,
                    width: size.width,
                    borderWidth: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  height: btnSize,
                                  width: btnSize,
                                  borderWidth: 0,
                                  borderRadius: 50,
                                  color: Colors.white,
                                  onTap: () {
                                    _onSwitchCamera();
                                    QuickHelp.hideLoadingDialog(context);
                                  },
                                  child: Lottie.asset(
                                    "assets/lotties/ic_switch_camera.json",
                                  ),
                                ),
                                TextWithTap(
                                  "live_streaming.switch_camera".tr(),
                                  color: Colors.white,
                                  fontSize: 10,
                                  alignment: Alignment.center,
                                  marginTop: 15,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  height: btnSize,
                                  width: btnSize,
                                  borderWidth: 0,
                                  borderRadius: 50,
                                  color: Colors.white,
                                  onTap: () {
                                    if (chatUser.getEnabledVideo!) {
                                      disableVideo(chatUser: chatUser);
                                    } else {
                                      enableVideo(chatUser: chatUser);
                                    }
                                    QuickHelp.hideLoadingDialog(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Lottie.asset(
                                        "assets/lotties/ic_toggle_video.json"),
                                  ),
                                ),
                                TextWithTap(
                                  "audio_chat.toggle_video".tr(),
                                  color: Colors.white,
                                  fontSize: 10,
                                  alignment: Alignment.center,
                                  marginTop: 15,
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  height: btnSize,
                                  width: btnSize,
                                  borderWidth: 0,
                                  borderRadius: 50,
                                  color: Colors.white,
                                  onTap: () {
                                    _onToggleMute();
                                    QuickHelp.hideLoadingDialog(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: muted
                                        ? Icon(Icons.mic_off, color: Colors.red)
                                        : Lottie.asset(
                                            "assets/lotties/ic_activated_mic.json",
                                          ),
                                  ),
                                ),
                                TextWithTap(
                                  "live_streaming.toggle_audio".tr(),
                                  color: Colors.white,
                                  fontSize: 10,
                                  alignment: Alignment.center,
                                  marginTop: 15,
                                ),
                              ],
                            ),
                          ],
                        ),
                        ContainerCorner(
                          marginTop: 60,
                          height: btnSize - 15,
                          width: btnSize - 15,
                          borderColor: Colors.white,
                          borderRadius: 50,
                          onTap: () => QuickHelp.hideLoadingDialog(context),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
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
                  //bottomNavigationBar: SafeArea(child: builderFooter(selectedBank: selectedBank)),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void disableVideo({required AudioChatUsersModel chatUser}) async {
    chatUser.setEnabledVideo = false;
    ParseResponse response = await chatUser.save();
    if (response.success && response.results != null) {
      _engine.disableVideo();
    } else {
      QuickHelp.showAppNotificationAdvanced(
          title: "error".tr(),
          context: context,
          message: "audio_chat.remove_failed_explain".tr());
    }
  }

  void enableVideo({required AudioChatUsersModel chatUser}) async {
    chatUser.setEnabledVideo = true;
    ParseResponse response = await chatUser.save();
    if (response.success && response.results != null) {
      _engine.enableVideo();
    } else {
      QuickHelp.showAppNotificationAdvanced(
          title: "error".tr(),
          context: context,
          message: "audio_chat.remove_failed_explain".tr());
    }
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
          currentUser: widget.currentUser,
          preferences: widget.preferences,
        ),
        back: false,
        finish: true,
      );
    });
  }

  var usersToPanel = [];

  _getAllUsers() {
    QueryBuilder<AudioChatUsersModel> query =
        QueryBuilder<AudioChatUsersModel>(AudioChatUsersModel());

    query.includeObject([
      AudioChatUsersModel.keyJoinedUser,
      AudioChatUsersModel.keyLiveStreaming,
    ]);

    query.whereEqualTo(AudioChatUsersModel.keyLiveStreamingId,
        widget.mLiveStreamingModel!.objectId);
    query.whereEqualTo(AudioChatUsersModel.keyLeftRoom, false);
    query.orderByAscending(AudioChatUsersModel.keySeatIndex);

    bool showTwoColumn = false;
    bool showThreeColumn = false;
    if (widget.mLiveStreamingModel!.getNumberOfChairs == 4) {
      showTwoColumn = true;
    } else if (widget.mLiveStreamingModel!.getNumberOfChairs == 6) {
      showThreeColumn = true;
    }

    return ParseLiveGridWidget<AudioChatUsersModel>(
      query: query,
      reverse: false,
      lazyLoading: false,
      crossAxisCount: showTwoColumn ? 2 : 3,
      crossAxisSpacing: 0,
      scrollPhysics: NeverScrollableScrollPhysics(),
      primary: false,
      mainAxisSpacing: 0,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      duration: const Duration(milliseconds: 200),
      animationController: _animationController,
      childAspectRatio: showTwoColumn
          ? 1.0
          : showThreeColumn
              ? 0.7
              : 1.1,
      listeningIncludes: [
        AudioChatUsersModel.keyJoinedUser,
        AudioChatUsersModel.keyLiveStreaming,
      ],
      listenOnAllSubItems: true,
      childBuilder: (BuildContext context,
          ParseLiveListElementSnapshot<AudioChatUsersModel> snapshot) {
        if (snapshot.hasData) {
          AudioChatUsersModel joinedUser = snapshot.loadedData!;
          if (joinedUser.getJoinedUserId == widget.currentUser.objectId) {
            currentChatUser = joinedUser;
          }
          return userDetails(
            index: joinedUser.getSeatIndex!,
            filled: joinedUser.getJoinedUser != null,
            user: joinedUser.getJoinedUser,
            canTalk: joinedUser.getCanUserTalk!,
            audioChatUsersModel: joinedUser,
            showTwoColumn: showTwoColumn,
            enabledVideo: joinedUser.getEnabledVideo!,
          );
        } else {
          return Container();
        }
      },
      queryEmptyElement: Container(),
      gridLoadingElement: Container(),
    );
  }

  Widget _getRenderViews() {
    Size size = MediaQuery.of(context).size;

    return ContainerCorner(
      width: size.width,
      height: size.height,
      borderWidth: 0,
      child: Stack(
        children: [
          ContainerCorner(
            height: size.height,
            width: size.width,
            borderWidth: 0,
            imageDecoration: "assets/images/audio_room_background.png",
          ),
          if(widget.mLiveStreamingModel!.getPartyTheme != null && widget.mLiveStreamingModel!.getAuthor!.getCanUsePartyTheme!)
            QuickActions.photosWidget(
              widget.mLiveStreamingModel!.getPartyTheme!.url!,
              height: size.height,
              width: size.width,
              borderRadius: 0,
            ),
          if(widget.mLiveStreamingModel!.getPartyTheme != null && widget.mLiveStreamingModel!.getAuthor!.getCanUsePartyTheme!)
            ContainerCorner(
              height: size.height,
              width: size.width,
              borderWidth: 0,
              color: Colors.black.withOpacity(0.5),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 3,
                child: ContainerCorner(
                  width: size.width,
                  borderWidth: 0,
                  color: kTransparentColor,
                  child: _getAllUsers(),
                ),
              ),
              ContainerCorner(
                width: size.width,
                borderWidth: 0,
                color: kTransparentColor,
                marginBottom: 50,
                child: liveMessages(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getHostRenderViews() {
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

  Widget getCoHostRenderView({required int userUid}) {
    if (userUid == widget.currentUser.getUid)
      return RtcLocalView.SurfaceView(
        channelId: widget.channelName,
      );
    else
      return RtcRemoteView.SurfaceView(
        channelId: widget.channelName,
        uid: userUid,
      );
  }

  givePermissionToUser(
      {required AudioChatUsersModel audioChatUsersModel}) async {
    audioChatUsersModel.setCanUserTalk = true;
    audioChatUsersModel.setEnabledVideo = true;
    ParseResponse response = await audioChatUsersModel.save();

    if (response.success && response.results != null) {
      unMuteRemoteUser(audioChatUsersModel.getJoinedUser!);
    } else {
      QuickHelp.showAppNotificationAdvanced(
        title: "audio_chat.failed_to_allow_title".tr(),
        message: "audio_chat.failed_to_allow_explain".tr(),
        context: context,
      );
    }
  }

  denyPermissionToUser(
      {required AudioChatUsersModel audioChatUsersModel}) async {
    audioChatUsersModel.setCanUserTalk = false;
    audioChatUsersModel.removeJoinedUser();
    audioChatUsersModel.removeJoinedUserId();
    audioChatUsersModel.removeJoinedUserUid();

    ParseResponse response = await audioChatUsersModel.save();

    if (response.success && response.results != null) {
      muteRemoteUser(audioChatUsersModel.getJoinedUser!);
    } else {
      QuickHelp.showAppNotificationAdvanced(
        title: "audio_chat.error_denying_title".tr(),
        message: "audio_chat.failed_to_allow_explain".tr(),
        context: context,
      );
    }
  }

  Widget userDetails({
    UserModel? user,
    required int index,
    required bool filled,
    required bool canTalk,
    required bool showTwoColumn,
    required bool enabledVideo,
    required AudioChatUsersModel audioChatUsersModel,
  }) {
    Size size = MediaQuery.of(context).size;
    if (user == null) {
      return ContainerCorner(
        color: showTwoColumn ? isTwoColumn(index) : isPar(index),
        onTap: () {
          if (!isBroadcaster) {
            checkCoHostPresenceBeforeAdd(seatIndex: index);
          }
        },
        borderWidth: 0,
        child: Column(
          children: [
            Row(
              children: [
                ContainerCorner(
                  height: 15,
                  width: 20,
                  radiusBottomRight: 10,
                  borderWidth: 0,
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: TextWithTap(
                      "${index + 1}",
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child: SvgPicture.asset(
                "assets/svg/ic_add_sofa.svg",
                width: size.width / 12.5,
                height: size.width / 12.5,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    } else {
      if (canTalk) {
        return Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            ContainerCorner(
              borderWidth: 0,
              color: showTwoColumn ? isTwoColumn(index) : isPar(index),
              onTap: () {
                if (audioChatUsersModel.getJoinedUserId !=
                    widget.currentUser.objectId) {
                  openUserOptions(audioChatUsersModel);
                } else if (user.objectId == widget.currentUser.objectId) {
                  openHostSettingsSheet(chatUser: audioChatUsersModel);
                }
              },
              child: enabledVideo
                  ? Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        Visibility(
                          visible: index == 0,
                          child: ContainerCorner(
                            height: double.infinity,
                            width: double.infinity,
                            child: _getHostRenderViews(),
                            borderWidth: 0,
                          ),
                        ),
                        Visibility(
                          visible: index != 0,
                          child: ContainerCorner(
                            height: double.infinity,
                            width: double.infinity,
                            child: getCoHostRenderView(userUid: user.getUid!),
                            borderWidth: 0,
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ContainerCorner(
                                  height: 15,
                                  width: 20,
                                  radiusBottomRight: 10,
                                  colors: filled
                                      ? [Colors.amber, Colors.yellow]
                                      : [Colors.transparent, Colors.transparent],
                                  child: Center(
                                    child: index == 0
                                        ? Icon(
                                            Icons.home_filled,
                                            color: Colors.white,
                                            size: 12,
                                          )
                                        : TextWithTap(
                                            "${index + 1}",
                                            color: Colors.white,
                                            fontSize: 9,
                                          ),
                                  ),
                                ),
                                ContainerCorner(
                                  height: 15,
                                  borderRadius: 50,
                                  marginRight: 3,
                                  marginTop: 3,
                                  color: Colors.black.withOpacity(0.3),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 5),
                                        child: SvgPicture.asset(
                                          "assets/svg/ic_coin_rose.svg",
                                          height: 10,
                                          width: 10,
                                        ),
                                      ),
                                      TextWithTap(
                                        QuickHelp.convertToK(
                                            user.getDiamondsTotal!),
                                        color: Colors.white,
                                        fontSize: 10,
                                        marginRight: 5,
                                        marginLeft: 5,
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Visibility(
                              visible: filled,
                              child: Expanded(
                                child: SizedBox(),
                              ),
                            ),
                            Visibility(
                              visible: !audioChatUsersModel.getEnabledAudio!,
                              child: ContainerCorner(
                                height: 35,
                                width: 35,
                                borderWidth: 0,
                                borderRadius: 50,
                                marginTop: 5,
                                marginBottom: 5,
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.mic_off, color: Colors.red),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 3,
                                bottom: 5,
                                right: 3,
                              ),
                              child: TextScroll(
                                hostNames(user: user),
                                mode: TextScrollMode.endless,
                                velocity: Velocity(pixelsPerSecond: Offset(80, 0)),
                                delayBefore: Duration(seconds: 1),
                                pauseBetween: Duration(milliseconds: 50),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.left,
                                selectable: true,
                                intervalSpaces: 1,
                                numberOfReps: 99,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Stack(
                      alignment: AlignmentDirectional.center,
                      children: [
                        QuickActions.profileCover(
                          user.getAvatar!.url!,
                          borderRadius: 0,
                          height: double.infinity,
                          width: double.infinity,
                        ),
                        ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ContainerCorner(
                                        height: 15,
                                        width: 20,
                                        radiusBottomRight: 10,
                                        colors: filled
                                            ? [Colors.amber, Colors.yellow]
                                            : [
                                                Colors.transparent,
                                                Colors.transparent
                                              ],
                                        child: Center(
                                          child: index == 0
                                              ? Icon(
                                                  Icons.home_filled,
                                                  color: Colors.white,
                                                  size: 12,
                                                )
                                              : TextWithTap(
                                                  "${index + 1}",
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                ),
                                        ),
                                      ),
                                      ContainerCorner(
                                        height: 15,
                                        borderRadius: 50,
                                        marginRight: 3,
                                        marginTop: 3,
                                        color: Colors.black.withOpacity(0.3),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(left: 5),
                                              child: SvgPicture.asset(
                                                "assets/svg/ic_coin_rose.svg",
                                                height: 10,
                                                width: 10,
                                              ),
                                            ),
                                            TextWithTap(
                                              QuickHelp.convertToK(
                                                  user.getDiamondsTotal!),
                                              color: Colors.white,
                                              fontSize: 10,
                                              marginRight: 5,
                                              marginLeft: 5,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: QuickActions.avatarBorder(
                                      user,
                                      width: showTwoColumn
                                          ? size.width / 5.0
                                          : size.width / 6.5,
                                      height: showTwoColumn
                                          ? size.width / 5.0
                                          : size.width / 6.5,
                                      borderColor: Colors.white,
                                    ),
                                  ),
                                  Visibility(
                                    visible: !audioChatUsersModel.getEnabledAudio!,
                                    child: ContainerCorner(
                                      height: 35,
                                      width: 35,
                                      borderWidth: 0,
                                      borderRadius: 50,
                                      marginTop: 5,
                                      marginBottom: 5,
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child:
                                            Icon(Icons.mic_off, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 3,
                                      bottom: 5,
                                      right: 3,
                                    ),
                                    child: TextScroll(
                                      hostNames(user: user),
                                      mode: TextScrollMode.endless,
                                      velocity:
                                          Velocity(pixelsPerSecond: Offset(80, 0)),
                                      delayBefore: Duration(seconds: 1),
                                      pauseBetween: Duration(milliseconds: 50),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.left,
                                      selectable: true,
                                      intervalSpaces: 1,
                                      numberOfReps: 99,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Visibility(
              visible: !isBroadcaster && widget.currentUser.objectId == audioChatUsersModel.getJoinedUserId,
              child: ContainerCorner(
                  height: 25,
                  width: 25,
                  onTap: ()=> removeUserFromChair(audioChat: audioChatUsersModel),
                  borderRadius: 50,
                  color: Colors.red,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.white, size: 11),
                  )
              ),
            ),
          ],
        );
      } else {
        return ContainerCorner(
          borderWidth: 0,
          onTap: () {
            if (isBroadcaster) {
              openInvitationBottomSheet(
                  audioChatUsersModel: audioChatUsersModel);
            }
          },
          child: Stack(
            children: [
              QuickActions.avatarWidget(
                user,
                width: double.infinity,
                height: double.infinity,
              ),
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: TextWithTap(
                        "audio_chat.wait_permission".tr().toLowerCase(),
                        color: Colors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String hostNames({required UserModel user}) {
    if (user.objectId == widget.currentUser.objectId) {
      return "audio_chat.me_".tr();
    } else {
      return user.getFullName!;
    }
  }

  Color isPar(int number) {
    if ((number % 2) == 0) {
      return Colors.white.withOpacity(0.1);
    } else {
      return Colors.black.withOpacity(0.2);
    }
  }

  Color isTwoColumn(int number) {
    if (number == 0 || number == 3) {
      return Colors.white.withOpacity(0.1);
    } else {
      return Colors.black.withOpacity(0.2);
    }
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
            "audio_chat.video_party".tr(),
            textAlign: TextAlign.center,
            alignment: Alignment.center,
          ),
        ]),
        //color: Colors.blue,
      );
    }
  }

  void followOrUnfollow({UserModel? user}) async {
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

  void followOrUnfollowUser(UserModel user) async {
    if (widget.currentUser.getFollowing!.contains(user.objectId)) {
      widget.currentUser.removeFollowing = user.objectId!;

      setState(() {
        following = false;
      });
    } else {
      widget.currentUser.setFollowing = user.objectId!;

      setState(() {
        following = true;
      });
    }

    await widget.currentUser.save();

    ParseResponse parseResponse = await QuickCloudCode.followUser(
        isFollowing: false, author: widget.currentUser, receiver: user);

    if (parseResponse.success) {
      QuickActions.createOrDeleteNotification(widget.currentUser, user,
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

  void saveLiveUpdate() async {
    if (isBroadcaster) {
      liveStreamingModel.setStreaming = false;
      await liveStreamingModel.save();
      _engine.leaveChannel();
    } else {
      QuickHelp.showLoadingDialog(context);

      leaveRoomChair();
      sendMessage(LiveMessagesModel.messageTypeLeave, "", widget.currentUser);

      onViewerLeave();

      if (liveJoined) {
        liveStreamingModel.removeViewersCount = 1;

        liveStreamingModel.removeInvitedPartyUid = widget.currentUser.getUid!;
        liveStreamingModel.removeViewersId = widget.currentUser.objectId!;

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
    if (muted) {
      selfMute();
    } else {
      selfEnableAudio();
    }
  }

  selfMute() async {
    currentChatUser!.setEnabledAudio = false;
    currentChatUser!.save();
  }

  selfEnableAudio() async {
    currentChatUser!.setEnabledAudio = true;
    currentChatUser!.save();
  }

  updateViewers(int uid, String objectId) async {
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

      if (!isBroadcaster) {
        sendMessage(LiveMessagesModel.messageTypeJoin, "", widget.currentUser);
      }

      setupCounterLive(liveStreamingModel.objectId!);
      setupCounterLiveUser();
      setupLiveMessage(liveStreamingModel.objectId!);
    }
  }

  createLive(LiveStreamingModel liveStreamingModel) async {
    liveStreamingModel.setStreaming = true;
    liveStreamingModel.setLiveType = LiveStreamingModel.liveAudio;
    liveStreamingModel.addInvitedPartyUid = [widget.currentUser.getUid];

    ParseResponse parseResponse = await liveStreamingModel.save();
    if (parseResponse.success) {
      setupCounterLive(liveStreamingModel.objectId!);
      setupCounterLiveUser();
      setupLiveMessage(liveStreamingModel.objectId!);

      SendNotifications.sendPush(
        widget.currentUser,
        widget.currentUser,
        SendNotifications.typeLive,
        objectId: liveStreamingModel.objectId!,
      );
    }
  }

  void openUserOptions(AudioChatUsersModel audioChat) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showUserOptions(audioChat);
        });
  }

  Widget _showUserOptions(AudioChatUsersModel audioChat) {
    bool isMuted = widget.currentUser.getDiamonds! > 10;
    /*bool isMuted = liveStreamingModel.getMutedUserIds!
        .contains(audioChat.getJoinedUser!.objectId);*/
    bool isFollowed = widget.currentUser.getFollowing!
        .contains(audioChat.getJoinedUser!.objectId);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (_, controller) {
              return StatefulBuilder(builder: (context, setState) {
                Size size = MediaQuery.of(context).size;
                return Container(
                  decoration: const BoxDecoration(
                    color: kTransparentColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                  ),
                  child: Scaffold(
                    backgroundColor: kTransparentColor,
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          ContainerCorner(
                            marginRight: 20,
                            marginLeft: 20,
                            borderRadius: 8,
                            marginBottom: 25,
                            width: size.width,
                            color: Colors.white.withOpacity(0.2),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  QuickActions.avatarWidget(
                                    audioChat.getJoinedUser!,
                                    width: size.width / 3.5,
                                    height: size.width / 3.4,
                                  ),
                                  TextWithTap(
                                    audioChat.getJoinedUser!.getFullName!,
                                    color: Colors.white,
                                    marginTop: 10,
                                    marginBottom: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      details(
                                        quantity:
                                            "${audioChat.getJoinedUser!.getFollowing!.length}",
                                        legend: "audio_chat.following".tr(),
                                      ),
                                      details(
                                        quantity:
                                            "${audioChat.getJoinedUser!.getFollowers!.length}",
                                        legend: "audio_chat.followers".tr(),
                                      ),
                                      details(
                                        quantity:
                                            "${audioChat.getJoinedUser!.getDiamondsTotal!}",
                                        legend: "audio_chat.diamonds".tr(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !isFollowed,
                            child: ContainerCorner(
                              marginRight: 20,
                              marginLeft: 20,
                              borderRadius: 8,
                              marginBottom: 25,
                              height: 45,
                              width: size.width,
                              color: Colors.white.withOpacity(0.2),
                              onTap: () {
                                QuickHelp.goBackToPreviousPage(context);
                                followOrUnfollowUser(audioChat.getJoinedUser!);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add,
                                    color: Colors.red,
                                    size: 17,
                                  ),
                                  TextWithTap(
                                    "audio_chat.start_follow".tr(namedArgs: {
                                      "name":
                                          audioChat.getJoinedUser!.getFullName!
                                    }),
                                    color: Colors.white,
                                    marginLeft: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ContainerCorner(
                            marginRight: 20,
                            marginLeft: 20,
                            borderRadius: 8,
                            marginBottom: 25,
                            height: 45,
                            width: size.width,
                            color: Colors.white.withOpacity(0.2),
                            onTap: () {
                              CoinsFlowPayment(
                                context: context,
                                currentUser: widget.currentUser,
                                onCoinsPurchased: (coins) {
                                  print(
                                      "onCoinsPurchased: $coins new: ${widget.currentUser.getCredits}");
                                },
                                onGiftSelected: (gift) {
                                  print(
                                      "onGiftSelected called ${gift.getCoins}");
                                  sendGift(
                                    giftsModel: gift,
                                    receiver: audioChat.getJoinedUser!,
                                  );

                                  QuickHelp.goBackToPreviousPage(context);
                                  QuickHelp.showAppNotificationAdvanced(
                                    context: context,
                                    user: widget.currentUser,
                                    title:
                                        "live_streaming.gift_sent_title".tr(),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(7.0),
                                  child: Lottie.asset(
                                      "assets/lotties/ic_gift.json"),
                                ),
                                TextWithTap(
                                  "audio_chat.send_gift".tr(namedArgs: {
                                    "name":
                                        audioChat.getJoinedUser!.getFirstName!
                                  }),
                                  color: Colors.white,
                                  marginLeft: 5,
                                ),
                              ],
                            ),
                          ),
                          ContainerCorner(
                            marginRight: 20,
                            marginLeft: 20,
                            borderRadius: 8,
                            marginBottom: 25,
                            height: 45,
                            width: size.width,
                            color: Colors.white.withOpacity(0.2),
                            onTap: () {
                              QuickActions.showUserProfile(
                                context,
                                widget.currentUser,
                                audioChat.getJoinedUser!,
                                preferences: widget.preferences!,
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_pin,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                TextWithTap(
                                  "audio_chat.go_to_profile".tr(namedArgs: {
                                    "name":
                                        audioChat.getJoinedUser!.getFirstName!
                                  }),
                                  color: Colors.white,
                                  marginLeft: 5,
                                ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: isBroadcaster,
                            child: ContainerCorner(
                              marginRight: 20,
                              marginLeft: 20,
                              borderRadius: 8,
                              marginBottom: 15,
                              width: size.width,
                              color: Colors.white.withOpacity(0.2),
                              height: 45,
                              onTap: () {
                                if (audioChat.getUserSelfMutedAudioIds!
                                    .contains(audioChat.getJoinedUserId)) {
                                  QuickHelp.showAppNotificationAdvanced(
                                    title:
                                        "audio_chat.cannot_toggle_remote_mic_title"
                                            .tr(),
                                    message:
                                        "audio_chat.cannot_toggle_remote_mic_explain"
                                            .tr(namedArgs: {
                                      "name":
                                          audioChat.getJoinedUser!.getFirstName!
                                    }),
                                    context: context,
                                  );
                                } else {
                                  if (isMuted) {
                                    unMuteRemoteUser(audioChat.getJoinedUser!);
                                    hideMutedIcon(audioChat);
                                  } else {
                                    muteRemoteUser(audioChat.getJoinedUser!);
                                    showMutedIcon(audioChat);
                                  }
                                }

                                QuickHelp.goBackToPreviousPage(context);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isMuted ? Icons.mic : Icons.mic_off,
                                    color: isMuted ? Colors.green : Colors.red,
                                    size: 17,
                                  ),
                                  TextWithTap(
                                    isMuted
                                        ? "audio_chat.enable_mic".tr(
                                            namedArgs: {
                                                "name": audioChat.getJoinedUser!
                                                    .getFirstName!
                                              })
                                        : "audio_chat.mute_mic".tr(namedArgs: {
                                            "name": audioChat
                                                .getJoinedUser!.getFirstName!
                                          }),
                                    color: Colors.white,
                                    marginLeft: 5,
                                  )
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: isBroadcaster,
                            child: ContainerCorner(
                              marginRight: 20,
                              marginLeft: 20,
                              borderRadius: 8,
                              marginBottom: 15,
                              width: size.width,
                              color: Colors.white.withOpacity(0.2),
                              height: 45,
                              onTap: () {
                                QuickHelp.goBackToPreviousPage(context);
                                removeUserFromChair(audioChat: audioChat);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 17,
                                  ),
                                  TextWithTap(
                                    "audio_chat.remove_as_co_host"
                                        .tr(namedArgs: {
                                      "name":
                                          audioChat.getJoinedUser!.getFirstName!
                                    }),
                                    color: Colors.white,
                                    marginLeft: 5,
                                  )
                                ],
                              ),
                            ),
                          ),
                          Visibility(
                            visible: isBroadcaster,
                            child: ContainerCorner(
                              marginRight: 20,
                              marginLeft: 20,
                              borderRadius: 8,
                              marginBottom: 15,
                              width: size.width,
                              color: Colors.white.withOpacity(0.2),
                              height: 45,
                              onTap: () {
                                QuickHelp.goBackToPreviousPage(context);
                                removeRemoteUser(audioChat.getJoinedUser!);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 17,
                                  ),
                                  TextWithTap(
                                    "audio_chat.remove_from_live"
                                        .tr(namedArgs: {
                                      "name":
                                          audioChat.getJoinedUser!.getFirstName!
                                    }),
                                    color: Colors.white,
                                    marginLeft: 5,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //bottomNavigationBar: SafeArea(child: builderFooter(selectedBank: selectedBank)),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  removeRemoteUser(UserModel user) async {
    widget.mLiveStreamingModel!.addRemovedUserIds = user.objectId!;
    ParseResponse response = await widget.mLiveStreamingModel!.save();
    if (response.success) {
      sendMessage(
        LiveMessagesModel.messageTypeRemoved,
        "",
        user,
      );
      removeUserFromLive(user: user);
    } else {
      QuickHelp.showAppNotificationAdvanced(
          title: "audio_chat.remove_failed_title".tr(),
          context: context,
          message: "audio_chat.remove_failed_explain".tr());
    }
  }

  muteRemoteUser(UserModel user) async {
    widget.mLiveStreamingModel!.addMutedUserIds = user.objectId!;
    widget.mLiveStreamingModel!.removeUnMutedUserIds = user.objectId!;
    ParseResponse response = await widget.mLiveStreamingModel!.save();

    if (response.success) {
      _engine.muteRemoteAudioStream(user.getUid!, true);
    } else {
      QuickHelp.showAppNotificationAdvanced(
          title: "audio_chat.remove_failed_title".tr(),
          context: context,
          message: "audio_chat.remove_failed_explain".tr());
    }
  }

  unMuteRemoteUser(UserModel user) async {
    widget.mLiveStreamingModel!.removeMutedUserIds = user.objectId!;
    widget.mLiveStreamingModel!.addUnMutedUserIds = user.objectId!;
    ParseResponse response = await widget.mLiveStreamingModel!.save();

    if (response.success) {
      _engine.muteRemoteAudioStream(user.getUid!, false);
    } else {
      QuickHelp.showAppNotificationAdvanced(
          title: "audio_chat.remove_failed_title".tr(),
          context: context,
          message: "audio_chat.remove_failed_explain".tr());
    }
  }

  showMutedIcon(AudioChatUsersModel audioChatUser) {
    audioChatUser.addUserMutedByHostIds = audioChatUser.getJoinedUserId!;
    audioChatUser.save();
  }

  hideMutedIcon(AudioChatUsersModel audioChatUser) {
    audioChatUser.removeUserMutedByHostIds = audioChatUser.getJoinedUserId!;
    audioChatUser.save();
  }

  Widget details({required String quantity, required String legend}) {
    return ContainerCorner(
      child: Column(
        children: [
          TextWithTap(
            quantity,
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          TextWithTap(
            legend,
            color: Colors.white.withOpacity(0.8),
          ),
        ],
      ),
    );
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

  void openInvitationBottomSheet(
      {required AudioChatUsersModel audioChatUsersModel}) async {
    showModalBottomSheet(
        context: (context),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        isDismissible: true,
        builder: (context) {
          return _showInvitation(audioChatUsersModel: audioChatUsersModel);
        });
  }

  Widget _showInvitation({required AudioChatUsersModel audioChatUsersModel}) {
    Size size = MediaQuery.of(context).size;
    UserModel user = audioChatUsersModel.getJoinedUser!;
    return ContainerCorner(
      color: Colors.black.withOpacity(0.05),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.1,
        maxChildSize: 1.0,
        builder: (_, controller) {
          return StatefulBuilder(
            builder: (context, setState) {
              return ContainerCorner(
                color: Colors.black.withOpacity(0.1),
                child: ContainerCorner(
                  borderWidth: 0,
                  imageDecoration: "assets/images/invite_bg.png",
                  fit: BoxFit.fill,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        QuickActions.avatarBorder(
                          user,
                          width: size.width / 3,
                          height: size.width / 3,
                          borderColor: Colors.white,
                        ),
                        TextWithTap(
                          user.getFullName!,
                          color: Colors.white,
                          fontSize: size.width / 18,
                          fontWeight: FontWeight.w600,
                          marginTop: 25,
                        ),
                        TextWithTap(
                          "audio_chat.want_join_live".tr().toLowerCase(),
                          color: Colors.white,
                          fontSize: size.width / 22,
                          alignment: Alignment.center,
                          textAlign: TextAlign.center,
                          marginTop: 7,
                          marginBottom: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ContainerCorner(
                              imageDecoration:
                                  "assets/images/ic_live_top_btn.png",
                              height: 45,
                              marginLeft: 30,
                              width: size.width / 3,
                              onTap: () {
                                QuickHelp.goBackToPreviousPage(context);
                                denyPermissionToUser(
                                    audioChatUsersModel: audioChatUsersModel);
                              },
                              child: Center(
                                child: TextWithTap(
                                  "deny_".tr(),
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ContainerCorner(
                              imageDecoration: "assets/images/white_btn.png",
                              height: 45,
                              fit: BoxFit.fill,
                              marginRight: 30,
                              width: size.width / 3,
                              onTap: () {
                                QuickHelp.goBackToPreviousPage(context);
                                givePermissionToUser(
                                    audioChatUsersModel: audioChatUsersModel);
                              },
                              child: Center(
                                child: TextWithTap(
                                  "accept_".tr(),
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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
      LiveStreamingModel.keyAudioHostsList,
    ]);

    subscription = await liveQuery.client.subscribe(query);

    subscription!.on(LiveQueryEvent.update, (LiveStreamingModel value) async {
      print('*** UPDATE ***');
      liveStreamingModel = value;
      liveStreamingModel = value;

      if (value.getRemovedUserIds!.contains(widget.currentUser.objectId)) {
        _onCallEnd(context);
        QuickHelp.showAppNotificationAdvanced(
          title: "audio_chat.notify_removed_user_title".tr(),
          message: "audio_chat.notify_removed_user_explain".tr(),
          context: context,
        );
      }

      if (value.isLiveCancelledByAdmin == true &&
          isBroadcaster &&
          liveEndAlerted == false) {
        print('*** UPDATE *** is isLiveCancelledByAdmin: ${value.getPrivate}');
        closeAdminAlert();

        liveEndAlerted = true;
        return;
      }

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
        LiveStreamingModel.keyAudioHostsList,
      ]);
      ParseResponse response = await query2.query();

      if (response.success) {
        LiveStreamingModel updatedLive =
            response.results!.first as LiveStreamingModel;

        if (updatedLive.getPrivate == true && !isBroadcaster) {
          print('*** UPDATE *** is Private: ${updatedLive.getPrivate}');
        } else if (updatedLive.getInvitationLivePending != null) {
          print('*** UPDATE *** is not Private: ${updatedLive.getPrivate}');
        }
      }
    });

    subscription!.on(LiveQueryEvent.enter, (LiveStreamingModel value) {
      print('*** ENTER ***');

      liveStreamingModel = value;
      liveStreamingModel = value;

      setState(() {
        liveCounter = liveStreamingModel.getViewersCount.toString();
        diamondsCounter = liveStreamingModel.getDiamonds.toString();
      });
    });
  }

  Widget chatInputField() {
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

  sendMessage(String messageType, String message, UserModel author,
      {GiftsSentModel? giftsSent, UserModel? giftReceiver}) async {
    if (messageType == LiveMessagesModel.messageTypeGift) {
      liveStreamingModel.addDiamonds = QuickHelp.getDiamondsForReceiver(
          giftsSent!.getDiamondsQuantity!, widget.preferences!);

      liveStreamingModel.setCoHostAuthorUid = author.getUid!;
      liveStreamingModel.addAuthorTotalDiamonds =
          QuickHelp.getDiamondsForReceiver(
              giftsSent.getDiamondsQuantity!, widget.preferences!);
      await liveStreamingModel.save();

      addOrUpdateGiftSender(giftsSent.getGift!);

      await QuickCloudCode.sendGift(
        author: giftReceiver!,
        credits: giftsSent.getDiamondsQuantity!,
        preferences: widget.preferences,
      );
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
      height: size.height / 3.2,
      width: size.width / 1.3,
      marginBottom: 15,
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
          user: liveMessages.getAuthor,
        );
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
          LiveMessagesModel.messageTypeLeave) {
        return messageAvatar(
            nameOrYou(liveMessages),
            "audio_chat.user_left_chat".tr(),
            liveMessages.getAuthor!.getAvatar!.url!,
            user: liveMessages.getAuthor);
      } else if (liveMessages.getMessageType ==
          LiveMessagesModel.messageTypeRemoved) {
        return messageAvatar(
          nameOrYou(liveMessages),
          "audio_chat.user_removed_from_chat".tr(),
          liveMessages.getAuthor!.getAvatar!.url!,
          user: liveMessages.getAuthor,
        );
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

  sendGift(
      {required GiftsModel giftsModel, required UserModel receiver}) async {
    GiftsSentModel giftsSentModel = new GiftsSentModel();
    giftsSentModel.setAuthor = widget.currentUser;
    giftsSentModel.setAuthorId = widget.currentUser.objectId!;

    giftsSentModel.setReceiver = receiver;
    giftsSentModel.setReceiverId = receiver.objectId!;

    giftsSentModel.setGift = giftsModel;
    giftsSentModel.setGiftId = giftsModel.objectId!;
    giftsSentModel.setCounterDiamondsQuantity = giftsModel.getCoins!;
    await giftsSentModel.save();

    QuickHelp.saveReceivedGifts(
        receiver: receiver, author: widget.currentUser, gift: giftsModel);
    QuickHelp.saveCoinTransaction(
      receiver: receiver,
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
          giftsSent: giftsSentModel, giftReceiver: receiver);
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

  updateCurrentUserCredit(int coins) async {
    widget.currentUser.removeCredit = coins;
    ParseResponse response = await widget.currentUser.save();
    if (response.success) {
      widget.currentUser = response.results!.first as UserModel;
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
        GiftsSenderModel.keyAuthor, widget.currentUser);
    queryGiftSender.whereEqualTo(GiftsSenderModel.keyReceiverId,
        widget.mLiveStreamingModel!.getAuthorId);
    queryGiftSender.whereEqualTo(
        GiftsSenderModel.keyLiveId, liveStreamingModel.objectId!);

    ParseResponse parseResponse = await queryGiftSender.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        GiftsSenderModel giftsSenderModel =
            parseResponse.results!.first! as GiftsSenderModel;
        giftsSenderModel.addDiamonds = giftsModel.getCoins!;
        await giftsSenderModel.save();
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
