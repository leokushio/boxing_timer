import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class StartWorkout extends StatefulWidget {
  const StartWorkout({Key? key}) : super(key: key);

  @override
  _StartWorkoutState createState() => _StartWorkoutState();
}

class _StartWorkoutState extends State<StartWorkout> {
  //----------------------------------------------------------------------------AdMob code
  final BannerAd myBanner2 = BannerAd(
    adUnitId: Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );

  set _interstitialAd(InterstitialAd _interstitialAd) {}
  InterstitialAd? myad;
  @override
  void initState() {
    super.initState();
    myBanner2.load();
    InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            this._interstitialAd = ad;
            myad = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error');
          },
        ));
  }

//---------------------------------------------------------------------Admob code END***
  AudioCache audioCache = AudioCache();

  Map data = {};
  int roundTime = 0;
  int restTime = 0;
  int rounds = 0;
  int timeVal = 10;
  int roundsCounter = 0;

  Duration timeValDuration = Duration(seconds: 10);

  Timer? initTimer;
  Timer? roundTimer;
  Timer? restTimer;
  bool roundActive = false;
  bool initTimeActive = true;

  double progressVal = 0;
  bool resting = false;

  // @override
  // void initState() {
  //   startTimer();
  //   super.initState();
  // }

  void startTimer() {
    if (initTimeActive) {
      audioCache.load('clap.mp3');
      audioCache.play('clap.mp3');
      initTimer = Timer.periodic(Duration(seconds: 1), (_) => initCountdown());
    } else if (roundActive) {
      startRoundTimer();
    } else {
      startRestTimer();
    }
  }

  void initCountdown() {
    setState(() {
      timeVal -= 1;
      progressVal = 1 - (timeVal / 10);
      if (timeVal < 0) {
        progressVal = 0;
        timeVal = roundTime;
        timeValDuration = Duration(seconds: timeVal);
        roundsCounter += 1;
        initTimer?.cancel();
        startRoundTimer();
        setState(() {
          initTimeActive = false;
        });
        print(initTimeActive);
      } else if (timeVal == 0) {
        audioCache.load('bell.mp3');
        audioCache.play('bell.mp3');
        timeValDuration = Duration(seconds: timeVal);
      } else {
        timeValDuration = Duration(seconds: timeVal);
      }
    });
  }

  void startRoundTimer() {
    roundTimer = Timer.periodic(Duration(seconds: 1), (_) => roundCountdown());
    setState(() {
      roundActive = true;
    });
  }

  void roundCountdown() {
    setState(() {
      timeVal -= 1;
      progressVal = 1 - (timeVal / roundTime);
      if (timeVal < 0) {
        progressVal = 0;
        timeVal = restTime;
        timeValDuration = Duration(seconds: timeVal);
        roundTimer?.cancel();
        startRestTimer();
        print('round');
      } else if (timeVal == 10) {
        audioCache.load('clap.mp3');
        audioCache.play('clap.mp3');
        timeValDuration = Duration(seconds: timeVal);
      } else if (timeVal == 0) {
        audioCache.load('bell.mp3');
        audioCache.play('bell.mp3');
        timeValDuration = Duration(seconds: timeVal);
      } else {
        timeValDuration = Duration(seconds: timeVal);
      }
    });
  }

  void startRestTimer() {
    restTimer = Timer.periodic(Duration(seconds: 1), (_) => restCountdown());
    setState(() {
      roundActive = false;
    });
  }

  void restCountdown() {
    if (roundsCounter > rounds - 1) {
      setState(() {
        timeValDuration = Duration(seconds: 0);
      });
      restTimer?.cancel();
      Navigator.pop(context);
      myad!.show();
      print('finished');
    } else {
      setState(() {
        timeVal -= 1;
        progressVal = 1 - (timeVal / restTime);
        if (timeVal < 0) {
          progressVal = 0;
          timeVal = roundTime;
          timeValDuration = Duration(seconds: timeVal);
          roundsCounter += 1;
          restTimer?.cancel();
          startRoundTimer();
          print('rest');
        } else if (timeVal == 10) {
          audioCache.load('clap.mp3');
          audioCache.play('clap.mp3');
          timeValDuration = Duration(seconds: timeVal);
        } else if (timeVal == 0) {
          audioCache.load('bell.mp3');
          audioCache.play('bell.mp3');
          timeValDuration = Duration(seconds: timeVal);
        } else {
          timeValDuration = Duration(seconds: timeVal);
        }
      });
    }
  }

  void pauseTime() {
    if (initTimeActive) {
      initTimer?.cancel();
    } else if (roundActive) {
      roundTimer?.cancel();
    } else {
      restTimer?.cancel();
    }
  }

  final bgColor = const Color(0xFF191d28);
  final lightShadow = const Color(0xFF242a3a);
  final darkShadow = const Color(0xFF0e1017);
  final buttonHighlight = BoxShadow(
    color: Color(0xFF242a3a),
    offset: Offset(-4.0, -4.0),
    blurRadius: 6,
    spreadRadius: 1,
  );
  final buttonShadow = BoxShadow(
    color: Color(0xFF0e1017),
    offset: Offset(4.0, 4.0),
    blurRadius: 6,
    spreadRadius: 1,
  );

  @override
  Widget build(BuildContext context) {
    data = ModalRoute.of(context)!.settings.arguments as Map;
    roundTime = data['roundTime'];
    restTime = data['restTime'];
    rounds = data['rounds'];
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 5, 30, 10),
                child: Center(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.centerRight,
                          child: roundIndicator(),
                        ),
                        SizedBox(height: 10),
                        LinearProgressIndicator(
                          backgroundColor: darkShadow,
                          valueColor: AlwaysStoppedAnimation(Colors.amber),
                          minHeight: 30,
                          value: progressVal,
                        ),
                        SizedBox(height: 80),
                        Text('Start'),
                        workoutTimerBlock(),
                        SizedBox(height: 50),

                        //----------------------------------------------action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            //-----------------------------------play pause
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                color: bgColor,
                                boxShadow: [
                                  buttonHighlight,
                                  buttonShadow,
                                ],
                              ),
                              child: playPauseButton(),
                            ),
                            //-------------------------------stop...
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(35),
                                color: bgColor,
                                boxShadow: [
                                  buttonHighlight,
                                  buttonShadow,
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  pauseTime();
                                  showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      // title: const Text('AlertDialog Title'),
                                      content: const Text('Are you sure?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            startTimer();
                                            Navigator.pop(context, 'Cancel');
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            myad!.show();
                                            Navigator.popUntil(context,
                                                ModalRoute.withName('/'));
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );

                                  // myad!.show();
                                  // pauseTime();
                                  // return Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.stop,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 50.0,
              child: AdWidget(ad: myBanner2),
            )
          ],
        ),
      ),
    );
  }

  Widget workoutTimerBlock() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final timeValMinutes = twoDigits(timeValDuration.inMinutes);
    final timeValSeconds = twoDigits(timeValDuration.inSeconds.remainder(60));

    return Text(
      '$timeValMinutes:$timeValSeconds',
      style: Theme.of(context).textTheme.headline1,
    );
  }

  Widget roundIndicator() {
    if (roundsCounter == 0) {
      return Text(
        'Get Ready',
        style: Theme.of(context).textTheme.headline6,
      );
    } else if (roundActive == false) {
      return Text(
        'Rest',
        style: Theme.of(context).textTheme.headline6,
      );
    } else {
      return Text(
        'Round: $roundsCounter',
        style: Theme.of(context).textTheme.headline6,
      );
    }
  }

  bool playBtn = true;
  Widget playPauseButton() => playBtn
      ? IconButton(
          onPressed: () {
            HapticFeedback.vibrate();
            startTimer();
            setState(() {
              playBtn = false;
            });
          },
          icon: Icon(
            Icons.play_arrow,
            size: 30,
          ),
        )
      : IconButton(
          onPressed: () {
            HapticFeedback.vibrate();
            pauseTime();
            setState(() {
              playBtn = true;
            });
          },
          icon: Icon(
            Icons.pause,
            size: 30,
          ),
        );
}
