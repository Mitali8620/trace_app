import 'package:agora_rtm/agora_rtm.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/navigation_service.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/models/UserModel.dart';

import '../app/setup.dart';
import '../home/calls/video_call_screen.dart';
import '../home/calls/voice_call_screen.dart';
import '../home/live/live_streaming_screen.dart';
import '../utils/shared_manager.dart';

class CallsProvider extends ChangeNotifier {

  int connectionStateDisconnected = 1;
  int connectionStateConnecting = 2;
  int connectionStateConnected = 3;
  int connectionStateReconnecting = 4;
  int connectionStateAborted = 5;

  AgoraRtmClient? _client;
  LocalInvitation? invitation;
  bool _isLogin = false;

  //BuildContext? _context;
  UserModel? _currentUser;
  bool isCallCanceled = false;
  bool isCallRinging = false;
  bool isCallRefused = false;
  bool busy = false;
  String getRoute = "";

  AgoraRtmClient? getAgoraRtmClient() {
    if (_client != null) {
      _createClient();
    }

    return _client;
  }

  setUserBusy(bool isUserBusy) {
    busy = isUserBusy;
    _log("User busy $isUserBusy");
  }

  setCallRefused(bool callRefused) {
    isCallRefused = callRefused;
    //notifyListeners();
  }

  setCanceled(bool callCanceled) {
    isCallCanceled = callCanceled;
    //notifyListeners();
  }

  bool isAgoraUserLogged(UserModel? user) {
    _currentUser = user;

    if (!_isLogin) {
      _toggleLogin(user!);
    }
    return _isLogin;
  }

  void connectAgoraRtm() {
    _createClient();
  }

  void loginAgoraUser(UserModel? user) {
    _currentUser = user;

    _toggleLogin(user!);
  }

  void _createClient() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    _client = await AgoraRtmClient.createInstance(SharedManager().getStreamProviderKey(preferences));
    _client!.onMessageReceived = (RtmMessage message, String peerId) {
      _log("Peer msg: " + peerId + ", msg: " + (message.text));
    };

    _client!.onConnectionStateChanged2 = (RtmConnectionState state, RtmConnectionChangeReason reason) {
      _log('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state  == RtmConnectionState.aborted) {
        _client!.logout();
        _log('Logout.');
        _isLogin = false;
        //notifyListeners();
      }

      connectionState(state);

      if (state == RtmConnectionState.connecting ||
          state  == RtmConnectionState.connected ||
          state  == RtmConnectionState.reconnecting) {
        //callState = true;
      }

      if (state  == RtmConnectionState.disconnected ||
          state == RtmConnectionState.aborted) {
        //callState = false;
      }
    };

    // Call MAKER

    _client!.getRtmCallManager().onLocalInvitationReceivedByPeer =
        (LocalInvitation invite) {
      _log(
          'Local invitation received by peer: ${invite.calleeId}, content: ${invite.content}');
      isCallRinging = true;
      notifyListeners();
    };

    _client!.getRtmCallManager().onLocalInvitationAccepted = (LocalInvitation invite, String string) {
      _log(
          'Local invitation received by peer: ${invite.calleeId}, content: ${invite.content}');
      isCallRinging = true;
      //notifyListeners();
    };

    _client!.getRtmCallManager().onLocalInvitationRefused = (LocalInvitation invite, String string) {
      _log(
          'Local invitation Refused by peer: ${invite.calleeId}, content: ${invite.content}');
      isCallRefused = true;


      if (invite.response != null && invite.response == "busy") {
        /* QuickHelp.showAppNotificationAdvanced(
            title: "sorry".tr(),
            message: "Busy",
            context: NavigationService.navigatorKey.currentContext!);*/
      }
      notifyListeners();
    };

    _client!.getRtmCallManager().onLocalInvitationCanceled = (LocalInvitation invite) {
      _log(
          'Local invitation Canceled by peer calle: ${invite.calleeId}, content: ${invite.content}');
      //isCallRefused = true;
      //notifyListeners();
    };

    _client!.getRtmCallManager().onLocalInvitationFailure =
        (LocalInvitation invite, int error) {
      _log(
          'Local invitation Failure by peer: ${invite.calleeId}, content: ${invite.content}');
      //notifyListeners();
    };

    // Call RECEIVER

    _client!.getRtmCallManager().onRemoteInvitationAccepted = (RemoteInvitation invite) {
      _log(
          'Remote invitation Accepted: ${invite.callerId}, content: ${invite.content}');
    };

    _client!.getRtmCallManager().onRemoteInvitationReceived =
        (RemoteInvitation invite) {
      _log(
          'Remote invitation received by peer: ${invite.callerId}, content: ${invite.content}');

      if (busy == false) {
        initCallScreen(invite, preferences);
      } else {
        //refuseRemoteInvitation(invite);
      }
    };

    _client!.getRtmCallManager().onRemoteInvitationCanceled = (RemoteInvitation invite) {
      _log(
          'Remote invitation Canceled by peer caller: ${invite.callerId}, content: ${invite.content}');
      isCallCanceled = true;
      notifyListeners();
    };

    _client!.getRtmCallManager().onRemoteInvitationRefused = (RemoteInvitation invite) {
      _log(
          'Remote invitation Refused by peer: ${invite.callerId}, content: ${invite.content}');
      //notifyListeners();
    };

    _client!.getRtmCallManager().onRemoteInvitationFailure =
        (RemoteInvitation invite, int error) {
      _log(
          'Remote invitation Failure by peer: ${invite.callerId}, content: ${invite.content}');
      //notifyListeners();
    };
  }

  void _toggleLogin(UserModel? userModel) async {
    if (_isLogin) {
      try {
        await _client!.logout();
        _log('Logout success.');

        _isLogin = false;
        //notifyListeners();
      } catch (errorCode) {
        _log('Logout error: ' + errorCode.toString());
      }
    } else {
      if (userModel!.objectId!.isEmpty) {
        _log('Please input your user id to login.');
        return;
      }

      try {
        await _client!.login(null, userModel.objectId!);
        _log('Login success: ' + userModel.objectId!);

        _isLogin = true;
        //notifyListeners();
      } catch (errorCode) {
        _log('Login error: ' + errorCode.toString());
      }
    }
  }

  // Make call to other user
  void callUserInvitation(
      {required String calleeId,
        required String channel,
        required bool isVideo}) async {
    _log('callUserInvitation clicked');

    Map<String, dynamic> params = <String, dynamic>{
      'calleeId': calleeId,
      'content': isVideo ? "video" : "voice",
      'channelId': channel,
    };


    try {

      invitation = LocalInvitation.fromJson(params);
      //invitation = AgoraRtmLocalInvitation(calleeId, content: isVideo ? "video" : "voice", channelId: channel);
      _log(invitation!.content ?? '');
      await _client!.getRtmCallManager().sendLocalInvitation(invitation!);
      _log('Send local invitation success.');
      //notifyListeners();
    } catch (errorCode) {
      _log('Send local invitation error: ' + errorCode.toString());
    }
  }

  // Cancel call made to other user before pickup
  void cancelCallInvitation() {
    busy = false;
    if (_client != null && invitation != null) {
      _client!.getRtmCallManager().cancelLocalInvitation(invitation!);
    } else {
      _log("cancelCallInvitation _client null");
    }
  }

  // Accept a call invitation.
  void answerCall(final RemoteInvitation invitation) {
    if (_client != null) {
      _client!.getRtmCallManager().acceptRemoteInvitation(invitation);
    } else {
      _log("acceptRemoteInvitation _client null");
    }
  }

  // Refuse a call invitation.
  void refuseRemoteInvitation(RemoteInvitation invitation) {
    if (_client != null) {
      invitation.response = "busy";
      //invitation.state = 1;
      _client!.getRtmCallManager().refuseRemoteInvitation(invitation);
    } else {
      _log("refuseRemoteInvitation _client null");
    }
  }

  getRoutes() async {
    final route = await SharedPreferences.getInstance();
    getRoute = route.getString("currentRoute")!;
  }

  initCallScreen(RemoteInvitation agoraRtmRemoteInvitation, SharedPreferences preferences) async {
    getRoutes();

    isCallCanceled = false;

    QueryBuilder<UserModel> queryUser =
    QueryBuilder<UserModel>(UserModel.forQuery());
    queryUser.whereEqualTo(
        UserModel.keyObjectId, agoraRtmRemoteInvitation.callerId);

    ParseResponse parseResponse = await queryUser.query();
    if (parseResponse.success && parseResponse.results != null) {
      UserModel mUser = parseResponse.results!.first! as UserModel;

      if(getRoute == VideoCallScreen.route) {

        //invitation.content = "busy";
        refuseRemoteInvitation(agoraRtmRemoteInvitation);

      } else if(getRoute == VoiceCallScreen.route) {

        //invitation.content = "busy";
        refuseRemoteInvitation(agoraRtmRemoteInvitation);

      } else if(getRoute == LiveStreamingScreen.route) {

        //invitation.content = "live";

        refuseRemoteInvitation(agoraRtmRemoteInvitation);

        //remoteInvitation = agoraRtmRemoteInvitation;
        //notifyListeners();

        /*QuickHelp.showDialogPermission(
          context: NavigationService.navigatorKey.currentContext!,
          title: "permissions.allow_push_denied_title".tr(),
          message: "live_streaming.accept_call_advise".tr(),
          dismissible: false,
          confirmButtonText: "ok_".tr(),
          onPressed: () async {
            QuickHelp.hideLoadingDialog(
                NavigationService.navigatorKey.currentContext!);

            _endLiveStreaming().then((value) {

              _acceptCall(
                isVideo: agoraRtmRemoteInvitation.content! == "video"
                    ? true
                    : false,
                currentUser: _currentUser!,
                mUser: mUser,
                channel: agoraRtmRemoteInvitation.channelId!,
                agoraRtmRemoteInvitation: agoraRtmRemoteInvitation,
              );

            });
          },
        );*/

        //showInComingCallBackground(_currentUser!, mUser, agoraRtmRemoteInvitation);


      } else if(getRoute == "background"){
        _log("AgoraCall received $getRoute");

        showInComingCallBackground(_currentUser!, mUser, agoraRtmRemoteInvitation, preferences);

      } else {

        _log("AgoraCall received $getRoute");

        showInComingCallBackground(_currentUser!, mUser, agoraRtmRemoteInvitation, preferences);
        /* QuickHelp.goToNavigatorScreen(
          NavigationService.navigatorKey.currentContext!,
          IncomingCallScreen(
            mUser: mUser,
            currentUser: _currentUser,
            channel: agoraRtmRemoteInvitation.channelId!,
            isVideoCall:
                agoraRtmRemoteInvitation.content! == "video" ? true : false,
            agoraRtmRemoteInvitation: agoraRtmRemoteInvitation,
          ),
          route: IncomingCallScreen.route,
        );*/
      }
    } else{
      _log("parseResponse error");
    }
  }

  void _acceptCall({
    required bool isVideo,
    required UserModel currentUser,
    required UserModel mUser,
    required String channel,
    required RemoteInvitation agoraRtmRemoteInvitation,
    required SharedPreferences preferences,
  }){

    if (isVideo) {
      QuickHelp.goToNavigatorScreen(
        NavigationService.navigatorKey.currentContext!,
        VideoCallScreen(
          currentUser: currentUser,
          mUser: mUser,
          channel: channel,
          isCaller: false,
          preferences: preferences,
        ),
        finish: false,
        back: true,
      );
    } else {
      QuickHelp.goToNavigatorScreen(
        NavigationService.navigatorKey.currentContext!,
        VoiceCallScreen(
          mUser: mUser,
          currentUser: currentUser,
          channel: channel,
          isCaller: false,
          preferences: preferences,
        ),
        finish: false,
        back: true,
      );
    }
  }

  showInComingCallBackground(UserModel currentUser, UserModel callerUser, RemoteInvitation invitation, SharedPreferences preferences) async {

    final params = CallKitParams(
      id: currentUser.objectId,
      nameCaller: callerUser.getFullName,
      appName: Setup.appName,
      avatar: callerUser.getAvatar!.url,
      handle: invitation.content! == "video" ? "calls_screen.text_video_call".tr()
          : "calls_screen.text_voice_call".tr(),
      type: invitation.content! == "video" ? 1 : 0,
      duration: 30000,
      textAccept: "calls_screen.text_accept".tr(),
      textDecline: "calls_screen.text_decline".tr(),
      textMissedCall: "calls_screen.text_missed_call".tr(),
      textCallback: "calls_screen.text_callback".tr(),
      //extra: <String, dynamic>{'userId': '1a2b3c4d'},
      //headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: AndroidParams(
        isCustomNotification: false,
        isShowLogo: false,
        isShowCallback: false,
        isShowMissedCallNotification: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#27E150',
        //backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
      ),
      ios: IOSParams(
        //iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    await listenerEvent(invitation: invitation, callerUser: callerUser, preferences: preferences);
  }

  endInComingCall() async{
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<void> listenerEvent({Function? callback, UserModel? callerUser, RemoteInvitation? invitation, required SharedPreferences preferences}) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        print('HOME CallKit: ${event!.event}');
        switch (event.event) {
          case Event.ACTION_CALL_INCOMING:
          // TODO: received an incoming call
            break;
          case Event.ACTION_CALL_START:
          // TODO: started an outgoing call
          // TODO: show screen calling in Flutter
            break;
          case Event.ACTION_CALL_ACCEPT:
          // TODO: accepted an incoming call
          // TODO: show screen calling in Flutter
            answerCall(invitation!);

            _acceptCall(
              isVideo: invitation.content! == "video"
                  ? true
                  : false,
              currentUser: _currentUser!,
              mUser: callerUser!,
              channel: invitation.channelId!,
              agoraRtmRemoteInvitation: invitation,
              preferences: preferences,
            );

            break;
          case Event.ACTION_CALL_DECLINE:
          // TODO: declined an incoming call

            refuseRemoteInvitation(invitation!);
            endInComingCall();
            break;
          case Event.ACTION_CALL_ENDED:
          // TODO: ended an incoming/outgoing call

            refuseRemoteInvitation(invitation!);
            endInComingCall();
            break;
          case Event.ACTION_CALL_TIMEOUT:
          // TODO: missed an incoming call

            refuseRemoteInvitation(invitation!);
            //endInComingCall();
            break;
          case Event.ACTION_CALL_CALLBACK:
          // TODO: only Android - click action `Call back` from missed call notification
            break;
          case Event.ACTION_CALL_TOGGLE_HOLD:
          // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_MUTE:
          // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_DMTF:
          // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_GROUP:
          // TODO: only iOS
            break;
          case Event.ACTION_CALL_TOGGLE_AUDIO_SESSION:
          // TODO: only iOS
            break;
          case Event.ACTION_DID_UPDATE_DEVICE_PUSH_TOKEN_VOIP:
          // TODO: only iOS
            break;
        }
        /*if (callback != null) {
          callback(event.toString());
        }*/
      });
    } on Exception {}
  }

  _log(String string) {
    print("AgoraCall " + string);
  }

  connectionState(RtmConnectionState state) {
    if (state == RtmConnectionState.aborted) {
      _log("connectionStateAborted");
    } else if (state == RtmConnectionState.connecting) {
      _log("connectionStateConnecting");
    } else if (state == RtmConnectionState.connected) {
      _log("connectionStateConnected");
    } else if (state == RtmConnectionState.reconnecting) {
      _log("connectionStateReconnecting");
    } else if (state == RtmConnectionState.aborted) {
      _log("connectionStateAborted");
    }
  }
}
