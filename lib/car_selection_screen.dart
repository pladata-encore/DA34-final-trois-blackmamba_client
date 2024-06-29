import 'dart:convert';
import 'package:drivetalk/device_service.dart';
import 'package:drivetalk/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io'; // For Platform check

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  bool _noCarSelected = false;
  String? _selectedCarCompany;
  String? _selectedCarName;
  CarInfo? _selectedCarInfo;

  static const String nullKeyword = "null"; // Placeholder for null values

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  Future<void> _initializeSelection() async {
    await _fetchCarMenuList();
    await _loadSelection();
    setState(() {});
  }

  Future<String> _getUserAgent() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String userAgent;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      userAgent =
          "Mozilla/5.0 (Linux; Android ${androidInfo.version.release}; ${androidInfo.model}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${androidInfo.version.sdkInt} Mobile Safari/537.36";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      userAgent =
          "Mozilla/5.0 (iPhone; CPU iPhone OS ${iosInfo.systemVersion.replaceAll('.', '_')} like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/${iosInfo.systemVersion} Mobile/${iosInfo.identifierForVendor} Safari/604.1";
    } else {
      userAgent =
          "Mozilla/5.0 (compatible; MyApp/1.0; +http://example.com/bot)";
    }

    return userAgent;
  }

  Future<void> _fetchCarMenuList() async {
    try {
      final deviceService = Provider.of<DeviceService>(context, listen: false);
      deviceService.carData = await deviceService.getCarMenuList();
      print("로드한 차량정보 : ${deviceService.carData}");
    } catch (e) {
      print("Failed to fetch car menu list: $e");
      // Handle error (show a message to the user, etc.)
    }
  }

  Future<void> _loadSelection() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _noCarSelected = prefs.getBool('noCarSelected') ?? false;
      print("로드된 체크 : $_noCarSelected");
      _selectedCarCompany = prefs.getString('selectedCarCompany') != nullKeyword
          ? prefs.getString('selectedCarCompany')
          : null;
      print("로드된 제조사 : $_selectedCarCompany");
      _selectedCarName = prefs.getString('selectedCarName') != nullKeyword
          ? prefs.getString('selectedCarName')
          : null;
      print("로드된 차량 : $_selectedCarName");
      String? jsonString = prefs.getString('selectedCarInfo');
      if (jsonString != null) {
        try {
          Map<String, dynamic> carInfoMap = jsonDecode(jsonString);
          _selectedCarInfo = CarInfo(carInfoMap['year'], carInfoMap['cid']);
          print("로드된 카인포 : $_selectedCarInfo");
        } catch (e) {
          _selectedCarInfo = null;
        }
      }
    } catch (e) {
      print("Failed to load selection: $e");
      // Handle error (show a message to the user, etc.)
    }
  }

  Future<void> _saveSelection(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('noCarSelected', _noCarSelected);
      print("체크 $_noCarSelected가 sp에 저장됨");
      await prefs.setString(
          'selectedCarCompany', _selectedCarCompany ?? nullKeyword);
      print("제조사 $_selectedCarCompany sp에 저장됨");
      await prefs.setString('selectedCarName', _selectedCarName ?? nullKeyword);
      print("차량 $_selectedCarName sp에 저장됨");
      await prefs.setString(
          'selectedCarYear', _selectedCarInfo?.year ?? nullKeyword);
      String jsonString = jsonEncode(
          {'year': _selectedCarInfo?.year, 'cid': _selectedCarInfo?.cid});
      await prefs.setString('selectedCarInfo', jsonString);
      print("카인포 $jsonString sp에 저장됨");

      final deviceService = Provider.of<DeviceService>(context, listen: false);
      deviceService.cid = _selectedCarInfo?.cid ?? 1;

      String userAgent = await _getUserAgent();

      if (deviceService.uid == null) {
        await deviceService.getCarMenuList();
        await deviceService.createDevice(userAgent, deviceService.cid!);
      } else {
        await deviceService.updateDevice(deviceService.cid!);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print("Failed to save selection: $e");
      // Handle error (show a message to the user, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceService>(
      builder: (context, deviceService, child) {
        Map<String, Map<String, List<Map<String, dynamic>>>> carData =
            deviceService.carData;
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: carData.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      Center(
                        child: Image.asset(
                          'assets/img/carselection.png',
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Select the car you want to receive manual information for.',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        title: Text("Do not select a car"),
                        value: _noCarSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            _noCarSelected = value ?? false;
                            if (_noCarSelected) {
                              _selectedCarCompany = null;
                              _selectedCarName = null;
                              _selectedCarInfo = null;
                              deviceService.cid = 1;
                            }
                          });
                        },
                      ),
                      _buildDropdown<String>(
                        hint: 'Select Manufacturer',
                        value: _selectedCarCompany,
                        items: carData.keys.map((carCompany) {
                          return DropdownMenuItem<String>(
                            value: carCompany,
                            child: Text(carCompany),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCarCompany = newValue;
                            _selectedCarName = null;
                            _selectedCarInfo = null;
                          });
                        },
                        enabled: !_noCarSelected,
                      ),
                      _buildDropdown<String>(
                        hint: 'Select Car',
                        value: _selectedCarName,
                        items: _selectedCarCompany == null
                            ? []
                            : carData[_selectedCarCompany]!.keys.map((carName) {
                                return DropdownMenuItem<String>(
                                  value: carName,
                                  child: Text(carName),
                                );
                              }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCarName = newValue;
                            _selectedCarInfo = null;
                          });
                        },
                        enabled: !_noCarSelected,
                      ),
                      _buildDropdown<CarInfo>(
                        hint: 'Select Year',
                        value: _selectedCarInfo,
                        items: _selectedCarName == null
                            ? []
                            : carData[_selectedCarCompany]![_selectedCarName]!
                                .map((carInfo) {
                                return DropdownMenuItem<CarInfo>(
                                  value:
                                      CarInfo(carInfo['year'], carInfo['cid']),
                                  child: Text(carInfo['year'].toString()),
                                );
                              }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCarInfo = newValue;
                            deviceService.cid = newValue?.cid ?? 1;
                          });
                        },
                        enabled: !_noCarSelected,
                      ),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(top: 24),
                        child: ElevatedButton(
                          onPressed: () => _saveSelection(context),
                          child: Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<T>(
        hint: Text(hint),
        value: value,
        onChanged: enabled ? onChanged : null,
        items: items,
        isExpanded: true,
      ),
    );
  }
}
