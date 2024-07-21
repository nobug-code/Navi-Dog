import 'package:navi_dog_flutter/stores/DestinationStore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'stores/SystemStore.dart';

// ignore: camel_case_types
class stores {

  List<SingleChildWidget> combineStores = [
    ChangeNotifierProvider<SystemStore>(
      create: (context) => SystemStore(),
    ),
    ChangeNotifierProvider<DestinationStore>(
      create: (context) => DestinationStore(),
    ),
  ];

}