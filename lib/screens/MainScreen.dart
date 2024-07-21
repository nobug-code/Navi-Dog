import 'dart:io';
import 'package:fancy_backdrop/fancy_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:navi_dog_flutter/stores/DestinationStore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

import 'RouteScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  FlutterSoundRecorder? _recorder;
  bool initialized = false;
  bool _isRecording = false;
  String? _filePath;
  bool _isPlaying = false;
  FlutterSoundPlayer? _player;
  FlutterTts? flutterTts;
  String inputText = "지금부터 말씀해주세요.";
  bool _isTtsPlaying = false;
  bool _shouldStartRecording = false;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    _determinePosition();
    flutterTts = FlutterTts();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _setTtsLanguage();
    _initializeRecorder();
  }

  Future<void> _setTtsLanguage() async {
    await flutterTts!.setLanguage("ko-KR");
  }

  Future<Directory> getApplicationDocumentsDirectory() async {
    return Directory.systemTemp;
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인합니다.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // 위치 권한을 요청합니다.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // 현재 위치를 가져옵니다.
    Position _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    DestinationStore destinationStore = Provider.of(context, listen: false);
    destinationStore.setCurrentLocationData(destination: "현 위치", longitude: _currentPosition.longitude, latitude: _currentPosition.latitude);
    setState(() {
      initialized = true;
    });
  }

  Future<void> _initializeRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/temp_record.wav';
    await _recorder!.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    Future.delayed(Duration(milliseconds: 200), () {
      _processRecording();
    });
  }

  Future<void> _processRecording() async {
    bool goNavigation = false;
    if (_filePath == null) return;
    setState(() {
      loading = true;
    });
    try{
      String whisperUrl = 'https://api.openai.com/v1/audio/transcriptions';
      String whisperApiKey = '';
      String chatGptUrl = 'https://api.openai.com/v1/chat/completions';
      String chatGptApiKey = '';

      // Whisper API 호출
      var request = http.MultipartRequest('POST', Uri.parse(whisperUrl))
        ..headers.addAll({
          'Authorization': 'Bearer $whisperApiKey',
          'Content-Type': 'multipart/form-data',
        })
        ..files.add(await http.MultipartFile.fromPath('file', _filePath!))
        ..fields['model'] = 'whisper-1'; // 모델명 설정

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var result = jsonDecode(responseData);
        String transcribedText = result['text'];

        // ChatGPT API 호출
        var chatResponse = await http.post(
          Uri.parse(chatGptUrl),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $chatGptApiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4',
            'messages': [
              {
                "role": "system",
                "content": "너는 사용자가 말하는 내용을 듣고 위치정보를 알려주는 네이게이션이야."
              },
              {'role': 'user', 'content': """
              $transcribedText 
              
              위 내용에서 대한민국 내에서 사용자가 가고싶어 하는 목적지 정보를 알려줘. 결과는 설명없이 아래 JSON 포맷으로 알려줘. 그리고 답변은 무조건 한국말로 해줘.
              
              {
                destination: {목적지명},
                lat: {목적지 latitude},
                lng: {목적지 longitude{
              }
              """}
            ]
          }),
        );

        if (chatResponse.statusCode == 200) {
          var chatData = jsonDecode(utf8.decode(chatResponse.bodyBytes));
          String gptResponseText = chatData['choices'][0]['message']['content'];
          Map<String, dynamic> responseMap = json.decode(gptResponseText);
          var destination = responseMap['destination'];
          DestinationStore destinationStore = Provider.of(context, listen: false);
          destinationStore.setEndLocationData(destination: destination, longitude: responseMap['lng'], latitude: responseMap['lat']);
          await flutterTts!.speak("지금부터 $destination로 안내하겠습니다.?");
          goNavigation = true;
        } else {
          print('ChatGPT API call failed: ${chatResponse.statusCode}');
        }
      } else {
        var responseData = await response.stream.bytesToString();
        print('Whisper API call failed: ${response.statusCode}');
        print('Error response: $responseData');
      }
    }on FormatException catch(e){
      await flutterTts!.speak(e.source);
    }
    setState(() {
      loading = false;
    });
    if(goNavigation){
      await Navigator.of(context).push(MaterialWithModalsPageRoute(builder: (context) {
        return const RouteScreen();
      }));
    }
  }

  Future<void> _playRecording() async {
    if (_isPlaying || _filePath == null) return;

    setState(() {
      _isPlaying = true;
    });

    await _player!.startPlayer(
      fromURI: _filePath,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        setState(() {
          _isPlaying = false;
        });
      },
    );
  }

  Future<void> _stopPlaying() async {
    if (!_isPlaying) return;

    await _player!.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPressStart: (_) async {
          if (_isRecording) return;
          if (inputText.isNotEmpty) {
            setState(() {
              _isTtsPlaying = true;
              _shouldStartRecording = true;
            });
            await flutterTts!.awaitSpeakCompletion(true);
            await flutterTts!.speak(inputText);
            setState(() {
              _isTtsPlaying = false;
            });
            if (_shouldStartRecording) {
              _startRecording();
            }
          } else {
            _startRecording();
          }
        },
        onLongPressEnd: (_) {
          if (_isTtsPlaying) {
            setState(() {
              _shouldStartRecording = false;
            });
          } else {
            _stopRecording();
          }
        },
        child: !initialized ? const Center(
          child: SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              backgroundColor: Colors.white10,
              strokeWidth: 2.4,
            ),
          ),
        ) : Stack(
          children: [
            AnimatedContainer(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              duration: Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _isRecording ? Colors.red.shade700 : Colors.blue.shade100,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: !_isRecording ? Colors.blue.shade700 : Colors.red.shade100,
                      child: Icon(
                        Icons.stop,
                        color: _isRecording ? Colors.red.shade700 : Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                ],
              ),
            ),
            FancyBackdrop(
              open: loading,
              child: Container(),
            )
          ],
        ),
      ),
    );
  }
}
