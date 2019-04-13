import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

class TickerWidget extends StatefulWidget {
  final GlobalKey<TickerWidgetState> key;
  final int tickTimes;
  final String textInitial;
  final VoidCallback onPressed;

  TickerWidget(
      {@required this.key,
      this.tickTimes = 30,
      this.textInitial = "发送短信",
      this.onPressed})
      : super(key: key);

  @override
  TickerWidgetState createState() =>
      TickerWidgetState(key, tickTimes, textInitial, onPressed);
}

class TickerWidgetState extends State<TickerWidget> {
  int currentTime = 0;
  final GlobalKey<TickerWidgetState> key;
  final int tickTimes;
  final String textInitial;
  final VoidCallback onPressed;

  TickerWidgetState(this.key, this.tickTimes, this.textInitial, this.onPressed);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: currentTime > 0 ? null : onPressed,
        child: currentTime <= 0
            ? Text(
                textInitial,
                style: TextStyle(color: CupertinoColors.activeBlue),
              )
            : Text(
                "$currentTime(s)",
                style: TextStyle(color: CupertinoColors.inactiveGray),
              ));
  }

  StreamSubscription<int> subscription;

  void startTick() {
    print('tick');
    subscription =
        Observable.periodic(Duration(seconds: 1), (i) => tickTimes - i)
            .take(tickTimes + 1)
            .listen((time) {
      setState(() {
        currentTime = time;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
  }
}
