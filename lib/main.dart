import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:navi_dog_flutter/screens/MainScreen.dart';
import 'package:navi_dog_flutter/screens/SplashScreen.dart';
import 'package:navi_dog_flutter/stores.dart';
import 'package:navi_dog_flutter/stores/SystemStore.dart';
import 'package:provider/provider.dart';

InAppLocalhostServer server = InAppLocalhostServer(port: 8080);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await server.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: stores().combineStores,
      child: Builder(
        builder: (BuildContext ctx){
          return Consumer<SystemStore>(
            builder: (ctx, systemStore, child){
              return GetMaterialApp(
                supportedLocales: const <Locale>[Locale('en', 'US')],
                themeMode: ThemeMode.light,
                theme: ThemeData(
                  fontFamily: 'Pretendard',
                  iconTheme: const IconThemeData(
                    color: Colors.black54,
                  ),
                  canvasColor: Colors.white,
                  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                    backgroundColor: Color.fromRGBO(1, 36, 60, 1),
                    selectedItemColor: Color.fromRGBO(1, 36, 60, 1),
                    selectedIconTheme: IconThemeData(
                      color: Color.fromRGBO(1, 36, 60, 1),
                    ),
                    unselectedIconTheme: IconThemeData(
                      color: Color.fromRGBO(1, 36, 60, 1),
                    ),
                    unselectedItemColor: Color.fromRGBO(1, 36, 60, 1),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  brightness: Brightness.light,
                  focusColor: const Color.fromRGBO(1, 36, 60, 1),
                  // accentColor: Colors.black87,
                  textSelectionTheme: const TextSelectionThemeData(
                      cursorColor: Color.fromRGBO(1, 36, 60, 1)
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    focusColor: const Color.fromRGBO(1, 36, 60, 1),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12
                    ),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: const Color.fromRGBO(1, 36, 60, 1)
                        ),
                        borderRadius: BorderRadius.circular(2)
                    ),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromRGBO(1, 36, 60, 1)
                        )
                    ),
                  ),
                  buttonTheme: const ButtonThemeData(
                      buttonColor: Color.fromRGBO(1, 36, 60, 1)
                  ),
                  textTheme: const TextTheme(
                    bodySmall: TextStyle(
                        color: Color.fromRGBO(1, 36, 60, 1),
                        fontSize: 22
                    ),
                    bodyMedium: TextStyle(
                      color: Color.fromRGBO(1, 36, 60, 1),
                    ),
                    bodyLarge: TextStyle(
                      color: Color.fromRGBO(1, 36, 60, 1),
                    ),
                  ),
                  dividerColor: Colors.black54,
                ),
                darkTheme: ThemeData(),
                home: const SplashScreen(),
                routes: <String, WidgetBuilder>{
                  '/routers': (context) => const MainScreen()
                },
              );
            },
          );
        },
      ),
    );
  }
}
