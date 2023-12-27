// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/UserModel.dart';
import '../../ui/container_with_corner.dart';

class OfficialServicesScreen extends StatefulWidget {
  UserModel? currentUser;
  SharedPreferences? preferences;
  OfficialServicesScreen({this.preferences, this.currentUser, Key? key}) : super(key: key);

  @override
  State<OfficialServicesScreen> createState() => _OfficialServicesScreenState();
}

class _OfficialServicesScreenState extends State<OfficialServicesScreen> {
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
