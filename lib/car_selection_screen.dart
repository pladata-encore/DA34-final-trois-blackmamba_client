import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivetalk/home_screen.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON encoding and decoding

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  String? _selectedCarCompany;
  String? _selectedCarName;
  String? _selectedCarYear;
  String? uid;
  int? cid;
  Map<String, Map<String, List<String>>> _carData = {};
  String? checkCarListDt;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    uid = prefs.getString('uid');
    cid = prefs.getInt('cid');
    checkCarListDt = prefs.getString('checkCarListDt');
    _carData = _decodeCarData(prefs.getString('carData') ?? '{}');

    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (checkCarListDt != today) {
      await _updateCarData();
    }

    if (cid != null && cid != 1) {
      await _loadCarDetails(cid!);
    }
    setState(() {});
  }

  Future<void> _updateCarData() async {
    // Call API to get car data
    Map<String, Map<String, List<String>>> newCarData = await getCarMenuList();
    setState(() {
      _carData = newCarData;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('carData', _encodeCarData(_carData));
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('checkCarListDt', today);
  }

  Future<void> _loadCarDetails(int cid) async {
    // Call API to get car details
    Map<String, String> carDetails = await getCar(cid);
    setState(() {
      _selectedCarCompany = _truncateString(carDetails['company'], 10);
      _selectedCarName = _truncateString(carDetails['name'], 10);
      _selectedCarYear = _truncateString(carDetails['year'], 15);
    });
  }

  Future<Map<String, Map<String, List<String>>>> getCarMenuList() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/carmenu'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map((key, value) => MapEntry(key,
              (value as List<dynamic>).map((e) => e as String).toList()))));
    } else {
      throw Exception('Failed to load car menu');
    }
  }

  Future<Map<String, String>> getCar(int cid) async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8000/cars/$cid'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'company': _truncateString(data['company'], 10),
        'name': _truncateString(data['name'], 10),
        'year': _truncateString(data['year'], 15)
      };
    } else {
      throw Exception('Failed to load car details');
    }
  }

  String _truncateString(String? str, int maxLength) {
    if (str == null) return '';
    return str.length > maxLength ? str.substring(0, maxLength) : str;
  }

  String _encodeCarData(Map<String, Map<String, List<String>>> carData) {
    return jsonEncode(carData);
  }

  Map<String, Map<String, List<String>>> _decodeCarData(String data) {
    final decodedData = jsonDecode(data) as Map<String, dynamic>;
    return decodedData.map((key, value) => MapEntry(
        key,
        (value as Map<String, dynamic>).map((key, value) => MapEntry(
            key, (value as List<dynamic>).map((e) => e as String).toList()))));
  }

  Future<void> _saveSelection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCarCompany', _selectedCarCompany ?? '');
    await prefs.setString('selectedCarName', _selectedCarName ?? '');
    await prefs.setString('selectedCarYear', _selectedCarYear ?? '');
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<T>(
        hint: Text(hint),
        value: value,
        onChanged: onChanged,
        items: items,
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                '메뉴얼 정보를 안내 받을 차량을 선택하세요.',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            _buildDropdown<String>(
              hint: '제조사를 선택하세요.',
              value: _selectedCarCompany,
              items: _carData.keys.map((carCompany) {
                return DropdownMenuItem<String>(
                  value: carCompany,
                  child: Text(carCompany),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCarCompany = newValue;
                  _selectedCarName = null;
                  _selectedCarYear = null;
                });
              },
            ),
            _buildDropdown<String>(
              hint: '차량을 선택하세요.',
              value: _selectedCarName,
              items: _selectedCarCompany == null
                  ? []
                  : _carData[_selectedCarCompany]!.keys.map((carName) {
                      return DropdownMenuItem<String>(
                        value: carName,
                        child: Text(carName),
                      );
                    }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCarName = newValue;
                  _selectedCarYear = null;
                });
              },
            ),
            _buildDropdown<String>(
              hint: '연식을 선택하세요.',
              value: _selectedCarYear,
              items: _selectedCarName == null
                  ? []
                  : _carData[_selectedCarCompany]![_selectedCarName]!
                      .map((carYear) {
                      return DropdownMenuItem<String>(
                        value: carYear,
                        child: Text(carYear),
                      );
                    }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCarYear = newValue;
                });
              },
            ),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 24),
              child: ElevatedButton(
                onPressed: _saveSelection,
                child: Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
