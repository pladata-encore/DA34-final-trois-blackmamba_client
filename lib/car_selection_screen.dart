import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivetalk/home_screen.dart';

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  String? _selectedCarCompany;
  String? _selectedCarName;
  String? _selectedCarYear;

  final Map<String, Map<String, List<String>>> _carData = {
    '현대': {
      '아반떼': ['2004-2015', '2005', '2006'],
      '그랜저': ['2004', '2005', '2006'],
      '포터': ['2004', '2005', '2006']
    },
    '폭스바겐': {
      '골프': ['2004', '2005', '2006'],
      '티구안': ['2004', '2005', '2006'],
      '파사트': ['2004', '2005', '2006']
    },
  };

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
