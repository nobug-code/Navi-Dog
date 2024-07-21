import 'package:flutter/material.dart';
import 'package:navi_dog_flutter/components/KakaoWebview.dart';
import 'package:navi_dog_flutter/components/TMapWebview.dart';
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: const TMapWebview()
      )
    );
  }
}
