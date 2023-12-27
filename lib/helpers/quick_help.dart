// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/app/cloud_params.dart';
import 'package:trace/app/setup.dart';
import 'package:trace/helpers/quick_actions.dart';
import 'package:trace/home/message/message_screen.dart';
import 'package:trace/models/GiftsModel.dart';
import 'package:trace/models/ReportModel.dart';
import 'package:trace/models/UserModel.dart';
import 'package:trace/ui/rounded_gradient_button.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';
import 'package:trace/utils/shared_manager.dart';
import 'package:trace/widgets/need_resume.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:trace/app/config.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:trace/widgets/snackbar_pro/snack_bar_pro.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../app/navigation_service.dart';
import '../models/CoinsTransactionsModel.dart';
import '../models/GiftReceivedModel.dart';
import '../models/LiveStreamingModel.dart';
import '../utils/datoo_exeption.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, kIsWeb;

import '../widgets/snackbar_pro/top_snack_bar.dart';

typedef EmailSendingCallback = void Function(bool sent, ParseError? error);

class QuickHelp {
  ParseConfig config = ParseConfig();

  static const String pageTypeTerms = "/terms";
  static const String pageTypePrivacy = "/privacy";
  static const String pageTypeOpenSource = "/opensource";
  static const String pageTypeHelpCenter = "/help";
  static const String pageTypeSafety = "/safety";
  static const String pageTypeCommunity = "/community";
  static const String pageTypeWhatsapp = "/whatsapp";
  static const String pageTypeInstructions = "/instructions";
  static const String pageTypeSupport = "/support";
  static const String pageTypeCashOut = "/cashOut";

  static String dateFormatDmy = "dd/MM/yyyy";
  static String dateFormatFacebook = "MM/dd/yyyy";
  static String dateFormatForFeed = "dd MMM, yyyy - HH:mm";

  static String dateFormatTimeOnly = "HH:mm";
  static String dateFormatListMessageFull = "dd MM, HH:mm";
  static String dateFormatDateOnly = "dd/MM/yy";
  static String dateFormatDayAndDateOnly = "EE., dd MMM";

  static String emailTypeWelcome = "welcome_email";
  static String emailTypeVerificationCode = "verification_code_email";

  static double earthMeanRadiusKm = 6371.0;
  static double earthMeanRadiusMile = 3958.8;

  // Online/offline track
  static int timeToSoon = 300 * 1000;
  static int timeToOffline = 2 * 60 * 1000;

  static final String admobBannerAdTest = isAndroidPlatform()
      ? "ca-app-pub-3940256099942544/6300978111"
      : "ca-app-pub-3940256099942544/2934735716";

  static final String admobNativeAdTest = isAndroidPlatform()
      ? "ca-app-pub-3940256099942544/2247696110"
      : "ca-app-pub-3940256099942544/3986624511";

  static final String admobOpenAppAdTest = isAndroidPlatform()
      ? "ca-app-pub-3940256099942544/3419835294"
      : "ca-app-pub-3940256099942544/5662855259";

  static copyText({required String textToCopy}) {
    Clipboard.setData(ClipboardData(text: textToCopy));
  }

  static Color stringToColor(String colorString) {
    String valueString =
    colorString.split('(0x')[1].split(')')[0]; // kind of hacky..
    int value = int.parse(valueString, radix: 16);
    Color reverseColor = Color(value);
    return reverseColor;
  }

  static bool isAvailable(DateTime expireDate) {
    DateTime now = DateTime.now();

    if (expireDate.isAfter(now)) {
      return true;
    } else {
      return false;
    }
  }

  static Color getColorStandard({bool? inverse}) {
    if (isDarkModeNoContext()) {
      if (inverse != null && inverse) {
        return kContentColorLightTheme;
      } else {
        return kContentColorDarkTheme;
      }
    } else {
      if (inverse != null && inverse) {
        return kContentColorDarkTheme;
      } else {
        return kContentColorLightTheme;
      }
    }
  }

  static String fanClubIcon({required int day}) {
    if(day == 0) {
      return "assets/images/tab_fst_0.png";
    }else if(day == 1) {
      return "assets/images/tab_fst_1.png";
    }else if(day == 2) {
      return "assets/images/tab_fst_2.png";
    }else if(day == 3) {
      return "assets/images/tab_fst_3.png";
    }else if(day == 4) {
      return "assets/images/tab_fst_4.png";
    }else if(day == 5) {
      return "assets/images/tab_fst_5.png";
    }else if(day == 6) {
      return "assets/images/tab_fst_6.png";
    }else if(day == 7) {
      return "assets/images/tab_fst_7.png";
    }else if(day == 8) {
      return "assets/images/tab_fst_8.png";
    }else if(day == 9) {
      return "assets/images/tab_fst_9.png";
    }else if(day == 10) {
      return "assets/images/tab_fst_10.png";
    }else if(day == 11) {
      return "assets/images/tab_fst_11.png";
    }else if(day == 12) {
      return "assets/images/tab_fst_12.png";
    }else if(day == 13) {
      return "assets/images/tab_fst_13.png";
    }else if(day == 14) {
      return "assets/images/tab_fst_14.png";
    }else if(day == 15) {
      return "assets/images/tab_fst_15.png";
    }else if(day == 16) {
      return "assets/images/tab_fst_16.png";
    }else if(day == 17) {
      return "assets/images/tab_fst_17.png";
    }else if(day == 18) {
      return "assets/images/tab_fst_18.png";
    }else if(day == 19) {
      return "assets/images/tab_fst_19.png";
    }else if(day == 20) {
      return "assets/images/tab_fst_20.png";
    }else if(day == 21) {
      return "assets/images/tab_fst_21.png";
    }else if(day == 22) {
      return "assets/images/tab_fst_22.png";
    }else if(day == 23) {
      return "assets/images/tab_fst_23.png";
    }else if(day == 24) {
      return "assets/images/tab_fst_24.png";
    }else if(day == 25) {
      return "assets/images/tab_fst_25.png";
    }else if(day == 26) {
      return "assets/images/tab_fst_26.png";
    }else if(day == 27) {
      return "assets/images/tab_fst_27.png";
    }else if(day == 28) {
      return "assets/images/tab_fst_28.png";
    }else if(day == 29) {
      return "assets/images/tab_fst_29.png";
    }else if(day == 30) {
      return "assets/images/tab_fst_30.png";
    }else if(day == 31) {
      return "assets/images/tab_fst_31.png";
    }else if(day == 32) {
      return "assets/images/tab_fst_32.png";
    }else if(day == 33) {
      return "assets/images/tab_fst_33.png";
    }else if(day == 34) {
      return "assets/images/tab_fst_34.png";
    }else if(day == 35) {
      return "assets/images/tab_fst_35.png";
    }else if(day == 36) {
      return "assets/images/tab_fst_36.png";
    }else if(day == 37) {
      return "assets/images/tab_fst_37.png";
    }else if(day == 38) {
      return "assets/images/tab_fst_38.png";
    }else if(day == 39) {
      return "assets/images/tab_fst_39.png";
    }else if(day == 40) {
      return "assets/images/tab_fst_40.png";
    }else if(day == 41) {
      return "assets/images/tab_fst_41.png";
    }else if(day == 42) {
      return "assets/images/tab_fst_42.png";
    }else if(day == 43) {
      return "assets/images/tab_fst_43.png";
    }else if(day == 44) {
      return "assets/images/tab_fst_44.png";
    }else if(day == 45) {
      return "assets/images/tab_fst_45.png";
    }else if(day == 46) {
      return "assets/images/tab_fst_46.png";
    }else if(day == 47) {
      return "assets/images/tab_fst_47.png";
    }else if(day == 48) {
      return "assets/images/tab_fst_48.png";
    }else if(day == 49) {
      return "assets/images/tab_fst_49.png";
    }else if(day == 50) {
      return "assets/images/tab_fst_50.png";
    }else if(day == 51) {
      return "assets/images/tab_fst_51.png";
    }else if(day == 52) {
      return "assets/images/tab_fst_52.png";
    }else if(day == 53) {
      return "assets/images/tab_fst_53.png";
    }else if(day == 54) {
      return "assets/images/tab_fst_54.png";
    }else if(day == 55) {
      return "assets/images/tab_fst_55.png";
    }else if(day == 56) {
      return "assets/images/tab_fst_56.png";
    }else if(day == 57) {
      return "assets/images/tab_fst_57.png";
    }else if(day == 58) {
      return "assets/images/tab_fst_58.png";
    }else if(day == 59) {
      return "assets/images/tab_fst_59.png";
    }else if(day == 60) {
      return "assets/images/tab_fst_60.png";
    }else if(day == 61) {
      return "assets/images/tab_fst_61.png";
    }else if(day == 62) {
      return "assets/images/tab_fst_62.png";
    }else if(day == 63) {
      return "assets/images/tab_fst_63.png";
    }else if(day == 64) {
      return "assets/images/tab_fst_64.png";
    }else if(day == 65) {
      return "assets/images/tab_fst_65.png";
    }else if(day == 66) {
      return "assets/images/tab_fst_66.png";
    }else if(day == 67) {
      return "assets/images/tab_fst_67.png";
    }else if(day == 68) {
      return "assets/images/tab_fst_68.png";
    }else if(day == 69) {
      return "assets/images/tab_fst_69.png";
    }else if(day == 70) {
      return "assets/images/tab_fst_70.png";
    }else if(day == 71) {
      return "assets/images/tab_fst_71.png";
    }else if(day == 72) {
      return "assets/images/tab_fst_72.png";
    }else if(day == 73) {
      return "assets/images/tab_fst_73.png";
    }else if(day == 74) {
      return "assets/images/tab_fst_74.png";
    }else if(day == 75) {
      return "assets/images/tab_fst_75.png";
    }else if(day == 76) {
      return "assets/images/tab_fst_76.png";
    }else if(day == 77) {
      return "assets/images/tab_fst_77.png";
    }else if(day == 78) {
      return "assets/images/tab_fst_78.png";
    }else if(day == 79) {
      return "assets/images/tab_fst_79.png";
    }else if(day == 80) {
      return "assets/images/tab_fst_80.png";
    }else if(day == 81) {
      return "assets/images/tab_fst_81.png";
    }else if(day == 82) {
      return "assets/images/tab_fst_82.png";
    }else if(day == 83) {
      return "assets/images/tab_fst_83.png";
    }else if(day == 84) {
      return "assets/images/tab_fst_84.png";
    }else if(day == 85) {
      return "assets/images/tab_fst_85.png";
    }else if(day == 86) {
      return "assets/images/tab_fst_86.png";
    }else if(day == 87) {
      return "assets/images/tab_fst_87.png";
    }else if(day == 88) {
      return "assets/images/tab_fst_88.png";
    }else if(day == 89) {
      return "assets/images/tab_fst_89.png";
    }else if(day == 90) {
      return "assets/images/tab_fst_90.png";
    }else if(day == 91) {
      return "assets/images/tab_fst_91.png";
    }else if(day == 92) {
      return "assets/images/tab_fst_92.png";
    }else if(day == 93) {
      return "assets/images/tab_fst_93.png";
    }else if(day == 94) {
      return "assets/images/tab_fst_94.png";
    }else if(day == 95) {
      return "assets/images/tab_fst_95.png";
    }else if(day == 96) {
      return "assets/images/tab_fst_96.png";
    }else if(day == 97) {
      return "assets/images/tab_fst_97.png";
    }else if(day == 98) {
      return "assets/images/tab_fst_98.png";
    }else if(day == 99) {
      return "assets/images/tab_fst_99.png";
    }else if(day == 100) {
      return "assets/images/tab_fst_100.png";
    }else{
      return "assets/images/tab_fst_0.png";
    }
  }

  static String checkFundsWithString({required String amount,}) {

    //final formatter = intl.NumberFormat.decimalPattern();

    NumberFormat format = NumberFormat.decimalPatternDigits(
        locale: Intl.defaultLocale,);
    if (amount.isNotEmpty) {
      return "${format.format(double.parse(amount))}";
    } else {
      return format.format(double.parse("0.00"));
    }
  }

  static String checkFundsWithCurrency(BuildContext context, {required String amount, required String currency,}) {

    NumberFormat format = NumberFormat.decimalPatternDigits(
        locale: Intl.defaultLocale,);
    if (amount.isNotEmpty) {
      return "${getCurrency(context, currency)} ${format.format(double.parse(amount))}";
    } else {
      return format.format(double.parse("0.00"));
    }
  }

  static NumberFormat getCurrency(BuildContext context, String currency) {
    Locale locale = Localizations.localeOf(context);
    return NumberFormat.simpleCurrency(
        locale: locale.toString(), name: currency);
  }

  static String levelImageWithBanner({required int pointsInApp}) {
    if(pointsInApp <= Setup.level1MaxPoint){
      return "assets/images/grade_big_1.png";
    }else if (pointsInApp <= Setup.level2MaxPoint) {
      return "assets/images/grade_big_2.png";
    } else if (pointsInApp <= Setup.level3MaxPoint) {
      return "assets/images/grade_big_3.png";
    } else if (pointsInApp <= Setup.level4MaxPoint) {
      return "assets/images/grade_big_4.png";
    } else if (pointsInApp <= Setup.level5MaxPoint) {
      return "assets/images/grade_big_5.png";
    } else if (pointsInApp <= Setup.level7MaxPoint) {
      return "assets/images/grade_big_6.png";
    } else if (pointsInApp <= Setup.level8MaxPoint) {
      return "assets/images/grade_big_7.png";
    } else if (pointsInApp <= Setup.level9MaxPoint) {
      return "assets/images/grade_big_8.png";
    } else if (pointsInApp <= Setup.level10MaxPoint) {
      return "assets/images/grade_big_9.png";
    } else if (pointsInApp <= Setup.level11MaxPoint) {
      return "assets/images/grade_big_10.png";
    } else if (pointsInApp <= Setup.level12MaxPoint) {
      return "assets/images/grade_big_11.png";
    } else if (pointsInApp <= Setup.level13MaxPoint) {
      return "assets/images/grade_big_12.png";
    } else if (pointsInApp <= Setup.level14MaxPoint) {
      return "assets/images/grade_big_13.png";
    } else if (pointsInApp <= Setup.level15MaxPoint) {
      return "assets/images/grade_big_14.png";
    } else if (pointsInApp <= Setup.level16MaxPoint) {
      return "assets/images/grade_big_15.png";
    } else if (pointsInApp <= Setup.level17MaxPoint) {
      return "assets/images/grade_big_16.png";
    } else if (pointsInApp <= Setup.level18MaxPoint) {
      return "assets/images/grade_big_17.png";
    } else if (pointsInApp <= Setup.level19MaxPoint) {
      return "assets/images/grade_big_18.png";
    } else if (pointsInApp <= Setup.level20MaxPoint) {
      return "assets/images/grade_big_19.png";
    } else if (pointsInApp <= Setup.level21MaxPoint) {
      return "assets/images/grade_big_20.png";
    } else if (pointsInApp <= Setup.level22MaxPoint) {
      return "assets/images/grade_big_21.png";
    } else if (pointsInApp <= Setup.level23MaxPoint) {
      return "assets/images/grade_big_22.png";
    } else if (pointsInApp <= Setup.level24MaxPoint) {
      return "assets/images/grade_big_23.png";
    } else if (pointsInApp <= Setup.level25MaxPoint) {
      return "assets/images/grade_big_24.png";
    } else if (pointsInApp <= Setup.level26MaxPoint) {
      return "assets/images/grade_big_25.png";
    } else{
      return "assets/images/grade_big_1.png";
    }
  }

  static String levelCaption({required int pointsInApp}) {
    if(pointsInApp <= Setup.level1MaxPoint){
      return "LV 1";
    }else if (pointsInApp <= Setup.level2MaxPoint) {
      return "LV 2";
    } else if (pointsInApp <= Setup.level3MaxPoint) {
      return "LV 3";
    } else if (pointsInApp <= Setup.level4MaxPoint) {
      return "LV 4";
    } else if (pointsInApp <= Setup.level5MaxPoint) {
      return "LV 5";
    } else if (pointsInApp <= Setup.level7MaxPoint) {
      return "LV 6";
    } else if (pointsInApp <= Setup.level8MaxPoint) {
      return "LV 7";
    } else if (pointsInApp <= Setup.level9MaxPoint) {
      return "LV 8";
    } else if (pointsInApp <= Setup.level10MaxPoint) {
      return "LV 9";
    } else if (pointsInApp <= Setup.level11MaxPoint) {
      return "LV 10";
    } else if (pointsInApp <= Setup.level12MaxPoint) {
      return "LV 11";
    } else if (pointsInApp <= Setup.level13MaxPoint) {
      return "LV 12";
    } else if (pointsInApp <= Setup.level14MaxPoint) {
      return "LV 13";
    } else if (pointsInApp <= Setup.level15MaxPoint) {
      return "LV 14";
    } else if (pointsInApp <= Setup.level16MaxPoint) {
      return "LV 15";
    } else if (pointsInApp <= Setup.level17MaxPoint) {
      return "LV 16";
    } else if (pointsInApp <= Setup.level18MaxPoint) {
      return "LV 17";
    } else if (pointsInApp <= Setup.level19MaxPoint) {
      return "LV 18";
    } else if (pointsInApp <= Setup.level20MaxPoint) {
      return "LV 19";
    } else if (pointsInApp <= Setup.level21MaxPoint) {
      return "LV 20";
    } else if (pointsInApp <= Setup.level22MaxPoint) {
      return "LV 21";
    } else if (pointsInApp <= Setup.level23MaxPoint) {
      return "LV 22";
    } else if (pointsInApp <= Setup.level24MaxPoint) {
      return "LV 23";
    } else if (pointsInApp <= Setup.level25MaxPoint) {
      return "LV 24";
    } else if (pointsInApp <= Setup.level26MaxPoint) {
      return "LV 26";
    } else{
      return "LV 0";
    }
  }

  static int levelPositionIndex({required int pointsInApp}) {
    if(pointsInApp <= Setup.level1MaxPoint){
      return 1;
    }else if (pointsInApp <= Setup.level2MaxPoint) {
      return 2;
    } else if (pointsInApp <= Setup.level3MaxPoint) {
      return 3;
    } else if (pointsInApp <= Setup.level4MaxPoint) {
      return 4;
    } else if (pointsInApp <= Setup.level5MaxPoint) {
      return 5;
    } else if (pointsInApp <= Setup.level7MaxPoint) {
      return 6;
    } else if (pointsInApp <= Setup.level8MaxPoint) {
      return 7;
    } else if (pointsInApp <= Setup.level9MaxPoint) {
      return 8;
    } else if (pointsInApp <= Setup.level10MaxPoint) {
      return 9;
    } else if (pointsInApp <= Setup.level11MaxPoint) {
      return 10;
    } else if (pointsInApp <= Setup.level12MaxPoint) {
      return 11;
    } else if (pointsInApp <= Setup.level13MaxPoint) {
      return 12;
    } else if (pointsInApp <= Setup.level14MaxPoint) {
      return 13;
    } else if (pointsInApp <= Setup.level15MaxPoint) {
      return 14;
    } else if (pointsInApp <= Setup.level16MaxPoint) {
      return 15;
    } else if (pointsInApp <= Setup.level17MaxPoint) {
      return 16;
    } else if (pointsInApp <= Setup.level18MaxPoint) {
      return 17;
    } else if (pointsInApp <= Setup.level19MaxPoint) {
      return 18;
    } else if (pointsInApp <= Setup.level20MaxPoint) {
      return 19;
    } else if (pointsInApp <= Setup.level21MaxPoint) {
      return 20;
    } else if (pointsInApp <= Setup.level22MaxPoint) {
      return 21;
    } else if (pointsInApp <= Setup.level23MaxPoint) {
      return 22;
    } else if (pointsInApp <= Setup.level24MaxPoint) {
      return 23;
    } else if (pointsInApp <= Setup.level25MaxPoint) {
      return 24;
    } else if (pointsInApp <= Setup.level26MaxPoint) {
      return 25;
    } else{
      return 0;
    }
  }

  static int levelPositionValues({required int pointsInApp}) {
    if(pointsInApp <= Setup.level1MaxPoint){
      return Setup.level1MaxPoint;
    }else if (pointsInApp <= Setup.level2MaxPoint) {
      return Setup.level2MaxPoint;
    } else if (pointsInApp <= Setup.level3MaxPoint) {
      return Setup.level3MaxPoint;
    } else if (pointsInApp <= Setup.level4MaxPoint) {
      return Setup.level4MaxPoint;
    } else if (pointsInApp <= Setup.level5MaxPoint) {
      return Setup.level5MaxPoint;
    } else if (pointsInApp <= Setup.level7MaxPoint) {
      return Setup.level7MaxPoint;
    } else if (pointsInApp <= Setup.level8MaxPoint) {
      return Setup.level8MaxPoint;
    } else if (pointsInApp <= Setup.level9MaxPoint) {
      return Setup.level9MaxPoint;
    } else if (pointsInApp <= Setup.level10MaxPoint) {
      return Setup.level10MaxPoint;
    } else if (pointsInApp <= Setup.level11MaxPoint) {
      return Setup.level11MaxPoint;
    } else if (pointsInApp <= Setup.level12MaxPoint) {
      return Setup.level12MaxPoint;
    } else if (pointsInApp <= Setup.level13MaxPoint) {
      return Setup.level13MaxPoint;
    } else if (pointsInApp <= Setup.level14MaxPoint) {
      return Setup.level14MaxPoint;
    } else if (pointsInApp <= Setup.level15MaxPoint) {
      return Setup.level15MaxPoint;
    } else if (pointsInApp <= Setup.level16MaxPoint) {
      return Setup.level16MaxPoint;
    } else if (pointsInApp <= Setup.level17MaxPoint) {
      return Setup.level17MaxPoint;
    } else if (pointsInApp <= Setup.level18MaxPoint) {
      return Setup.level18MaxPoint;
    } else if (pointsInApp <= Setup.level19MaxPoint) {
      return Setup.level19MaxPoint;
    } else if (pointsInApp <= Setup.level20MaxPoint) {
      return Setup.level20MaxPoint;
    } else if (pointsInApp <= Setup.level21MaxPoint) {
      return Setup.level21MaxPoint;
    } else if (pointsInApp <= Setup.level22MaxPoint) {
      return Setup.level22MaxPoint;
    } else if (pointsInApp <= Setup.level23MaxPoint) {
      return Setup.level23MaxPoint;
    } else if (pointsInApp <= Setup.level24MaxPoint) {
      return Setup.level24MaxPoint;
    } else if (pointsInApp <= Setup.level25MaxPoint) {
      return Setup.level25MaxPoint;
    } else if (pointsInApp <= Setup.level26MaxPoint) {
      return Setup.level26MaxPoint;
    } else{
      return 0;
    }
  }

  static int wealthLevelValue({required int creditSent}) {
    if(creditSent == 0) {
      return 0;
    }else if (creditSent <= 3000) {
      return 3000;
    } else if (creditSent <= 6000) {
      return 6000;
    } else if (creditSent <= 16000) {
      return 16000;
    } else if (creditSent <= 66000) {
      return 66000;
    } else if (creditSent <= 166000) {
      return 166000;
    } else if (creditSent <= 330000) {
      return 330000;
    } else if (creditSent <= 500000) {
      return 500000;
    } else if (creditSent <= 700000) {
      return 700000;
    } else if (creditSent <= 1000000) {
      return 1000000;
    } else if (creditSent <= 1100000) {
      return 1100000;
    } else if (creditSent <= 1300000) {
      return 1300000;
    } else if (creditSent <= 1600000) {
      return 1600000;
    } else if (creditSent <= 2000000) {
      return 2000000;
    } else if (creditSent <= 2600000) {
      return 2600000;
    } else if (creditSent <= 3400000) {
      return 3400000;
    } else if (creditSent <= 4400000) {
      return 4400000;
    } else if (creditSent <= 5600000) {
      return 5600000;
    } else if (creditSent <= 7000000) {
      return 7000000;
    } else if (creditSent <= 10000000) {
      return 10000000;
    } else if (creditSent <= 10500000) {
      return 10500000;
    } else if (creditSent <= 11500000) {
      return 11500000;
    } else if (creditSent <= 13000000) {
      return 13000000;
    } else if (creditSent <= 15000000) {
      return 15000000;
    } else if (creditSent <= 18000000) {
      return 18000000;
    } else if (creditSent <= 22000000) {
      return 22000000;
    } else if (creditSent <= 27000000) {
      return 27000000;
    } else if (creditSent <= 33000000) {
      return 33000000;
    } else if (creditSent <= 40000000) {
      return 40000000;
    } else if (creditSent <= 50000000) {
      return 50000000;
    } else if (creditSent <= 52000000) {
      return 52000000;
    } else if (creditSent <= 55000000) {
      return 55000000;
    } else if (creditSent <= 60000000) {
      return 60000000;
    } else if (creditSent <= 68000000) {
      return 68000000;
    } else if (creditSent <= 79000000) {
      return 79000000;
    } else if (creditSent <= 95000000) {
      return 95000000;
    } else if (creditSent <= 114000000) {
      return 114000000;
    } else if (creditSent <= 137000000) {
      return 137000000;
    } else if (creditSent <= 163000000) {
      return 163000000;
    } else if (creditSent <= 200000000) {
      return 200000000;
    } else if (creditSent <= 204000000) {
      return 204000000;
    } else if (creditSent <= 210000000) {
      return 210000000;
    } else if (creditSent <= 220000000) {
      return 220000000;
    } else if (creditSent <= 236000000) {
      return 236000000;
    } else if (creditSent <= 258000000) {
      return 258000000;
    } else if (creditSent <= 290000000) {
      return 290000000;
    } else if (creditSent <= 328000000) {
      return 328000000;
    } else if (creditSent <= 375000000) {
      return 375000000;
    } else if (creditSent <= 428000000) {
      return 428000000;
    } else if (creditSent <= 500000000) {
      return 500000000;
    } else if (creditSent <= 506000000) {
      return 506000000;
    } else if (creditSent <= 516000000) {
      return 516000000;
    } else if (creditSent <= 535000000) {
      return 535000000;
    } else if (creditSent <= 560000000) {
      return 560000000;
    } else if (creditSent <= 598000000) {
      return 598000000;
    } else if (creditSent <= 648000000) {
      return 648000000;
    } else if (creditSent <= 710000000) {
      return 710000000;
    } else if (creditSent <= 785000000) {
      return 785000000;
    } else if (creditSent <= 870000000) {
      return 870000000;
    } else if (creditSent <= 1000000000) {
      return 1000000000;
    } else if (creditSent <= 1020000000) {
      return 1020000000;
    } else if (creditSent <= 1060000000) {
      return 1060000000;
    } else if (creditSent <= 1120000000) {
      return 1120000000;
    } else if (creditSent <= 1220000000) {
      return 1220000000;
    } else if (creditSent <= 1360000000) {
      return 1360000000;
    } else if (creditSent <= 1560000000) {
      return 1560000000;
    } else if (creditSent <= 1800000000) {
      return 1800000000;
    } else if (creditSent <= 2100000000) {
      return 2100000000;
    } else if (creditSent <= 2440000000) {
      return 2440000000;
    } else if (creditSent <= 3000000000) {
      return 3000000000;
    } else if (creditSent <= 3020000000) {
      return 3020000000;
    } else if (creditSent <= 3060000000) {
      return 3060000000;
    } else if (creditSent <= 3120000000) {
      return 3120000000;
    } else if (creditSent <= 3220000000) {
      return 3220000000;
    } else if (creditSent <= 3220000000) {
      return 3220000000;
    } else if (creditSent <= 3360000000) {
      return 3360000000;
    } else if (creditSent <= 3560000000) {
      return 3560000000;
    } else if (creditSent <= 3800000000) {
      return 3800000000;
    } else if (creditSent <= 4100000000) {
      return 4100000000;
    } else if (creditSent <= 4440000000) {
      return 4440000000;
    } else if (creditSent <= 5000000000) {
      return 5000000000;
    } else if (creditSent <= 5050000000) {
      return 5050000000;
    } else if (creditSent <= 5150000000) {
      return 5150000000;
    } else if (creditSent <= 5300000000) {
      return 5300000000;
    } else if (creditSent <= 5550000000) {
      return 5550000000;
    } else if (creditSent <= 5900000000) {
      return 5900000000;
    } else if (creditSent <= 6400000000) {
      return 6400000000;
    } else if (creditSent <= 7000000000) {
      return 7000000000;
    } else if (creditSent <= 7750000000) {
      return 7750000000;
    } else if (creditSent <= 7750000000) {
      return 7750000000;
    } else if (creditSent <= 8600000000) {
      return 8600000000;
    } else if (creditSent <= 10000000000) {
      return 10000000000;
    } else if (creditSent <= 10100000000) {
      return 10100000000;
    } else if (creditSent <= 10300000000) {
      return 10300000000;
    } else if (creditSent <= 10600000000) {
      return 10600000000;
    } else if (creditSent <= 11100000000) {
      return 11100000000;
    } else if (creditSent <= 11800000000) {
      return 11800000000;
    } else if (creditSent <= 12800000000) {
      return 12800000000;
    } else if (creditSent <= 14000000000) {
      return 14000000000;
    } else if (creditSent <= 15500000000) {
      return 15500000000;
    } else if (creditSent <= 17200000000) {
      return 17200000000;
    } else if (creditSent <= 20600000000) {
      return 20600000000;
    } else if (creditSent <= 20710000000) {
      return 20710000000;
    } else if (creditSent <= 20930000000) {
      return 20930000000;
    } else if (creditSent <= 21260000000) {
      return 21260000000;
    } else if (creditSent <= 21810000000) {
      return 21810000000;
    } else if (creditSent <= 22580000000) {
      return 22580000000;
    } else if (creditSent <= 23680000000) {
      return 23680000000;
    } else if (creditSent <= 25000000000) {
      return 25000000000;
    } else if (creditSent <= 26650000000) {
      return 26650000000;
    } else if (creditSent <= 28520000000) {
      return 28520000000;
    } else if (creditSent <= 30200000000) {
      return 30200000000;
    } else if (creditSent <= 30320000000) {
      return 30320000000;
    } else if (creditSent <= 30560000000) {
      return 30560000000;
    } else if (creditSent <= 30920000000) {
      return 30920000000;
    } else if (creditSent <= 31520000000) {
      return 31520000000;
    } else if (creditSent <= 32360000000) {
      return 32360000000;
    } else if (creditSent <= 33560000000) {
      return 33560000000;
    } else if (creditSent <= 35000000000) {
      return 35000000000;
    } else if (creditSent <= 36800000000) {
      return 36800000000;
    } else if (creditSent <= 38840000000) {
      return 38840000000;
    } else if (creditSent <= 40688000000) {
      return 40688000000;
    } else if (creditSent <= 40820000000) {
      return 40820000000;
    } else if (creditSent <= 41084000000) {
      return 41084000000;
    } else if (creditSent <= 41480000000) {
      return 41480000000;
    } else if (creditSent <= 42140000000) {
      return 42140000000;
    } else if (creditSent <= 43064000000) {
      return 43064000000;
    } else if (creditSent <= 44384000000) {
      return 44384000000;
    } else if (creditSent <= 45968000000) {
      return 45968000000;
    } else if (creditSent <= 47948000000) {
      return 47948000000;
    } else if (creditSent <= 50192000000) {
      return 50192000000;
    } else if (creditSent <= 52208000000) {
      return 52208000000;
    } else if (creditSent <= 52352000000) {
      return 52352000000;
    } else if (creditSent <= 52640000000) {
      return 52640000000;
    } else if (creditSent <= 53072000000) {
      return 53072000000;
    } else if (creditSent <= 53792000000) {
      return 53792000000;
    } else if (creditSent <= 54800000000) {
      return 54800000000;
    } else if (creditSent <= 56240000000) {
      return 56240000000;
    } else if (creditSent <= 57968000000) {
      return 57968000000;
    } else if (creditSent <= 60128000000) {
      return 60128000000;
    } else if (creditSent <= 62576000000) {
      return 62576000000;
    } else if (creditSent <= 64793000000) {
      return 64793000000;
    } else if (creditSent <= 64952000000) {
      return 64952000000;
    } else if (creditSent <= 65268800000) {
      return 65268800000;
    } else if (creditSent <= 65744000000) {
      return 65744000000;
    } else if (creditSent <= 66536000000) {
      return 66536000000;
    } else if (creditSent <= 67644000000) {
      return 67644000000;
    } else if (creditSent <= 69228800000) {
      return 69228800000;
    } else if (creditSent <= 71129600000) {
      return 71129600000;
    } else if (creditSent <= 73505600000) {
      return 73505600000;
    } else if (creditSent <= 76198400000) {
      return 76198400000;
    } else if (creditSent <= 78617600000) {
      return 78617600000;
    } else if (creditSent <= 78790400000) {
      return 78790400000;
    } else if (creditSent <= 79136000000) {
      return 79136000000;
    } else if (creditSent <= 79654400000) {
      return 79654400000;
    } else if (creditSent <= 80518400000) {
      return 80518400000;
    } else if (creditSent <= 81728000000) {
      return 81728000000;
    } else if (creditSent <= 83456000000) {
      return 83456000000;
    } else if (creditSent <= 85529600000) {
      return 85529600000;
    } else if (creditSent <= 88121600000) {
      return 88121600000;
    } else if (creditSent <= 91059200000) {
      return 91059200000;
    } else if (creditSent <= 93720320000) {
      return 93720320000;
    } else if (creditSent <= 93910400000) {
      return 93910400000;
    } else if (creditSent <= 94290560000) {
      return 94290560000;
    } else if (creditSent <= 94860800000) {
      return 94860800000;
    } else if (creditSent <= 95811200000) {
      return 95811200000;
    } else if (creditSent <= 97141760000) {
      return 97141760000;
    } else if (creditSent <= 99042560000) {
      return 99042560000;
    } else if (creditSent <= 101324000000) {
      return 101324000000;
    } else if (creditSent <= 104174720000) {
      return 104174720000;
    } else if (creditSent <= 107406080000) {
      return 107406080000;
    } else if (creditSent <= 110309120000) {
      return 110309120000;
    } else if (creditSent <= 110516480000) {
      return 110516480000;
    } else if (creditSent <= 110931200000) {
      return 110931200000;
    } else if (creditSent <= 111553280000) {
      return 111553280000;
    } else if (creditSent <= 112590080000) {
      return 112590080000;
    } else if (creditSent <= 114041600000) {
      return 114041600000;
    } else if (creditSent <= 116115200000) {
      return 116115200000;
    } else if (creditSent <= 118603520000) {
      return 118603520000;
    } else if (creditSent <= 121713920000) {
      return 121713920000;
    } else if (creditSent <= 125239040000) {
      return 125239040000;
    } else if (creditSent <= 128432384000) {
      return 128432384000;
    } else if (creditSent <= 128660480000) {
      return 128660480000;
    } else if (creditSent <= 129116672000) {
      return 129116672000;
    } else if (creditSent <= 129800960000) {
      return 129800960000;
    } else if (creditSent <= 130941440000) {
      return 130941440000;
    } else if (creditSent <= 132538112000) {
      return 132538112000;
    } else if (creditSent <= 134819072000) {
      return 134819072000;
    } else if (creditSent <= 137556224000) {
      return 137556224000;
    } else if (creditSent <= 140977664000) {
      return 140977664000;
    } else if (creditSent <= 144855296000) {
      return 144855296000;
    } else if (creditSent <= 148587776000) {
      return 148587776000;
    } else if (creditSent <= 149085440000) {
      return 149085440000;
    } else if (creditSent <= 149831936000) {
      return 149831936000;
    } else if (creditSent <= 151076096000) {
      return 151076096000;
    } else if (creditSent <= 152817920000) {
      return 152817920000;
    } else if (creditSent <= 155306240000) {
      return 155306240000;
  } else if (creditSent <= 158292224000) {
    return 158292224000;
    } else if (creditSent <= 162024704000) {
    return 162024704000;
    } else if (creditSent <= 166254848000) {
    return 166254848000;
    } else if (creditSent <= 170086860800) {
    return 170086860800;
    } else if (creditSent <= 185286860800) {
    return 185286860800;
    } else {
    return 3000;
    }
  }

  static String wealthLevel({required int creditSent}) {
    if(creditSent == 0){
      return "assets/images/caifu_level_1.png";
    }else if (creditSent <= 3000) {
      return "assets/images/caifu_level_2.png";
    } else if (creditSent <= 6000) {
      return "assets/images/caifu_level_3.png";
    } else if (creditSent <= 16000) {
      return "assets/images/caifu_level_4.png";
    } else if (creditSent <= 66000) {
      return "assets/images/caifu_level_5.png";
    } else if (creditSent <= 166000) {
      return "assets/images/caifu_level_6.png";
    } else if (creditSent <= 330000) {
      return "assets/images/caifu_level_7.png";
    } else if (creditSent <= 500000) {
      return "assets/images/caifu_level_8.png";
    } else if (creditSent <= 700000) {
      return "assets/images/caifu_level_9.png";
    } else if (creditSent <= 1000000) {
      return "assets/images/caifu_level_10.png";
    } else if (creditSent <= 1100000) {
      return "assets/images/caifu_level_11.png";
    } else if (creditSent <= 1300000) {
      return "assets/images/caifu_level_12.png";
    } else if (creditSent <= 1600000) {
      return "assets/images/caifu_level_13.png";
    } else if (creditSent <= 2000000) {
      return "assets/images/caifu_level_14.png";
    } else if (creditSent <= 2600000) {
      return "assets/images/caifu_level_15.png";
    } else if (creditSent <= 3400000) {
      return "assets/images/caifu_level_16.png";
    } else if (creditSent <= 4400000) {
      return "assets/images/caifu_level_17.png";
    } else if (creditSent <= 5600000) {
      return "assets/images/caifu_level_18.png";
    } else if (creditSent <= 7000000) {
      return "assets/images/caifu_level_19.png";
    } else if (creditSent <= 10000000) {
      return "assets/images/caifu_level_20.png";
    } else if (creditSent <= 10500000) {
      return "assets/images/caifu_level_21.png";
    } else if (creditSent <= 11500000) {
      return "assets/images/caifu_level_22.png";
    } else if (creditSent <= 13000000) {
      return "assets/images/caifu_level_23.png";
    } else if (creditSent <= 15000000) {
      return "assets/images/caifu_level_24.png";
    } else if (creditSent <= 18000000) {
      return "assets/images/caifu_level_25.png";
    } else if (creditSent <= 22000000) {
      return "assets/images/caifu_level_26.png";
    } else if (creditSent <= 27000000) {
      return "assets/images/caifu_level_27.png";
    } else if (creditSent <= 33000000) {
      return "assets/images/caifu_level_28.png";
    } else if (creditSent <= 40000000) {
      return "assets/images/caifu_level_29.png";
    } else if (creditSent <= 50000000) {
      return "assets/images/caifu_level_30.png";
    } else if (creditSent <= 52000000) {
      return "assets/images/caifu_level_31.png";
    } else if (creditSent <= 55000000) {
      return "assets/images/caifu_level_32.png";
    } else if (creditSent <= 60000000) {
      return "assets/images/caifu_level_33.png";
    } else if (creditSent <= 68000000) {
      return "assets/images/caifu_level_34.png";
    } else if (creditSent <= 79000000) {
      return "assets/images/caifu_level_35.png";
    } else if (creditSent <= 95000000) {
      return "assets/images/caifu_level_36.png";
    } else if (creditSent <= 114000000) {
      return "assets/images/caifu_level_37.png";
    } else if (creditSent <= 137000000) {
      return "assets/images/caifu_level_38.png";
    } else if (creditSent <= 163000000) {
      return "assets/images/caifu_level_39.png";
    } else if (creditSent <= 200000000) {
      return "assets/images/caifu_level_40.png";
    } else if (creditSent <= 204000000) {
      return "assets/images/caifu_level_41.png";
    } else if (creditSent <= 210000000) {
      return "assets/images/caifu_level_42.png";
    } else if (creditSent <= 220000000) {
      return "assets/images/caifu_level_43.png";
    } else if (creditSent <= 236000000) {
      return "assets/images/caifu_level_44.png";
    } else if (creditSent <= 258000000) {
      return "assets/images/caifu_level_45.png";
    } else if (creditSent <= 290000000) {
      return "assets/images/caifu_level_46.png";
    } else if (creditSent <= 328000000) {
      return "assets/images/caifu_level_47.png";
    } else if (creditSent <= 375000000) {
      return "assets/images/caifu_level_48.png";
    } else if (creditSent <= 428000000) {
      return "assets/images/caifu_level_49.png";
    } else if (creditSent <= 500000000) {
      return "assets/images/caifu_level_50.png";
    } else if (creditSent <= 506000000) {
      return "assets/images/caifu_level_51.png";
    } else if (creditSent <= 516000000) {
      return "assets/images/caifu_level_52.png";
    } else if (creditSent <= 535000000) {
      return "assets/images/caifu_level_53.png";
    } else if (creditSent <= 560000000) {
      return "assets/images/caifu_level_54.png";
    } else if (creditSent <= 598000000) {
      return "assets/images/caifu_level_55.png";
    } else if (creditSent <= 648000000) {
      return "assets/images/caifu_level_56.png";
    } else if (creditSent <= 710000000) {
      return "assets/images/caifu_level_57.png";
    } else if (creditSent <= 785000000) {
      return "assets/images/caifu_level_58.png";
    } else if (creditSent <= 870000000) {
      return "assets/images/caifu_level_59.png";
    } else if (creditSent <= 1000000000) {
      return "assets/images/caifu_level_60.png";
    } else if (creditSent <= 1020000000) {
      return "assets/images/caifu_level_61.png";
    } else if (creditSent <= 1060000000) {
      return "assets/images/caifu_level_62.png";
    } else if (creditSent <= 1120000000) {
      return "assets/images/caifu_level_63.png";
    } else if (creditSent <= 1220000000) {
      return "assets/images/caifu_level_64.png";
    } else if (creditSent <= 1360000000) {
      return "assets/images/caifu_level_65.png";
    } else if (creditSent <= 1560000000) {
      return "assets/images/caifu_level_66.png";
    } else if (creditSent <= 1800000000) {
      return "assets/images/caifu_level_67.png";
    } else if (creditSent <= 2100000000) {
      return "assets/images/caifu_level_68.png";
    } else if (creditSent <= 2440000000) {
      return "assets/images/caifu_level_69.png";
    } else if (creditSent <= 3000000000) {
      return "assets/images/caifu_level_70.png";
    } else if (creditSent <= 3020000000) {
      return "assets/images/caifu_level_71.png";
    } else if (creditSent <= 3060000000) {
      return "assets/images/caifu_level_72.png";
    } else if (creditSent <= 3120000000) {
      return "assets/images/caifu_level_73.png";
    } else if (creditSent <= 3220000000) {
      return "assets/images/caifu_level_74.png";
    } else if (creditSent <= 3360000000) {
      return "assets/images/caifu_level_75.png";
    } else if (creditSent <= 3560000000) {
      return "assets/images/caifu_level_76.png";
    } else if (creditSent <= 3800000000) {
      return "assets/images/caifu_level_77.png";
    } else if (creditSent <= 4100000000) {
      return "assets/images/caifu_level_78.png";
    } else if (creditSent <= 4440000000) {
      return "assets/images/caifu_level_79.png";
    } else if (creditSent <= 5000000000) {
      return "assets/images/caifu_level_80.png";
    } else if (creditSent <= 5050000000) {
      return "assets/images/caifu_level_81.png";
    } else if (creditSent <= 5150000000) {
      return "assets/images/caifu_level_82.png";
    } else if (creditSent <= 5300000000) {
      return "assets/images/caifu_level_83.png";
    } else if (creditSent <= 5550000000) {
      return "assets/images/caifu_level_84.png";
    } else if (creditSent <= 5900000000) {
      return "assets/images/caifu_level_85.png";
    } else if (creditSent <= 6400000000) {
      return "assets/images/caifu_level_86.png";
    } else if (creditSent <= 7000000000) {
      return "assets/images/caifu_level_87.png";
    } else if (creditSent <= 7750000000) {
      return "assets/images/caifu_level_88.png";
    } else if (creditSent <= 8600000000) {
      return "assets/images/caifu_level_89.png";
    } else if (creditSent <= 10000000000) {
      return "assets/images/caifu_level_90.png";
    } else if (creditSent <= 10100000000) {
      return "assets/images/caifu_level_91.png";
    } else if (creditSent <= 10300000000) {
      return "assets/images/caifu_level_92.png";
    } else if (creditSent <= 10600000000) {
      return "assets/images/caifu_level_93.png";
    } else if (creditSent <= 11100000000) {
      return "assets/images/caifu_level_94.png";
    } else if (creditSent <= 11800000000) {
      return "assets/images/caifu_level_95.png";
    } else if (creditSent <= 12800000000) {
      return "assets/images/caifu_level_96.png";
    } else if (creditSent <= 14000000000) {
      return "assets/images/caifu_level_97.png";
    } else if (creditSent <= 15500000000) {
      return "assets/images/caifu_level_98.png";
    } else if (creditSent <= 17200000000) {
      return "assets/images/caifu_level_99.png";
    } else if (creditSent <= 20600000000) {
      return "assets/images/caifu_level_100.png";
    } else if (creditSent <= 20710000000) {
      return "assets/images/caifu_level_101.png";
    } else if (creditSent <= 20930000000) {
      return "assets/images/caifu_level_102.png";
    } else if (creditSent <= 21260000000) {
      return "assets/images/caifu_level_103.png";
    } else if (creditSent <= 21810000000) {
      return "assets/images/caifu_level_104.png";
    } else if (creditSent <= 22580000000) {
      return "assets/images/caifu_level_105.png";
    } else if (creditSent <= 23680000000) {
      return "assets/images/caifu_level_106.png";
    } else if (creditSent <= 25000000000) {
      return "assets/images/caifu_level_107.png";
    } else if (creditSent <= 26650000000) {
      return "assets/images/caifu_level_108.png";
    } else if (creditSent <= 28520000000) {
      return "assets/images/caifu_level_109.png";
    } else if (creditSent <= 30200000000) {
      return "assets/images/caifu_level_110.png";
    } else if (creditSent <= 30320000000) {
      return "assets/images/caifu_level_111.png";
    } else if (creditSent <= 30560000000) {
      return "assets/images/caifu_level_112.png";
    } else if (creditSent <= 30920000000) {
      return "assets/images/caifu_level_113.png";
    } else if (creditSent <= 31520000000) {
      return "assets/images/caifu_level_114.png";
    } else if (creditSent <= 32360000000) {
      return "assets/images/caifu_level_115.png";
    } else if (creditSent <= 33560000000) {
      return "assets/images/caifu_level_116.png";
    } else if (creditSent <= 35000000000) {
      return "assets/images/caifu_level_117.png";
    } else if (creditSent <= 36800000000) {
      return "assets/images/caifu_level_118.png";
    } else if (creditSent <= 38840000000) {
      return "assets/images/caifu_level_119.png";
    } else if (creditSent <= 40688000000) {
      return "assets/images/caifu_level_120.png";
    } else if (creditSent <= 40820000000) {
      return "assets/images/caifu_level_121.png";
    } else if (creditSent <= 41084000000) {
      return "assets/images/caifu_level_122.png";
    } else if (creditSent <= 41480000000) {
      return "assets/images/caifu_level_123.png";
    } else if (creditSent <= 42140000000) {
      return "assets/images/caifu_level_124.png";
    } else if (creditSent <= 43064000000) {
      return "assets/images/caifu_level_125.png";
    } else if (creditSent <= 44384000000) {
      return "assets/images/caifu_level_126.png";
    } else if (creditSent <= 45968000000) {
      return "assets/images/caifu_level_127.png";
    } else if (creditSent <= 47948000000) {
      return "assets/images/caifu_level_128.png";
    } else if (creditSent <= 50192000000) {
      return "assets/images/caifu_level_129.png";
    } else if (creditSent <= 52208000000) {
      return "assets/images/caifu_level_130.png";
    } else if (creditSent <= 52352000000) {
      return "assets/images/caifu_level_131.png";
    } else if (creditSent <= 52640000000) {
      return "assets/images/caifu_level_132.png";
    } else if (creditSent <= 53072000000) {
      return "assets/images/caifu_level_133.png";
    } else if (creditSent <= 53792000000) {
      return "assets/images/caifu_level_134.png";
    } else if (creditSent <= 54800000000) {
      return "assets/images/caifu_level_135.png";
    } else if (creditSent <= 56240000000) {
      return "assets/images/caifu_level_136.png";
    } else if (creditSent <= 57968000000) {
      return "assets/images/caifu_level_137.png";
    } else if (creditSent <= 60128000000) {
      return "assets/images/caifu_level_138.png";
    } else if (creditSent <= 62576000000) {
      return "assets/images/caifu_level_139.png";
    } else if (creditSent <= 64793000000) {
      return "assets/images/caifu_level_140.png";
    } else if (creditSent <= 64952000000) {
      return "assets/images/caifu_level_141.png";
    } else if (creditSent <= 65268800000) {
      return "assets/images/caifu_level_142.png";
    } else if (creditSent <= 65744000000) {
      return "assets/images/caifu_level_143.png";
    } else if (creditSent <= 66536000000) {
      return "assets/images/caifu_level_144.png";
    } else if (creditSent <= 67644000000) {
      return "assets/images/caifu_level_145.png";
    } else if (creditSent <= 69228800000) {
      return "assets/images/caifu_level_146.png";
    } else if (creditSent <= 71129600000) {
      return "assets/images/caifu_level_147.png";
    } else if (creditSent <= 73505600000) {
      return "assets/images/caifu_level_148.png";
    } else if (creditSent <= 76198400000) {
      return "assets/images/caifu_level_149.png";
    } else if (creditSent <= 78617600000) {
      return "assets/images/caifu_level_150.png";
    } else if (creditSent <= 78790400000) {
      return "assets/images/caifu_level_151.png";
    } else if (creditSent <= 79136000000) {
      return "assets/images/caifu_level_152.png";
    } else if (creditSent <= 79654400000) {
      return "assets/images/caifu_level_153.png";
    } else if (creditSent <= 80518400000) {
      return "assets/images/caifu_level_154.png";
    } else if (creditSent <= 81728000000) {
      return "assets/images/caifu_level_155.png";
    } else if (creditSent <= 83456000000) {
      return "assets/images/caifu_level_156.png";
    } else if (creditSent <= 85529600000) {
      return "assets/images/caifu_level_157.png";
    } else if (creditSent <= 88121600000) {
      return "assets/images/caifu_level_158.png";
    } else if (creditSent <= 91059200000) {
      return "assets/images/caifu_level_159.png";
    } else if (creditSent <= 93720320000) {
      return "assets/images/caifu_level_160.png";
    } else if (creditSent <= 93910400000) {
      return "assets/images/caifu_level_161.png";
    } else if (creditSent <= 94290560000) {
      return "assets/images/caifu_level_162.png";
    } else if (creditSent <= 94860800000) {
      return "assets/images/caifu_level_163.png";
    } else if (creditSent <= 95811200000) {
      return "assets/images/caifu_level_164.png";
    } else if (creditSent <= 97141760000) {
      return "assets/images/caifu_level_165.png";
    } else if (creditSent <= 99042560000) {
      return "assets/images/caifu_level_166.png";
    } else if (creditSent <= 101324000000) {
      return "assets/images/caifu_level_167.png";
    } else if (creditSent <= 104174720000) {
      return "assets/images/caifu_level_168.png";
    } else if (creditSent <= 107406080000) {
      return "assets/images/caifu_level_169.png";
    } else if (creditSent <= 110309120000) {
      return "assets/images/caifu_level_170.png";
    } else if (creditSent <= 110516480000) {
      return "assets/images/caifu_level_171.png";
    } else if (creditSent <= 110931200000) {
      return "assets/images/caifu_level_172.png";
    } else if (creditSent <= 111553280000) {
      return "assets/images/caifu_level_173.png";
    } else if (creditSent <= 112590080000) {
      return "assets/images/caifu_level_174.png";
    } else if (creditSent <= 114041600000) {
      return "assets/images/caifu_level_175.png";
    } else if (creditSent <= 116115200000) {
      return "assets/images/caifu_level_176.png";
    } else if (creditSent <= 118603520000) {
      return "assets/images/caifu_level_177.png";
    } else if (creditSent <= 121713920000) {
      return "assets/images/caifu_level_178.png";
    } else if (creditSent <= 125239040000) {
      return "assets/images/caifu_level_179.png";
    } else if (creditSent <= 128432384000) {
      return "assets/images/caifu_level_180.png";
    } else if (creditSent <= 128660480000) {
      return "assets/images/caifu_level_181.png";
    } else if (creditSent <= 129116672000) {
      return "assets/images/caifu_level_182.png";
    } else if (creditSent <= 129800960000) {
      return "assets/images/caifu_level_183.png";
    } else if (creditSent <= 130941440000) {
      return "assets/images/caifu_level_184.png";
    } else if (creditSent <= 132538112000) {
      return "assets/images/caifu_level_185.png";
    } else if (creditSent <= 134819072000) {
      return "assets/images/caifu_level_186.png";
    } else if (creditSent <= 137556224000) {
      return "assets/images/caifu_level_187.png";
    } else if (creditSent <= 140977664000) {
      return "assets/images/caifu_level_188.png";
    } else if (creditSent <= 144855296000) {
      return "assets/images/caifu_level_189.png";
    } else if (creditSent <= 148587776000) {
      return "assets/images/caifu_level_190.png";
    } else if (creditSent <= 149085440000) {
      return "assets/images/caifu_level_191.png";
    } else if (creditSent <= 149831936000) {
      return "assets/images/caifu_level_192.png";
    } else if (creditSent <= 151076096000) {
      return "assets/images/caifu_level_193.png";
    } else if (creditSent <= 152817920000) {
      return "assets/images/caifu_level_194.png";
    } else if (creditSent <= 155306240000) {
      return "assets/images/caifu_level_195.png";
  } else if (creditSent <= 158292224000) {
    return "assets/images/caifu_level_196.png";
    } else if (creditSent <= 162024704000) {
    return "assets/images/caifu_level_197.png";
    } else if (creditSent <= 166254848000) {
    return "assets/images/caifu_level_198.png";
    } else if (creditSent <= 170086860800) {
    return "assets/images/caifu_level_199.png";
    } else if (creditSent <= 189986860800) {
    return "assets/images/caifu_level_200.png";
    } else {
    return "assets/images/caifu_level_1.png";
    }
  }

  static String receivedGiftsLevelIcon({required int receivedGift}) {
    if (receivedGift == 0) {
      return "assets/images/zhibo_level_0.png";
    } else if (receivedGift <= 10000) {
      return "assets/images/zhibo_level_1.png";
    } else if (receivedGift <= 70000) {
      return "assets/images/zhibo_level_2.png";
    } else if (receivedGift <= 250000) {
      return "assets/images/zhibo_level_3.png";
    } else if (receivedGift <= 630000) {
      return "assets/images/zhibo_level_4.png";
    } else if (receivedGift <= 1410000) {
      return "assets/images/zhibo_level_5.png";
    } else if (receivedGift <= 3010000) {
      return "assets/images/zhibo_level_6.png";
    } else if (receivedGift <= 5710000) {
      return "assets/images/zhibo_level_7.png";
    } else if (receivedGift <= 10310000) {
      return "assets/images/zhibo_level_8.png";
    } else if (receivedGift <= 18110000) {
      return "assets/images/zhibo_level_9.png";
    } else if (receivedGift <= 31010000) {
      return "assets/images/zhibo_level_10.png";
    } else if (receivedGift <= 52010000) {
      return "assets/images/zhibo_level_11.png";
    } else if (receivedGift <= 85010000) {
      return "assets/images/zhibo_level_12.png";
    } else if (receivedGift <= 137010000) {
      return "assets/images/zhibo_level_13.png";
    } else if (receivedGift <= 214010000) {
      return "assets/images/zhibo_level_14.png";
    } else if (receivedGift <= 323010000) {
      return "assets/images/zhibo_level_15.png";
    } else if (receivedGift <= 492010000) {
      return "assets/images/zhibo_level_16.png";
    } else if (receivedGift <= 741010000) {
      return "assets/images/zhibo_level_17.png";
    } else if (receivedGift <= 11000100000) {
      return "assets/images/zhibo_level_18.png";
    } else if (receivedGift <= 16890100000) {
      return "assets/images/zhibo_level_19.png";
    } else if (receivedGift <= 25280100000) {
      return "assets/images/zhibo_level_20.png";
    } else if (receivedGift <= 36370100000) {
      return "assets/images/zhibo_level_21.png";
    } else if (receivedGift <= 51370100000) {
      return "assets/images/zhibo_level_22.png";
    } else if (receivedGift <= 73370100000) {
      return "assets/images/zhibo_level_23.png";
    } else if (receivedGift <= 10137010000) {
      return "assets/images/zhibo_level_24.png";
    } else if (receivedGift <= 141370100000) {
      return "assets/images/zhibo_level_25.png";
    } else if (receivedGift <= 191370100000) {
      return "assets/images/zhibo_level_26.png";
    } else if (receivedGift <= 300000000000) {
      return "assets/images/zhibo_level_27.png";
    } else if (receivedGift <= 450000000000) {
      return "assets/images/zhibo_level_28.png";
    } else if (receivedGift <= 600000000000) {
      return "assets/images/zhibo_level_29.png";
    } else if (receivedGift <= 800000000000) {
      return "assets/images/zhibo_level_30.png";
    } else if (receivedGift <= 100000000000) {
      return "assets/images/zhibo_level_31.png";
    } else if (receivedGift <= 130000000000) {
      return "assets/images/zhibo_level_32.png";
    } else if (receivedGift <= 160000000000) {
      return "assets/images/zhibo_level_33.png";
    } else if (receivedGift <= 2000000000000) {
      return "assets/images/zhibo_level_34.png";
    } else {
      return "assets/images/zhibo_level_0.png";
    }
  }

  static int receivedGiftsValue({required int receivedGift}) {
    if (receivedGift == 0) {
      return 0;
    } else if (receivedGift <= 10000) {
      return 10000;
    } else if (receivedGift <= 70000) {
      return 70000;
    } else if (receivedGift <= 250000) {
      return 250000;
    } else if (receivedGift <= 630000) {
      return 630000;
    } else if (receivedGift <= 1410000) {
      return 1410000;
    } else if (receivedGift <= 3010000) {
      return 3010000;
    } else if (receivedGift <= 5710000) {
      return 5710000;
    } else if (receivedGift <= 10310000) {
      return 10310000;
    } else if (receivedGift <= 18110000) {
      return 18110000;
    } else if (receivedGift <= 31010000) {
      return 31010000;
    } else if (receivedGift <= 52010000) {
      return 52010000;
    } else if (receivedGift <= 85010000) {
      return 85010000;
    } else if (receivedGift <= 137010000) {
      return 137010000;
    } else if (receivedGift <= 214010000) {
      return 214010000;
    } else if (receivedGift <= 323010000) {
      return 323010000;
    } else if (receivedGift <= 492010000) {
      return 492010000;
    } else if (receivedGift <= 741010000) {
      return 741010000;
    } else if (receivedGift <= 11000100000) {
      return 11000100000;
    } else if (receivedGift <= 16890100000) {
      return 16890100000;
    } else if (receivedGift <= 25280100000) {
      return 2528010000;
    } else if (receivedGift <= 36370100000) {
      return 36370100000;
    } else if (receivedGift <= 51370100000) {
      return 51370100000;
    } else if (receivedGift <= 73370100000) {
      return 73370100000;
    } else if (receivedGift <= 10137010000) {
      return 10137010000;
    } else if (receivedGift <= 141370100000) {
      return 141370100000;
    } else if (receivedGift <= 191370100000) {
      return 191370100000;
    } else if (receivedGift <= 300000000000) {
      return 30000000000;
    } else if (receivedGift <= 450000000000) {
      return 45000000000;
    } else if (receivedGift <= 600000000000) {
      return 60000000000;
    } else if (receivedGift <= 800000000000) {
      return 80000000000;
    } else if (receivedGift <= 100000000000) {
      return 100000000000;
    } else if (receivedGift <= 130000000000) {
      return 130000000000;
    } else if (receivedGift <= 160000000000) {
      return 160000000000;
    } else if (receivedGift <= 2000000000000) {
      return 2000000000000;
    } else {
      return 0;
    }
  }

  static int receivedGiftsLevelNumber({required int receivedGift}) {
    if (receivedGift == 0) {
      return 0;
    } else if (receivedGift <= 10000) {
      return 1;
    } else if (receivedGift <= 70000) {
      return 2;
    } else if (receivedGift <= 250000) {
      return 3;
    } else if (receivedGift <= 630000) {
      return 4;
    } else if (receivedGift <= 1410000) {
      return 5;
    } else if (receivedGift <= 3010000) {
      return 6;
    } else if (receivedGift <= 5710000) {
      return 7;
    } else if (receivedGift <= 10310000) {
      return 8;
    } else if (receivedGift <= 18110000) {
      return 9;
    } else if (receivedGift <= 31010000) {
      return 10;
    } else if (receivedGift <= 52010000) {
      return 11;
    } else if (receivedGift <= 85010000) {
      return 12;
    } else if (receivedGift <= 137010000) {
      return 13;
    } else if (receivedGift <= 214010000) {
      return 14;
    } else if (receivedGift <= 323010000) {
      return 15;
    } else if (receivedGift <= 492010000) {
      return 16;
    } else if (receivedGift <= 741010000) {
      return 17;
    } else if (receivedGift <= 11000100000) {
      return 18;
    } else if (receivedGift <= 16890100000) {
      return 19;
    } else if (receivedGift <= 25280100000) {
      return 20;
    } else if (receivedGift <= 36370100000) {
      return 21;
    } else if (receivedGift <= 51370100000) {
      return 22;
    } else if (receivedGift <= 73370100000) {
      return 23;
    } else if (receivedGift <= 10137010000) {
      return 24;
    } else if (receivedGift <= 141370100000) {
      return 25;
    } else if (receivedGift <= 191370100000) {
      return 26;
    } else if (receivedGift <= 300000000000) {
      return 27;
    } else if (receivedGift <= 450000000000) {
      return 28;
    } else if (receivedGift <= 600000000000) {
      return 29;
    } else if (receivedGift <= 800000000000) {
      return 30;
    } else if (receivedGift <= 100000000000) {
      return 31;
    } else if (receivedGift <= 130000000000) {
      return 32;
    } else if (receivedGift <= 160000000000) {
      return 33;
    } else if (receivedGift <= 2000000000000) {
      return 34;
    } else {
      return 0;
    }
  }

  static int wealthLevelNumber({required int creditSent}) {
    if(creditSent == 0){
      return 0;
    }else if (creditSent < 3000) {
      return 1;
    } else if (creditSent <= 6000) {
      return 2;
    } else if (creditSent <= 16000) {
      return 3;
    } else if (creditSent <= 66000) {
      return 4;
    } else if (creditSent <= 166000) {
      return 5;
    } else if (creditSent <= 330000) {
      return 6;
    } else if (creditSent <= 500000) {
      return 7;
    } else if (creditSent <= 700000) {
      return 8;
    } else if (creditSent <= 1000000) {
      return 9;
    } else if (creditSent <= 1100000) {
      return 10;
    } else if (creditSent <= 1300000) {
      return 11;
    } else if (creditSent <= 1600000) {
      return 12;
    } else if (creditSent <= 2000000) {
      return 13;
    } else if (creditSent <= 2600000) {
      return 14;
    } else if (creditSent <= 3400000) {
      return 15;
    } else if (creditSent <= 4400000) {
      return 16;
    } else if (creditSent <= 5600000) {
      return 17;
    } else if (creditSent <= 7000000) {
      return 18;
    } else if (creditSent <= 10000000) {
      return 19;
    } else if (creditSent <= 10500000) {
      return 20;
    } else if (creditSent <= 11500000) {
      return 21;
    } else if (creditSent <= 13000000) {
      return 22;
    } else if (creditSent <= 15000000) {
      return 23;
    } else if (creditSent <= 18000000) {
      return 24;
    } else if (creditSent <= 22000000) {
      return 25;
    } else if (creditSent <= 27000000) {
      return 26;
    } else if (creditSent <= 33000000) {
      return 27;
    } else if (creditSent <= 40000000) {
      return 28;
    } else if (creditSent <= 50000000) {
      return 29;
    } else if (creditSent <= 52000000) {
      return 30;
    } else if (creditSent <= 55000000) {
      return 31;
    } else if (creditSent <= 60000000) {
      return 32;
    } else if (creditSent <= 68000000) {
      return 34;
    } else if (creditSent <= 79000000) {
      return 35;
    } else if (creditSent <= 95000000) {
      return 36;
    } else if (creditSent <= 114000000) {
      return 37;
    } else if (creditSent <= 137000000) {
      return 38;
    } else if (creditSent <= 163000000) {
      return 39;
    } else if (creditSent <= 200000000) {
      return 40;
    } else if (creditSent <= 204000000) {
      return 41;
    } else if (creditSent <= 210000000) {
      return 42;
    } else if (creditSent <= 220000000) {
      return 43;
    } else if (creditSent <= 236000000) {
      return 44;
    } else if (creditSent <= 258000000) {
      return 45;
    } else if (creditSent <= 290000000) {
      return 46;
    } else if (creditSent <= 328000000) {
      return 47;
    } else if (creditSent <= 375000000) {
      return 48;
    } else if (creditSent <= 428000000) {
      return 49;
    } else if (creditSent <= 500000000) {
      return 50;
    } else if (creditSent <= 506000000) {
      return 51;
    } else if (creditSent <= 516000000) {
      return 52;
    } else if (creditSent <= 535000000) {
      return 53;
    } else if (creditSent <= 560000000) {
      return 54;
    } else if (creditSent <= 598000000) {
      return 55;
    } else if (creditSent <= 648000000) {
      return 56;
    } else if (creditSent <= 710000000) {
      return 57;
    } else if (creditSent <= 785000000) {
      return 58;
    } else if (creditSent <= 870000000) {
      return 59;
    } else if (creditSent <= 1000000000) {
      return 60;
    } else if (creditSent <= 1020000000) {
      return 61;
    } else if (creditSent <= 1060000000) {
      return 62;
    } else if (creditSent <= 1120000000) {
      return 63;
    } else if (creditSent <= 1220000000) {
      return 64;
    } else if (creditSent <= 1360000000) {
      return 65;
    } else if (creditSent <= 1560000000) {
      return 66;
    } else if (creditSent <= 1800000000) {
      return 67;
    } else if (creditSent <= 2100000000) {
      return 68;
    } else if (creditSent <= 2440000000) {
      return 69;
    } else if (creditSent <= 3000000000) {
      return 70;
    } else if (creditSent <= 3020000000) {
      return 71;
    } else if (creditSent <= 3060000000) {
      return 72;
    } else if (creditSent <= 3120000000) {
      return 73;
    } else if (creditSent <= 3220000000) {
      return 74;
    } else if (creditSent <= 3220000000) {
      return 75;
    } else if (creditSent <= 3360000000) {
      return 76;
    } else if (creditSent <= 3560000000) {
      return 77;
    } else if (creditSent <= 3800000000) {
      return 78;
    } else if (creditSent <= 4100000000) {
      return 79;
    } else if (creditSent <= 4440000000) {
      return 80;
    } else if (creditSent <= 5000000000) {
      return 81;
    } else if (creditSent <= 5050000000) {
      return 82;
    } else if (creditSent <= 5150000000) {
      return 83;
    } else if (creditSent <= 5300000000) {
      return 84;
    } else if (creditSent <= 5550000000) {
      return 85;
    } else if (creditSent <= 5900000000) {
      return 86;
    } else if (creditSent <= 6400000000) {
      return 87;
    } else if (creditSent <= 7000000000) {
      return 88;
    } else if (creditSent <= 7750000000) {
      return 89;
    } else if (creditSent <= 7750000000) {
      return 90;
    } else if (creditSent <= 8600000000) {
      return 91;
    } else if (creditSent <= 10000000000) {
      return 92;
    } else if (creditSent <= 10100000000) {
      return 93;
    } else if (creditSent <= 10300000000) {
      return 94;
    } else if (creditSent <= 10600000000) {
      return 95;
    } else if (creditSent <= 11100000000) {
      return 97;
    } else if (creditSent <= 11800000000) {
      return 98;
    } else if (creditSent <= 12800000000) {
      return 99;
    } else if (creditSent <= 14000000000) {
      return 100;
    } else if (creditSent <= 15500000000) {
      return 101;
    } else if (creditSent <= 17200000000) {
      return 102;
    } else if (creditSent <= 20600000000) {
      return 103;
    } else if (creditSent <= 20710000000) {
      return 104;
    } else if (creditSent <= 20930000000) {
      return 105;
    } else if (creditSent <= 21260000000) {
      return 106;
    } else if (creditSent <= 21810000000) {
      return 107;
    } else if (creditSent <= 22580000000) {
      return 108;
    } else if (creditSent <= 23680000000) {
      return 109;
    } else if (creditSent <= 25000000000) {
      return 110;
    } else if (creditSent <= 26650000000) {
      return 111;
    } else if (creditSent <= 28520000000) {
      return 112;
    } else if (creditSent <= 30200000000) {
      return 113;
    } else if (creditSent <= 30320000000) {
      return 114;
    } else if (creditSent <= 30560000000) {
      return 115;
    } else if (creditSent <= 30920000000) {
      return 116;
    } else if (creditSent <= 31520000000) {
      return 117;
    } else if (creditSent <= 32360000000) {
      return 118;
    } else if (creditSent <= 33560000000) {
      return 119;
    } else if (creditSent <= 35000000000) {
      return 120;
    } else if (creditSent <= 36800000000) {
      return 121;
    } else if (creditSent <= 38840000000) {
      return 122;
    } else if (creditSent <= 40688000000) {
      return 123;
    } else if (creditSent <= 40820000000) {
      return 124;
    } else if (creditSent <= 41084000000) {
      return 125;
    } else if (creditSent <= 41480000000) {
      return 126;
    } else if (creditSent <= 42140000000) {
      return 127;
    } else if (creditSent <= 43064000000) {
      return 128;
    } else if (creditSent <= 44384000000) {
      return 129;
    } else if (creditSent <= 45968000000) {
      return 130;
    } else if (creditSent <= 47948000000) {
      return 131;
    } else if (creditSent <= 50192000000) {
      return 132;
    } else if (creditSent <= 52208000000) {
      return 133;
    } else if (creditSent <= 52352000000) {
      return 134;
    } else if (creditSent <= 52640000000) {
      return 135;
    } else if (creditSent <= 53072000000) {
      return 136;
    } else if (creditSent <= 53792000000) {
      return 137;
    } else if (creditSent <= 54800000000) {
      return 138;
    } else if (creditSent <= 56240000000) {
      return 139;
    } else if (creditSent <= 57968000000) {
      return 140;
    } else if (creditSent <= 60128000000) {
      return 141;
    } else if (creditSent <= 62576000000) {
      return 142;
    } else if (creditSent <= 64793000000) {
      return 143;
    } else if (creditSent <= 64952000000) {
      return 144;
    } else if (creditSent <= 65268800000) {
      return 145;
    } else if (creditSent <= 65744000000) {
      return 146;
    } else if (creditSent <= 66536000000) {
      return 147;
    } else if (creditSent <= 67644000000) {
      return 148;
    } else if (creditSent <= 69228800000) {
      return 149;
    } else if (creditSent <= 71129600000) {
      return 150;
    } else if (creditSent <= 73505600000) {
      return 151;
    } else if (creditSent <= 76198400000) {
      return 152;
    } else if (creditSent <= 78617600000) {
      return 153;
    } else if (creditSent <= 78790400000) {
      return 154;
    } else if (creditSent <= 79136000000) {
      return 155;
    } else if (creditSent <= 79654400000) {
      return 156;
    } else if (creditSent <= 80518400000) {
      return 157;
    } else if (creditSent <= 81728000000) {
      return 158;
    } else if (creditSent <= 83456000000) {
      return 159;
    } else if (creditSent <= 85529600000) {
      return 160;
    } else if (creditSent <= 88121600000) {
      return 161;
    } else if (creditSent <= 91059200000) {
      return 162;
    } else if (creditSent <= 93720320000) {
      return 163;
    } else if (creditSent <= 93910400000) {
      return 164;
    } else if (creditSent <= 94290560000) {
      return 165;
    } else if (creditSent <= 94860800000) {
      return 166;
    } else if (creditSent <= 95811200000) {
      return 167;
    } else if (creditSent <= 97141760000) {
      return 168;
    } else if (creditSent <= 99042560000) {
      return 169;
    } else if (creditSent <= 101324000000) {
      return 170;
    } else if (creditSent <= 104174720000) {
      return 171;
    } else if (creditSent <= 107406080000) {
      return 172;
    } else if (creditSent <= 110309120000) {
      return 173;
    } else if (creditSent <= 110516480000) {
      return 174;
    } else if (creditSent <= 110931200000) {
      return 175;
    } else if (creditSent <= 111553280000) {
      return 176;
    } else if (creditSent <= 112590080000) {
      return 177;
    } else if (creditSent <= 114041600000) {
      return 178;
    } else if (creditSent <= 116115200000) {
      return 179;
    } else if (creditSent <= 118603520000) {
      return 180;
    } else if (creditSent <= 121713920000) {
      return 181;
    } else if (creditSent <= 125239040000) {
      return 182;
    } else if (creditSent <= 128432384000) {
      return 183;
    } else if (creditSent <= 128660480000) {
      return 184;
    } else if (creditSent <= 129116672000) {
      return 185;
    } else if (creditSent <= 129800960000) {
      return 186;
    } else if (creditSent <= 130941440000) {
      return 187;
    } else if (creditSent <= 132538112000) {
      return 188;
    } else if (creditSent <= 134819072000) {
      return 189;
    } else if (creditSent <= 137556224000) {
      return 190;
    } else if (creditSent <= 140977664000) {
      return 191;
    } else if (creditSent <= 144855296000) {
      return 192;
    } else if (creditSent <= 148587776000) {
      return 193;
    } else if (creditSent <= 149085440000) {
      return 194;
    } else if (creditSent <= 149831936000) {
      return 195;
    } else if (creditSent <= 151076096000) {
      return 196;
    } else if (creditSent <= 152817920000) {
      return 197;
    } else if (creditSent <= 155306240000) {
      return 198;
  } else if (creditSent <= 158292224000) {
    return 199;
    } else if (creditSent <= 162024704000) {
    return 200;
    } else if (creditSent <= 166254848000) {
    return 201;
    } else if (creditSent <= 170086860800) {
    return 202;
    } else if (creditSent <= 185286860800) {
    return 203;
    } else {
    return 0;
    }
  }

  static List<String> getBusinessCooperationIssuesList() {
    List<String> list = [
      ReportModel.BUSINESS_AGENCY_APPLICATION,
      ReportModel.BUSINESS_AGENCY_HOST,
    ];

    return list;
  }

  static String getBusinessCooperationIssuesByCode(String code) {
    switch (code) {
      case ReportModel.BUSINESS_AGENCY_APPLICATION:
        return "business_cooperation_issue.agency_application".tr();

      case ReportModel.BUSINESS_AGENCY_HOST:
        return "business_cooperation_issue.agency_host".tr();

      default:
        return "";
    }
  }

  static List<String> getFeedbackIssuesList() {
    List<String> list = [
      ReportModel.FEEDBACK_ACCOUNT_SECURE,
      ReportModel.FEEDBACK_GAME,
      ReportModel.FEEDBACK_SOFTWARE_DEFECT,
      ReportModel.FEEDBACK_FEATURE_REQUEST,
      ReportModel.FEEDBACK_SPOT_ERROR_GET_COINS,
    ];

    return list;
  }

  static String getFeedbackIssuesByCode(String code) {
    switch (code) {
      case ReportModel.FEEDBACK_ACCOUNT_SECURE:
        return "feedbacks_issue.account_security".tr();

      case ReportModel.FEEDBACK_GAME:
        return "feedbacks_issue.game_".tr();

      case ReportModel.FEEDBACK_SOFTWARE_DEFECT:
        return "feedbacks_issue.software_defect".tr();

      case ReportModel.FEEDBACK_FEATURE_REQUEST:
        return "feedbacks_issue.feature_requests".tr();

      case ReportModel.FEEDBACK_SPOT_ERROR_GET_COINS:
        return "feedbacks_issue.spot_error_coins".tr();

      default:
        return "";
    }
  }

  static List<String> getReportComplaintsIssuesList() {
    List<String> list = [
      ReportModel.REPORT_COMPLAINT_REPORT,
      ReportModel.REPORT_LIVE_VIOLATION,
    ];

    return list;
  }

  static String getReportComplaintsIssuesByCode(String code) {
    switch (code) {
      case ReportModel.REPORT_COMPLAINT_REPORT:
        return "report_complaints_issue.complaint_".tr();

      case ReportModel.REPORT_LIVE_VIOLATION:
        return "report_complaints_issue.live_broadcast_violation".tr();

      default:
        return "";
    }
  }

  static String getAnyIssueDetailByCode(String code) {
    switch (code) {
      case ReportModel.BUSINESS_AGENCY_APPLICATION:
        return "business_cooperation_issue.agency_application".tr();

      case ReportModel.BUSINESS_AGENCY_HOST:
        return "business_cooperation_issue.agency_host".tr();

      case ReportModel.FEEDBACK_ACCOUNT_SECURE:
        return "feedbacks_issue.account_security".tr();

      case ReportModel.FEEDBACK_GAME:
        return "feedbacks_issue.game_".tr();

      case ReportModel.FEEDBACK_SOFTWARE_DEFECT:
        return "feedbacks_issue.software_defect".tr();

      case ReportModel.FEEDBACK_FEATURE_REQUEST:
        return "feedbacks_issue.feature_requests".tr();

      case ReportModel.FEEDBACK_SPOT_ERROR_GET_COINS:
        return "feedbacks_issue.spot_error_coins".tr();

      case ReportModel.REPORT_COMPLAINT_REPORT:
        return "report_complaints_issue.complaint_".tr();

      case ReportModel.REPORT_LIVE_VIOLATION:
        return "report_complaints_issue.live_broadcast_violation".tr();

      case ReportModel.CONSULT_HOST_REWARD:
        return "consult_issue.host_tasks_rewards".tr();

      case ReportModel.CONSULT_FAILURE_RECEIVING_COIN:
        return "consult_issue.failure_receiving_coins".tr();

      case ReportModel.CONSULT_FACE_AUTHENTICATION:
        return "consult_issue.face_authentication".tr();

      case ReportModel.CONSULT_CHANGE_GENDER:
        return "consult_issue.change_gender_country".tr();

      case ReportModel.CONSULT_APPEAL_ACCOUNT_SUSPENSION:
        return "consult_issue.appeal_account_suspension".tr();

      case ReportModel.CONSULT_INVITATION_REWARD:
        return "consult_issue.invitation_reward".tr();

      case ReportModel.CONSULT_OTHER:
        return "consult_issue.others_".tr();

      default:
        return "";
    }
  }

  static List<String> getConsultIssuesList() {
    List<String> list = [
      ReportModel.CONSULT_HOST_REWARD,
      ReportModel.CONSULT_FAILURE_RECEIVING_COIN,
      ReportModel.CONSULT_FACE_AUTHENTICATION,
      ReportModel.CONSULT_CHANGE_GENDER,
      ReportModel.CONSULT_APPEAL_ACCOUNT_SUSPENSION,
      ReportModel.CONSULT_INVITATION_REWARD,
      ReportModel.CONSULT_OTHER,
    ];

    return list;
  }

  static String getConsultIssuesByCode(String code) {
    switch (code) {
      case ReportModel.CONSULT_HOST_REWARD:
        return "consult_issue.host_tasks_rewards".tr();

      case ReportModel.CONSULT_FAILURE_RECEIVING_COIN:
        return "consult_issue.failure_receiving_coins".tr();

      case ReportModel.CONSULT_FACE_AUTHENTICATION:
        return "consult_issue.face_authentication".tr();

      case ReportModel.CONSULT_CHANGE_GENDER:
        return "consult_issue.change_gender_country".tr();

      case ReportModel.CONSULT_APPEAL_ACCOUNT_SUSPENSION:
        return "consult_issue.appeal_account_suspension".tr();

      case ReportModel.CONSULT_INVITATION_REWARD:
        return "consult_issue.invitation_reward".tr();

      case ReportModel.CONSULT_OTHER:
        return "consult_issue.others_".tr();

      default:
        return "";
    }
  }

  static List<String> getCategoryQuestionList() {
    List<String> list = [
      ReportModel.CATEGORY_CONSULT,
      ReportModel.CATEGORY_REPORT_COMPLAINT,
      ReportModel.CATEGORY_FEEDBACKS,
      ReportModel.CATEGORY_BUSINESS_COOPERATION,
    ];

    return list;
  }

  static String getCategoryQuestionByCode(String code) {
    switch (code) {
      case ReportModel.CATEGORY_CONSULT:
        return "category_question.consult_".tr();

      case ReportModel.CATEGORY_REPORT_COMPLAINT:
        return "category_question.report_complaints".tr();

      case ReportModel.CATEGORY_FEEDBACKS:
        return "category_question.feedbacks_".tr();

      case ReportModel.CATEGORY_BUSINESS_COOPERATION:
        return "category_question.business_cooperation".tr();

      default:
        return "";
    }
  }

  static List<String> getUserStatesList() {
    List<String> list = [
      UserModel.userOnline,
      UserModel.userOffline,
      UserModel.userParty,
      UserModel.userViewing,
      UserModel.userLiving,
    ];

    return list;
  }

  static String getUserStatesByCode(String code) {
    switch (code) {
      case UserModel.userOnline:
        return "user_state_in_app.online_".tr();

      case UserModel.userOffline:
        return "user_state_in_app.offline_".tr();

      case UserModel.userParty:
        return "user_state_in_app.party_".tr();

      case UserModel.userViewing:
        return "user_state_in_app.viewing_".tr();

      case UserModel.userLiving:
        return "user_state_in_app.living_".tr();

      default:
        return "";
    }
  }

  static String getUserStatesIcon(String code) {
    switch (code) {
      case UserModel.userOnline:
        return "assets/lotties/ic_online.json";

      case UserModel.userOffline:
        return "assets/lotties/ic_offline.json";

      case UserModel.userParty:
        return "assets/lotties/ic_live_animation.json";

      case UserModel.userViewing:
        return "assets/lotties/ic_viewer.json";

      case UserModel.userLiving:
        return "assets/lotties/ic_on_live.json";

      default:
        return "";
    }
  }

  static List<String> getReportCodeMessageList() {
    List<String> list = [
      ReportModel.THIS_POST_HAS_SEXUAL_CONTENTS,
      ReportModel.FAKE_PROFILE_SPAN,
      ReportModel.INAPPROPRIATE_MESSAGE,
      ReportModel.SOMEONE_IS_IN_DANGER,
    ];

    return list;
  }

  static String getReportMessage(String code) {
    switch (code) {
      case ReportModel.THIS_POST_HAS_SEXUAL_CONTENTS:
        return "message_report.report_without_interest".tr();

      case ReportModel.FAKE_PROFILE_SPAN:
        return "message_report.report_fake_profile".tr();

      case ReportModel.INAPPROPRIATE_MESSAGE:
        return "message_report.report_inappropriate_message".tr();

      case ReportModel.SOMEONE_IS_IN_DANGER:
        return "message_report.report_some_in_danger".tr();

      default:
        return "";
    }
  }

  static List<String> getLiveSubTypeList() {
    List<String> list = [
      LiveStreamingModel.liveSubTalking,
      LiveStreamingModel.liveSubSinging,
      LiveStreamingModel.liveSubDancing,
      LiveStreamingModel.liveSubFriends,
      LiveStreamingModel.liveSubGame,
    ];

    return list;
  }

  static String getLiveSubTypeByCode(String code) {
    switch (code) {
      case LiveStreamingModel.liveSubTalking:
        return "live_type.talking_".tr();

      case LiveStreamingModel.liveSubSinging:
        return "live_type.singing_".tr();

      case LiveStreamingModel.liveSubDancing:
        return "live_type.dancing".tr();

      case LiveStreamingModel.liveSubFriends:
        return "live_type.friends_".tr();

      case LiveStreamingModel.liveSubGame:
        return "live_type.game_".tr();

      default:
        return "";
    }
  }

  static Color getColorSettingsBg() {
    if (isDarkModeNoContext()) {
      return kContentColorLightTheme;
    } else {
      return kSettingsBg;
    }
  }

  static String getDurationInMinutes({Duration? duration}) {
    if (duration != null) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

      if (duration.inHours > 0) {
        return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
      } else {
        return "$twoDigitMinutes:$twoDigitSeconds";
      }
    } else {
      return "00:00";
    }
  }

  static String formatTime(int second) {
    var hour = (second / 3600).floor();
    var minutes = ((second - hour * 3600) / 60).floor();
    var seconds = (second - hour * 3600 - minutes * 60).floor();

    var secondExtraZero = (seconds < 10) ? "0" : "";
    var minuteExtraZero = (minutes < 10) ? "0" : "";
    var hourExtraZero = (hour < 10) ? "0" : "";

    if (hour > 0) {
      return "$hourExtraZero$hour:$minuteExtraZero$minutes:$secondExtraZero$seconds";
    } else {
      return "$minuteExtraZero$minutes:$secondExtraZero$seconds";
    }
  }

  static Color getColorTextCustom1({bool? inverse}) {
    if (isDarkModeNoContext()) {
      if (inverse != null && inverse) {
        return kContentColorLightTheme;
      } else {
        return kContentColorDarkTheme;
      }
    } else {
      if (inverse != null && inverse) {
        return kContentColorDarkTheme;
      } else {
        return kContentColorLightTheme;
      }
    }
  }

  static Color getColorToolbarIcons() {
    if (isDarkModeNoContext()) {
      return kContentColorDarkTheme;
    } else {
      return kColorsGrey600;
    }
  }

  static bool isDarkMode(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark;
  }

  static bool isDarkModeNoContext() {
    var brightness = SchedulerBinding.instance.window.platformBrightness;
    return brightness == Brightness.dark;
  }

  static bool isWebPlatform() {
    return UniversalPlatform.isWeb;
  }

  static bool isAndroidPlatform() {
    return UniversalPlatform.isAndroid;
  }

  static bool isFuchsiaPlatform() {
    return UniversalPlatform.isFuchsia;
  }

  static bool isIOSPlatform() {
    return UniversalPlatform.isIOS;
  }

  static bool isMacOsPlatform() {
    return UniversalPlatform.isMacOS;
  }

  static bool isLinuxPlatform() {
    return UniversalPlatform.isLinux;
  }

  static bool isWindowsPlatform() {
    return UniversalPlatform.isWindows;
  }

  // Get country code
  static String? getCountryIso() {
    final List<Locale>? systemLocales = WidgetsBinding.instance.window.locales;
    return systemLocales?.first.countryCode;
  }

  static String? getCountryCodeFromLocal(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);

    return myLocale.countryCode;
  }

  // Save Installation
  static Future<void> initInstallation(UserModel? user, String? token) async {
    DateTime dateTime = DateTime.now().toLocal();

    ParseInstallation installation = ParseInstallation.forQuery();
    ParseInstallation installationCurrent =
        await ParseInstallation.currentInstallation();

    if (token != null) {
      installation.set('deviceToken', token);
    } else {
      installation.unset('deviceToken');
    }

    installation.set('GCMSenderId', Config.pushGcm);
    installation.set('timeZone', dateTime.timeZoneName);
    installation.set('installationId', installationCurrent.installationId);

    if (kIsWeb) {
      installation.set('deviceType', 'web');
      installation.set('pushType', 'FCM');
    } else if (Platform.isAndroid) {
      installation.set('deviceType', 'android');
      installation.set('pushType', 'FCM');
    } else if (Platform.isIOS) {
      installation.set('deviceType', 'ios');
      installation.set('pushType', 'APN');
    }

    if (user != null) {
      installation.set('user', user);
      installation.subscribeToChannel('global');
    } else {
      installation.unset('user');
      installation.unsubscribeFromChannel('global');
    }
  }

  static setCurrentUser(UserModel? userModel, {StateSetter? setState}) async {
    UserModel userModel = await ParseUser.currentUser();

    if (setState != null) {
      setState(() {
        userModel = userModel;
      });
    } else {
      userModel = userModel;
    }
  }

  static Future<UserModel?>? getCurrentUser() async {
    UserModel? currentUser = await ParseUser.currentUser();
    return currentUser;
  }

  static Future<UserModel?> getCurrentUserModel(UserModel? userModel) async {
    UserModel currentUser = await ParseUser.currentUser();
    return currentUser;
  }

  static Future<UserModel> getUserModelResult(dynamic d) async {
    UserModel? user = await ParseUser.currentUser();
    user = UserModel.clone()..fromJson(d as Map<String, dynamic>);

    return user;
  }

  static Future<UserModel?> getUserAwait() async {
    UserModel? currentUser = await ParseUser.currentUser();

    if (currentUser != null) {
      ParseResponse response = await currentUser.getUpdatedUser();
      if (response.success) {
        currentUser = response.result;
        return currentUser;
      } else if (response.error!.code == 100) {
        // Return stored user

        return currentUser;
      } else if (response.error!.code == 101) {
        // User deleted or doesn't exist.

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else if (response.error!.code == 209) {
        // Invalid session token

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else {
        // General error

        return currentUser;
      }
    } else {
      return null;
    }
  }

  static Future<UserModel?> getUser(UserModel? currentUser) async {
    currentUser = await ParseUser.currentUser();

    if (currentUser != null) {
      ParseResponse response = await currentUser.getUpdatedUser();

      if (response.success) {
        UserModel userModel = response.results!.first!;

        return userModel;
      } else if (response.error!.code == 100) {
        // Return stored user

        return currentUser;
      } else if (response.error!.code == 101) {
        // User deleted or doesn't exist.

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else if (response.error!.code == 209) {
        // Invalid session token

        currentUser.logout(deleteLocalUserData: true);
        return null;
      } else {
        // General error

        return currentUser;
      }
    } else {
      return null;
    }
  }

  // Check if email is valid
  static bool isValidEmail(String email) {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);
  }

  // Check if string has only number(s)
  static bool isNumeric(String string) {
    return double.tryParse(string) != null;
  }

  static bool isPasswordCompliant(String password, [int minLength = 6]) {
    bool hasUppercase = password.contains(new RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(new RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(new RegExp(r'[a-z]'));
    bool hasSpecialCharacters =
        password.contains(new RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length > minLength;

    return hasDigits &
        hasUppercase &
        hasLowercase &
        hasSpecialCharacters &
        hasMinLength;
  }

  static DateTime getDateFromString(String date, String format) {
    return new DateFormat(format).parse(date);
  }

  static Object getDateDynamic(String date) {
    DateFormat dateFormat = DateFormat(dateFormatDmy);
    DateTime dateTime = dateFormat.parse(date);

    return json.encode(dateTime, toEncodable: myEncode);
  }

  static dynamic myEncode(dynamic item) {
    if (item is DateTime) {
      return item.toIso8601String();
    }
    return item;
  }

  static DateTime getDate(String date) {
    DateFormat dateFormat = DateFormat(dateFormatDmy);
    DateTime dateTime = dateFormat.parse(date);

    return dateTime;
  }

  static bool isValidDateBirth(String date, String format) {
    try {
      int day = 1, month = 1, year = 2000;

      //Get separator data  10/10/2020, 2020-10-10, 10.10.2020
      String separator = RegExp("([-/.])").firstMatch(date)!.group(0)![0];

      //Split by separator [mm, dd, yyyy]
      var frSplit = format.split(separator);
      //Split by separtor [10, 10, 2020]
      var dtSplit = date.split(separator);

      for (int i = 0; i < frSplit.length; i++) {
        var frm = frSplit[i].toLowerCase();
        var vl = dtSplit[i];

        if (frm == "dd")
          day = int.parse(vl);
        else if (frm == "mm")
          month = int.parse(vl);
        else if (frm == "yyyy") year = int.parse(vl);
      }

      //First date check
      //The dart does not throw an exception for invalid date.
      var now = DateTime.now();
      if (month > 12 ||
          month < 1 ||
          day < 1 ||
          day > daysInMonth(month, year) ||
          year < 1810 ||
          (year > now.year && day > now.day && month > now.month))
        throw Exception("Date birth invalid.");

      return true;
    } catch (e) {
      return false;
    }
  }

  static bool minimumAgeAllowed(String birthDateString, String datePattern) {
    // Current time - at this moment
    DateTime today = DateTime.now();

    // Parsed date to check
    DateTime birthDate = DateFormat(datePattern).parse(birthDateString);

    // Date to check but moved 18 years ahead
    DateTime adultDate = DateTime(
      birthDate.year + Setup.minimumAgeToRegister,
      birthDate.month,
      birthDate.day,
    );

    return adultDate.isBefore(today);
  }

  static int daysInMonth(int month, int year) {
    int days = 28 +
        (month + (month / 8).floor()) % 2 +
        2 % month +
        2 * (1 / month).floor();
    return (isLeapYear(year) && month == 2) ? 29 : days;
  }

  static bool isLeapYear(int year) =>
      ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0);

  static void showLoadingDialog(BuildContext context, {bool? isDismissible}) {
    showDialog(
        context: context,
        barrierDismissible: isDismissible != null ? isDismissible : false,
        builder: (BuildContext context) {
          return showLoadingAnimation(); //LoadingDialog();
        });
  }

  static void hideLoadingDialog(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }

  static goToNavigator(BuildContext context, String route,
      {Object? arguments, ResumableState? resumeState}) {
    Future.delayed(Duration.zero, () {
      if (resumeState != null) {
        resumeState.pushNamed(context, route, arguments: arguments);
      } else {
        //Navigator.of(context).pushNamed(route, arguments: arguments);
        NavigationService.navigatorKey.currentState
            ?.pushNamed(route, arguments: arguments);
      }
    });
  }

  static gotoChat(BuildContext context,
      {UserModel? currentUser,
      UserModel? mUser,
      required SharedPreferences preferences}) {
    QuickHelp.goToNavigatorScreen(
        context,
        MessageScreen(
            currentUser: currentUser, mUser: mUser, preferences: preferences));
  }

  static goToNavigatorScreen(BuildContext context, Widget widget,
      {bool? finish = false, bool? back = true}) {
    if (finish == false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => widget,
        ),
      );
    } else {
      Navigator.pushAndRemoveUntil<dynamic>(
        context,
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => widget,
        ),
        (route) => back!, //if you want to disable back feature set to false
      );
    }
  }

  static Future<dynamic> goToNavigatorScreenForResult(
      BuildContext context, Widget widget) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          //settings: RouteSettings(name: route),
          builder: (context) => widget),
    );

    return result;
  }

  static void goBack(BuildContext context, {Object? arguments}) {
    Navigator.pop(context, arguments);
  }

  /*static goToNavigatorAndClear(BuildContext context, String route,
      {Object? arguments}) {
    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false,
          arguments: arguments);
    });
  }*/

  static goToPageWithClear(BuildContext context, Widget widget) {
    Navigator.pushAndRemoveUntil<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => widget,
      ),
      (route) => false, //if you want to disable back feature set to false
    );
  }

  static void goBackToPreviousPage(BuildContext context,
      {bool? useCustomAnimation,
      PageTransitionsBuilder? pageTransitionsBuilder,
      dynamic result}) {
    Navigator.of(context).pop(result);
  }

  static checkRoute(BuildContext context, bool authNeeded, Widget widget) {
    if (authNeeded && QuickHelp.getCurrentUser() != null) {
      return widget;
    } else {
      return QuickHelp.goBackToPreviousPage(context);
    }
  }

  /*static _logout(BuildContext context, UserModel? userModel) async {
    Navigator.pop(context);
    QuickHelp.showLoadingDialog(context);

    ParseResponse response = await userModel!.logout(deleteLocalUserData: true);
    if (response.success) {
      QuickHelp.hideLoadingDialog(context);
      //QuickHelp.goToPageWithClear(context, WelcomeScreen(), route: WelcomeScreen.route);
      //goToNavigatorAndClear(context, '/');
      QuickHelp.goToNavigatorScreen(
          context, WelcomeScreen(), finish: true, back: false);
    } else {
      QuickHelp.hideLoadingDialog(context);
      //QuickHelp.goToPageWithClear(context, WelcomeScreen(), route: WelcomeScreen.route);
      QuickHelp.goToNavigatorScreen(
          context, WelcomeScreen(), finish: true, back: false);
    }
  }*/

  static void showDialogWithButton(
      {required BuildContext context,
      String? message,
      String? title,
      String? buttonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title!),
          content: Text(message!),
          actions: [
            new ElevatedButton(
              child: Text(buttonText!),
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void showDialogWithButtonCustom(
      {required BuildContext context,
      String? message,
      String? title,
      required String? cancelButtonText,
      required String? confirmButtonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          title: TextWithTap(
            title!,
            fontWeight: FontWeight.bold,
          ),
          content: Text(message!),
          actions: [
            TextWithTap(
              cancelButtonText!,
              fontWeight: FontWeight.bold,
              marginRight: 10,
              marginLeft: 10,
              marginBottom: 10,
              onTap: () => Navigator.of(context).pop(),
            ),
            TextWithTap(
              confirmButtonText!,
              fontWeight: FontWeight.bold,
              marginRight: 10,
              marginLeft: 10,
              marginBottom: 10,
              onTap: () {
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void showDialogHeyto(
      {required BuildContext context,
      String? message,
      String? title,
      required String? cancelButtonText,
      required String? confirmButtonText,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: Column(
            children: [
              Center(
                child: Container(
                  width: 28,
                  height: 28,
                  child: SvgPicture.asset(
                    'assets/svg/ic_icon.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              TextWithTap(
                title!,
                marginTop: 28,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: TextWithTap(
            message!,
            textAlign: TextAlign.center,
          ),
          actions: [
            Column(
              children: [
                RoundedGradientButton(
                  text: confirmButtonText!,
                  //width: 150,
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 30,
                  borderRadius: 60,
                  textColor: Colors.white,
                  borderRadiusBottomLeft: 15,
                  colors: [kPrimaryColor, kSecondaryColor],
                  marginTop: 0,
                  fontSize: 16,
                  onTap: () {
                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                ),
                TextWithTap(
                  cancelButtonText!.toUpperCase(),
                  fontWeight: FontWeight.bold,
                  color: kPrimacyGrayColor,
                  marginRight: 10,
                  marginLeft: 10,
                  fontSize: 15,
                  marginBottom: 10,
                  textAlign: TextAlign.center,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showDialogPermission(
      {required BuildContext context,
      String? message,
      String? title,
      required String? confirmButtonText,
      VoidCallback? onPressed,
      bool? dismissible = true}) {
    showDialog(
      context: context,
      barrierDismissible: dismissible!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: TextWithTap(
            title!,
            marginTop: 5,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          content: TextWithTap(
            message!,
            textAlign: TextAlign.center,
            color: kSecondaryGrayColor,
          ),
          actions: [
            Column(
              children: [
                RoundedGradientButton(
                  text: confirmButtonText!,
                  //width: 150,
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 20,
                  borderRadius: 60,
                  textColor: Colors.white,
                  borderRadiusBottomLeft: 15,
                  colors: [kPrimaryColor, kSecondaryColor],
                  marginTop: 0,
                  fontSize: 15,
                  onTap: () {
                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showDialogLivEend(
      {required BuildContext context,
      String? message,
      String? title,
      required String? confirmButtonText,
      VoidCallback? onPressed,
      bool? dismiss = true}) {
    showDialog(
      barrierDismissible: dismiss!,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: QuickHelp.isDarkMode(context)
              ? kContentColorLightTheme
              : kContentColorDarkTheme,
          elevation: 2,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          title: TextWithTap(
            title!,
            marginTop: 5,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          content: TextWithTap(
            message!,
            textAlign: TextAlign.center,
            color: kSecondaryGrayColor,
          ),
          actions: [
            Column(
              children: [
                RoundedGradientButton(
                  text: confirmButtonText!,
                  //width: 150,
                  height: 48,
                  marginLeft: 30,
                  marginRight: 30,
                  marginBottom: 20,
                  borderRadius: 60,
                  textColor: Colors.white,
                  borderRadiusBottomLeft: 15,
                  colors: [kPrimaryColor, kSecondaryColor],
                  marginTop: 0,
                  fontSize: 15,
                  onTap: () {
                    if (onPressed != null) {
                      onPressed();
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void showError(
      {required BuildContext context,
      String? message,
      VoidCallback? onPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error!"),
          content: Text(message!),
          actions: <Widget>[
            new ElevatedButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                if (onPressed != null) {
                  onPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static bool isAccountDisabled(UserModel? user) {
    if (user!.getActivationStatus == true) {
      return true;
    } else if (user.getAccountDeleted == true) {
      return true;
    } else {
      return false;
    }
  }

  static updateUserServer(
      {required String column,
      required dynamic value,
      required UserModel user}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.updateUserGlobalParam);
    Map<String, dynamic> params = <String, dynamic>{
      CloudParams.columnGlobal: column,
      CloudParams.valueGlobal: value,
      CloudParams.userGlobal: user.getUsername!,
    };

    ParseResponse parseResponse = await function.execute(parameters: params);
    if (parseResponse.success) {
      UserModel.getUserResult(parseResponse.result);
    }
  }

  // Use this example
  /* Map<String, dynamic> paramsList = <String, dynamic>{
     CloudParams.userGlobal: user.getUsername!,
     UserModel.keyFirstName: "Maravilho",
     UserModel.keyLastName: "Singa",
     UserModel.keyAge: 26,
  }; */

  static updateUserServerList({required Map<String, dynamic> map}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.updateUserGlobalListParam);
    Map<String, dynamic> params = map;

    ParseResponse parseResponse = await function.execute(parameters: params);
    if (parseResponse.success) {
      UserModel.getUserResult(parseResponse.result);
    }
  }

  //final emailSendingCallback? _sendingCallback;

  static sendEmail(String accountNumber, String emailType,
      {EmailSendingCallback? sendingCallback}) async {
    ParseCloudFunction function =
        ParseCloudFunction(CloudParams.sendEmailParam);
    Map<String, String> params = <String, String>{
      CloudParams.userGlobal: accountNumber,
      CloudParams.emailType: emailType
    };
    ParseResponse result = await function.execute(parameters: params);

    if (result.success) {
      sendingCallback!(true, null);
    } else {
      sendingCallback!(false, result.error);
    }
  }

  static bool isMobile() {
    if (isWebPlatform()) {
      return false;
    } else if (isAndroidPlatform()) {
      return true;
    } else if (isIOSPlatform()) {
      return true;
    } else {
      return false;
    }
  }

  static goToWebPage(BuildContext context, {required String pageType}) {
    goToNavigator(context, pageType);
  }

  static void showErrorResult(BuildContext context, int error) {
    QuickHelp.hideLoadingDialog(context);

    if (error == DatooException.connectionFailed) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "not_connected".tr(),
        isError: true,
      );
    } else if (error == DatooException.otherCause) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "not_connected".tr(),
        isError: true,
      );
    } else if (error == DatooException.emailTaken) {
      // Internet problem
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "auth.email_taken".tr(),
        isError: true,
      );
    }

    /*else if(error == DatooException.accountBlocked){
      // Internet problem
      QuickHelp.showAlertError(context: context, title: "error".tr(), message: "auth.account_blocked".tr());
    }*/
    else {
      // Invalid credentials
      QuickHelp.showAppNotificationAdvanced(
        context: context,
        title: "error".tr(),
        message: "auth.invalid_credentials".tr(),
        isError: true,
      );
    }
  }

  static bool isAndroidLogin() {
    if (QuickHelp.isAndroidPlatform()) {
      return false;
    } else if (QuickHelp.isIOSPlatform() && Setup.isAppleLoginEnabled) {
      return true;
    } else {
      return false;
    }
  }

  static final bool areSocialLoginsDisabled = !Setup.isPhoneLoginEnabled &&
      !Setup.isGoogleLoginEnabled &&
      !isAndroidLogin();

  static int generateUId() {
    Random rnd = new Random();
    return 1000000000 + rnd.nextInt(999999999);
  }

  static int generateShortUId() {
    Random rnd = new Random();
    return 1000 + rnd.nextInt(9999);
  }

  static Future<String> downloadFilePath(
      String url, String fileName, String dir) async {
    HttpClient httpClient = new HttpClient();
    File file;
    String filePath = '';
    String myUrl = '';

    try {
      myUrl = url + '/' + fileName;
      var request = await httpClient.getUrl(Uri.parse(myUrl));
      var response = await request.close();
      if (response.statusCode == 200) {
        var bytes = await consolidateHttpClientResponseBytes(response);
        filePath = '$dir/$fileName';
        file = File(filePath);
        await file.writeAsBytes(bytes);
      } else
        filePath = 'Error code: ' + response.statusCode.toString();
    } catch (ex) {
      filePath = 'Can not fetch url';
    }

    return filePath;
  }

  static Map<String, dynamic>? getInfoFromToken(String token) {
    // validate token

    final List<String> parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }
    // retrieve token payload
    final String payload = parts[1];
    final String normalized = base64Url.normalize(payload);
    final String resp = utf8.decode(base64Url.decode(normalized));
    // convert to Map
    final payloadMap = json.decode(resp);
    if (payloadMap is! Map<String, dynamic>) {
      return null;
    }
    return payloadMap;
  }

  static Future<dynamic> downloadFile(String url, String filename) async {
    HttpClient httpClient = new HttpClient();

    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static setWebPageTitle(BuildContext context, String title) {
    SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
      label: '${Setup.appName} - $title',
      primaryColor: Theme.of(context).primaryColor.value,
    ));
  }

  /*static List<InAppPurchaseModel> getMoods() {
    InAppPurchaseModel rc = new InAppPurchaseModel();
    rc.setName("profile_tab.mood_rc".tr());
    rc.setCode("RC");

    InAppPurchaseModel lmu = new InAppPurchaseModel();
    lmu.setName("profile_tab.mood_lmu".tr());
    lmu.setCode("LMU");

    InAppPurchaseModel hle = new InAppPurchaseModel();
    hle.setName("profile_tab.mood_hle".tr());
    hle.setCode("HLE");

    InAppPurchaseModel bmm = new InAppPurchaseModel();
    bmm.setName("profile_tab.mood_bmm".tr());
    bmm.setCode("BMM");

    InAppPurchaseModel cc = new InAppPurchaseModel();
    cc.setName("profile_tab.mood_cc".tr());
    cc.setCode("CC");

    InAppPurchaseModel rfd = new InAppPurchaseModel();
    rfd.setName("profile_tab.mood_rfd".tr());
    rfd.setCode("RFD");

    InAppPurchaseModel icud = new InAppPurchaseModel();
    icud.setName("profile_tab.mood_icud".tr());
    icud.setCode("ICUD");

    InAppPurchaseModel jpt = new InAppPurchaseModel();
    jpt.setName("profile_tab.mood_jpt".tr());
    jpt.setCode("JPT");

    InAppPurchaseModel mml = new InAppPurchaseModel();
    mml.setName("profile_tab.mood_mml".tr());
    mml.setCode("MML");

    InAppPurchaseModel sm = new InAppPurchaseModel();
    sm.setName("profile_tab.mood_sm".tr());
    sm.setCode("SM");

    InAppPurchaseModel none = new InAppPurchaseModel();
    none.setName("profile_tab.mood_none".tr());
    none.setCode("");

    List<InAppPurchaseModel> moodModelArrayList = [];

    moodModelArrayList.add(rc);
    moodModelArrayList.add(lmu);
    moodModelArrayList.add(hle);
    moodModelArrayList.add(bmm);
    moodModelArrayList.add(cc);
    moodModelArrayList.add(rfd);
    moodModelArrayList.add(icud);
    moodModelArrayList.add(jpt);
    moodModelArrayList.add(mml);
    moodModelArrayList.add(sm);
    moodModelArrayList.add(none);

    return moodModelArrayList;
  }*/

  /*static String getMoodName(InAppPurchaseModel moodModel) {
    switch (moodModel.getCode()) {
      case "RC":
        return "profile_tab.mood_rc".tr();

      case "LMU":
        return "profile_tab.mood_lmu".tr();

      case "HLE":
        return "profile_tab.mood_hle".tr();

      case "BMM":
        return "profile_tab.mood_bmm".tr();

      case "CC":
        return "profile_tab.mood_cc".tr();

      case "RFD":
        return "profile_tab.mood_rfd".tr();

      case "ICUD":
        return "profile_tab.mood_icud".tr();

      case "JPT":
        return "profile_tab.mood_jpt".tr();

      case "MML":
        return "profile_tab.mood_mml".tr();

      case "SM":
        return "profile_tab.mood_sm".tr();

      default:
        return "profile_tab.mood_none".tr();
    }
  }*/

  static String getMoodNameByCode(String modeCode) {
    switch (modeCode) {
      case "RC":
        return "profile_tab.mood_rc".tr();

      case "LMU":
        return "profile_tab.mood_lmu".tr();

      case "HLE":
        return "profile_tab.mood_hle".tr();

      case "BMM":
        return "profile_tab.mood_bmm".tr();

      case "CC":
        return "profile_tab.mood_cc".tr();

      case "RFD":
        return "profile_tab.mood_rfd".tr();

      case "ICUD":
        return "profile_tab.mood_icud".tr();

      case "JPT":
        return "profile_tab.mood_jpt".tr();

      case "MML":
        return "profile_tab.mood_mml".tr();

      case "SM":
        return "profile_tab.mood_sm".tr();

      default:
        return "profile_tab.mood_none".tr();
    }
  }

  static void setRandomArray(List arrayList) {
    arrayList.shuffle();
  }

  static int getAgeFromDate(DateTime birthday) {
    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthday.year;

    int month1 = currentDate.month;
    int month2 = birthday.month;

    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthday.day;

      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  static int getAgeFromDateString(String birthDateString, String datePattern) {
    // Parsed date to check
    DateTime birthday = DateFormat(datePattern).parse(birthDateString);

    DateTime currentDate = DateTime.now();

    int age = currentDate.year - birthday.year;

    int month1 = currentDate.month;
    int month2 = birthday.month;

    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = currentDate.day;
      int day2 = birthday.day;

      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  static DateTime incrementDate(int days) {
    DateTime limitDate = DateTime.now();
    limitDate.add(Duration(days: days));

    return limitDate;
  }

  static String getStringFromDate(DateTime utcTime) {
    final dateTime = utcTime.toLocal();

    return DateFormat(dateFormatDmy).format(dateTime);
  }

  static String getTimeAgoForFeed(DateTime utcTime) {
    // Get local time based on UTC time
    final dateTime = utcTime.toLocal();

    DateTime now = DateTime.now();
    int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (dateDiff == -1) {
      // Yesterday
      return "date_time.yesterday_".tr();
    } else if (dateDiff == 0) {
      // today
      return DateFormat().add_Hm().format(dateTime);
    } else {
      return DateFormat().add_MMMEd().add_Hm().format(dateTime);
    }
  }

  static String convertToK(int number) {
    if (number > 999) {
      return "${number ~/ 1000}k+";
    } else {
      return number.toString();
    }
  }

  static String getBirthdayFromDate(DateTime date) {
    return DateFormat(dateFormatDmy).format(date.add(Duration(days: 1)));
  }

  static saveCoinTransaction({
    required UserModel author,
    UserModel? receiver,
    required int amountTransacted
  }) {
    CoinsTransactionsModel coinsTransactionsModel = CoinsTransactionsModel();

    coinsTransactionsModel.setAuthor = author;
    coinsTransactionsModel.setAuthorId = author.objectId!;

    if(receiver != null) {
      coinsTransactionsModel.setReceiver = receiver;
      coinsTransactionsModel.setReceiverId = receiver.objectId!;
      coinsTransactionsModel.setTransactionType = CoinsTransactionsModel.transactionTypeSent;
    }else{
      coinsTransactionsModel.setTransactionType = CoinsTransactionsModel.transactionTypeTopUP;
    }

    coinsTransactionsModel.setTransactedAmount = amountTransacted;
    coinsTransactionsModel.setAmountAfterTransaction = author.getCredits!;
    coinsTransactionsModel.save();
  }

  static saveReceivedGifts({
    required UserModel receiver,
    required UserModel author,
    required GiftsModel gift,
  }) async {
    QueryBuilder<GiftsReceivedModel> query =
        QueryBuilder<GiftsReceivedModel>(GiftsReceivedModel());

    query.whereEqualTo(
      GiftsReceivedModel.keyReceiverId,
      receiver.objectId,
    );

    query.whereEqualTo(
      GiftsReceivedModel.keyGiftId,
      gift.objectId,
    );

    ParseResponse verificationResponse = await query.query();

    if (verificationResponse.success && verificationResponse.results != null) {
      GiftsReceivedModel giftReceived = verificationResponse.results!.first;
      giftReceived.incrementQuantity = 1;
      giftReceived.save();
    } else {
      GiftsReceivedModel receivedGIft = new GiftsReceivedModel();
      receivedGIft.setAuthor = author;
      receivedGIft.setAuthorId = author.objectId!;
      receivedGIft.setQuantity = 1;
      receivedGIft.setReceiver = receiver;
      receivedGIft.setReceiverId = receiver.objectId!;

      receivedGIft.setGift = gift;
      receivedGIft.setGiftId = gift.objectId!;

      await receivedGIft.save();
    }
  }

  static String getDeviceOsName() {
    if (QuickHelp.isAndroidPlatform()) {
      return "Android";
    } else if (QuickHelp.isIOSPlatform()) {
      return "iOS";
    } else if (QuickHelp.isWebPlatform()) {
      return "Web";
    } else if (QuickHelp.isWindowsPlatform()) {
      return "Windows";
    } else if (QuickHelp.isLinuxPlatform()) {
      return "Linux";
    } else if (QuickHelp.isFuchsiaPlatform()) {
      return "Fuchsia";
    } else if (QuickHelp.isMacOsPlatform()) {
      return "MacOS";
    }

    return "";
  }

  static String getDeviceOsType() {
    if (QuickHelp.isAndroidPlatform()) {
      return "android";
    } else if (QuickHelp.isIOSPlatform()) {
      return "ios";
    } else if (QuickHelp.isWebPlatform()) {
      return "web";
    } else if (QuickHelp.isWindowsPlatform()) {
      return "windows";
    } else if (QuickHelp.isLinuxPlatform()) {
      return "linux";
    } else if (QuickHelp.isFuchsiaPlatform()) {
      return "fuchsia";
    } else if (QuickHelp.isMacOsPlatform()) {
      return "macos";
    }

    return "";
  }

  static getGender(UserModel user) {
    if (user.getGender == UserModel.keyGenderMale) {
      return "male_".tr();
    } else {
      return "female_".tr();
    }
  }

  static List<String> getShowMyPostToList() {
    List<String> list = [UserModel.ANY_USER, UserModel.ONLY_MY_FRIENDS, ""];

    return list;
  }

  static String getShowMyPostToMessage(String code) {
    switch (code) {
      case UserModel.ANY_USER:
        return "privacy_settings.explain_see_my_posts"
            .tr(namedArgs: {"app_name": Config.appName});

      case UserModel.ONLY_MY_FRIENDS:
        return "privacy_settings.explain_see_my_post".tr();

      default:
        return "edit_profile.profile_no_answer".tr();
    }
  }

  static Future<void> launchInWebViewWithJavaScript(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(
        url,
      );
    } else {
      throw 'Could not launch $url';
    }
  }

  static Widget appLoading() {
    return Center(
      child: Container(
        width: 50,
        height: 50,
        child:
            showLoadingAnimation(), //SvgPicture.asset('assets/svg/ic_icon.svg', width: 50, height: 50,),
      ),
    );
  }

  static Widget appLoadingLogo() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        child: Image.asset(
          QuickHelp.isDarkModeNoContext()
              ? 'assets/images/ic_logo_white.png'
              : 'assets/images/ic_logo.png',
          width: 120,
          height: 120,
        ),
      ),
    );
  }

  static double distanceInKilometersTo(
      ParseGeoPoint point1, ParseGeoPoint point2) {
    return _distanceInRadiansTo(point1, point2) * earthMeanRadiusKm;
  }

  static double distanceInMilesTo(ParseGeoPoint point1, ParseGeoPoint point2) {
    return _distanceInRadiansTo(point1, point2) * earthMeanRadiusMile;
  }

  static double _distanceInRadiansTo(
      ParseGeoPoint point1, ParseGeoPoint point2) {
    double d2r = math.pi / 180.0; // radian conversion factor
    double lat1rad = point1.latitude * d2r;
    double long1rad = point1.longitude * d2r;
    double lat2rad = point2.latitude * d2r;
    double long2rad = point2.longitude * d2r;
    double deltaLat = lat1rad - lat2rad;
    double deltaLong = long1rad - long2rad;
    double sinDeltaLatDiv2 = math.sin(deltaLat / 2);
    double sinDeltaLongDiv2 = math.sin(deltaLong / 2);
    // Square of half the straight line chord distance between both points.
    // [0.0, 1.0]
    double a = sinDeltaLatDiv2 * sinDeltaLatDiv2 +
        math.cos(lat1rad) *
            math.cos(lat2rad) *
            sinDeltaLongDiv2 *
            sinDeltaLongDiv2;
    a = math.min(1.0, a);
    return 2 * math.asin(math.sqrt(a));
  }

  static String isUserOnlineChat(UserModel user) {
    DateTime? dateTime;

    if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return "offline_".tr();
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return QuickHelp.timeAgoSinceDate(dateTime);
    } else {
      // online
      return "online_".tr();
    }
  }

  static String isUserOnlineLiveInvite(UserModel user) {
    DateTime? dateTime;

    if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return "offline_".tr();
    } else {
      // online
      return "online_".tr();
    }
  }

  static bool isUserOnline(UserModel user) {
    DateTime? dateTime;

    if (user.getLastOnline != null) {
      dateTime = user.getLastOnline;
    } else {
      dateTime = user.updatedAt;
    }

    if (DateTime.now().millisecondsSinceEpoch -
            dateTime!.millisecondsSinceEpoch >
        timeToOffline) {
      // offline
      return false;
    } else if (DateTime.now().millisecondsSinceEpoch -
            dateTime.millisecondsSinceEpoch >
        timeToSoon) {
      // offline / recently online
      return true;
    } else {
      // online
      return true;
    }
  }

  static DateTime getDateFromAge(int age) {
    var birthday = DateTime.now();

    int currentYear = birthday.year;
    int birthYear = currentYear - age;

    return new DateTime(birthYear, birthday.month, birthday.day);
  }

  static String getDiamondsLeftToRedeem(
      int diamonds, SharedPreferences preferences) {
    if (diamonds >= SharedManager().getDiamondsNeededToRedeem(preferences)) {
      return 0.toString();
    } else {
      return (SharedManager().getDiamondsNeededToRedeem(preferences) - diamonds)
          .toString();
    }
  }

  static bool hasSameDate(DateTime first, DateTime second) {
    int dateDiff = DateTime(second.year, second.month, second.day)
        .difference(DateTime(first.year, first.month, first.day))
        .inDays;
    return dateDiff == 0;
  }

  static String getMessageListTime(DateTime utcTime) {
    final dateTime = utcTime.toLocal();

    Duration diff = DateTime.now().difference(dateTime);
    DateTime now = DateTime.now();
    int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (dateDiff == -1) {
      // Yesterday
      return "date_time.yesterday_".tr();
    } else if (dateDiff == 0) {
      // today
      return DateFormat(dateFormatTimeOnly).format(dateTime);
    } else if (diff.inDays > 0 && diff.inDays < 6) {
      // Day name
      return getDaysOfWeek(dateTime);
    } else {
      return DateFormat(dateFormatDateOnly).format(dateTime);
    }
  }

  static String getMessageTime(DateTime utcTime, {bool? time}) {
    final dateTime = utcTime.toLocal();

    if (time != null && time == true) {
      return DateFormat(dateFormatTimeOnly).format(dateTime);
    } else {
      Duration diff = DateTime.now().difference(dateTime);
      DateTime now = DateTime.now();
      int dateDiff = DateTime(dateTime.year, dateTime.month, dateTime.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

      if (dateDiff == -1) {
        // Yesterday
        return "date_time.yesterday_".tr();
      } else if (dateDiff == 0) {
        // today
        return "date_time.today_".tr();
      } else if (diff.inDays > 0 && diff.inDays < 6) {
        // Day name
        return getDaysOfWeek(dateTime);
      } else {
        return DateFormat().add_MMMEd().format(dateTime);
      }
    }
  }

  static String getTimeAndDate(DateTime utcTime, {bool? time}) {
    final dateTime = utcTime.toLocal();

    DateTime date1 = DateTime.now();
    return dateTime.difference(date1).toYearsMonthsDaysString();
  }

  static String getDaysOfWeek(DateTime dateTime) {
    int day = dateTime.weekday;

    if (day == 1) {
      return "date_time.monday_".tr();
    } else if (day == 2) {
      return "date_time.tuesday_".tr();
    } else if (day == 3) {
      return "date_time.wednesday_".tr();
    } else if (day == 4) {
      return "date_time.thursday_".tr();
    } else if (day == 5) {
      return "date_time.friday_".tr();
    } else if (day == 6) {
      return "date_time.saturday_".tr();
    } else if (day == 7) {
      return "date_time.sunday_".tr();
    }

    return "";
  }

  static String timeAgoSinceDate(DateTime utcTime, {bool numericDates = true}) {
    final dateTime = utcTime.toLocal();

    final date2 = DateTime.now();
    final difference = date2.difference(dateTime);

    if (difference.inDays > 8) {
      return DateFormat(dateFormatDateOnly).format(dateTime);
    } else if ((difference.inDays / 7).floor() >= 1) {
      return (numericDates) ? '1 week ago' : 'Last week';
    } else if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }

  static String getRemainingTime({required DateTime futureDate}) {
    DateTime currentDate = DateTime.now();

    if (futureDate.isBefore(currentDate)) {
      return '0D-0h';
    }

    Duration remainingDuration = futureDate.difference(currentDate);

    if (remainingDuration.inDays > 0) {
      int days = remainingDuration.inDays;
      int hours = remainingDuration.inHours.remainder(24);

      String formattedDays = days.toString();
      String formattedHours = hours.toString();

      return '${formattedDays}D - ${formattedHours}h';
    }

    int hours = remainingDuration.inHours;
    String formattedHours = hours.toString();

    return '${formattedHours}h';
  }

  static String getTimeByDate({required DateTime date}) {

    DateTime now = DateTime.now();
    Duration difference = now.difference(date);

    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);
    int seconds = difference.inSeconds.remainder(60);

    String formattedTime = DateFormat('HH:mm:ss').format(DateTime(0, 1, 1, hours, minutes, seconds));

    return formattedTime;
  }

  static void showAppNotification(
      {required BuildContext context, String? title, bool isError = true}) {
    showTopSnackBar(
      context,
      isError
          ? SnackBarPro.error(
              title: title!,
            )
          : SnackBarPro.success(
              title: title!,
            ),
    );
  }

  static void showAppNotificationAdvanced(
      {required String title,
      required BuildContext context,
      Widget? avatar,
      String? message,
      bool? isError = true,
      VoidCallback? onTap,
      UserModel? user,
      String? avatarUrl}) {
    showTopSnackBar(
      context,
      SnackBarPro.custom(
        title: title,
        message: message,
        icon: user != null
            ? QuickActions.avatarWidget(
                user,
                imageUrl: avatarUrl,
                width: 60,
                height: 60,
              )
            : avatar,
        textStyleTitle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: isError != null ? Colors.white : Colors.black,
        ),
        textStyleMessage: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 15,
          color: isError != null ? Colors.white : Colors.black,
        ),
        isError: isError,
      ),
      onTap: onTap,
      overlayState: null,
    );
  }

  static double convertDiamondsToMoney(
      int diamonds, SharedPreferences preferences) {
    double totalMoney = (diamonds.toDouble() / 10000) *
        SharedManager().getWithDrawPercent(preferences);
    return totalMoney;
  }

  static double convertMoneyToDiamonds(
      double amount, SharedPreferences preferences) {
    double diamonds = (amount.toDouble() * 10000) /
        SharedManager().getWithDrawPercent(preferences);
    return diamonds;
  }

  static int getDiamondsForReceiver(
      int diamonds, SharedPreferences preferences) {
    double finalDiamonds =
        (diamonds / 100) * SharedManager().getDiamondsEarnPercent(preferences);
    return int.parse(finalDiamonds.toStringAsFixed(0));
  }

  static int getDiamondsForAgency(int diamonds, SharedPreferences preferences) {
    double finalDiamonds =
        (diamonds / 100) * SharedManager().getAgencyPercent(preferences);
    return int.parse(finalDiamonds.toStringAsFixed(0));
  }

  static DateTime getUntilDateFromDays(int days) {
    return DateTime.now().add(Duration(days: days));
  }

  static void showLoadingDialogWithText(BuildContext context,
      {bool? isDismissible,
      bool? useLogo = false,
      required String description,
      Color? backgroundColor}) {
    showDialog(
        context: context,
        barrierDismissible: isDismissible != null ? isDismissible : false,
        builder: (BuildContext context) {
          return Scaffold(
            extendBodyBehindAppBar: false,
            backgroundColor: backgroundColor,
            body: Container(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    useLogo! ? appLoadingLogo() : appLoading(),
                    TextWithTap(
                      description,
                      marginTop: !useLogo ? 10 : 0,
                      marginLeft: 10,
                      marginRight: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  static Future<XFile?> compressImage(String path, {int quality = 40}) async {
    final dir = await getTemporaryDirectory();
    final targetPath = dir.absolute.path + '/file.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      path,
      targetPath,
      quality: quality,
      rotate: 0,
    );

    return result;
  }

  static Future<List<File?>> compressImagesList(List<File> images,
      {int quality = 40}) async {
    final tempDir = await getTemporaryDirectory();
    List<File> imagesList = [];
    List<String> savedImagesPaths = [];

    for (int i = 0; i < images.length; i++) {
      String imageName = 'image_$i.jpg';
      final targetPath = tempDir.absolute.path + imageName;

      File tempFile = File('${tempDir.path}/$imageName');
      await tempFile.writeAsBytes(await images[i].readAsBytes());
      savedImagesPaths.add(tempFile.path);

      await tempFile.writeAsBytes(await images[i].readAsBytes());
      savedImagesPaths.add(tempFile.path);

      imagesList.add(await FlutterImageCompress.compressAndGetFile(
        images[i].path,
        targetPath,
        quality: quality,
        rotate: 0,
      ) as File);
    }

    return imagesList;
  }

  static File bytesToFile(Uint8List uint8List) {
    return File.fromRawPath(uint8List);
  }

  static Widget showLoadingAnimation(
      {Color leftDotColor = kPrimaryColor,
      Color rightDotColor = kSecondaryColor,
      double size = 35}) {
    return Center(
        child: LoadingAnimationWidget.twistingDots(
            leftDotColor: leftDotColor,
            rightDotColor: rightDotColor,
            size: size));
  }

  static bool isNormal(UserModel user){

    DateTime now = DateTime.now();

    if(user.getNormalVip != null){
      DateTime to = user.getNormalVip!;

      if(to.isAfter(now)){
        return true;
      }
    }

    return false;
  }

  static List<Locale> getLanguages(List<String> languages){

    List<Locale> availableLanguages = [];

    for(String language in languages){
      availableLanguages.add(Locale(language));
    }

    return availableLanguages;
  }

  static String getLanguageByCode(String code){
    if(code == "en"){
      return "language_screen.en_".tr();
    }else if(code == "fr") {
      return "language_screen.fr_".tr();
    }else if(code == "pt"){
      return "language_screen.pt_".tr();
    }else if(code == "ar"){
      return "language_screen.ar_".tr();
    } else{
      return "language_screen.en_".tr();
    }
  }

  static String convertNumberToK(int number) {
    return NumberFormat.compact().format(number);
  }

  static saveCurrentRoute({required String route}) async {
    final currentRoute = await SharedPreferences.getInstance();
    await currentRoute.setString('currentRoute', route);
    print("route: ${currentRoute.getString('currentRoute')}");
  }

  static removeFocusOnTextField(BuildContext context) {
    FocusScopeNode focusScopeNode = FocusScope.of(context);
    if (!focusScopeNode.hasPrimaryFocus &&
        focusScopeNode.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

extension DurationExtensions on Duration {
  String toYearsMonthsDaysString() {
    final years = this.inDays ~/ 365;
    // You will need a custom logic for the months part, since not every month has 30 days
    final months = (this.inDays % 365) ~/ 30;
    final days = (this.inDays % 365) % 30;

    return "$years y - $months m - $days d";
  }
}

