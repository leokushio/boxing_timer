
import 'package:boxing_timer/ad_state.dart';
import 'package:boxing_timer/startworkout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'home.dart';
import 'loading.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        brightness: Brightness.dark,
      ),
      // initialRoute: '/home',
      routes: {
        // '/': (context) => LoadingScreen(),
        '/': (context) => HomePage(title: 'Rounds Timer'),
        '/startworkoutpage': (context) => StartWorkout()
      },
    );
  }
}
