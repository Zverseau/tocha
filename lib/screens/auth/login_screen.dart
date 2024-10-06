import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tocha/helper/dialogs.dart';
import 'package:tocha/screens/home_scrren.dart';

import '../../api/api.dart';

late Size mq;

class loginScreen extends StatefulWidget {
  const loginScreen({super.key});

  @override
  State<loginScreen> createState() => _loginScreenState();
}

class _loginScreenState extends State<loginScreen> {
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimated = true;
      });
    });
  }

  // Gestion du clic du bouton Google
  _handleGoogleBtnClick() {
    Dialogs.showProgressBar(context);
    //Navigator.pop(context);
    _signInWithGoogle().then((user) async{
      if(user != null){
        log('\nUser: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');
        if(await (APIs.userExists())){
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const homeScreen())
          );
        }else{
          await APIs.creatUser().then((value){
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const homeScreen())
              );
          });

        }

      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
  try{
    await InternetAddress.lookup('google.com');
    // Déclenche le flux d'authentification
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtenir les détails d'authentification de la demande
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Créer une nouvelle authentification avec les informations obtenues
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Une fois connecté, retourne les informations d'identification utilisateur
    return await APIs.auth.signInWithCredential(credential);
  } catch(e){
    log('\n_signInWithGoogle: $e');
    Dialogs.showSnackbar(context, 'Une erreur s\'est produite, verifier votre connexion !');
    return null;
  }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenue sur Tocha'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        elevation: 6.0,
      ),
      body: Stack(
        children: [
          // Animation pour déplacer l'image de la droite vers le centre
          AnimatedPositioned(
            top: mq.height * 0.15, // Positionnement vertical de l'image
            left: _isAnimated
                ? (mq.width - mq.width * 0.40) / 2 // Centre horizontalement
                : mq.width, // Commence à droite, hors de l'écran
            duration: const Duration(seconds: 1), // Durée de l'animation
            curve: Curves.easeInOut, // Courbe d'animation plus fluide
            child: Image.asset(
              'images/chating.png',
              width: mq.width * 0.40, // Largeur de l'image
            ),
          ),

          // Bouton Se connecter avec Google
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: mq.height * 0.20), // Padding pour espacer le bouton du bas
              child: ElevatedButton.icon(
                onPressed: () {
                  _handleGoogleBtnClick();
                },
                icon: Image.asset('images/google.png', width: 24, height: 24), // Taille ajustée de l'icône
                label: const Text(
                  'Se connecter avec Google',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
