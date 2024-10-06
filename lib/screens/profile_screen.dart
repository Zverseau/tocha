import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tocha/helper/dialogs.dart';
import 'package:tocha/models/chat_user.dart';
import 'package:tocha/widgets/chat_user_card.dart';
import '../api/api.dart';
import 'auth/login_screen.dart';

class profileScreen extends StatefulWidget {
  final ChatUser user;

  const profileScreen({super.key, required this.user});

  @override
  State<profileScreen> createState() => _profileScreenState();
}

class _profileScreenState extends State<profileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;
  late Size mq;

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size; // Initialize mq to get the size of the screen
    return Scaffold(
      // AppBar section
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
      ),

      // Floating button to log out
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton.extended(
          onPressed: () async {
            Dialogs.showProgressBar(context);
            await APIs.auth.signOut().then((value) async {
              await GoogleSignIn().signOut().then((value) async {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const loginScreen()));
              });
            });
          },
          icon: const Icon(Icons.logout),
          label: const Text('Déconnexion'),
          foregroundColor: Colors.white,
          backgroundColor: Colors.redAccent,
        ),
      ),

      // Body section with form
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(width: mq.width, height: mq.height * .03),

                // Profile Picture Section
                Stack(
                  children: [
                    _image != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .1),
                      child: Image.file(
                        File(_image!),
                        width: mq.height * .2,
                        height: mq.height * .2,
                        fit: BoxFit.cover,
                      ),
                    )
                        : CircleAvatar(
                      radius: mq.height * .1,
                      backgroundImage: CachedNetworkImageProvider(widget.user.image),
                    ),

                    // Edit button for profile picture
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MaterialButton(
                        elevation: 1,
                        color: Colors.blue,
                        shape: const CircleBorder(),
                        onPressed: () {
                          _showBottomSheet();
                        },
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mq.height * .03),

                // Email Display
                Text(widget.user.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16)),
                SizedBox(height: mq.height * .05),

                // Name Input Field
                TextFormField(
                  onSaved: (val) => APIs.me.name = val ?? '',
                  validator: (val) => val != null && val.isNotEmpty ? null : 'Champ requis',
                  initialValue: widget.user.name,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person, color: Colors.blue),
                    hintText: 'ex: John Doe',
                    label: const Text('Nom'),
                  ),
                ),
                SizedBox(height: mq.height * .02),

                // Info Input Field
                TextFormField(
                  onSaved: (val) => APIs.me.about = val ?? '',
                  validator: (val) => val != null && val.isNotEmpty ? null : 'Champ requis',
                  initialValue: widget.user.about,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.info_outline, color: Colors.blue),
                    hintText: 'ex: J\'utilise Tocha',
                    label: const Text('Info'),
                  ),
                ),
                SizedBox(height: mq.height * .05),

                // Update Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackbar(context, 'Mise à jour terminée');
                        });
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Mettre à jour',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      maximumSize: Size(mq.width * .5, mq.height * .06),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Function to show bottom sheet for selecting profile picture
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              const Text('Choisissez une photo de profil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),

              SizedBox(height: mq.height * .02),

              // Buttons to choose from gallery or camera
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pick from gallery button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/image_gallery.png')),

                  // Take picture from camera button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 80);
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/take_photo.png')),
                ],
              ),
            ],
          );
        });
  }
}
