import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/models/LiveStreamingModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/container_with_corner.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../app/constants.dart';
import '../../app/setup.dart';
import '../../models/AudioChatUsersModel.dart';
import '../audio_live/audio_live_screen.dart';
import '../host_rules/host_rules_screen.dart';
import '../upload_live_photo/upload_live_photo_screen.dart';
import 'live_party_screen.dart';
import 'live_streaming_screen.dart';

// ignore: must_be_immutable
class LivePreviewScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  int? liveTypeIndex;

  LivePreviewScreen({
    Key? key,
    this.currentUser,
    this.preferences,
    this.liveTypeIndex,
  }) : super(key: key);

  static String route = "/live/preview";

  @override
  _LivePreviewScreenState createState() => _LivePreviewScreenState();
}

class _LivePreviewScreenState extends State<LivePreviewScreen>
    with TickerProviderStateMixin {
  String? _privacySelection = LiveStreamingModel.privacyTypeAnyone;

  TextEditingController liveTitleTextController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  List<CameraDescription>? listOfCameras;
  CameraController? cameraController;
  bool isFrontCamera = true;
  late Future<void> initializeControllerFuture;

  bool partyBtnSelected = false;
  bool goLiveBtnSelected = true;
  bool battleBtnSelected = false;

  bool isFirstTime = false;

  var liveSubTypeSelected = [];
  int partyOrLiveIndex = 1;
  int partyVoiceOrVideoIndex = 1;

  bool showTempAlert = false;
  bool showErrorOnTitleInput = false;

  late SharedPreferences preferences;

  var shareOptionIcons = [
    "assets/images/icon_share_facebook_tr.png",
    "assets/images/icon_share_messager_tr.png",
    "assets/images/icon_share_whatsapp_tr.png",
    "assets/images/icon_share_line_tr.png",
  ];

  var selectedPartyChair = [
    "assets/images/ic_party_person_4_select.png",
    "assets/images/ic_party_person_6_select.png",
    "assets/images/ic_party_person_9_select.png",
  ];

  var unselectedPartyChair = [
    "assets/images/ic_party_person_4_unselect.png",
    "assets/images/ic_party_person_6_unselect.png",
    "assets/images/ic_party_person_9_unselect.png",
  ];

  var selectedPartyChairsNumber = [0];

  @override
  void initState() {
    super.initState();
    initSharedPref();
    loadCamera();
    partyOrLiveIndex = widget.liveTypeIndex ?? 0;

    isFirstLive();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool switchedCamera = false;

  loadCamera() async {
    listOfCameras = await availableCameras();

    CameraDescription selectedCamera = isFrontCamera
        ? listOfCameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front)
        : listOfCameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back);

    cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
    );

    initializeControllerFuture = cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    if (!mounted) return;

    setState(() {});
  }

  switchCamera() {
    setState(() {
      if (switchedCamera) {
        cameraController =
            CameraController(listOfCameras![1], ResolutionPreset.max);
        switchedCamera = false;
      } else {
        cameraController =
            CameraController(listOfCameras![0], ResolutionPreset.max);
        switchedCamera = true;
      }
      cameraController!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => QuickHelp.removeFocusOnTextField(context),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: kTransparentColor,
          leading: Visibility(
            visible: partyVoiceOrVideoIndex == 0 || partyOrLiveIndex == 0,
            child: IconButton(
              onPressed: () => switchCamera(),
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          actions: [
            /*IconButton(
              onPressed: () => QuickHelp.goBackToPreviousPage(context),
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),*/
          ],
        ),
        body: ContainerCorner(
          color: kTransparentColor,
          borderWidth: 0,
          marginBottom: 0,
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              ContainerCorner(
                width: size.width,
                height: size.height,
                borderWidth: 0,
                child: background(),
                marginBottom: 0,
              ),
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ContainerCorner(
                      height: 170,
                      width: size.width,
                      marginLeft: 15,
                      marginRight: 15,
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: 10,
                      borderWidth: 0,
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ContainerCorner(
                                  borderWidth: 0,
                                  marginTop: 10,
                                  width: size.width / 5,
                                  height: size.width / 4.6,
                                  marginLeft: 10,
                                  color: kTransparentColor,
                                  onTap: () async {
                                    UserModel? user = await QuickHelp
                                        .goToNavigatorScreenForResult(
                                            context,
                                            UploadLivePhoto(
                                              currentUser: widget.currentUser,
                                              preferences: widget.preferences,
                                            ));
                                    if (user != null) {
                                      setState(() {
                                        widget.currentUser = user;
                                      });
                                    }
                                  },
                                  child: Stack(
                                    alignment:
                                        AlignmentDirectional.bottomCenter,
                                    children: [
                                      if(widget.currentUser!.getLiveCover != null)
                                      QuickActions.photosWidget(
                                        widget.currentUser!.getLiveCover!.url,
                                        borderRadius: 10,
                                      ),
                                      if(widget.currentUser!.getLiveCover == null)
                                        Center(child: Icon(Icons.camera_alt, color: Colors.white, size: 35,)),
                                      ContainerCorner(
                                        width: size.width / 5,
                                        radiusBottomLeft: 10,
                                        radiusBottomRight: 10,
                                        height: size.width / 20,
                                        color: Colors.white.withOpacity(0.2),
                                        child: TextWithTap(
                                          "update_".tr(),
                                          color: Colors.white,
                                          overflow: TextOverflow.ellipsis,
                                          alignment: Alignment.center,
                                          fontSize: size.width / 35,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ContainerCorner(
                                      marginTop: 10,
                                      height: 40,
                                      width: size.width / 1.56,
                                      borderRadius: 10,
                                      marginLeft: 10,
                                      color: Colors.white.withOpacity(0.3),
                                      borderColor: showErrorOnTitleInput
                                          ? Colors.red
                                          : kTransparentColor,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10),
                                        child: TextFormField(
                                          controller: liveTitleTextController,
                                          maxLines: 1,
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                          ),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText:
                                                "live_streaming.enter_title"
                                                    .tr(),
                                            hintStyle: GoogleFonts.roboto(
                                              color: Colors.white,
                                            ),
                                            errorStyle: GoogleFonts.roboto(
                                              fontSize: 0.0,
                                            ),
                                          ),
                                          autovalidateMode:
                                              AutovalidateMode.disabled,
                                          validator: (value) {
                                            if (value!.isEmpty) {
                                              setState(() {
                                                showErrorOnTitleInput = true;
                                              });
                                              return "";
                                            } else {
                                              setState(() {
                                                showErrorOnTitleInput = false;
                                              });
                                              return null;
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    ContainerCorner(
                                      marginTop: 5,
                                      height: 35,
                                      width: size.width / 1.56,
                                      marginLeft: 10,
                                      child: ListView(
                                        padding: EdgeInsets.zero,
                                        scrollDirection: Axis.horizontal,
                                        children: List.generate(
                                            QuickHelp.getLiveSubTypeList()
                                                .length, (index) {
                                          bool isSelected = liveSubTypeSelected
                                              .contains(QuickHelp
                                                  .getLiveSubTypeList()[index]);
                                          return ContainerCorner(
                                            borderRadius: 50,
                                            borderWidth: isSelected ? 0 : 1,
                                            borderColor: isSelected
                                                ? kTransparentColor
                                                : Colors.white,
                                            color: isSelected
                                                ? kPrimaryColor
                                                : kTransparentColor,
                                            onTap: () {
                                              liveSubTypeSelected.clear();
                                              setState(() {
                                                liveSubTypeSelected.add(QuickHelp
                                                        .getLiveSubTypeList()[
                                                    index]);
                                              });
                                            },
                                            marginRight: 10,
                                            child: TextWithTap(
                                              QuickHelp.getLiveSubTypeByCode(
                                                  QuickHelp
                                                          .getLiveSubTypeList()[
                                                      index]),
                                              color: Colors.white,
                                              marginLeft: 8,
                                              marginRight: 8,
                                              alignment: Alignment.center,
                                            ),
                                          );
                                        }),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, top: 10, bottom: 10),
                              child: Divider(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 30,
                              ),
                              child: Row(
                                children: [
                                  TextWithTap(
                                    "audio_chat.share_".tr(),
                                    color: Colors.white,
                                    marginRight: 5,
                                  ),
                                  TextWithTap(
                                    "after_start".tr(),
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    ContainerCorner(
                      width: size.width,
                      marginLeft: 15,
                      marginRight: 15,
                      borderRadius: 10,
                      borderWidth: 0,
                      marginBottom: 15,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Visibility(
                            visible: partyOrLiveIndex == 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ContainerCorner(
                                  borderRadius: 50,
                                  borderColor: Colors.white,
                                  marginTop: 5,
                                  width: 140,
                                  child: Row(
                                    children: [
                                      ContainerCorner(
                                        height: 30,
                                        borderRadius: 50,
                                        width: 69,
                                        borderWidth: 0,
                                        onTap: () {
                                          setState(() {
                                            partyVoiceOrVideoIndex = 0;
                                          });
                                        },
                                        color: partyVoiceOrVideoIndex == 0
                                            ? kPrimaryColor
                                            : kTransparentColor,
                                        child: TextWithTap(
                                          "live_start_screen.video_".tr(),
                                          color: Colors.white,
                                          textAlign: TextAlign.center,
                                          alignment: Alignment.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ContainerCorner(
                                        height: 30,
                                        width: 69,
                                        borderRadius: 50,
                                        borderWidth: 0,
                                        onTap: () {
                                          setState(() {
                                            partyVoiceOrVideoIndex = 1;
                                          });
                                        },
                                        color: partyVoiceOrVideoIndex == 1
                                            ? kPrimaryColor
                                            : kTransparentColor,
                                        child: TextWithTap(
                                          "live_start_screen.voice".tr(),
                                          color: Colors.white,
                                          textAlign: TextAlign.center,
                                          alignment: Alignment.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: List.generate(
                                      selectedPartyChair.length, (index) {
                                    return ContainerCorner(
                                      onTap: () {
                                        selectedPartyChairsNumber.clear();
                                        setState(() {
                                          selectedPartyChairsNumber.add(index);
                                        });
                                      },
                                      child: Image.asset(
                                        selectedPartyChairsNumber
                                                .contains(index)
                                            ? selectedPartyChair[index]
                                            : unselectedPartyChair[index],
                                        height: size.width / 5,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/ic_room_bottom_beauty.webp",
                                height: 45,
                              ),
                              ContainerCorner(
                                color: kPrimaryColor,
                                borderWidth: 0,
                                height: 45,
                                borderRadius: 50,
                                marginLeft: 10,
                                width: size.width / 1.8,
                                onTap: () {
                                  if (formKey.currentState!.validate()) {
                                    startSelectedLiveType();
                                  }
                                },
                                child: TextWithTap(
                                  partyOrLiveIndex == 0
                                      ? "live_start_screen.start_live_streaming"
                                          .tr()
                                      : "live_start_screen.start_party".tr(),
                                  color: Colors.white,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          SizedBox(
                            width: size.width / 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ContainerCorner(
                                  onTap: () {
                                    setState(() {
                                      partyOrLiveIndex = 0;
                                    });
                                  },
                                  borderRadius: 8,
                                  color: Colors.black.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.live_tv,
                                          color: partyOrLiveIndex == 0
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.3),
                                          size: 30,
                                        ),
                                        TextWithTap(
                                          "live_start_screen.live_".tr(),
                                          color: partyOrLiveIndex == 0
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.3),
                                          marginTop: 5,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                ContainerCorner(
                                  onTap: () {
                                    setState(() {
                                      partyOrLiveIndex = 1;
                                    });
                                  },
                                  borderRadius: 8,
                                  color: Colors.black.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          partyOrLiveIndex == 1
                                              ? "assets/images/ic_party_person_9_select.png"
                                              : "assets/images/ic_party_person_9_unselect.png",
                                          height: 35,
                                        ),
                                        TextWithTap(
                                          "live_start_screen.party_".tr(),
                                          color: partyOrLiveIndex == 1
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.3),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  QuickHelp.goToNavigatorScreen(
                                      context,
                                      HostRulesScreen(
                                        currentUser: widget.currentUser,
                                        preferences: widget.preferences,
                                      ));
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: kPrimaryColor,
                                      size: 17,
                                    ),
                                    RichText(
                                        textAlign: TextAlign.start,
                                        text: TextSpan(children: [
                                          WidgetSpan(
                                            child: SizedBox(width: 5),
                                          ),
                                          TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            text: "live_start_screen.i_agree"
                                                .tr(),
                                          ),
                                          WidgetSpan(
                                            child: SizedBox(width: 3),
                                          ),
                                          TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: kOrangeColor,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            text:
                                                "live_start_screen.hosting_contract"
                                                    .tr(),
                                          ),
                                        ])),
                                  ],
                                ),
                              )
                            ],
                          ),
                          SizedBox(
                            height: 5,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Visibility(
                visible: showTempAlert,
                child: ContainerCorner(
                  color: Colors.black.withOpacity(0.5),
                  height: 50,
                  marginRight: 50,
                  marginLeft: 50,
                  borderRadius: 50,
                  width: size.width / 2,
                  shadowColor: kGrayColor,
                  shadowColorOpacity: 0.3,
                  child: TextWithTap(
                    "live_start_screen.choose_live_sub_type".tr(),
                    color: Colors.white,
                    marginBottom: 5,
                    marginTop: 5,
                    marginLeft: 15,
                    marginRight: 15,
                    fontSize: 12,
                    alignment: Alignment.center,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget background() {
    var size = MediaQuery.of(context).size;
    if (partyVoiceOrVideoIndex == 0 || partyOrLiveIndex == 0) {
      if(cameraController == null) {
        return ContainerCorner(
          borderWidth: 0,
          width: size.width,
          height: size.height,
          color: kContentColorLightTheme,
        );
      }else{
        return CameraPreview(cameraController!);
      }
    } else {
      return Image.asset(
        "assets/images/pk_bg_fot.webp",
        height: size.height,
        width: size.width,
        fit: BoxFit.fill,
      );
    }
  }

  showTemporaryAlert() {
    setState(() {
      showTempAlert = true;
    });
    hideTemporaryAlert();
  }

  hideTemporaryAlert() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showTempAlert = false;
      });
    });
  }

  startSelectedLiveType() {
    if (liveSubTypeSelected.isEmpty) {
      showTemporaryAlert();
    } else {
      if(widget.currentUser!.getLiveCover != null) {
        if (partyOrLiveIndex == 0) {
          createLive();
        } else if (partyOrLiveIndex == 1) {
          createParty();
        }
      }else{
        QuickHelp.showAppNotificationAdvanced(
          title: "live_starter_screen.select_live_cover_tittle".tr(),
          message: "live_starter_screen.select_live_cover_explain".tr(),
          context: context,
        );
      }
    }
  }

  Row whoCanSeeFilters(String gender, String text, String selected) {
    return Row(
      children: [
        Radio(
            activeColor: kPrimaryColor,
            value: gender,
            groupValue: _privacySelection,
            onChanged: (String? value) {
              setState(() {
                _privacySelection = value;
                widget.currentUser!.setGender = gender;
                //currentUser!.save();
              });
            }),
        SizedBox(
          width: 5,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _privacySelection = gender;
              widget.currentUser!.setGender = gender;
              //currentUser!.save();
            });
          },
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: selected == gender ? Colors.white : kGrayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void isFirstLive() async {
    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder(LiveStreamingModel());
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId);

    ParseResponse parseResponse = await queryBuilder.count();

    if (parseResponse.success) {
      if (parseResponse.count > 0) {
        isFirstTime = false;
      } else {
        isFirstTime = true;
      }
    }
  }

  void createLive() async {
    QuickHelp.showLoadingDialog(context, isDismissible: false);

    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder(LiveStreamingModel());
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId);
    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);

    ParseResponse parseResponse = await queryBuilder.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        LiveStreamingModel live =
            parseResponse.results!.first! as LiveStreamingModel;

        live.setStreaming = false;
        await live.save();

        createLiveFinish();
      } else {
        createLiveFinish();
      }
    } else {
      QuickHelp.hideLoadingDialog(context);

      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "live_streaming.live_set_cover_error".tr(),
          message: parseResponse.error!.message,
          isError: true,
          user: widget.currentUser);
    }
  }

  createLiveFinish() async {
    LiveStreamingModel streamingModel = LiveStreamingModel();
    if (Setup.isDebug) print("Check live 1");
    streamingModel.setStreamingChannel =
        widget.currentUser!.objectId! + widget.currentUser!.getUid!.toString();
    if (Setup.isDebug) print("Check live 2");
    streamingModel.setAuthor = widget.currentUser!;
    if (Setup.isDebug) print("Check live 3");
    streamingModel.setAuthorId = widget.currentUser!.objectId!;
    if (Setup.isDebug) print("Check live 4");
    streamingModel.setAuthorUid = widget.currentUser!.getUid!;
    if (Setup.isDebug) print("Check live 5");
    streamingModel.addAuthorTotalDiamonds =
        widget.currentUser!.getDiamondsTotal!;
    if (Setup.isDebug) print("Check live 6");
    streamingModel.setFirstLive = isFirstTime;
    if (Setup.isDebug) print("Check live 7");

    streamingModel.setImage = widget.currentUser!.getLiveCover!;
    if (Setup.isDebug) print("Check live 8");
    streamingModel.setLiveSubType = liveSubTypeSelected[0];
    if (widget.currentUser!.getGeoPoint != null) {
      if (Setup.isDebug) print("Check live 9");
      streamingModel.setStreamingGeoPoint = widget.currentUser!.getGeoPoint!;
    }

    if (Setup.isDebug) print("Check live 10");

    if (Setup.isDebug) print("Check live 12");
    streamingModel.setPrivate = false;
    if (Setup.isDebug) print("Check live 3");
    streamingModel.setStreaming = false;
    if (Setup.isDebug) print("Check live 14");
    streamingModel.addViewersCount = 0;
    if (Setup.isDebug) print("Check live 15");
    streamingModel.addDiamonds = 0;
    if (Setup.isDebug) print("Check live 16");

    streamingModel.setLiveTitle = liveTitleTextController.text;
    if (Setup.isDebug) print("Check live 16");

    streamingModel.setLiveType = LiveStreamingModel.liveVideo;
    streamingModel.save().then((value) {
      if (Setup.isDebug) print("Check live 17");

      if (value.success) {
        LiveStreamingModel liveStreaming = value.results!.first!;

        QuickHelp.hideLoadingDialog(context);

        QuickHelp.goToNavigatorScreen(
          context,
          LiveStreamingScreen(
            channelName: streamingModel.getStreamingChannel!,
            isBroadcaster: true,
            preferences: preferences,
            currentUser: widget.currentUser!,
            mLiveStreamingModel: liveStreaming,
          ),
        );
      } else {
        QuickHelp.hideLoadingDialog(context);

        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "live_streaming.live_set_cover_error".tr(),
            message: value.error!.message,
            isError: true,
            user: widget.currentUser);
      }

      if (Setup.isDebug) print("Check live 17 (1)");
    }).onError((ParseError error, stackTrace) {
      if (Setup.isDebug) print("Check live 18");

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "live_streaming.live_set_cover_error".tr(),
          message: "unknown_error".tr(),
          isError: true,
          user: widget.currentUser);
    }).catchError((err) {
      if (Setup.isDebug) print("Check live 19: $err");

      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "live_streaming.live_set_cover_error".tr(),
          message: "unknown_error".tr(),
          isError: true,
          user: widget.currentUser);
    });
  }

  initSharedPref() async {
    preferences = await SharedPreferences.getInstance();
    Constants.queryParseConfig(preferences);
  }

  void createParty() async {
    QuickHelp.showLoadingDialog(context, isDismissible: false);

    QueryBuilder<LiveStreamingModel> queryBuilder =
        QueryBuilder(LiveStreamingModel());
    queryBuilder.whereEqualTo(
        LiveStreamingModel.keyAuthorId, widget.currentUser!.objectId);
    queryBuilder.whereEqualTo(LiveStreamingModel.keyStreaming, true);

    ParseResponse parseResponse = await queryBuilder.query();
    if (parseResponse.success) {
      if (parseResponse.results != null) {
        LiveStreamingModel live =
            parseResponse.results!.first! as LiveStreamingModel;

        live.setStreaming = false;
        await live.save();

        createLivePartyFinish();
      } else {
        createLivePartyFinish();
      }
    } else {
      QuickHelp.showErrorResult(context, parseResponse.error!.code);
      QuickHelp.hideLoadingDialog(context);
    }
  }

  createLivePartyFinish() async {
    int numberOfChairs = 0;
    LiveStreamingModel streamingModel = LiveStreamingModel();
    streamingModel.setStreamingChannel =
        widget.currentUser!.objectId! + widget.currentUser!.getUid!.toString();

    streamingModel.setAuthor = widget.currentUser!;
    streamingModel.setAuthorId = widget.currentUser!.objectId!;
    streamingModel.setAuthorUid = widget.currentUser!.getUid!;
    streamingModel.addAuthorTotalDiamonds =
        widget.currentUser!.getDiamondsTotal!;
    streamingModel.setFirstLive = isFirstTime;

    streamingModel.setLiveTitle = liveTitleTextController.text;
    streamingModel.setImage = widget.currentUser!.getLiveCover!;

    if(widget.currentUser!.getPartyTheme != null) {
      streamingModel.setPartyTheme = widget.currentUser!.getPartyTheme!;
    }

    if (selectedPartyChairsNumber[0] == 0) {
      numberOfChairs = 4;
    } else if (selectedPartyChairsNumber[0] == 1) {
      numberOfChairs = 6;
    } else {
      numberOfChairs = 9;
    }
    streamingModel.setNumberOfChairs = numberOfChairs;

    if (partyVoiceOrVideoIndex == 0) {
      streamingModel.setPartyType = LiveStreamingModel.liveVideo;
    } else {
      streamingModel.setPartyType = LiveStreamingModel.liveAudio;
    }

    if (widget.currentUser!.getGeoPoint != null) {
      streamingModel.setStreamingGeoPoint = widget.currentUser!.getGeoPoint!;
    }

    streamingModel.setPrivate = false;
    streamingModel.setStreaming = false;
    streamingModel.addViewersCount = 0;
    streamingModel.addDiamonds = 0;

    ParseResponse parseResponse = await streamingModel.save();

    if (parseResponse.success) {
      LiveStreamingModel liveStreaming = parseResponse.results!.first!;

      for (int i = 0; i < numberOfChairs; i++) {
        AudioChatUsersModel audioChatUsersModel = AudioChatUsersModel();
        audioChatUsersModel.setSeatIndex = i;
        audioChatUsersModel.setLiveStreaming = liveStreaming;
        audioChatUsersModel.setLiveStreamingId = liveStreaming.objectId!;

        if (i == 0) {
          audioChatUsersModel.setJoinedUser = widget.currentUser!;
          audioChatUsersModel.setJoinedUserId = widget.currentUser!.objectId!;
          audioChatUsersModel.setJoinedUserUid = widget.currentUser!.getUid!;
          audioChatUsersModel.setCanUserTalk = true;
          audioChatUsersModel.setEnabledVideo = true;
        } else if (i > 0) {
          audioChatUsersModel.setCanUserTalk = false;
          audioChatUsersModel.setEnabledVideo = false;
        }
        audioChatUsersModel.setLetTheRoom = false;

        if (i < (numberOfChairs - 1)) {
          audioChatUsersModel.save();
        }
        if (i == (numberOfChairs - 1)) {
          ParseResponse response = await audioChatUsersModel.save();

          if (response.success) {
            QuickHelp.hideLoadingDialog(context);
            liveTitleTextController.text = "";
            if (partyVoiceOrVideoIndex == 0) {
              QuickHelp.goToNavigatorScreen(
                context,
                VideoPartyScreen(
                  channelName: streamingModel.getStreamingChannel!,
                  isBroadcaster: true,
                  currentUser: widget.currentUser!,
                  mLiveStreamingModel: liveStreaming,
                  preferences: preferences,
                ),
              );
            } else {
              QuickHelp.goToNavigatorScreen(
                context,
                AudioLiveScreen(
                  channelName: streamingModel.getStreamingChannel!,
                  isBroadcaster: true,
                  currentUser: widget.currentUser!,
                  mLiveStreamingModel: liveStreaming,
                  preferences: preferences,
                ),
              );
            }
          } else {
            QuickHelp.hideLoadingDialog(context);
            QuickHelp.showErrorResult(context, 100);
          }
        }
      }
    }
  }
}
