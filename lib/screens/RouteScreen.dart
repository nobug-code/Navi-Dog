import 'package:flutter/material.dart';
import 'package:navi_dog_flutter/screens/DetectionScreen.dart';
import 'package:navi_dog_flutter/screens/NavigationScreen.dart';
import 'package:navi_dog_flutter/screens/VoiceScreen.dart';
import 'package:provider/provider.dart';

import '../stores/DestinationStore.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {

  final String javascriptKeyKakao = "a3c752f63450aa031a589fddd255547a";

  final List<Widget> _pages = [
    const NavigationScreen(),
    const DetectionScreen(),
  ];

  int _selectedPage = 0;


  @override
  void dispose() {
    super.dispose();
    DestinationStore destinationStore = Provider.of(context, listen: false);
    destinationStore.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: routerComponent(context),
    );
  }

  Widget routerComponent(BuildContext context){
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: _pages[_selectedPage],
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
            ),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: Color.fromRGBO(241, 241, 244, 1),
                      width: 1.8
                  )
              ),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              elevation: 0,
              unselectedFontSize: 12,
              unselectedIconTheme: const IconThemeData(
                  color: Colors.grey
              ),
              selectedItemColor: const Color.fromRGBO(165, 166, 246, 1),
              unselectedItemColor: null,
              selectedIconTheme: const IconThemeData(
                  color: Colors.black
              ),
              onTap: (idx) async {
                setState(() {
                  this._selectedPage = idx;
                });
              },
              currentIndex: _selectedPage,
              items: const [
                BottomNavigationBarItem(
                    label: '',
                    icon: Icon(Icons.map_outlined,
                      size: 28,
                    )
                  // icon: Image.asset("assets/new_image/home.png")
                ),
                BottomNavigationBarItem(
                    label: '',
                    icon: Icon(Icons.camera_alt_outlined,
                        size: 28
                    )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
