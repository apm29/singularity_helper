import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:singularity_helper/dio_util.dart';
import 'package:singularity_helper/main.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class BlocProvider<T extends BlocBase> extends StatefulWidget {
  final Widget child;
  final T bloc;

  BlocProvider({Key key, @required this.child, @required this.bloc})
      : super(key: key);

  @override
  _BlocProviderState createState() => _BlocProviderState();

  static T of<T extends BlocBase>(BuildContext context) {
    var type = _typeOf<BlocProvider<T>>();
    return (context.ancestorWidgetOfExactType(type) as BlocProvider).bloc;
  }

  static Type _typeOf<T>() => T;
}

class _BlocProviderState extends State<BlocProvider> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }
}

abstract class BlocBase {
  void dispose();
}

class ApplicationBloc extends BlocBase {
  BehaviorSubject<UserInfo> _userStateController = BehaviorSubject();

  Observable<UserInfo> get user => _userStateController.stream;

  @override
  void dispose() {
    _userStateController.close();
  }

  ApplicationBloc() {
    var userInfo = sharedPreferences.getString("userInfo") ?? "{}";
    var map = json.decode(userInfo);
    var event = UserInfo.fromJson(map);
    print('$event');
    _userStateController.add(event);

    getAllContacts();
  }

  void login(Map<String, dynamic> json) {
    var userInfo = UserInfo.fromJson(json);
    sharedPreferences.setString("userInfo", userInfo.toString());
    sharedPreferences.setString("access_token", userInfo.access_token);
    print('$userInfo');
    _userStateController.add(userInfo);
  }

  void logout() {
    sharedPreferences.setString("userInfo", null);
    sharedPreferences.setString("access_token", null);
    _userStateController.add(null);
  }

  void getAllContacts() async {
    var map = await PermissionHandler()
        .requestPermissions([PermissionGroup.contacts]);
    if (map[PermissionGroup.contacts] == PermissionStatus.granted) {
      // Get all contacts on device
      Iterable<Contact> contacts = await ContactsService.getContacts();
      contacts.map((contact){
        print('${contact.displayName}');
      });
    }
  }
}

class ProfileBloc extends BlocBase {
  PublishSubject<UserProfile> _userProfileController = PublishSubject();

  Observable<UserProfile> get userProfile => _userProfileController.stream;

  @override
  void dispose() {
    _userProfileController.close();
  }

  void onReceiveProfile(Map<String, dynamic> data) {
    if (data == null) {
      _userProfileController.add(null);
      return;
    }
    UserProfile userProfile = UserProfile.fromJson(data);
    _userProfileController.add(userProfile);
  }
}

class VerifyBloc extends BlocBase {
  BehaviorSubject<Map<String, dynamic>> _bankCodeController = BehaviorSubject();

  Observable<Map<String, dynamic>> get bankCode => _bankCodeController.stream;

  BehaviorSubject<MapEntry<String, dynamic>> _currentBankController =
      BehaviorSubject();

  Observable<MapEntry<String, dynamic>> get currentBank =>
      _currentBankController.stream;

  @override
  void dispose() {
    _bankCodeController.close();
    _currentBankController.close();
  }

  VerifyBloc() {
    DioUtil.getInstance().post("/v1/common/bankcode", {}).then(
        (BaseResp<Map<String, dynamic>> value) {
      if (value.success() && value.data != null) {
        _bankCodeController.add(value.data);
      }
    });
  }

  void setCurrentBank(MapEntry<String, dynamic> pair) {
    _currentBankController.add(pair);
  }
}
