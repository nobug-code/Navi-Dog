import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kakaomap_webview/kakaomap_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kakaoMapKey = 'a3c752f63450aa031a589fddd255547a';
const String restApiKey = '9abe734692bbc05f10f6fa3de71a12d9';

class BakKakaoWebview extends StatefulWidget {
  const BakKakaoWebview({super.key});

  @override
  State<BakKakaoWebview> createState() => _BakKakaoWebview();
}

class _BakKakaoWebview extends State<BakKakaoWebview> {
  late WebViewController _mapController;
  final double _startLat = 33.450701;
  final double _startLng = 126.570667;
  final double _endLat = 33.45162008091554;
  final double _endLng = 126.5713226693152;
  List<KakaoLatLng> _routePath = [];

  @override
  void initState() {
    super.initState();
    _getRoutePath();
  }

  Future<void> _getRoutePath() async {
    final dio = Dio();
    final url = 'https://apis-navi.kakaomobility.com/v1/directions';
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
      } else {
        throw Exception('Failed to load route path: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load route path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: Uri.dataFromString(
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>Kakao Map</title>
            <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoMapKey&autoload=false"></script>
            <script>
              function initMap() {
                kakao.maps.load(function() {
                  var mapContainer = document.getElementById('map'), // 지도를 표시할 div 
                      mapOption = {
                          center: new kakao.maps.LatLng($_startLat, $_startLng), // 지도의 중심좌표
                          level: 3 // 지도의 확대 레벨
                      }; 

                  var map = new kakao.maps.Map(mapContainer, mapOption); // 지도를 생성합니다

                  var polylinePath = ${jsonEncode(_routePath.map((e) => [e.lng, e.lat]).toList())};

                  var linePath = polylinePath.map(function(point) {
                    return new kakao.maps.LatLng(point[1], point[0]);
                  });

                  var polyline = new kakao.maps.Polyline({
                    path: linePath,
                    strokeWeight: 5,
                    strokeColor: '#FF0000',
                    strokeOpacity: 0.7,
                    strokeStyle: 'solid'
                  });

                  polyline.setMap(map);
                });
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
      ),
    );
  }
}
