import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  String recognizedText = "듣고 있어요...";
  String responseText = "";

  @override
  void initState() {
    super.initState();
    flutterTts.setLanguage("ko-KR");
    flutterTts.setSpeechRate(0.5);
    _speak("네, 말씀하세요");
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
    flutterTts.setCompletionHandler(() {
      if (text == "네, 말씀하세요") {
        _listen();
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

    var request = http.Request(
        'POST', Uri.parse('https://api.openai.com/v1/chat/completions'));
    request.body = json.encode({
      "model": "gpt-4o",
      "messages": [
        {
          "role": "user",
          "content": message,
        }
      ]
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseString = await response.stream.bytesToString();
      Map<String, dynamic> jsonResponse = json.decode(responseString);
      setState(() {
        responseText = jsonResponse['choices'][0]['message']['content'].trim();
      });
      _speak(responseText);
    } else {
      setState(() {
        responseText = "저도 잘 모르겠어요. 좀 더 열심히 공부할께요.";
      });
      _speak("저도 잘 모르겠어요. 좀 더 열심히 공부할께요.");
    }
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
            Text(
              recognizedText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              responseText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
