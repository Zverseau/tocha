import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tocha/helper/my_date_util.dart';
import 'package:tocha/models/chat_user.dart';
import 'package:tocha/models/message.dart';
import 'package:tocha/widgets/message_card.dart';

import '../api/api.dart';
import '../widgets/chat_user_card.dart';
import 'auth/login_screen.dart';

class chatScreen extends StatefulWidget {
  final ChatUser user;
  const chatScreen({super.key, required this.user});

  @override
  State<chatScreen> createState() => _chatScreenState();
}

class _chatScreenState extends State<chatScreen> {
  // stocker les messages
  List<Message> list = [];
  //pour gérer les modifications de texte des messages
  final _textController = TextEditingController();
  // pour implementer les emoji
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: _appBar(),
          ),
          foregroundColor: Colors.white,
          backgroundColor: Colors.blueAccent,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getAllMessages(widget.user),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                  // data is loading
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return const SizedBox();
                  // if data is loaded then show it
                    case ConnectionState.active:
                    case ConnectionState.done:
                      final data = snapshot.data?.docs;
                      list = data
                          ?.map((e) => Message.fromJson(e.data()))
                          .toList() ??
                          [];
        
                      // Vérification de la longueur des données avant d'y accéder
                      if (data == null || data.isEmpty) {
                        return const Center(child: Text( 'Dire Bonjour👋', style: TextStyle(fontSize: 20)));
                      }
        
                      // Log de la première entrée si elle existe
                      log('Data: ${jsonEncode(data[0].data())}');
        
                      // Liste des messages fictifs (à remplacer par les vrais messages après la récupération)
                      // list.clear();
                      // list.add(Message(
                      //     msg: 'bonjour', read: '', told: 'xyz', type: Type.text, sent: '12:01 PM', fromId: APIs.user.uid));
                      // list.add(Message(
                      //     msg: 'hello', read: '', told: APIs.user.uid, type: Type.text, sent: '12:03 PM', fromId: 'xyz'));
        
                      if (list.isNotEmpty) {
                        return ListView.builder(
                          reverse : true,
                          physics: BouncingScrollPhysics(),
                          padding: EdgeInsets.only(top: mq.height * .01),
                          itemCount: list.length, // ajout de l'itemCount
                          itemBuilder: (context, index) {
                            return messageCard(message: list[index]);
                          },
                        );
                      } else {
                        return const Center(
                            child: Text('Commencez à écrire !', style: TextStyle(fontSize: 20)));
                      }
                  }
                },
              ),
            ),

            //progress indicator for showing uploading
            if (_isUploading)
              const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                      padding:
                      EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      child: CircularProgressIndicator(strokeWidth: 2))),
            _chatInput(),

            if (_showEmoji)
              SizedBox(
                height: mq.height * .35,
                child: EmojiPicker(
                  textEditingController: _textController,
                  config:  const Config(
                    bgColor: Color(0xFFF2F2F2), // Utilisation de backgroundColor
                  ),
                ),
              )





          ],
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () {},
        child: StreamBuilder(stream: APIs.getUserInfo(widget.user), builder: (context, snapshot){

          final data  = snapshot.data?.docs;
          final    list = data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: Colors.white),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .03),
                child: CachedNetworkImage(
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  errorWidget: (context, url, error) =>
                  const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  width: mq.height * .05,
                  height: mq.height * .05,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // nom d'utilisateur
                  Text( list.isNotEmpty ? list[0].name : widget.user.name,
                      style: const TextStyle(
                          fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  // dernière connexion
                   Text(list.isNotEmpty ?
                   list[0].isOnline ? 'En ligne'
                   :MyDateUtil.getLastActiveTime(context: context, lastActive: list[0].lastActive)
                   : MyDateUtil.getLastActiveTime(context: context, lastActive: widget.user.lastActive),
                      style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w200)),
                ],
              )
            ],
          );


        }),
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  // bouton emoji
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(Icons.emoji_emotions,
                          color: Colors.blueAccent, size: 25)),
                  Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                        },
                        decoration: const InputDecoration(
                            hintText: 'Ecrire message...',
                            hintStyle: TextStyle(color: Colors.black54),
                            border: InputBorder.none),
                      )),
                  // bouton galerie
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage(
                           imageQuality: 80);
                      for ( var i in images){
                        log('Image Path: ${i.path}');
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(widget.user,File(i.path));
                        setState(() => _isUploading = false);

                      }
                    },
                    icon: const Icon(Icons.image, color: Colors.blueAccent, size: 26),
                  ),


                  // bouton photo
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 80);
                      if (image != null) {
                        log('Image Path: ${image.path}');
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(widget.user,File(image.path));
                        setState(() => _isUploading = false);
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.blueAccent, size: 26),
                  ),
                ],
              ),
            ),
          ),
          // Boutton d'envoi de message
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (list.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  APIs.sendFirstMessage(
                      widget.user, _textController.text, Type.text);
                } else {
                  //simply send message
                  APIs.sendMessage(
                      widget.user, _textController.text, Type.text);
                }
                _textController.text = '';
              }
            },
            shape: const CircleBorder(),
            padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 5),
            minWidth: 0,
            color: Colors.green,
            child: Icon(Icons.send, color: Colors.white, size: 28),
          )
        ],
      ),
    );
  }
}
