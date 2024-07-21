import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navi_dog_flutter/stores/DestinationStore.dart';
import 'package:provider/provider.dart';

class TMapWebview extends StatefulWidget {
  const TMapWebview({super.key});

  @override
  State<TMapWebview> createState() => _TMapWebviewState();
}

class _TMapWebviewState extends State<TMapWebview> {
  InAppWebViewController? _controller;
  Timer? _timer;
  bool _loadPosition = false;


  Future<void> _determinePosition(DestinationStore store) async {
    if(_loadPosition) {
      return;
    }
    _loadPosition = true;
    bool serviceEnabled;
    LocationPermission permission;
    late Position _currentPosition;

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
    _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    store.determineStartPosition(lat: _currentPosition.latitude, lng: _currentPosition.longitude);
    // 위치가 변경될 때마다 업데이트합니다.
    // Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)).listen((Position position) async {
    //   if(mounted) _currentPosition = position;
    // });
    await _updateMapLocation(store);
    _loadPosition = false;
  }

  Future<void> _updateMapLocation(DestinationStore store) async {
    if(store.startLongitude != null && store.startLatitude != null && store.endLatitude != null && store.endLongitude != null) {
      return _controller?.evaluateJavascript(source: '''window.fetchWalkLoad({
          startX: ${store.startLongitude},
          startY: ${store.startLatitude},
          endX: ${store.endLongitude},
          endY: ${store.endLatitude},
          reqCoordType: "WGS84GEO",
          resCoordType: "EPSG3857",
          startName: "출발지",
          endName: "도착지",
        });''');
    }
  }

  void _updateMapCenter(double lat, double lng) {
    _controller?.evaluateJavascript(source: '''window.handleChangeCenter({lat: $lat, lng: $lng});''');
  }

  void _startTimer(DestinationStore store) {
    // 1초 간격으로 타이머 설정
    _timer = Timer.periodic(Duration(milliseconds: 2000), (timer) {
      _determinePosition(store);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DestinationStore store = Provider.of(context, listen: false);
    _startTimer(store);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Consumer<DestinationStore>(
        builder: (context, store, widget) => InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("http://13.125.38.76:3000/map")),
          onWebViewCreated: (ctr) {
            _controller = ctr;
            ctr.addJavaScriptHandler(handlerName: 'mapLoaded', callback: _mapLoaded);
          },
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useHybridComposition: true,
            useOnDownloadStart: true,
            supportZoom: true,
          ),
        )
      ),
    );
  }

  Future<void> _mapLoaded(List<dynamic> args) async {
    DestinationStore store = Provider.of(context, listen: false);
    if(store.startLongitude != null && store.startLatitude != null && store.endLatitude != null && store.endLongitude != null) {
      _updateMapLocation(store);
      _updateMapCenter(store.startLatitude!, store.startLongitude!);
    }
  }
}
