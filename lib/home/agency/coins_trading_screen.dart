// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/ui/container_with_corner.dart';

import '../../models/UserModel.dart';

class CoinsTradingScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  CoinsTradingScreen({this.currentUser, this.preferences, Key? key}) : super(key: key);

  @override
  State<CoinsTradingScreen> createState() => _CoinsTradingScreenState();
}

class _CoinsTradingScreenState extends State<CoinsTradingScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: ContainerCorner(
        width: size.width,
        height: size.height,
        borderWidth: 0,
        child: Center(
            child: Image.asset(
              "assets/images/szy_kong_icon.png",
              height: size.width / 2,
            )),
      ),
    );
  }
}
