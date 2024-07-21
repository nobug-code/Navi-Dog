import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SystemStore with ChangeNotifier{
  bool initialized = false;
  int _selectedPage = 0;
  initialize(){
    this._selectedPage = 0;
    if(!initialized) initialized = true;
    notifyListeners();
  }
}