import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:navi_dog_flutter/stores/DestinationStore.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

const String kakaoMapKey = 'a3c752f63450aa031a589fddd255547a';
const String restApiKey = '9abe734692bbc05f10f6fa3de71a12d9';

class KakaoWebview extends StatefulWidget {
  const KakaoWebview({super.key});

  @override
  State<KakaoWebview> createState() => _KakaoWebviewState();
}

class _KakaoWebviewState extends State<KakaoWebview> {
  late WebViewController _mapController;
  late double _startLat;
  late double _startLng;
  late double _endLat;
  late double _endLng;
  List<KakaoLatLng> _routePath = [];
  late Position _currentPosition;

  @override
  void initState() {
    super.initState();
    DestinationStore destinationStore = Provider.of(context, listen: false);
    setState(() {
      _startLat = destinationStore.startLatitude!;
      _startLng = destinationStore.startLongitude!;
      _endLat = destinationStore.endLatitude!;
      _endLng = destinationStore.endLongitude!;
    });
    _getRoutePath();
  }

  Future<void> _getRoutePath() async {
    final dio = Dio();
    const url = 'https://apis-navi.kakaomobility.com/v1/directions';
    final queryParameters = {
      'origin': '$_startLng,$_startLat',
      'destination': '$_endLng,$_endLat',
      'waypoints': '',
      'priority': 'RECOMMEND',
      'car_fuel': 'GASOLINE',
      'car_hipass': 'false',
      'alternatives': 'false',
      'road_details': 'false'
    };

    final headers = {
      'Authorization': 'KakaoAK $restApiKey'
    };

    try {
      final response = await dio.get(url, queryParameters: queryParameters, options: Options(headers: headers));

      if (response.statusCode == 200) {
        final data = response.data;
        final sections = data['routes'][0]['sections'] as List;
        List<KakaoLatLng> path = [];

        for (var section in sections) {
          for (var road in section['roads']) {
            final vertexes = road['vertexes'] as List;
            for (int i = 0; i < vertexes.length; i += 2) {
              path.add(KakaoLatLng(lat: vertexes[i + 1], lng: vertexes[i]));
            }
          }
        }

        setState(() {
          _routePath = path;
        });

        // 지도 초기화 후 경로 데이터 업데이트
        _mapController.runJavascript('updateRoutePath(${jsonEncode(_routePath.map((e) => [e.lng, e.lat]).toList())});');

      } else {
        throw Exception('Failed to load route path: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load route path: $e');
    }
  }

  // Future<void> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   // 위치 서비스가 활성화되어 있는지 확인합니다.
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }
  //
  //   // 위치 권한을 요청합니다.
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  //   }
  //
  //   // 현재 위치를 가져옵니다.
  //   _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  //   setState(() {
  //     _startLng = _currentPosition.longitude;
  //     _startLat = _currentPosition.latitude;
  //   });
  //   _getRoutePath();
  //
  //   // // 위치가 변경될 때마다 업데이트합니다.
  //   Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).listen((Position position) {
  //     setState(() {
  //       if(mounted) _currentPosition = position;
  //     });
  //     _updateMapLocation(position);
  //   });
  // }
  //
  // void _updateMapLocation(Position position) {
  //   _mapController.runJavascript('updateCurrentLocation(${position.latitude}, ${position.longitude});');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: Uri.dataFromString('''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Kakao Map</title>
            <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoMapKey&autoload=false"></script>
            <script>
              let map, marker, polyline;
              function initMap() {
                kakao.maps.load(function() {
                  var mapContainer = document.getElementById('map'), // 지도를 표시할 div 
                      mapOption = {
                          center: new kakao.maps.LatLng($_startLat, $_startLng), // 지도의 중심좌표
                          level: 3 // 지도의 확대 레벨
                      }; 

                  map = new kakao.maps.Map(mapContainer, mapOption); // 지도를 생성합니다

                  marker = new kakao.maps.Marker({
                    position: new kakao.maps.LatLng($_startLat, $_startLng),
                    map: map
                  });
                });
              }

              function updateRoutePath(routePath) {
                var linePath = routePath.map(function(point) {
                  return new kakao.maps.LatLng(point[1], point[0]);
                });

                if (polyline) {
                  polyline.setMap(null);
                }

                polyline = new kakao.maps.Polyline({
                  path: linePath,
                  strokeWeight: 5,
                  strokeColor: '#FF0000',
                  strokeOpacity: 0.7,
                  strokeStyle: 'solid'
                });

                polyline.setMap(map);
              }

              function updateCurrentLocation(lat, lng) {
                var moveLatLon = new kakao.maps.LatLng(lat, lng);
                map.setCenter(moveLatLon);
                marker.setPosition(moveLatLon);
              }
            </script>
          </head>
          <body onload="initMap()">
            <div id="map" style="width:100%;height:100vh;"></div>
          </body>
          </html>
          ''',
            mimeType: 'text/html',
            encoding: Encoding.getByName('utf-8')
        ).toString(),
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _mapController = webViewController;
        },
        onPageFinished: (String url) {
          if (_routePath.isNotEmpty) {
            _mapController.runJavascript('updateRoutePath(${jsonEncode(_routePath.map((e) => [e.lng, e.lat]).toList())});');
          }
        },
      ),
    );
  }
}
