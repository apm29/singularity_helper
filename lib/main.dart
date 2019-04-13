import 'package:flutter/cupertino.dart';
import 'package:singularity_helper/bloc_provider.dart';
import 'package:singularity_helper/dio_util.dart';
import 'package:singularity_helper/ticker_widget.dart';
import 'dart:math' show pi;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

SharedPreferences sharedPreferences;

Future main() async {
  sharedPreferences = await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ApplicationBloc>(
      bloc: ApplicationBloc(),
      child: CupertinoApp(
        title: 'Flutter Demo',
        theme: CupertinoThemeData(primaryColor: CupertinoColors.activeBlue),
        routes: {
          "/": (context) {
            return StreamBuilder(
                stream: BlocProvider.of<ApplicationBloc>(context).user,
                builder: (context, AsyncSnapshot<UserInfo> snapshot) {
                  print('main:${snapshot.data}');
                  if (snapshot.hasData && snapshot.data.access_token != null) {
                    return BlocProvider<ProfileBloc>(
                      bloc: ProfileBloc(),
                      child: HomePage(),
                    );
                  } else {
                    return LoginPage();
                  }
                });
          },
          "/login": (_) => LoginPage(),
          "/verify": (_) {
            return BlocProvider<VerifyBloc>(
              child: VerifyPage(),
              bloc: VerifyBloc(),
            );
          },
          "/home": (_) => BlocProvider<ProfileBloc>(
                bloc: ProfileBloc(),
                child: HomePage(),
              ),
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _nameController;
  TextEditingController _passController;
  bool serviceChecked = true;
  GlobalKey<TickerWidgetState> key = GlobalKey();

  @override
  void initState() {
    _nameController = TextEditingController();
    _passController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var screenHeight = MediaQuery.of(context).size.height;
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            "登录",
            style: TextStyle(color: CupertinoColors.white),
          ),
          backgroundColor: CupertinoColors.activeBlue,
          actionsForegroundColor: CupertinoColors.white,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: screenHeight * 0.15,
                ),
                Icon(
                  CupertinoIcons.person,
                  color: CupertinoColors.activeBlue,
                  size: 50,
                ),
                Text("齐点助手"),
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.phone_solid,
                      color: CupertinoColors.activeBlue,
                    ),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _nameController,
                        maxLength: 11,
                        keyboardType: TextInputType.phone,
                        clearButtonMode: OverlayVisibilityMode.editing,
                        placeholder: "请输入手机号",
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.padlock_solid,
                      color: CupertinoColors.activeBlue,
                    ),
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          CupertinoTextField(
                            controller: _passController,
                            maxLength: 6,
                            placeholder: "请输入验证码",
                            keyboardType: TextInputType.number,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: EdgeInsets.all(6),
                              child: TickerWidget(
                                key: key,
                                onPressed: () async {
                                  //key.currentState.startTick();
                                  BaseResp baseResp =
                                      await DioUtil.getInstance()
                                          .post("/v1/user/send_sms", {
                                    "mobile": _nameController.text,
                                  });
                                  if (baseResp.success()) {
                                    Fluttertoast.showToast(msg: "短信发送成功");
                                    key.currentState.startTick();
                                  } else {
                                    Fluttertoast.showToast(msg: baseResp.msg);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(top: 28),
                        child: CupertinoButton.filled(
                          child: Text("登录"),
                          onPressed: () async {
                            BaseResp<Map<String, dynamic>> baseResp =
                                await DioUtil.getInstance()
                                    .post("/v1/user/login", {
                              "mobile": _nameController.text,
                              "code": _passController.text,
                            });
                            if (baseResp.success()) {
                              Fluttertoast.showToast(msg: baseResp.msg);
                              ApplicationBloc applicationBloc =
                                  BlocProvider.of<ApplicationBloc>(context);
                              applicationBloc.login(baseResp.data);
                            } else {
                              Fluttertoast.showToast(msg: baseResp.msg);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: screenHeight * 0.15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.check_mark_circled,
                      color: CupertinoColors.activeGreen,
                    ),
                    Text(
                      "登录即视为同意《齐点助手服务协议》",
                      style: TextStyle(
                          fontSize: 12, color: CupertinoColors.inactiveGray),
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }
}

class VerifyPage extends StatefulWidget {
  @override
  _VerifyPageState createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  GlobalKey<TickerWidgetState> key = GlobalKey();
  TextEditingController _realNameController = TextEditingController();
  TextEditingController _idCardController = TextEditingController();
  TextEditingController _bankCardController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  TextEditingController _codeController = TextEditingController();
  String _selectedBankCode;

  @override
  Widget build(BuildContext context) {
    var dividerThick = Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      height: 0.5,
      color: CupertinoColors.inactiveGray,
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "实名绑卡",
          style: TextStyle(color: CupertinoColors.white),
        ),
        backgroundColor: CupertinoColors.activeBlue,
        actionsForegroundColor: CupertinoColors.white,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: Color(0xFF333333)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ListView(
            children: <Widget>[
              SizedBox(height: 28),
              Row(
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints.tightFor(width: 100),
                      child: Text(
                        "绑卡银行",
                      )),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        onSelectBank(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(
                              color: CupertinoColors.inactiveGray,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(4))),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                                child: StreamBuilder<MapEntry<String, dynamic>>(
                                    stream: BlocProvider.of<VerifyBloc>(context)
                                        .currentBank,
                                    builder: (context, snapshot) {
                                      _selectedBankCode = snapshot.data?.key;
                                      return Text(
                                          snapshot.data?.value ?? "选择银行");
                                    })),
                            Transform.rotate(
                                angle: 0.5 * pi,
                                child: Icon(CupertinoIcons.right_chevron))
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              dividerThick,
              Row(
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints.tightFor(width: 100),
                      child: Text(
                        "银行卡号",
                      )),
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "请输入银行卡号",
                      controller: _bankCardController,
                      keyboardType: TextInputType.number,
                      clearButtonMode: OverlayVisibilityMode.editing,
                    ),
                  )
                ],
              ),
              dividerThick,
              Row(
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints.tightFor(width: 100),
                      child: Text(
                        "身份证号",
                      )),
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "请输入开户人身份证号",
                      controller: _idCardController,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      maxLength: 18,
                    ),
                  )
                ],
              ),
              dividerThick,
              Row(
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints.tightFor(width: 100),
                      child: Text(
                        "开户入姓名",
                      )),
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "请输入开户人姓名",
                      controller: _realNameController,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      maxLength: 8,
                    ),
                  )
                ],
              ),
              dividerThick,
              Row(
                children: <Widget>[
                  Container(
                      constraints: BoxConstraints.tightFor(width: 100),
                      child: Text(
                        "预留电话号码",
                      )),
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "请输入预留电话号码",
                      controller: _mobileController,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      maxLength: 11,
                      keyboardType: TextInputType.phone,
                    ),
                  )
                ],
              ),
              dividerThick,
              Row(
                children: <Widget>[
                  Container(
                      child: Text(
                    "验证码",
                  )),
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "请输入验证码",
                      controller: _codeController,
                      clearButtonMode: OverlayVisibilityMode.editing,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(6),
                    child: TickerWidget(
                      key: key,
                      onPressed: () async {
                        BaseResp<Map<String, dynamic>> baseResp =
                            await DioUtil.getInstance()
                                .post("/v1/account/sms_code", {
                          "bank_card_no": _bankCardController.text,
                          "mobile": _mobileController.text,
                          "id_card_no": _idCardController.text,
                          "real_name": _realNameController.text,
                          "bank_code": _selectedBankCode,
                        });
                        Fluttertoast.showToast(msg: baseResp.msg);
                        if (baseResp.success()) {
                          key.currentState.startTick();
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 100,
              ),
              CupertinoButton.filled(
                child: Text("提交"),
                onPressed: () async {
                  BaseResp<Map<String, dynamic>> baseResp =
                      await DioUtil.getInstance()
                          .post("/v1/account/bind_card", {
                    "code": _codeController.text,
                  });
                  Fluttertoast.showToast(msg: baseResp.msg);
                  if (baseResp.success()) {
                    Navigator.of(context).pushReplacementNamed("/home");
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void onSelectBank(BuildContext fatherContext) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return StreamBuilder<Map<String, dynamic>>(
              stream: BlocProvider.of<VerifyBloc>(fatherContext).bankCode,
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text("获取银行列表失败");
                }
                var firstPair = snapshot.data.entries.first;
                BlocProvider.of<VerifyBloc>(fatherContext)
                    .setCurrentBank(firstPair);
                var bankList = snapshot.data.entries.map((e) {
                  return Text(e.value.toString());
                }).toList();
                return SizedBox(
                  height: 180,
                  child: CupertinoPicker(
                    itemExtent: 30,
                    onSelectedItemChanged: (index) {
                      print('$index');
                      var mapEntry = snapshot.data.entries.toList()[index];
                      BlocProvider.of<VerifyBloc>(fatherContext)
                          .setCurrentBank(mapEntry);
                    },
                    children: bankList,
                  ),
                );
              });
        });
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    if (mounted) profileRequest(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var divider = Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      height: 0.1,
      color: CupertinoColors.inactiveGray,
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          "个人中心",
          style: TextStyle(color: CupertinoColors.white),
        ),
        backgroundColor: CupertinoColors.activeBlue,
        actionsForegroundColor: CupertinoColors.white,
      ),
      child: StreamBuilder<UserProfile>(
          stream: BlocProvider.of<ProfileBloc>(context).userProfile,
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text("没有数据,点击重新获取"),
                    CupertinoButton(
                        child: Icon(
                          CupertinoIcons.refresh,
                          size: 45,
                        ),
                        onPressed: () {
                          profileRequest(context);
                        }),
                    CupertinoButton.filled(
                      padding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 40),
                      child: Text("退出登录"),
                      onPressed: () {
                        ApplicationBloc applicationBloc =
                            BlocProvider.of<ApplicationBloc>(context);
                        applicationBloc.logout();
                      },
                    )
                  ],
                ),
              );
            }

            var _realName = mask(snapshot.data.real_name, 1, snapshot.data.real_name.length, 2);
            var _bankName = snapshot.data.bank_name;
            var _mobile = mask(snapshot.data.mobile, 3, 7, 4);

            return DefaultTextStyle(
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF333333),
              ),
              child: Container(
                padding: EdgeInsets.all(22),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      "images/face.png",
                      height: 80,
                      width: 80,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("恭喜您成功绑定银行卡"),
                    ),
                    divider,
                    Row(
                      children: <Widget>[
                        Text(
                          "姓名",
                          textAlign: TextAlign.start,
                        ),
                        Expanded(
                            child: Text(
                          "$_realName",
                          textAlign: TextAlign.end,
                        )),
                      ],
                    ),
                    divider,
                    Row(
                      children: <Widget>[
                        Text(
                          "手机号",
                          textAlign: TextAlign.start,
                        ),
                        Expanded(
                            child: Text(
                          "$_mobile",
                          textAlign: TextAlign.end,
                        )),
                      ],
                    ),
                    divider,
                    Row(
                      children: <Widget>[
                        Text(
                          "绑定银行卡",
                          textAlign: TextAlign.start,
                        ),
                        Expanded(
                            child: Text(
                          "$_bankName",
                          textAlign: TextAlign.end,
                        )),
                      ],
                    ),
                    divider,
                    SizedBox(
                      height: 28,
                    ),
                    CupertinoButton.filled(
                      padding:
                          EdgeInsets.symmetric(vertical: 6, horizontal: 40),
                      child: Text("退出登录"),
                      onPressed: () {
                        ApplicationBloc applicationBloc =
                            BlocProvider.of<ApplicationBloc>(context);
                        applicationBloc.logout();
                      },
                    )
                  ],
                ),
              ),
            );
          }),
    );
  }

  void profileRequest(BuildContext context) async {
    var baseResp = await DioUtil.getInstance().post("/v1/user/profile", {});
    ProfileBloc profileBloc = BlocProvider.of<ProfileBloc>(context);
    if (profileBloc == null) {
      return;
    }
    if (baseResp.success()) {
      profileBloc.onReceiveProfile(baseResp.data);
      if (baseResp.data["is_real"] == 0) {
        Navigator.of(context).pushReplacementNamed("/verify");
      }
    } else {
      Fluttertoast.showToast(msg: baseResp.msg);
      Navigator.of(context).pushNamed("/verify");
    }
  }

  String mask(
      String originString, int startIndex, int endIndex, int maskCount) {
    if (startIndex >= originString.length ||
        endIndex < startIndex) {
      return originString;
    }
    var startString = originString.substring(0, startIndex);
    var endString = originString.substring(endIndex);
    var masked = "*" * maskCount;
    return startString + masked + endString;
  }
}
