import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DestinationStore with ChangeNotifier {
  String? startDestination;
  double? startLongitude = 126.922255;
  double? startLatitude = 37.526126;
  // double? startLongitude;
  // double? startLatitude;

  String? endDestination;
  double? endLongitude = 127.03237;
  double? endLatitude = 37.49795;
  // double? endLongitude;
  // double? endLatitude;

  void clear() {
    startDestination = null;
    startLongitude = null;
    startLatitude = null;
    endDestination = null;
    endLongitude = null;
    endLatitude = null;
    notifyListeners();
  }

  setCurrentLocationData(
      {required var destination,
      required var longitude,
      required var latitude}) {
    this.startDestination = destination;
    this.startLongitude = double.parse(longitude.toString());
    this.startLatitude = double.parse(latitude.toString());
    notifyListeners();
  }

  determineStartPosition({required double lat, required double lng}) {
    startLatitude = lat;
    startLongitude = lng;
  }

  setEndLocationData(
      {required var destination,
      required var longitude,
      required var latitude}) {
    this.endDestination = destination;
    this.endLongitude = double.parse(longitude.toString());
    this.endLatitude = double.parse(latitude.toString());
    notifyListeners();
  }
}
