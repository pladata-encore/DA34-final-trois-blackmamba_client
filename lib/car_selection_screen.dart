import 'package:drivetalk/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    // 화면에 보이는 영역
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/img/carselection.png', // 이미지 경로
                width: MediaQuery.of(context).size.width * 0.4, // 이미지 너비 조절
                height: 100, // 이미지 높이 조절
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '메뉴얼 정보를 안내 받을 차량을 선택하세요.',
                style: TextStyle(
                  fontSize: 25, // 폰트 크기
                  fontWeight: FontWeight.bold, // 폰트 두께
                  color: Colors.black, // 폰트 색상
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                hint: Text('제조사를 선택하세요.'),
                value: _selectedCarCompany,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCarCompany = newValue;
                    _selectedCarName = null;
                    _selectedCarYear = null; // 제조사가 변경되면 차명와 연식 선택 초기화
                  });
                },
                items: _carData.keys.map((carCompany) {
                  return DropdownMenuItem<String>(
                    value: carCompany,
                    child: Text(carCompany),
                  );
                }).toList(),
                isExpanded: true, // 가로 화면 꽉 채우기
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                hint: Text('차량을 선택하세요.'),
                value: _selectedCarName,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCarName = newValue;
                    _selectedCarYear = null; // 차명이 변경되면 연식 선택 초기화
                  });
                },
                items: _selectedCarCompany == null
                    ? []
                    : _carData[_selectedCarCompany]!.keys.map((carName) {
                        return DropdownMenuItem<String>(
                          value: carName,
                          child: Text(carName),
                        );
                      }).toList(),
                isExpanded: true, // 가로 화면 꽉 채우기
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButton<String>(
                hint: Text('연식을 선택하세요.'),
                value: _selectedCarYear,
                onChanged: (newValue) {
                  setState(() {
                    _selectedCarYear = newValue;
                  });
                },
                items: _selectedCarName == null
                    ? []
                    : _carData[_selectedCarCompany]![_selectedCarName]!
                        .map((carYear) {
                        return DropdownMenuItem<String>(
                          value: carYear,
                          child: Text(carYear),
                        );
                      }).toList(),
                isExpanded: true, // 가로 화면 꽉 채우기
              ),
            ),
            SizedBox(height: 10),
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
