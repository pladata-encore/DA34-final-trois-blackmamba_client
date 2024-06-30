import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Memo 데이터의 형식을 정해줍니다. 추후 isPinned, updatedAt 등의 정보도 저장할 수 있습니다.
class Device {
  Device({
    required this.uid,
    required this.cid,
  });
  int? uid;
  int? cid;
}

// Device 데이터는 모두 여기서 관리
class DeviceService extends ChangeNotifier {
  Map<String, Map<String, List<Map<String, dynamic>>>> carData = {};

  int? _uid;
  int? _cid;

  int? get uid => _uid;

  set uid(int? newUid) {
    _uid = newUid;
    notifyListeners(); // 상태 변경을 알림
  }

  int? get cid => _cid;

  set cid(int? newCid) {
    _cid = newCid;
    notifyListeners(); // 상태 변경을 알림
  }

  final Dio _dio = Dio();

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
      getCarMenuList() async {
    try {
      final response = await _dio.get('http://10.0.2.2:8000/carmenu');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(
            key,
            (value as Map<String, dynamic>).map((key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()))));
      } else {
        throw Exception('Failed to load car menu');
      }
    } catch (e) {
      throw Exception('Failed to load car menu: $e');
    }
  }

  Future<void> createDevice(String userAgent, int cid) async {
    try {
      print("createDevice에서 넘겨받은 userAgent : $userAgent");
      print("createDevice에서 넘겨받은 cid : $cid");

      final response = await _dio.post(
        'http://10.0.2.2:8000/devices',
        data: {'userAgent': userAgent, 'cid': cid},
        options: Options(
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        uid = data['uid'];
        print("cid $cid를 담아 uid $uid로 디바이스 생성했습니다.");

        // Save cid and uid to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cid', cid);
        await prefs.setInt('uid', uid!);
        print("cid $cid와 uid $uid가 SharedPreferences에 저장되었습니다.");
      } else {
        print(
            "Failed to create device: ${response.statusCode} ${response.statusMessage}");
        throw Exception('Failed to create device');
      }
    } catch (e) {
      if (e is DioException) {
        print('DioException: ${e.message}');
        if (e.response != null) {
          print('Response data: ${e.response?.data}');
          print('Response headers: ${e.response?.headers}');
        }
      } else {
        print('Exception: $e');
      }
      throw Exception('Failed to create device: $e');
    }
  }

  Future<void> updateDevice(int cid) async {
    try {
      final response = await _dio.put(
        'http://10.0.2.2:8000/devices/$uid',
        data: {'cid': cid},
        options: Options(
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
        ),
      );

      if (response.statusCode == 200) {
        print("uid $uid의 cid를 $cid로 수정 성공했습니다.");
        // Device updated successfully
      } else {
        throw Exception('Failed to update device');
      }
    } catch (e) {
      throw Exception('Failed to update device: $e');
    }
  }
}

class CarInfo {
  final String year;
  final int cid;

  CarInfo(this.year, this.cid);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarInfo &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          cid == other.cid;

  @override
  int get hashCode => year.hashCode ^ cid.hashCode;
}
