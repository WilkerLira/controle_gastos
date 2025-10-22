import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:controle_gastos/screens/home_page.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        children: [
          Center(child: Lottie.asset("assets/animation/flying_pengiun.json")),
        ],
      ),
      nextScreen: const HomePage(),
      splashIconSize: 400,
      duration: 3000,
    );
  }
}
