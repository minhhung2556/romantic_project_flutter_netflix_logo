import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    return Container(
      color: Colors.black,
      child: Center(
          child: NetFlixLogo(
        color: Color(0xffff0000),
        durationMilliseconds: 1200,
        width: 0.7 * screenSize.height / 3,
        height: screenSize.height / 3,
        strokeWidth: 2,
      )),
    );
  }
}

class NetFlixLogo extends StatefulWidget {
  final double strokeWidth;
  final double width, height;
  final int durationMilliseconds;
  final Color color;

  const NetFlixLogo(
      {Key key,
      this.strokeWidth,
      this.durationMilliseconds,
      this.color,
      this.width,
      this.height})
      : super(key: key);

  @override
  _NetFlixLogoState createState() => _NetFlixLogoState();
}

const int kSubLineCount = 2000;

class _NetFlixLogoState extends State<NetFlixLogo>
    with TickerProviderStateMixin {
  AnimationController _acMain;
  List<AnimationController> _ac;
  List<double> _stops;
  List<double> _tweenSpeeds;
  ColorTween _colorTween;
  CrossFadeState _buttonState = CrossFadeState.showFirst;
  List<Color> _endColors;

  @override
  void initState() {
    _stops = List<double>.generate(kSubLineCount,
        (index) => math.min(0.8, 0.2 + math.Random.secure().nextDouble()));
    _tweenSpeeds = List<double>.generate(kSubLineCount,
        (index) => math.Random.secure().nextDouble() * 10); // [0...10]
    _colorTween = ColorTween(
      begin: widget.color,
      end: Colors.transparent,
    );

    _ac = List<AnimationController>.generate(3, (index) {
      var a = AnimationController(
          vsync: this,
          duration: Duration(
              milliseconds: index == 1
                  ? (widget.durationMilliseconds * 0.8).round()
                  : widget.durationMilliseconds));
      a.addListener(() {
        if (index < 2 && a.value >= 0.4) {
          if (_ac[index + 1].isAnimating == false) {
            _ac[index + 1].forward(from: 0.0);
          }
        } else if (index == 2 && a.isCompleted) {
          _ac.forEach((e) {
            e.reset();
          });
          _acMain.reset();
          _buttonState = CrossFadeState.showFirst;
        }
        setState(() {});
      });
      return a;
    });

    var dur = 0;
    _ac.forEach((element) {
      dur += element.duration.inMilliseconds;
    });
    _acMain =
        AnimationController(vsync: this, duration: Duration(milliseconds: dur));

    _endColors = List<Color>.generate(kSubLineCount, (index) => randomColor());

    super.initState();
  }

  final scaleTween = Tween<double>(
    begin: 1,
    end: 10,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: TweenSequence(
                <TweenSequenceItem<double>>[
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 1.0, end: 4)
                        .chain(CurveTween(curve: Curves.easeIn)),
                    weight: 80,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(begin: 4, end: 7.0)
                        .chain(CurveTween(curve: Curves.easeOut)),
                    weight: 20,
                  ),
                ],
              ).animate(_acMain),
              alignment: Alignment(-1, 0),
              child: CustomPaint(
                painter: NetFlixLogoPainter(
                  endColors: _endColors,
                  animationValues: _ac.map((e) => e.value).toList(),
                  colorTween: _colorTween,
                  strokeWidth: widget.strokeWidth,
                  stops: _stops,
                  tweenSpeeds: _tweenSpeeds,
                ),
                size: Size(widget.width, widget.height),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: AnimatedCrossFade(
              duration: Duration(milliseconds: 400),
              crossFadeState: _buttonState,
              alignment: Alignment.bottomCenter,
              firstChild: ElevatedButton(
                onPressed: () {
                  _buttonState = _buttonState == CrossFadeState.showFirst
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst;
                  _ac.forEach((e) {
                    e.reset();
                  });
                  // _acMain.reset();
                  _acMain.forward(from: 0);
                  _ac.first.forward(from: 0);
                },
                child: Text('Play'),
              ),
              secondChild: Container(),
            ),
          ),
        ),
      ],
    );
  }
}

class NetFlixLogoPainter extends CustomPainter {
  final List<double> animationValues;
  final double strokeWidth;
  final List<double> stops;
  final List<double> tweenSpeeds;
  final ColorTween colorTween;
  final kTweens = <CurveTween>[
    CurveTween(curve: Curves.easeIn),
    CurveTween(curve: Curves.easeInCubic),
    CurveTween(curve: Curves.easeInCirc),
  ];
  final tween1 = CurveTween(curve: Curves.linear);
  final int parts = 3;
  final double shear = 0.1;
  final List<Color> endColors;
  Color _colorDarker;

  NetFlixLogoPainter({
    this.endColors,
    this.animationValues,
    this.strokeWidth,
    this.colorTween,
    this.stops,
    this.tweenSpeeds,
  }) {
    _colorDarker = Color.fromRGBO(colorTween.begin.red - 20,
        colorTween.begin.green - 20, colorTween.begin.blue - 20, 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintLine1(canvas, size);
    paintLine3(canvas, size);
    paintLine2(canvas, size);
  }

  void paintLine1(Canvas canvas, Size size) {
    var a = kTweens[2].transform(animationValues[2]);
    var b = tween1.transform(animationValues[2]);

    int j = 0;
    var aw = 0.9 * size.width / parts;
    var start = 0.0;
    int k = 0;
    int sc = 0;
    sc = aw ~/ strokeWidth;
    var delta = strokeWidth * 5;
    var ww = sc * delta;
    for (var i = start; i <= aw; i += strokeWidth) {
      var p0, p1;
      p0 = Offset(
          i +
              a * k * delta -
              (a * delta * tweenSpeeds[j]) / 2 -
              a * (ww - aw) / 2,
          0);
      p1 = Offset(
          i +
              a * k * delta -
              (a * delta * tweenSpeeds[j]) / 2 -
              a * (ww - aw) / 2,
          size.height - i * shear);

      var paint = Paint();
      paint.strokeWidth = strokeWidth;
      var v = b * (tweenSpeeds[j] * math.Random.secure().nextDouble());
      paint.shader = ui.Gradient.linear(
        p1,
        p0,
        [
          colorTween
              .transform(math.max(0, math.min(1, a + a * tweenSpeeds[j])))
              .withOpacity(math.max(0.4, 1 - (a + a * tweenSpeeds[j]) - 0.4)),
          endColors[j],
        ],
        <double>[
          math.max(0, 1 - v),
          1,
        ],
      );
      canvas.drawLine(p0, p1, paint);
      j++;
      k++;
    }
  }

  void paintLine2(Canvas canvas, Size size) {
    var a = kTweens[1].transform(animationValues[1]);
    var b = tween1.transform(animationValues[1]);

    int j = kSubLineCount * 2 ~/ 3;
    var aw = size.width / parts;
    var start = 0.0;
    int k = 0;
    int count = (aw - start) ~/ strokeWidth;
    for (var i = start; i <= aw; i += strokeWidth) {
      var p0 = Offset(i, 0);
      var p1 = Offset(size.width - aw + i,
          size.height - (count - k++) * strokeWidth * shear);

      var path = Path();
      path.moveTo(p0.dx, p0.dy);
      path.lineTo(p1.dx, p1.dy);
      canvas.drawShadow(
          path, Colors.black54.withOpacity(1 - animationValues[1]), 10, true);

      var paint = Paint();
      paint.strokeWidth = strokeWidth;
      var v = b * tweenSpeeds[j];
      paint.shader = ui.Gradient.linear(
        p0,
        p1,
        [
          colorTween
              .transform(math.max(0, math.min(1, a + a * tweenSpeeds[j])))
              .withOpacity(math.max(0, 1 - (a + a * tweenSpeeds[j]))),
          colorTween.end,
        ],
        <double>[
          math.max(0, 1 - v),
          1,
        ],
      );
      canvas.drawLine(p0, p1, paint);
      j++;
    }
  }

  void paintLine3(Canvas canvas, Size size) {
    var a = kTweens[0].transform(animationValues[0]);
    var b = tween1.transform(animationValues[0]);

    int j = kSubLineCount ~/ 3;
    var aw = 0.9 * size.width / parts;
    var start = size.width - aw;
    int k = 0;
    int count = (size.width - start) ~/ strokeWidth;
    for (var i = start; i <= size.width; i += strokeWidth) {
      var p0 = Offset(i, 0);
      var p1 = Offset(i, size.height - (count - k++) * strokeWidth * shear);
      var paint = Paint();
      paint.strokeWidth = strokeWidth;
      var v = b * tweenSpeeds[j];
      paint.shader = ui.Gradient.linear(
        p1,
        p0,
        [
          colorTween
              .transform(math.max(0, math.min(1, a + a * tweenSpeeds[j])))
              .withOpacity(math.max(0.4, 1 - (a + a * tweenSpeeds[j]) - 0.4)),
          colorTween.end,
        ],
        <double>[
          math.max(0, 1 - v),
          1,
        ],
      );
      canvas.drawLine(p0, p1, paint);
      j++;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

num abs(num a) => a < 0 ? -a : a;

Color randomColor() {
  var g = math.Random.secure().nextInt(255);
  var b = math.Random.secure().nextInt(255);
  var r = math.Random.secure().nextInt(255);
  return Color.fromARGB(255, r, g, b);
}
