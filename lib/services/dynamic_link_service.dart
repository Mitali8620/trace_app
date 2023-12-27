import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/config.dart';
import '../app/constants.dart';
import '../helpers/quick_help.dart';
import '../home/audio_live/audio_live_screen.dart';
import '../home/feed/comment_post_screen.dart';
import '../home/live/live_party_screen.dart';
import '../home/live/live_streaming_screen.dart';
import '../home/profile/profile_edit.dart';
import '../models/InvitedUsersModel.dart';
import '../models/LiveStreamingModel.dart';
import '../models/PostsModel.dart';
import '../models/UserModel.dart';
import '../utils/shared_manager.dart';

class DynamicLinkService {
  static String keyLinkPost = "post";
  static String keyLinkLive = "live";
  static String keyLinkInvitation = "invitation";

  Future<Uri?>? createDynamicLink(String? id, String type) async {
    try {
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        // The Dynamic Link URI domain. You can view created URIs on your Firebase console
        uriPrefix: Config.uriPrefix,
        // The deep Link passed to your application which you can use to affect change
        //link: Uri.parse("${Config.link.replaceAll("/", "")}/?${Config.inviteSuffix}=$id"),
        link: Uri.parse("${Config.link}/${Config.inviteSuffix}=$id?type=$type"),
        // Android application details needed for opening correct app on device/Play Store
        androidParameters: AndroidParameters(
          packageName: Constants.appPackageName(),
          minimumVersion: 1,
        ),
        // iOS application details needed for opening correct app on device/App Store
        iosParameters: IOSParameters(
          bundleId: Constants.appPackageName(),
          appStoreId: Config.iosAppStoreId,
          minimumVersion: '1',
        ),
      );

      final ShortDynamicLink shortDynamicLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);
      final Uri uri = shortDynamicLink.shortUrl;
      return uri;
    } catch (e) {
      return null;
    }
  }

  Future<void> retrieveDynamicLink(BuildContext context) async {
    try {
      final PendingDynamicLinkData? data =
          await FirebaseDynamicLinks.instance.getInitialLink();
      Uri? deepLink = data?.link;

      if (deepLink != null) {
        if (deepLink.queryParameters.containsKey(Config.inviteSuffix)) {
          String? preLink = deepLink.queryParameters[Config.inviteSuffix];
          String id = preLink!.replaceAll("/${Config.inviteSuffix}", "");

          print("DeepLink invited by: $preLink");
          print("DeepLink invited by: $id");
        }

        print("DeepLink found : ${deepLink.toString()}");
      } else {
        print("DeepLink not found");
      }
    } catch (e) {
      print("DeepLink invited by Error: $e");
    }
  }

  listenDynamicLink(BuildContext context) async {
    print("DeepLink listenDynamicLink");

    SharedPreferences preferences = await SharedPreferences.getInstance();

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      print("DeepLink Listen invited by: ${dynamicLinkData.link.path}");

      String id =
          dynamicLinkData.link.path.replaceAll("/${Config.inviteSuffix}=", "");

      SharedManager().setInvitee(preferences, id);

      print("DeepLink ID invited by: $id");
    }).onError((error) {
      print("DeepLink listen by Error: $error");
      // Handle errors
    });
  }

  openSharedContents({
    required UserModel currentUser,
    required SharedPreferences preferences,
    required BuildContext context,
  }) {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      print("DeepLink Listen invited by: ${dynamicLinkData.link.path}");

      String completeLink = dynamicLinkData.link.toString();

      List<String> parts = completeLink.split('?');

      String linkType = "";

      if (parts.length > 1) {
        String params = parts[1];
        List<String> paramsDivided = params.split('=');

        if (paramsDivided.length > 1 && paramsDivided[0] == 'type') {
          String valor = paramsDivided[1];
          linkType = valor;
          print(valor);
        }
      }

      String id =
          dynamicLinkData.link.path.replaceAll("/${Config.inviteSuffix}=", "");

      if (linkType == keyLinkPost) {
        QuickHelp.showLoadingDialog(context);

        QueryBuilder queryBuilder = QueryBuilder<PostsModel>(PostsModel());

        queryBuilder.whereEqualTo(PostsModel.keyObjectId, id);

        queryBuilder.includeObject([
          PostsModel.keyAuthor,
          PostsModel.keyAuthorName,
          PostsModel.keyLastLikeAuthor,
          PostsModel.keyLastDiamondAuthor,
          PostsModel.keyTargetPeople
        ]);
        ParseResponse response = await queryBuilder.query();

        if (response.success && response.results != null) {
          QuickHelp.hideLoadingDialog(context);
          PostsModel post = response.results!.first;
          QuickHelp.goToNavigatorScreen(
            context,
            CommentPostScreen(
              preferences: preferences,
              post: post,
              currentUser: currentUser,
            ),
          );
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showAppNotificationAdvanced(
              title: "error".tr(),
              message: "not_connected".tr(),
              context: context);
        }
      } else if (linkType == keyLinkLive) {
        QuickHelp.showLoadingDialog(context);

        QueryBuilder<LiveStreamingModel> queryBuilder =
            QueryBuilder<LiveStreamingModel>(LiveStreamingModel());

        queryBuilder.whereEqualTo(LiveStreamingModel.keyObjectId, id);

        queryBuilder.includeObject([
          LiveStreamingModel.keyAuthor,
          LiveStreamingModel.keyAuthorInvited,
          LiveStreamingModel.keyPrivateLiveGift,
          LiveStreamingModel.keyAudioHostsList,
        ]);

        queryBuilder.whereNotEqualTo(
            LiveStreamingModel.keyAuthorUid, currentUser.getUid);

        queryBuilder.whereValueExists(LiveStreamingModel.keyAuthor, true);

        ParseResponse response = await queryBuilder.query();

        if (response.success && response.results != null) {
          QuickHelp.hideLoadingDialog(context);
          LiveStreamingModel liveStreamingModel = response.results!.first;

          if (currentUser.getAvatar == null) {
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
                    currentUser: currentUser,
                  ),
                );
              },
            );
          } else if (liveStreamingModel.getPartyType == null) {
            QuickHelp.goToNavigatorScreen(
              context,
              LiveStreamingScreen(
                channelName: liveStreamingModel.getStreamingChannel!,
                isBroadcaster: false,
                currentUser: currentUser,
                preferences: preferences,
                mUser: liveStreamingModel.getAuthor,
                isUserInvited: liveStreamingModel.getInvitedPartyUid!
                    .contains(currentUser.getUid!),
                mLiveStreamingModel: liveStreamingModel,
              ),
            );
          } else if (liveStreamingModel.getPartyType ==
              LiveStreamingModel.liveVideo) {
            QuickHelp.goToNavigatorScreen(
              context,
              VideoPartyScreen(
                channelName: liveStreamingModel.getStreamingChannel!,
                isBroadcaster: false,
                currentUser: currentUser,
                mUser: liveStreamingModel.getAuthor,
                isUserInvited: liveStreamingModel.getInvitedPartyUid!
                    .contains(currentUser.getUid!),
                mLiveStreamingModel: liveStreamingModel,
                preferences: preferences,
              ),
            );
          } else {
            QuickHelp.goToNavigatorScreen(
              context,
              AudioLiveScreen(
                channelName: liveStreamingModel.getStreamingChannel!,
                isBroadcaster: false,
                currentUser: currentUser,
                mUser: liveStreamingModel.getAuthor,
                isUserInvited: liveStreamingModel.getInvitedPartyUid!
                    .contains(currentUser.getUid!),
                mLiveStreamingModel: liveStreamingModel,
                preferences: preferences,
              ),
            );
          }
        } else {
          QuickHelp.hideLoadingDialog(context);
          QuickHelp.showAppNotificationAdvanced(
              title: "error".tr(),
              message: "not_connected".tr(),
              context: context);
        }
      }
    }).onError((error) {
      print("DeepLink listen by Error: $error");
      // Handle errors
    });
  }

  registerInviteBy(
      UserModel currentUser, String inviteeId, BuildContext context) async {
    QuickHelp.showLoadingDialog(context);

    QueryBuilder<UserModel> queryFrom =
        QueryBuilder<UserModel>(UserModel.forQuery());

    queryFrom.whereEqualTo(UserModel.keyId, inviteeId);

    ParseResponse apiResponse = await queryFrom.query();

    if (apiResponse.success) {
      if (apiResponse.results != null) {
        InvitedUsersModel invitedUsersModel = InvitedUsersModel();

        invitedUsersModel.setAuthor = currentUser;
        invitedUsersModel.setAuthorId = currentUser.objectId!;

        invitedUsersModel.setInvitedBy =
            apiResponse.results!.first! as UserModel;
        invitedUsersModel.setInvitedById = inviteeId;

        invitedUsersModel.setValidUntil =
            DateTime.now().add(Duration(days: 730));
        ParseResponse response = await invitedUsersModel.save();

        if (response.success) {
          currentUser.setInvitedByAnswer = true;
          currentUser.setInvitedByUser = inviteeId;

          ParseResponse user = await currentUser.save();
          if (user.success) {
            currentUser = user.results!.first! as UserModel;
          }
        }
      }
    }
  }
}
