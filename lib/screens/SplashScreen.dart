import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navi_dog_flutter/screens/RouteScreen.dart';
import 'package:provider/provider.dart';

import '../stores/SystemStore.dart';
import 'MainScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  bool visible = false;
  final _kTestingCrashlytics = true;
  final _kShouldTestAsyncErrorOnInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) => initPlugin());
    initialized();
    startTime();
  }


  initialized() async {
    Future.microtask(() async {
      // If the system can show an authorization request dialog
      SystemStore systemStore = Provider.of(context, listen: false);
      systemStore.initialize();
      await initApplication();
    });
  }

  Future<void> showCustomTrackingDialog(BuildContext context) async =>
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dear User'),
          content: const Text(
            'We care about your privacy and data security. We keep this app free by showing ads. '
                'Can we continue to use your data to tailor ads for you?\n\nYou can change your choice anytime in the app settings. '
                'Our partners will collect data and use a unique identifier on your device to show you ads.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

  Future initPlugin() async {

  }

  Future initApplication() async {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(94, 95, 239, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(94, 95, 239, 1),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 0,
        elevation: 0,
      ),
      // body: Container(),
      body: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          // child: Container(),
          child: Image.asset('assets/navidog-splash.jpeg',
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  startTime() async {
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      visible = true;
    });

    var duration = const Duration(milliseconds: 2000);
    return Timer(duration, navigationPage);
  }

  void navigationPage() async {
    setState(() {
      visible = false;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return child;
      },
    ));
  }

}
