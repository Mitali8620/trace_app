// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/helpers/quick_help.dart';
import 'package:trace/app/setup.dart';
import 'package:trace/ui/text_with_tap.dart';
import 'package:trace/utils/colors.dart';

import '../app/config.dart';
import '../models/UserModel.dart';
import '../services/dynamic_link_service.dart';
import '../ui/button_with_icon.dart';
import '../ui/container_with_corner.dart';
import '../utils/datoo_exeption.dart';
import '../utils/shared_manager.dart';
import '../widgets/CountDownTimer.dart';
import 'dispache_screen.dart';


class PhoneLoginScreen extends StatefulWidget {

  SharedPreferences? preferences;

  PhoneLoginScreen({Key? key, required this.preferences}) : super(key: key);

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

FirebaseAuth _auth = FirebaseAuth.instance;
late ConfirmationResult confirmationResult;
late UserCredential userCredential;

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  PhoneNumber number = PhoneNumber(isoCode: Config.initialCountry);

  TextEditingController phoneNumberEditingController = TextEditingController();
  TextEditingController pinCodeEditingController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();

  // Web confirmation result for OTP.
  ConfirmationResult? _webConfirmationResult;

  bool isPasswordHidden = true;

  int _positionPhoneInput = 0;

  String _phoneNumber = "";
  String _pinCode = "";

  bool _showResend = false;
  late String _verificationId;
  int? _tokenResend;

  StreamController<ErrorAnimationType>? errorController;

  int position = 0;

  bool validPhoneNumber = false;
  bool passwordError = false;

  late SharedPreferences preferences;

  togglePasswordVisibility() {
    setState(() {
      if (isPasswordHidden) {
        isPasswordHidden = false;
      } else {
        isPasswordHidden = true;
      }
    });
  }

  initSharedPref() async {
    preferences = await SharedPreferences.getInstance();
  }

  nextPosition() {
    setState(() {
      position = position + 1;
    });
  }

  previousPosition() {
    setState(() {
      position = position - 1;
    });
  }

  @override
  void initState() {
    errorController = StreamController<ErrorAnimationType>();
    initSharedPref();
    super.initState();
  }

  @override
  void dispose() {
    errorController!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = QuickHelp.isDarkMode(context);
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => QuickHelp.removeFocusOnTextField(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kTransparentColor,
          automaticallyImplyLeading: false,
          leading: BackButton(
            color: isDarkMode ? Colors.white : kContentColorLightTheme,
          ),
        ),
        body: SingleChildScrollView(
          child: IndexedStack(
            index: position,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWithTap(
                      "login_screen.hello_".tr(),
                    fontSize: size.width / 10,
                    marginLeft: size.width / 9,
                    fontWeight: FontWeight.w900,
                    marginBottom: 30,
                    marginTop: 20,
                  ),
                  phoneNumberInput(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWithTap(
                        "login_screen.by_using".tr(namedArgs: {
                          "app_name": Config.appName
                        }),
                        fontSize: 9,
                        marginLeft: 5,
                        marginTop: 5,
                      ),
                      ContainerCorner(
                        marginLeft: 5,
                        marginRight: 20,
                        marginTop: 5,
                        child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(children: [
                              TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.lightBlueAccent,
                                    decoration:
                                    TextDecoration.underline,
                                  ),
                                  text:
                                  "login_screen.terms_of_service"
                                      .tr(),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (QuickHelp.isMobile()) {
                                        QuickHelp.goToWebPage(context,
                                            pageType: QuickHelp
                                                .pageTypeTerms);
                                      } else {
                                        QuickHelp
                                            .launchInWebViewWithJavaScript(
                                            Config.termsOfUseUrl);
                                      }
                                    }),
                              TextSpan(
                                style: TextStyle(
                                    color: isDarkMode ? Colors.white : kContentColorLightTheme,
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal),
                                text: "login_screen.and_"
                                    .tr()
                                    .toLowerCase(),
                              ),
                              TextSpan(
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.lightBlueAccent,
                                    decoration:
                                    TextDecoration.underline,
                                  ),
                                  text: "login_screen.privacy_".tr(),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      if (QuickHelp.isMobile()) {
                                        QuickHelp.goToWebPage(context,
                                            pageType: QuickHelp
                                                .pageTypePrivacy);
                                      } else {
                                        QuickHelp
                                            .launchInWebViewWithJavaScript(
                                            Config
                                                .privacyPolicyUrl);
                                      }
                                    }),
                            ])),
                      ),
                    ],
                  )
                ],
              ),
              Column(
                children: [
                  phoneCodeInput(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendVerificationCode(bool resend) async {
    QuickHelp.showLoadingDialog(context, isDismissible: false);

    PhoneVerificationCompleted verificationCompleted =
        (PhoneAuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);

      print('Verified automatically');

      _checkUserAccount();
    };

    PhoneVerificationFailed verificationFailed = (FirebaseAuthException e) {
      QuickHelp.hideLoadingDialog(context);

      print(
          'Phone number verification failed. Code: ${e.code}. Message: ${e.message}');

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else if (e.code == "invalid-phone-number") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_phone_number".tr());
      } else {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    };

    PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      QuickHelp.hideLoadingDialog(context);
      // Check your phone for the sms code
      _verificationId = verificationId;
      _tokenResend = forceResendingToken;

      print('Verification code sent');

      if (!resend) {
        //_updateCurrentState();
        nextPosition();
      }

      setState(() {
        _showResend = false;
      });
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
      print('PhoneCodeAutoRetrievalTimeout');
    };

    try {
      if (QuickHelp.isWebPlatform()) {
        /*confirmationResult =
        await _auth.signInWithPhoneNumber(number.phoneNumber!);*/
        //userCredential = await confirmationResult.confirm('123456');

        _webConfirmationResult = await _auth.signInWithPhoneNumber(
            number.phoneNumber!,
            RecaptchaVerifier(
              auth: FirebaseAuthPlatform.instance,
              size: RecaptchaVerifierSize.compact,
              theme: RecaptchaVerifierTheme.dark,
              onSuccess: () {
                QuickHelp.hideLoadingDialog(context);

                print('Verification code sent');

                if (!resend) {
                  //_updateCurrentState();
                  nextPosition();
                }

                setState(() {
                  _showResend = false;
                });
              },
              onError: (FirebaseAuthException error) {
                QuickHelp.showAppNotificationAdvanced(
                    context: context,
                    title: "error".tr(),
                    message: error.message);
              },
              onExpired: () {
                QuickHelp.showAppNotificationAdvanced(
                    context: context,
                    title: "error".tr(),
                    message: "auth.recaptcha_expired".tr());
              },
            ));

      } else {
        await _auth.verifyPhoneNumber(
            phoneNumber: number.phoneNumber!,
            timeout: const Duration(seconds: 5),
            verificationCompleted: verificationCompleted,
            verificationFailed: verificationFailed,
            codeSent: codeSent,
            forceResendingToken: _tokenResend,
            codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
      }
    } on FirebaseAuthException catch (e) {
      QuickHelp.hideLoadingDialog(context);

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else if (e.code == "invalid-phone-number") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_phone_number".tr());
      } else {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    }
  }

  void showError(int error) {
    QuickHelp.hideLoadingDialog(context);

    if (error == DatooException.connectionFailed) {
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "error".tr(), message: "not_connected".tr());
    } else if (error == DatooException.accountBlocked) {
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "auth.account_blocked".tr());
    } else if (error == DatooException.accountDeleted) {
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "auth.account_deleted".tr());
    } else {
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "auth.invalid_credentials".tr());
    }
  }

  Future<void> verifyCode(String pinCode) async {
    _pinCode = pinCode;
    QuickHelp.showLoadingDialog(context);

    try {
      if (QuickHelp.isWebPlatform()) {

        userCredential =
        await _webConfirmationResult!.confirm(_pinCode);
        final User? user = userCredential.user;

        if (user != null) {
          _checkUserAccount();
        }
      } else {
        final PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId,
          smsCode: _pinCode,
        );

        final User? user = (await _auth.signInWithCredential(credential)).user;

        if (user != null) {
          _checkUserAccount();
        }
      }

      //return;
    } on FirebaseAuthException catch (e) {
      QuickHelp.hideLoadingDialog(context);

      if (e.code == "web-context-cancelled") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.canceled_phone".tr());
      } else if (e.code == "invalid-verification-code") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "auth.invalid_code".tr());
      } else if (e.code == "network-request-failed") {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "no_internet_connection".tr());
      } else {
        QuickHelp.showAppNotificationAdvanced(
            context: context,
            title: "error".tr(),
            message: "try_again_later".tr());
      }
    }
  }

  // Login button clicked
  Future<void> _checkUserAccount() async {
    QueryBuilder<UserModel> queryBuilder =
    QueryBuilder<UserModel>(UserModel.forQuery());
    queryBuilder.whereEqualTo(UserModel.keyPhoneNumber, number.parseNumber());
    ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.results != null) {
      UserModel userModel = apiResponse.results!.first;
      _processLogin(userModel.getUsername, userModel.getSecondaryPassword!);
    } else if (apiResponse.success && apiResponse.results == null) {
      signUpUser();
    } else if (apiResponse.error!.code == DatooException.objectNotFound) {
      signUpUser();
    } else {
      showError(apiResponse.error!.code);
    }
  }

  Future<void> _processLogin(String? username, String password) async {
    final user = ParseUser(username, password, null);

    var response = await user.login();

    if (response.success) {
      showSuccess();
    } else {
      showError(response.error!.code);
    }
  }

  Future<void> showSuccess() async {
    QuickHelp.hideLoadingDialog(context);

    UserModel? currentUser = await ParseUser.currentUser();
    if (currentUser != null) {
      QuickHelp.goToNavigatorScreen(
          context,
          DispacheScreen(
            currentUser: currentUser, preferences: preferences,
          ),
          finish: true,
          back: false);
    }
  }

  Widget phoneNumberInput() {
    bool isDarkMode = QuickHelp.isDarkMode(context);
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15),
      child: Column(
        children: [
          ContainerCorner(
            borderRadius: 50,
          color: isDarkMode ? Colors.blueAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.05),
            child: Center(
              child: InternationalPhoneNumberInput(
                inputDecoration: InputDecoration(
                  hintText: "auth.phone_number_hint".tr(),
                  hintStyle: QuickHelp.isDarkMode(context)
                      ? TextStyle(color: kColorsGrey500)
                      : TextStyle(color: kColorsGrey500),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                    borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: kTransparentColor,
                        width: 1.0,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  ),
                ),
                errorMessage: "auth.invalid_phone_number".tr(),
                searchBoxDecoration: InputDecoration(
                  hintText: "auth.country_input_hint".tr(),
                ),
                onInputChanged: (PhoneNumber number) {
                  this.number = number;
                  this._phoneNumber = number.phoneNumber!;
                },
                onInputValidated: (bool value) {
                  setState(() {
                    if(value){
                      validPhoneNumber = true;
                    }else{
                      validPhoneNumber = false;
                    }
                  });
                },
                countrySelectorScrollControlled: true,
                locale: Config.initialCountry,
                selectorConfig: SelectorConfig(
                    selectorType: PhoneInputSelectorType.DIALOG,
                    showFlags: true,
                    useEmoji: QuickHelp.isWebPlatform() ? false : true,
                    setSelectorButtonAsPrefixIcon: true,
                    trailingSpace: true,
                    leadingPadding: 20),
                ignoreBlank: false,
                spaceBetweenSelectorAndTextField: 5,
                autoValidateMode: AutovalidateMode.onUserInteraction,
                textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                selectorTextStyle: TextStyle(
                    color: isDarkMode ? Colors.white : kPrimaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.normal),
                initialValue: number,
                countries: Setup.allowedCountries,
                textFieldController: phoneNumberEditingController,
                formatInput: true,
                autoFocus: true,
                autoFocusSearch: true,
                keyboardType:
                TextInputType.numberWithOptions(signed: false, decimal: false),
                onSaved: (PhoneNumber number) {
                  //print('On Saved: $number');
                },
              ),
            ),
          ),
          ButtonWithIcon(
            mainAxisAlignment: MainAxisAlignment.center,
            height: 45,
            marginTop: 50,
            marginBottom: 10,
            borderRadius: 60,
            fontSize: 14,
            textColor: Colors.white,
            backgroundColor: validPhoneNumber ? Colors.blueAccent :  Colors.blueAccent.withOpacity(0.4),
            text: "next".tr(),
            fontWeight: FontWeight.normal,
            onTap: !validPhoneNumber ? null : () {
              FocusManager.instance.primaryFocus?.unfocus();

              if (position == _positionPhoneInput) {
                _sendVerificationCode(false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget phoneCodeInput() {
    Size size = MediaQuery.of(context).size;
    bool isDarkMode = QuickHelp.isDarkMode(context);
    return Padding(
      padding: EdgeInsets.only(top: 40, left: 30, right: 30),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWithTap(
              "login_screen.login_phone".tr(),
              fontSize: size.width / 15,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black,
              marginBottom: 5,
            ),
            TextWithTap(
              _phoneNumber,
              marginBottom: 18,
              fontSize: 12,
              color: isDarkMode ? Colors.white :  Colors.black,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.normal,
              marginRight: 10,
            ),
            TextWithTap(
              "auth.enter_code".tr(),
              marginTop: 20,
              marginBottom: 5,
              marginLeft: 15,
              fontSize: 13,
              color: isDarkMode ? Colors.white :  Colors.black,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.normal,
              onTap: () => _showResend ? _sendVerificationCode(true) : null,
            ),
            ContainerCorner(
              borderRadius: 50,
              height: 55,
              color: isDarkMode ? Colors.blueAccent.withOpacity(0.3) :  Colors.blueAccent.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20,),
                child: PinCodeTextField(
                  appContext: context,
                  length: Setup.verificationCodeDigits,
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  animationType: AnimationType.fade,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    borderWidth: 2.0,
                    shape: PinCodeFieldShape.underline,
                    borderRadius: BorderRadius.zero,
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.transparent,
                    inactiveFillColor: Colors.transparent,
                    selectedFillColor: Colors.transparent,
                    activeColor: kPrimaryColor,
                    inactiveColor: kDisabledColor,
                    selectedColor: kDisabledGrayColor,
                  ),
                  animationDuration: Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  errorAnimationController: errorController,
                  enableActiveFill: true,
                  controller: pinCodeEditingController,
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    return null;
                  },
                  useHapticFeedback: true,
                  hapticFeedbackTypes: HapticFeedbackTypes.selection,
                  onChanged: (value) {
                    print(value);
                  },
                  onCompleted: (v) {
                    _pinCode = v;
                  },
                  beforeTextPaste: (text) {
                    print("Allowing to paste $text");
                    return true;
                  },
                ),
              ),
            ),
            passwordTextField(),
            TextWithTap(
              "login_screen.password_info".tr(),
              fontSize: 9,
              marginLeft: 20,
              marginTop: 3,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            ButtonWithIcon(
              mainAxisAlignment: MainAxisAlignment.center,
              height: 45,
              marginTop: 50,
              marginBottom: 10,
              borderRadius: 60,
              fontSize: 14,
              textColor: Colors.white,
              backgroundColor: Colors.blueAccent,
              text: "next".tr(),
              fontWeight: FontWeight.normal,
              onTap: () {
                if(formKey.currentState!.validate()) {
                  verifyCode(_pinCode);
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ContainerCorner(
                      marginTop: 3,
                      marginRight: 4,
                      color: Colors.transparent,
                      child: Visibility(
                        visible: !_showResend,
                        child: CountDownTimer(
                          countDownTimerStyle: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.normal,
                              fontSize: 14),
                          text: "auth.resend_in".tr(),
                          secondsRemaining: 30,
                          whenTimeExpires: () {
                            setState(() {
                              _showResend = true;
                            });
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _showResend,
                      child: TextWithTap(
                        "auth.resend_now".tr(),
                        marginTop: 10,
                        marginBottom: 5,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        onTap: () => _showResend ? _sendVerificationCode(true) : null,
                      ),
                    ),
                    TextWithTap(
                      "auth.edit_phone_number".tr(),
                      marginTop: 10,
                      marginBottom: 5,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                      onTap: () => previousPosition(),
                    ),
                    TextWithTap(
                      "auth.contact_support".tr(),
                      marginTop: 10,
                      marginBottom: 15,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      onTap: () => QuickHelp.goToWebPage(context,
                          pageType: QuickHelp.pageTypeHelpCenter),
                    ),
                  ],
                )
            ],),

          ],
        ),
      ),
    );
  }

  Widget passwordTextField() {
    bool isDarkMode = QuickHelp.isDarkMode(context);
    return ContainerCorner(
      borderRadius: 50,
      height: passwordError ? null: 55,
      marginTop: 10,
      color: isDarkMode ? Colors.blueAccent.withOpacity(0.3) : Colors.blueAccent.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: Center(
          child: TextFormField(
            controller: passwordTextController,
            keyboardType: TextInputType.text,
            cursorColor: kGrayColor,
            autocorrect: false,
            obscureText: isPasswordHidden,
            decoration: InputDecoration(
              errorMaxLines: 1,
              errorStyle: TextStyle(fontSize: 10),
              border: InputBorder.none,
              hintText: "login_screen.password_hint".tr(),
              hintStyle: TextStyle(color: kGrayColor.withOpacity(0.5), fontSize: 13),
              suffix: IconButton(
                onPressed: ()=> togglePasswordVisibility(),
                  icon: Icon(isPasswordHidden ? Icons.visibility : Icons.visibility_off)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                setState(() {
                  passwordError = true;
                });
                return "login_screen.password_required".tr();
              } else if (!QuickHelp.isPasswordCompliant(
                  passwordTextController.text, 8)) {
                setState(() {
                  passwordError = true;
                });
                return "login_screen.strong_password_required".tr();
              }else{
                setState(() {
                  passwordError = false;
                });
                return null;
              }
            },
            style: TextStyle(
                color: isDarkMode ? Colors.white : kGrayColor, decorationStyle: TextDecorationStyle.solid),
          ),
        ),
      ),
    );
  }

  static saveAgencyEarn(
      BuildContext context, UserModel user, SharedPreferences preferences) {
    if (SharedManager().getInvitee(preferences)!.isNotEmpty) {
      DynamicLinkService().registerInviteBy(
          user, SharedManager().getInvitee(preferences)!, context);
      SharedManager().clearInvitee(preferences);
    }
  }

  static void getPhotoFromUrl(BuildContext context, UserModel user, String url,
      SharedPreferences preferences) async {
    File avatar = await QuickHelp.downloadFile(url, "avatar.jpeg") as File;

    ParseFileBase parseFile;
    if (QuickHelp.isWebPlatform()) {
      //Seems weird, but this lets you get the data from the selected file as an Uint8List very easily.
      ParseWebFile file =
      ParseWebFile(null, name: "avatar.jpeg", url: avatar.path);
      await file.download();
      parseFile = ParseWebFile(file.file, name: file.name);
    } else {
      parseFile = ParseFile(File(avatar.path));
    }

    user.setAvatar = parseFile;
    //user.setAvatar1 = parseFile;

    final ParseResponse response = await user.save();
    if (response.success) {
      saveAgencyEarn(context, user, preferences);
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(
          context,
          DispacheScreen(
            currentUser: user, preferences: null,
          ),
          finish: true,
          back: false);
    } else {
      saveAgencyEarn(context, user, preferences);
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.goToNavigatorScreen(
          context,
          DispacheScreen(
            currentUser: user,
            preferences: preferences,
          ),
          finish: true,
          back: false);
    }
  }

  Future<void> signUpUser() async {
    var faker = Faker();

    String imageUrl =
    faker.image.image(width: 640, height: 640, keywords: ["nature"]);

    String password = passwordTextController.text;
    String username = number.parseNumber();

    UserModel user = UserModel(username, password, null);

    //user.setFullName = number.phoneNumber!;
    user.setFullName = faker.person.firstName();
    user.setSecondaryPassword = password;
    //user.setFirstName = username;
    user.setFirstName = faker.person.firstName();
    //user.setLastName = faker.person.lastName();
    user.username = username.toLowerCase();
    user.setPhotoVerified = true;
    //user.setNeedsChangeName = true;

    //user.setPhoneNumberFull = phoneNumber;

    //user.setCountry = country.name!;
    user.setCountryCode = number.isoCode!;
    user.setCountryDialCode = number.dialCode!;
    //user.setSchool = schoolEditingController.text;
    user.setPhoneNumber = username;
    user.setPhoneNumberFull = number.phoneNumber!;
    //user.setEmail = emailEditingController.text.trim();
    //user.setEmailPublic = emailEditingController.text.trim();
    //user.setGender = mySelectedGender;
    user.setUid = QuickHelp.generateUId();

    user.setUserRole = UserModel.roleUser;
    user.setPrefMinAge = Setup.minimumAgeToRegister;
    user.setPrefMaxAge = Setup.maximumAgeToRegister;
    user.setLocationTypeNearBy = true;
    user.addCredit = Setup.welcomeCredit;
    user.setBio = Setup.bio;
    user.setHasPassword = true;
    //user.setBirthday = QuickHelp.getDate(birthdayEditingController.text);

    ParseResponse userResult = await user.signUp(allowWithoutEmail: true);

    if (userResult.success) {
      getPhotoFromUrl(context, user, imageUrl, preferences);
    } else if (userResult.error!.code == 100) {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context, title: "error".tr(), message: "not_connected".tr());
    } else {
      QuickHelp.hideLoadingDialog(context);
      QuickHelp.showAppNotificationAdvanced(
          context: context,
          title: "error".tr(),
          message: "try_again_later".tr());
    }
  }
}
