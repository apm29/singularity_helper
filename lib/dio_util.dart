import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:singularity_helper/main.dart';

///应佳伟
class DioUtil {
  static DioUtil _instance;

  static DioUtil getInstance() {
    if (_instance == null) {
      _instance = DioUtil._();
    }
    return _instance;
  }

  Dio dio;

  DioUtil._() {
    dio = Dio(BaseOptions(
      connectTimeout: 5000,
      receiveTimeout: 6000,
      baseUrl: "http://qi_api.junleizg.com.cn",
    ));

    dio.interceptors.add(InterceptorsWrapper(onRequest: (RequestOptions req) {
      req.headers.addAll({"content-type": "application/json;charset=utf-8"});
      if (req.data is Map) {
        var copy = req.data;
        var newData = {};
        newData["access_token"] = sharedPreferences.getString("access_token");
        newData["biz_content"] = copy;
        req.data = newData;
      }
      print("REQUEST:");
      print("===========================================");
      print("  Method:${req.method},Url:${req.baseUrl + req.path}");
      print("  Headers:${req.headers}");
      print("  QueryParams:${req.queryParameters}");
      print("  Data:${req.data}");
      print("===========================================");
    }, onResponse: (resp) {
      print("REQUEST:");
      print("===========================================");
      print(
          "  Method:${resp.request.method},Url:${resp.request.baseUrl + resp.request.path}");
      print("  Headers:${resp.request.headers}");
      print("  QueryParams:${resp.request.queryParameters}");
      print("  Data:${resp.request.data}");
      print("  -------------------------");
      print("  RESULT:");
      print("    Headers:${resp.headers}");
      print("    Data:${resp.data}");
      print("    Redirect:${resp.redirects}");
      print("    StatusCode:${resp.statusCode}");
      print("    Extras:${resp.extra}");
      print(" ===========================================");
    }, onError: (err) {
      print("ERROR:");
      print("===========================================");
      print("Message:${err.message}");
      print("Error:${err.error}");
      print("Type:${err.type}");
      print("Trace:${err.stackTrace}");
      print("===========================================");
      print("  RESULT:");
      print("    Headers:${err.response.headers}");
      print("    Data:${err.response.data}");
      print("    Redirect:${err.response.redirects}");
      print("    StatusCode:${err.response.statusCode}");
      print("    Extras:${err.response.extra}");
    }));
  }

  Future<BaseResp<Map<String, dynamic>>> post(
      String path, Map<String, dynamic> data) async {
    return dio.post<String>(path, data: data).then((resp) {
      if (resp.statusCode == 200) {
        var rawString = resp.data;
        var map = json.decode(rawString.trim());
        var code = map['code'];
        var msg = map['msg'];
        var data = map['data'] is Map<String, dynamic> ? map['data'] : null;
        return BaseResp<Map<String, dynamic>>(code, msg, data);
      } else {
        return BaseResp<Map<String, dynamic>>(
            resp.statusCode, "请求失败:${resp.statusCode}", null);
      }
    }).catchError((Object error, StackTrace stack) {
      var msg = error is DioError ? error.message : error.toString();
      return BaseResp<Map<String, dynamic>>(400, msg, null);
    });
  }
}

class BaseResp<T> {
  final int code;
  final String msg;
  final T data;

  BaseResp(this.code, this.msg, this.data);

  bool success() {
    return code == 200;
  }

  @override
  String toString() {
    return '{"code": "$code", "msg": "$msg", "data": "$data"}';
  }
}

class ContactInfo {
  final String phone;
  final String name;

  ContactInfo(this.phone, this.name);

  @override
  String toString() {
    return '{"phone":"$phone","name":"$name"}';
  }

  Map<String, dynamic> toJson() {
    return {"phone": phone, "name": name};
  }
}

class UserInfo {
  String access_token;
  String user_id;

  UserInfo.fromJson(Map<String, dynamic> json) {
    this.access_token = json == null ? null : json["access_token"];
    this.user_id = json == null
        ? null
        : (json["user_id"] is int
            ? json["user_id"].toString()
            : json["user_id"]);
  }

  @override
  String toString() {
    return '{ "access_token": "$access_token", "user_id": "$user_id"}';
  }
}

class UserProfile {
  String real_name;
  String mobile;
  String id_card_no;
  String bank_card_no;
  String bank_name;
  int is_real;

  UserProfile.fromJson(Map<String, dynamic> json) {
    this.real_name = json == null ? null : json["real_name"];
    this.mobile = json == null ? null : json["mobile"];
    this.id_card_no = json == null ? null : json["id_card_no"];
    this.bank_name = json == null ? null : json["bank_name"];
    this.bank_card_no = json == null ? null : json["bank_card_no"];
    this.is_real =
        json == null ? null : (json["is_real"] is int ? json["is_real"] : 0);
  }

  @override
  String toString() {
    return '{"real_name": "$real_name", "mobile": "$mobile", "id_card_no": "$id_card_no", "bank_name": "$bank_name", "is_real": $is_real,"bank_card_no":"$bank_card_no"}';
  }
}
