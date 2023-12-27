// ignore_for_file: must_be_immutable

import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/Config.dart';
import '../../helpers/quick_actions.dart';
import '../../helpers/quick_help.dart';
import '../../models/GiftsModel.dart';
import '../../models/UserModel.dart';
import '../../services/dynamic_link_service.dart';
import '../../ui/container_with_corner.dart';
import '../../ui/text_with_tap.dart';
import '../../utils/colors.dart';

class SendGiftInvitationScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  SendGiftInvitationScreen({this.currentUser, this.preferences,Key? key}) : super(key: key);

  @override
  State<SendGiftInvitationScreen> createState() => _SendGiftInvitationScreenState();
}

class _SendGiftInvitationScreenState extends State<SendGiftInvitationScreen> {
  final DynamicLinkService _dynamicLinkService = DynamicLinkService();
  var promotionalImages = [];
  int current = 0;
  final CarouselController _controller = CarouselController();
  String linkToShare = "";


  @override
  void initState() {
    super.initState();
    createLink();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = QuickHelp.isDarkMode(context);

    return Scaffold(
      backgroundColor: kSendGiftColor,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: TextWithTap(
          "invitation_gift_screen.invitation_gift".tr(),
          fontWeight: FontWeight.w700,
        ),
        leading: BackButton(
          color: isDark ? Colors.white : kContentColorLightTheme,
        ),
      ),
      body: ListView(
        children: [
          Stack(
            children: [
              ContainerCorner(
                marginTop: 60,
                borderRadius: 10,
                height: 350,
                marginLeft: 30,
                marginRight: 30,
                color: Colors.white,
                borderWidth: 0,
                child: FutureBuilder(
                    future: getPromotionalImages(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        promotionalImages = snapshot.data as List<dynamic>;
                        return ContainerCorner(
                          borderWidth: 0,
                          child: CarouselSlider.builder(
                              options: CarouselOptions(
                                  autoPlay: false,
                                  enableInfiniteScroll: false,
                                  enlargeCenterPage: true,
                                  viewportFraction: 0.65,
                                  enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                                  aspectRatio: 1.3,
                                  autoPlayCurve: Curves.bounceIn,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      current = index;
                                    });
                                  }),
                              carouselController: _controller,
                              itemCount: promotionalImages.length,
                              itemBuilder: (BuildContext context, int itemIndex,
                                  int pageViewIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 5, right: 5, top: 50, bottom: 10),
                                  child: QuickActions.photosWidget(
                                    promotionalImages[itemIndex]["file"]["url"],
                                    borderRadius: 10,
                                  ),
                                );
                              }),
                        );
                      } else if (snapshot.hasError) {
                        return ContainerCorner(
                            height: 230,
                            child: Center(child: TextWithTap("personality_screen.nothing_found".tr())));
                      }else if(!snapshot.hasData){
                        return ContainerCorner(
                            height: 230,
                            child: Center(child: QuickHelp.appLoading())
                        );
                      }else {
                        return ContainerCorner(
                            height: 230,
                            child: Center(child: QuickHelp.appLoading())
                        );
                      }
                    }),
              ),
              Align(
                child: ContainerCorner(
                  borderWidth: 0,
                  borderRadius: 10,
                  height: 35,
                  marginLeft: 30,
                  marginRight: 30,
                  color: kColorsAmber900,
                  marginBottom: 20,
                  marginTop: 40,
                  width: 170,
                  child: TextWithTap(
                    "invitation_gift_screen.choose_promotional_image".tr(),
                    color: Colors.white,
                    alignment: Alignment.center,
                    marginLeft: 10,
                    marginRight: 10,
                  ),
                ),
              ),
            ],
          ),
          ContainerCorner(
            height: 150,
            color: Colors.black.withOpacity(0.3),
            borderRadius: 10,
            marginRight: 30,
            marginLeft: 30,
            marginTop: 15,
            child: TextWithTap(linkToShare, color: Colors.white, marginTop: 10, marginLeft: 15, marginRight: 15,),
          ),
          ContainerCorner(
            borderWidth: 0,
            borderRadius: 10,
            height: 35,
            marginLeft: 30,
            marginRight: 30,
            color: kColorsAmber900,
            marginBottom: 20,
            marginTop: 40,
            width: 170,
            onTap: ()=> shareLink(),
            child: TextWithTap(
              "invitation_gift_screen.click_to_share".tr(),
              color: Colors.white,
              alignment: Alignment.center,
              marginLeft: 10,
              marginRight: 10,
            ),
          )
      ],),
    );
  }

  getPromotionalImages() async {

    QueryBuilder<GiftsModel> query = QueryBuilder<GiftsModel>(GiftsModel());

    query.whereEqualTo(
        GiftsModel.keyGiftCategories, GiftsModel.categoryPromotionalImage);


    ParseResponse response = await query.query();

    if (response.success) {
      if (response.result != null) {
        return response.results;
      }else{
        return response.error as dynamic;
      }
    }
  }

  shareLink() async {
    Share.share("settings_screen.share_app_url".tr(namedArgs: {"app_name": Config.appName, "url": linkToShare}));
  }

  createLink() async {
    Uri? uri = await _dynamicLinkService
        .createDynamicLink(widget.currentUser!.objectId, DynamicLinkService.keyLinkInvitation);

    if (uri != null) {
      setState(() {
        linkToShare = uri.toString();
      });
    }
    else {
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "settings_screen.app_could_not_gen_uri".tr(),
          user: widget.currentUser);
    }
  }
}
