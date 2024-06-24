import 'package:drivetalk/car_selection_screen.dart';
import 'package:drivetalk/talk_screen.dart';
import 'package:drivetalk/utterance_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 화면에 보이는 영역
    return SafeArea(
      top: true,
      bottom: false,
      child: BasicScreen(),
    );
  }
}

class BasicScreen extends StatefulWidget {
  const BasicScreen({super.key});

  @override
  State<BasicScreen> createState() => _BasicScreenState();
}

class _BasicScreenState extends State<BasicScreen> {
  int bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeUid();
  }

  Future<void> initializeUid() async {
    int uid = await getUid();
    setState(() {
      bottomNavIndex = uid;
    });
  }

  Future<int> getUid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? uid = prefs.getInt('uid');
    if (uid == null) {
      return 2;
    } else {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        UtteranceScreen(),
        TalkScreen(),
        CarSelectionScreen(),
      ].elementAt(bottomNavIndex),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          setState(() {
            bottomNavIndex = value;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: '음성입력',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '대화목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: '차량',
          ),
        ],
        currentIndex: bottomNavIndex,
      ),
    );
  }
}
