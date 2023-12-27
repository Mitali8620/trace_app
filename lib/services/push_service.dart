import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/config.dart';
import '../app/navigation_service.dart';
import '../helpers/quick_actions.dart';
import '../helpers/quick_help.dart';
import '../helpers/send_notifications.dart';
import '../home/feed/comment_post_screen.dart';
import '../home/live/live_streaming_screen.dart';
import '../home/message/message_screen.dart';
import '../home/reels/reels_single_screen.dart';
import '../models/LiveStreamingModel.dart';
import '../models/PostsModel.dart';
import '../models/UserModel.dart';

class PushService {
  UserModel? currentUser;
  BuildContext? context;
  SharedPreferences? preferences;

  PushService({
    required this.currentUser,
    required this.context,
    required this.preferences,
  });

  Future initialise() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    analytics.setAnalyticsCollectionEnabled(true);

    if (QuickHelp.isIOSPlatform()) {
      checkNotifications(messaging);
    } else {
      messaging.requestPermission().then((value) => savePush(messaging));
    }

    // When you click in push
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Push Notification onMessageOpenedApp");
      _decodePushMessage(message.data);
    });

    // When you receive the push and app is opened
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Push Notification onMessage");
      if (message.notification != null) {
        _showNotifications(message);
      }
    });

    // When you receive the push and app is terminated or in background
    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      print("Push Notification onBackgroundMessage");
    });

    final RemoteMessage? message = await messaging.getInitialMessage();
    if(message != null){
      _decodePushMessage(message.data);
    }
  }

  checkNotifications(FirebaseMessaging messaging) {
    messaging.getNotificationSettings().then((value) async {
      if (value.authorizationStatus == AuthorizationStatus.notDetermined) {
        print("Notification notDetermined ");

        _notificationAsk(false, messaging);
      } else if (value.authorizationStatus == AuthorizationStatus.authorized) {
        print("Notification authorized ");

        savePush(messaging);
      } else if (value.authorizationStatus == AuthorizationStatus.denied) {
        print("Notification authorized ");

        _notificationAsk(true, messaging);
      } else if (value.authorizationStatus == AuthorizationStatus.provisional) {
        print("Notification authorized ");

        _notificationAsk(false, messaging);
      }
    });
  }

  _notificationAsk(bool denied, FirebaseMessaging messaging) {
    if (denied) {
      QuickHelp.showDialogPermission(
        context: NavigationService.navigatorKey.currentContext!,
        title: "permissions.allow_push_denied_title".tr(),
        message: "permissions.allow_push_denied".tr(),
        dismissible: false,
        confirmButtonText: "ok_".tr(),
        onPressed: () async {
          QuickHelp.hideLoadingDialog(
              NavigationService.navigatorKey.currentContext!);
          savePush(messaging);
        },
      );
    } else {
      QuickHelp.showDialogPermission(
        context: NavigationService.navigatorKey.currentContext!,
        title: "permissions.push_notifications_tile".tr(),
        message: "permissions.app_notifications_explain".tr(),
        dismissible: false,
        confirmButtonText: "permissions.allow_push_notifications".tr(),
        onPressed: () async {
          QuickHelp.hideLoadingDialog(
              NavigationService.navigatorKey.currentContext!);

          messaging.requestPermission().then((value) => savePush(messaging));
        },
      );
    }
  }

  savePush(FirebaseMessaging messaging) {
    messaging.getToken(vapidKey: Config.webPushCertificate).then((token) {
      if (QuickHelp.isIOSPlatform()) {
        messaging.getAPNSToken().then((value) {
          if (value != null) {
            _storeToken(value);
          } else {
            _storeToken("");
          }
        });
      } else {
        _storeToken(token!);
      }
    });
  }

  _storeToken(String deviceToken) async {
    if (kDebugMode) {
      print(
          "Push User: ${currentUser != null ? currentUser!.objectId! : "null"} Token $deviceToken");
    }

    QuickHelp.initInstallation(currentUser, deviceToken);
  }

  _showNotifications(RemoteMessage notification) {

    var avatar;

    if(notification.data["data"] != null){
      String data = notification.data["data"];
      Map messageData = json.decode(data);
      avatar = messageData[SendNotifications.pushNotificationSenderAvatar];
    }


    Flushbar(
      title: notification.notification!.title!,
      message: notification.notification!.body!,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      duration: Duration(seconds: 5),
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      backgroundColor: Colors.white,
      titleColor: Colors.black,
      messageColor: Colors.black,
      titleSize: 16,
      messageSize: 14,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: 5,
          blurStyle: BlurStyle.normal,
        ),
      ],
      icon: QuickActions.avatarWidgetNotification(
        currentUser: currentUser,
        imageUrl: avatar,
        width: 70,
        height: 70,
        margin: EdgeInsets.only(left: 5, right: 5),
      ),
      onTap: (_){
        _decodePushMessage(notification.data);
      },
    ).show(context!);
  }

  _decodePushMessage(Map<String, dynamic> message) async {
    UserModel? mUser;
    PostsModel? mPost;
    LiveStreamingModel? mLive;

    var data = message["data"];
    Map notification = json.decode(data);

    print("Push Notification: onBackgroundMessage $notification");

    var type = notification[SendNotifications.pushNotificationType];
    var senderId = notification[SendNotifications.pushNotificationSender];
    var objectId = notification[SendNotifications.pushNotificationObjectId];

    if (type == SendNotifications.typeChat) {
      QueryBuilder<UserModel> queryUser =
          QueryBuilder<UserModel>(UserModel.forQuery());
      queryUser.whereEqualTo(UserModel.keyObjectId, senderId);

      ParseResponse parseResponse = await queryUser.query();
      if (parseResponse.success && parseResponse.results != null) {
        mUser = parseResponse.results!.first! as UserModel;
      }

      if (currentUser != null && mUser != null) {
        _gotToChat(currentUser!, mUser);
      }
    } else if (type == SendNotifications.typeLive ||
        type == SendNotifications.typeLiveInvite) {
      QueryBuilder<LiveStreamingModel> queryPost =
          QueryBuilder<LiveStreamingModel>(LiveStreamingModel());
      queryPost.whereEqualTo(LiveStreamingModel.keyObjectId, objectId);
      queryPost.includeObject([LiveStreamingModel.keyAuthor]);

      ParseResponse parseResponse = await queryPost.query();
      if (parseResponse.success && parseResponse.results != null) {
        mLive = parseResponse.results!.first! as LiveStreamingModel;
      }

      if (currentUser != null && mLive != null) {
        _goToLive(currentUser!, mLive);
      }
    } else if (type == SendNotifications.typeLike ||
        type == SendNotifications.typeComment || type == SendNotifications.typeReplyComment) {
      QueryBuilder<PostsModel> queryPost =
          QueryBuilder<PostsModel>(PostsModel());
      queryPost.whereEqualTo(PostsModel.keyObjectId, objectId);
      queryPost.includeObject([PostsModel.keyAuthor]);

      ParseResponse parseResponse = await queryPost.query();
      if (parseResponse.success && parseResponse.results != null) {
        mPost = parseResponse.results!.first! as PostsModel;
      }

      if (currentUser != null && mPost != null) {
       if(mPost.isVideo!){
         _goToReels(currentUser!, mPost);
       } else {
         _goToPost(currentUser!, mPost);
       }
      }

    } else if (type == SendNotifications.typeFollow ||
        type == SendNotifications.typeMissedCall) {
      QueryBuilder<UserModel> queryUser =
          QueryBuilder<UserModel>(UserModel.forQuery());
      queryUser.whereEqualTo(UserModel.keyObjectId, senderId);

      ParseResponse parseResponse = await queryUser.query();
      if (parseResponse.success && parseResponse.results != null) {
        mUser = parseResponse.results!.first! as UserModel;
      }

      if (currentUser != null && mUser != null) {
        QuickActions.showUserProfile(
            NavigationService.navigatorKey.currentContext!,
            currentUser!,
            preferences: preferences!,
            mUser);
      }
    }

    print("Push Notification data: $notification");
  }

  _gotToChat(UserModel currentUser, UserModel mUser) {
    QuickHelp.goToNavigatorScreen(
        NavigationService.navigatorKey.currentContext!,
      MessageScreen(
        preferences: preferences,
        currentUser: currentUser,
        mUser: mUser,
      ),
    );
  }

  _goToPost(UserModel currentUser, PostsModel mPost) {
    QuickHelp.goToNavigatorScreen(
      NavigationService.navigatorKey.currentContext!,
      CommentPostScreen(
        preferences: preferences,
        currentUser: currentUser,
        post: mPost,
      ),
    );
  }

  _goToReels(UserModel currentUser, PostsModel mPost) {
    QuickHelp.goToNavigatorScreen(NavigationService.navigatorKey.currentContext!, ReelsSingleScreen(currentUser: currentUser, post: mPost,));
  }

  _goToLive(UserModel currentUser, LiveStreamingModel mLive) {
    QuickHelp.goToNavigatorScreen(
        NavigationService.navigatorKey.currentContext!,
        LiveStreamingScreen(
          channelName: mLive.getStreamingChannel!,
          isBroadcaster: false,
          currentUser: currentUser,
          preferences: preferences,
          mUser: mLive.getAuthor,
          mLiveStreamingModel: mLive,
        ),
    );
  }
}
