import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechScreen extends StatefulWidget {
  final String? initialText;

  const SpeechScreen({super.key, this.initialText});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  final Dio dio = Dio();
  String recognizedText = "듣고 있어요...";
  String responseText = "";
  String backButtonText = "뒤로가기";
  Timer? countdownTimer;
  int uid = 0;

  @override
  void initState() {
    super.initState();
    _loadUid().then((_) {
      flutterTts.setLanguage("ko-KR");
      flutterTts.setSpeechRate(0.5);

      if (widget.initialText != null) {
        recognizedText = widget.initialText!;
        _sendRequestToGPT(recognizedText);
        _saveMessageToServer(recognizedText, 1); // Save user1's message
      } else {
        _speak("네, 말씀하세요");
      }
    });
  }

  Future<void> _loadUid() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getInt('uid') ?? 0;
      print("로드한 uid는 $uid");
    });
  }

  Future<void> _speak(String text) async {
    print('TTS 방송이 시작됩니다.');
    await flutterTts.speak(text);
    flutterTts.setCompletionHandler(() {
      print('TTS 방송이 끝납니다.');
      if (text == "네, 말씀하세요") {
        _listen();
      } else {
        _startCountdown();
      }
    });
  }

  void _listen() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (result) {
        setState(() {
          recognizedText = result.recognizedWords;
        });
        if (result.finalResult) {
          _sendRequestToGPT(recognizedText);
          _saveMessageToServer(recognizedText, 1); // Save user1's message
        }
      });
    } else {
      setState(() {
        recognizedText = "Speech recognition not available";
      });
    }
  }

  Future<void> _sendRequestToGPT(String message) async {
    await dotenv.load(fileName: ".env");
    String? openaiKey = dotenv.env['OPENAI_API_KEY'];

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $openaiKey',
    };

    var data = json.encode({
      "model": "gpt-4",
      "messages": [
        {
          "role": "user",
          "content": message,
        }
      ]
    });

    try {
      var response = await dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = response.data;
        setState(() {
          responseText =
              jsonResponse['choices'][0]['message']['content'].trim();
        });
        print('TTS 방송이 시작됩니다.');
        await flutterTts.speak(responseText);
        flutterTts.setCompletionHandler(() {
          print('TTS 방송이 끝납니다.');
          _startCountdown();
        });
        _saveMessageToServer(responseText, 2); // Save user2's message
      } else {
        setState(() {
          responseText = "저도 잘 모르겠어요. 좀 더 열심히 공부할께요.";
        });
        print('TTS 방송이 시작됩니다.');
        await flutterTts.speak("저도 잘 모르겠어요. 좀 더 열심히 공부할께요.");
        flutterTts.setCompletionHandler(() {
          print('TTS 방송이 끝납니다.');
          _startCountdown();
        });
      }
    } catch (e) {
      print("Failed to send request: $e");
      setState(() {
        responseText = "저도 잘 모르겠어요. 좀 더 열심히 공부할께요.";
      });
      print('TTS 방송이 시작됩니다.');
      await flutterTts.speak("저도 잘 모르겠어요. 좀 더 열심히 공부할께요.");
      flutterTts.setCompletionHandler(() {
        print('TTS 방송이 끝납니다.');
        _startCountdown();
      });
    }
  }

  Future<void> _saveMessageToServer(String message, int userId) async {
    var truncatedMessage =
        message.length > 500 ? message.substring(0, 500) : message;

    var data = {
      'text': truncatedMessage,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
      'uid': uid,
    };
    print("저장하는 메시지 내용은 $data");

    try {
      await dio.post(
        'http://10.0.2.2:8000/messages',
        data: data,
      );
      print("메시지 저장에 성공했습니다.");
    } catch (e) {
      print("Failed to save message: $e");
    }
  }

  void _startCountdown() {
    int countdown = 3;
    setState(() {
      backButtonText = "뒤로가기 ($countdown)";
    });

    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
        if (countdown > 0) {
          backButtonText = "뒤로가기 ($countdown)";
        } else {
          backButtonText = "뒤로가기";
          timer.cancel();
          _navigateBack();
        }
      });
    });
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Widget _buildChatBubble(
      String text, Color backgroundColor, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("음성 인식"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "네, 말씀하세요",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            _buildChatBubble(
                recognizedText, Colors.grey.shade200, Alignment.centerLeft),
            SizedBox(height: 20),
            _buildChatBubble(
                responseText, Colors.blue.shade100, Alignment.centerRight),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateBack,
              child: Text(backButtonText),
            ),
          ],
        ),
      ),
    );
  }
}
