import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tocha/api/api.dart';
import 'package:tocha/screens/auth/login_screen.dart';
import 'package:tocha/screens/home_scrren.dart';
import 'package:flutter/cupertino.dart';

late Size mq;

class splashScreen extends StatefulWidget {
  const splashScreen({super.key});

  @override
  State<splashScreen> createState() => _splashScreenState();
}

class _splashScreenState extends State<splashScreen> with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Start the opacity change after a delay
    _timer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Always show the logo for at least 2 seconds, then navigate
    Timer(const Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
         const SystemUiOverlayStyle(systemNavigationBarColor: Colors.white, statusBarColor: Colors.white)
      );
      if (APIs.auth.currentUser != null) {
        log('\nUser: ${APIs.auth.currentUser}');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const homeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const loginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.height * 0.15),
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(seconds: 2),
                  child: Image.asset(
                    'images/icon.png',
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: mq.height * 0.10),
              child: Text(
                'BIENVENUE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();  // Cancel the timer when the widget is disposed
    super.dispose();
  }
}
