import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:boxing_timer/dbhelper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:rate_my_app/rate_my_app.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //-------------------------------------------------rate my app
  RateMyApp _rateMyApp = RateMyApp(
      preferencesPrefix: 'rateMyApp_',
      minDays: 1,
      minLaunches: 3,
      remindDays: 5,
      remindLaunches: 5,
      googlePlayIdentifier: 'club.profaceapp');

  T getCondition<T>() => _rateMyApp.conditions.whereType<T>().toList().first;

  //--------------------------------------------------Add Baner
  final BannerAd myBanner = BannerAd(
    adUnitId: Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );

  @override
  void initState() {
    super.initState();
    myBanner.load();

    _rateMyApp.init().then((_) {
      //--------------------------------reseting & testing ratemy app conditions
      // print('init pass');
      // _rateMyApp.reset();
      // final minimumDays = getCondition<MinimumDaysCondition>();
      // final minimumLaunches = getCondition<MinimumAppLaunchesCondition>();
      // final doNotOpenAgain = getCondition<DoNotOpenAgainCondition>();
      // final openRatingAgain = doNotOpenAgain.doNotOpenAgain;
      // print(minimumDays.minDays);
      // print(minimumLaunches.launches);
      // print(openRatingAgain);
      // print(_rateMyApp.shouldOpenDialog);

      if (_rateMyApp.shouldOpenDialog) {
        _rateMyApp.showStarRateDialog(
          context,
          title: 'Rate this app',
          message:
              'You like this app ? Then take a little bit of your time to leave a rating :', // The dialog message.

          actionsBuilder: (context, stars) {
            return [
              TextButton(
                child: Text('Maybe later'),
                onPressed: () {
                  _rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thanks for your review!')));
                  if (stars! >= 4) {
                    _rateMyApp.launchStore();
                  }
                  await _rateMyApp
                      .callEvent(RateMyAppEventType.rateButtonPressed);
                  Navigator.pop<RateMyAppDialogButton>(
                      context, RateMyAppDialogButton.rate);
                },
              ),
            ];
          },
          ignoreNativeDialog: Platform
              .isAndroid, // Set to false if you want to show the Apple's native app rating dialog on iOS or Google's native app rating dialog (depends on the current Platform).
          dialogStyle: const DialogStyle(
            // Custom dialog styles.
            titleAlign: TextAlign.center,
            messageAlign: TextAlign.center,
            messagePadding: EdgeInsets.only(bottom: 20),
          ),
          starRatingOptions: const StarRatingOptions(
              initialRating: 4), // Custom star bar rating options.
          onDismissed: () => _rateMyApp.callEvent(RateMyAppEventType
              .laterButtonPressed), // Called when the user dismissed the dialog (either by taping outside or by pressing the "back" button).
        );
      }
    });
  }

  int roundTime = 30; // duration of each round in seconds
  int restTime = 10; // duration of resting time in seconds
  int rounds = 3; // number of rounds
  int workoutTime = 0; // Total workout time in seconds

  Duration roundDuration =
      Duration(seconds: 30); // 00:00 format duration of each round
  Duration restDuration =
      Duration(seconds: 10); // 00:00 format duration of resting time
  Duration workoutDuration =
      Duration(seconds: 110); // 00:00 format for total workout time
  Duration timeValDuration = Duration(seconds: 10);

  //-----------------------------------------for saved variables

  int savedRound = 0;
  Duration savedRoundDuration = Duration();

  void setWorkoutDuration() {
    setState(() {
      if (rounds > 0 && roundTime > 0) {
        workoutTime = ((roundTime + restTime) * rounds) - restTime;
        workoutDuration = Duration(seconds: workoutTime);
      } else {
        workoutDuration = Duration(seconds: 0);
      }
    });
  }

  Future<void> increaseRoundTime() async {
    setState(() {
      roundTime += 5;
      roundDuration = Duration(seconds: roundTime);
    });
  }

  Future<void> reduceRoundTime() async {
    setState(() {
      if (roundDuration.inSeconds > 5) {
        roundTime -= 5;
        roundDuration = Duration(seconds: roundTime);
      }
    });
  }

  Future<void> increaseRest() async {
    setState(() {
      restTime += 5;
      restDuration = Duration(seconds: restTime);
    });
  }

  Future<void> reduceRest() async {
    setState(() {
      if (restDuration.inSeconds > 0) {
        restTime -= 5;
        restDuration = Duration(seconds: restTime);
      }
    });
  }

  Future<void> increaseRounds() async {
    setState(() {
      rounds += 1;
    });
  }

  Future<void> reduceRounds() async {
    setState(() {
      if (rounds > 1) {
        rounds -= 1;
      }
    });
  }

  final bgColor = const Color(0xFF191d28);
  final lightShadow = const Color(0xFF242a3a);
  final darkShadow = const Color(0xFF0e1017);
//------------------------------------button shadows for neomorphism efx
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

  String workoutName = '';
  List<Map<String, dynamic>> savedWorkout = [];
  final formKey = GlobalKey<FormState>();
  Map<String, dynamic> newWork = {};

//----------------------------------DATABASE ADD AND DELETE FUNCTIONS
  final dbHelper = DatabaseHelper.instance;

  void insertData() async {
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: workoutName,
      DatabaseHelper.columnRoundTime: roundTime,
      DatabaseHelper.columnRestTime: restTime,
      DatabaseHelper.columnRounds: rounds,
    };
    final id = await dbHelper.insert(row);
    print(id);
  }

  Future<void> clearWorkout() async {
    savedWorkout.clear();
  }

  Future<bool>? queryData() async {
    var allRows = await dbHelper.queryAllRows();
    await clearWorkout();
    allRows.forEach((element) {
      savedWorkout.add(element);
      // print(element);
    });

    return Future.value(true);
  }

  void delete(id) async {
    await dbHelper.deletedata(id);
  }

  void bottomSheet() {
    showModalBottomSheet<void>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white70,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          // initialData: [],
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 600,
                child: Center(
                  child: Text('Loading....'),
                ),
              );
            } else if (savedWorkout.length == 0) {
              return Container(
                height: 600,
                child: Center(
                  child: Text('No Workouts'),
                ),
              );
            } else {
              return Container(
                padding: EdgeInsets.fromLTRB(10, 20, 10, 0),
                height: 600,
                child: ListView(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Column(
                            children: savedWorkout
                                .map((e) => Column(
                                      children: [
                                        Dismissible(
                                          key: Key(e['name']),
                                          onDismissed: (direction) {
                                            delete(e['id']);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Workout Deleted')));
                                          },
                                          child: InkWell(
                                            onTap: () {
                                              print('object');

                                              setState(() {
                                                roundDuration = Duration(
                                                    seconds: e['roundtime']);
                                                roundTime = e['roundtime'];
                                                restDuration = Duration(
                                                    seconds: e['resttime']);
                                                restTime = e['resttime'];
                                                rounds = e['rounds'];
                                                workoutTime =
                                                    ((roundTime + restTime) *
                                                            rounds) -
                                                        restTime;
                                                workoutDuration = Duration(
                                                    seconds: workoutTime);
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content:
                                                          Text('Workout Set')));
                                              return Navigator.pop(context);
                                            },
                                            child: savedRoundTimeBlock(e),
                                          ),
                                        ),
                                      ],
                                    ))
                                .toList())
                      ],
                    ),
                  ],
                ),
              );
            }
          },
          future: queryData(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 5, 30, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 20),
                      //-----------------------header boxing timer
                      Row(
                        children: [
                          Container(
                            child: Text(
                              'Boxing Timer',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
                      //------------------------header 'set new workout'
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Set New',
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold)),
                              Text('Workout',
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // --------------------------------workout duration block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Workout Time:'),
                          workoutDurationBlock(),
                        ],
                      ),
                      SizedBox(height: 30),
                      //---------------------------------Round time duration block
                      Row(children: [Text('Rounds:')]),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.sports_mma,
                            size: 40,
                            color: Colors.red[400],
                          ),
                          roundTimeBlock(),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await increaseRoundTime();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      size: 30,
                                    )),
                              ),
                              SizedBox(width: 20),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await reduceRoundTime();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.remove,
                                      size: 30,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      //--------------------------------------------rest time block
                      Row(children: [Text('Rest:')]),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.opacity,
                            size: 40,
                            color: Colors.blue[100],
                          ),
                          restBlock(),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await increaseRest();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      size: 30,
                                    )),
                              ),
                              SizedBox(width: 20),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await reduceRest();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.remove,
                                      size: 30,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      //-------------------------------------------Rounds block
                      Row(children: [Text('Rounds:')]),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.notifications,
                            size: 40,
                            color: Colors.amber[300],
                          ),
                          Text(
                            '$rounds',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await increaseRounds();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.add,
                                      size: 30,
                                    )),
                              ),
                              SizedBox(width: 20),
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    color: bgColor,
                                    boxShadow: [
                                      buttonHighlight,
                                      buttonShadow,
                                    ]),
                                child: IconButton(
                                    onPressed: () async {
                                      HapticFeedback.vibrate();
                                      await reduceRounds();
                                      setWorkoutDuration();
                                    },
                                    icon: Icon(
                                      Icons.remove,
                                      size: 30,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      //----------------------------------------------action buttons
                      Flexible(
                        fit: FlexFit.tight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            //----------------------------------bookmark button
                            Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: bgColor,
                                boxShadow: [
                                  buttonHighlight,
                                  buttonShadow,
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  bottomSheet();
                                },
                                icon: Icon(
                                  Icons.bookmark,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            //----------------------------------play button
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(60),
                                color: bgColor,
                                boxShadow: [
                                  buttonHighlight,
                                  buttonShadow,
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  //startTimer();
                                  HapticFeedback.vibrate();
                                  Navigator.pushNamed(
                                      context, '/startworkoutpage', arguments: {
                                    'restTime': restTime,
                                    'roundTime': roundTime,
                                    'rounds': rounds
                                  });
                                },
                                icon: Icon(
                                  Icons.play_arrow,
                                  size: 45,
                                  color: Colors.blue[200],
                                ),
                              ),
                            ),
                            //--------------------------------------save button
                            Container(
                              height: 35,
                              width: 35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: bgColor,
                                boxShadow: [
                                  buttonHighlight,
                                  buttonShadow,
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  HapticFeedback.vibrate();
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Enter Workout Name:'),
                                          content: Form(
                                            key: formKey,
                                            child: TextFormField(
                                              maxLength: 19,
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please Name your Workout';
                                                }
                                                return null;
                                              },
                                              autofocus: true,
                                              // decoration: InputDecoration(
                                              //     counterText:
                                              //         '${workoutName.length.toString()} character(s)'),
                                              onChanged: (String value) {
                                                setState(() {
                                                  workoutName = value;
                                                });
                                              },
                                            ),
                                          ),
                                          actions: [
                                            Center(
                                              child: ElevatedButton(
                                                  onPressed: () {
                                                    if (formKey.currentState!
                                                        .validate()) {
                                                      insertData();
                                                      // queryData();
                                                      // newWork = {
                                                      //   'name': workoutName,
                                                      //   'roundTime': roundTime,
                                                      //   'restTime': restTime,
                                                      //   'rounds': rounds,
                                                      // };
                                                      setState(() {
                                                        // savedWorkout
                                                        //     .add(newWork);
                                                        Navigator.of(context)
                                                            .pop();
                                                      });
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(SnackBar(
                                                              content: Text(
                                                                  'Workout Saved')));
                                                    }
                                                  },
                                                  child: Text('SAVE')),
                                            )
                                          ],
                                        );
                                      });
                                },
                                icon: Icon(
                                  Icons.save,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40),
                      // Column(
                      //     children: savedWorkout
                      //         .map((e) => Text('${e['name']}'))
                      //         .toList()),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: 50.0,
              child: AdWidget(ad: myBanner),
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
      style: Theme.of(context).textTheme.headline4,
    );
  }

  Widget roundTimeBlock() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final roundMinutes = twoDigits(roundDuration.inMinutes);
    final roundSeconds = twoDigits(roundDuration.inSeconds.remainder(60));

    return Text(
      '$roundMinutes:$roundSeconds',
      style: Theme.of(context).textTheme.headline4,
    );
  }

  Widget restBlock() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final restMinutes = twoDigits(restDuration.inMinutes);
    final restSeconds = twoDigits(restDuration.inSeconds.remainder(60));

    return Text(
      '$restMinutes:$restSeconds',
      style: Theme.of(context).textTheme.headline4,
    );
  }

  Widget workoutDurationBlock() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final workoutHours = twoDigits(workoutDuration.inHours);
    final workoutMinutes = twoDigits(workoutDuration.inMinutes.remainder(60));
    final workoutSeconds = twoDigits(workoutDuration.inSeconds.remainder(60));
    String workoutDurationFormat = '';

    if (workoutDuration.inHours > 0) {
      workoutDurationFormat = '$workoutHours:$workoutMinutes:$workoutSeconds';
    } else {
      workoutDurationFormat = '$workoutMinutes:$workoutSeconds';
    }

    return Text('$workoutDurationFormat');
  }

  Widget savedRoundTimeBlock(e) {
    final savedRoundDuration = Duration(seconds: e['roundtime']);
    final savedRestDuration = Duration(seconds: e['resttime']);
    final savedRound = e['rounds'];

    String twoDigits(int? n) => n.toString().padLeft(2, '0');
    final roundMinutes = twoDigits(savedRoundDuration.inMinutes);
    final roundSeconds = twoDigits(savedRoundDuration.inSeconds.remainder(60));

    final restMinutes = twoDigits(savedRestDuration.inMinutes);
    final restSeconds = twoDigits(savedRestDuration.inSeconds.remainder(60));
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      margin: EdgeInsets.only(bottom: 15.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Colors.pink, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red,
                blurRadius: 6,
              )
            ]),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(e['name'], style: TextStyle(fontSize: 20)),
                ],
              ),
              Divider(
                thickness: 5,
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('Rounds:'),
                      Text(
                        '$savedRound',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ],
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round Time:'),
                      Text(
                        '$roundMinutes:$roundSeconds',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ],
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rest Time:'),
                      Text(
                        '$restMinutes:$restSeconds',
                        style: Theme.of(context).textTheme.headline4,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
