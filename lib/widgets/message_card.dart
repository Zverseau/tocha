import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:tocha/api/api.dart';
import 'package:tocha/helper/my_date_util.dart';
import 'package:tocha/models/message.dart';

import '../helper/dialogs.dart';
import '../screens/auth/login_screen.dart';

class messageCard extends StatefulWidget {
  const messageCard({super.key, required this.message});
  final Message message;

  @override
  State<messageCard> createState() => _messageCardState();
}

class _messageCardState extends State<messageCard> {
  @override
  Widget build(BuildContext context) {

    bool  isMe = APIs.user.uid == widget.message.fromId ;
    return InkWell(
      onLongPress: (){
        _showBottomSheet(isMe);

      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: Column(
          crossAxisAlignment: APIs.user.uid == widget.message.fromId
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: APIs.user.uid == widget.message.fromId
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                isMe ?_greenMessage() : _blueMessage(),
              ],
            ),
            const SizedBox(height: 5),
            // Affichage de la date/heure sous chaque message
            Row(
              mainAxisAlignment: APIs.user.uid == widget.message.fromId
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                Text(
                  MyDateUtil.getFormattedTime(context: context, time: widget.message.sent), // Affiche l'heure du message
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(width: 4), // Espacement entre la date et l'icône
                Icon(
                  Icons.done_all, // Icône pour indiquer que le message a été vu
                  color: widget.message.read.isEmpty ? Colors.grey : Colors.blue, // Changer la couleur selon l'état de lecture
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blueMessage() {
    // mettre à jour le dernier message lu si l'expéditeur et le destinataire sont différents
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
      log('message lu mis à jour');
    }
    return Flexible(
      child: Container(
        padding: EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 50),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),

        child:
        widget.message.type == Type.text ?
        Text(
          widget.message.msg,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ) : ClipRRect(
          borderRadius: BorderRadius.circular(mq.height * .03),
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            placeholder: (context, url) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth : 2),
            ),
            errorWidget: (context, url, error) =>
            const Icon(Icons.image, size: 70,),
          ),
        ),
      ),
    );
  }

  Widget _greenMessage() {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(left: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(15),
          ),
          border: Border.all(color: Colors.green.shade200),
        ),
        child:
        widget.message.type == Type.text ?
        Text(
          widget.message.msg,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ) : ClipRRect(
          borderRadius: BorderRadius.circular(mq.height * .03),
          child: CachedNetworkImage(
            imageUrl: widget.message.msg,
            placeholder: (context, url) => const Padding(
              padding: const EdgeInsets.all(8.0),
              child: const CircularProgressIndicator(strokeWidth : 2),
            ),
            errorWidget: (context, url, error) =>
            const Icon(Icons.image, size: 70,),
          ),
        ),
      ),
    );
  }


  // Function to show bottom sheet for selecting profile picture
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ?
              // copy option
              _optionItem(
                  icon: const Icon(Icons.copy_all_rounded,
                      color: Colors.blue, size: 26),
                  name: 'Copier Texte',
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: widget.message.msg))
                        .then((value) {
                      // for hiding bottom sheet
                      Navigator.pop(context);

                      Dialogs.showSnackbar(context, 'Texte Copié!');
                    });
                  })
                  :
              // save option
              _optionItem(
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.blue, size: 26),
                  name: 'Enregistrer',
                  onTap: () async {
                    try {
                      log('Image Url: ${widget.message.msg}');
                      await GallerySaver.saveImage(widget.message.msg,
                          albumName: 'Tocha')
                          .then((success) {
                        // for hiding bottom sheet
                        Navigator.pop(context);
                        if (success != null && success) {
                          Dialogs.showSnackbar(
                              context, 'Image enregistré avec succès!');
                        }
                      });
                    } catch (e) {
                      log('ErrorWhileSavingImg: $e');
                    }
                  }),

              // separator or divider
              if (isMe)
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              // edit option
              if (widget.message.type == Type.text && isMe)
                _optionItem(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 26),
                    name: 'Modifier Message',
                    onTap: () {
                      // for hiding bottom sheet
                      Navigator.pop(context);

                      _showMessageUpdateDialog();
                    }),

              // delete option
              if (isMe)
                _optionItem(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.red, size: 26),
                    name: 'Supprimer Message',
                    onTap: () async {
                      await APIs.deleteMessage(widget.message).then((value) {
                        // for hiding bottom sheet
                        Navigator.pop(context);
                      });
                    }),

              // separator or divider
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              // sent time
              _optionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  name:
                  'Envoyé à: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              // read time
              _optionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                  name: widget.message.read.isEmpty
                      ? 'Vu à: Pas encore vu'
                      : 'Lu à: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  Widget _optionItem({
    required Icon icon,
    required String name,
    required Function() onTap,
  }) {
    return ListTile(
      leading: icon,
      title: Align(
        alignment: Alignment.centerLeft, // Alignement du texte à gauche
        child: Text(name),
      ),
      onTap: onTap,
    );
  }


  //dialog for updating message content
  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: const EdgeInsets.only(
              left: 24, right: 24, top: 20, bottom: 10),

          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),

          //title
          title: const Row(
            children: [
              Icon(
                Icons.message,
                color: Colors.blue,
                size: 28,
              ),
              Text(' Modifier ')
            ],
          ),

          //content
          content: TextFormField(
            initialValue: updatedMsg,
            maxLines: null,
            onChanged: (value) => updatedMsg = value,
            decoration: const InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)))),
          ),

          //actions
          actions: [
            //cancel button
            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                },
                child: const Text(
                  'Retour',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )),

            //update button
            MaterialButton(
                onPressed: () {
                  //hide alert dialog
                  Navigator.pop(context);
                  APIs.updateMessage(widget.message, updatedMsg);
                },
                child: const Text(
                  'Modifier',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ))
          ],
        ));
  }
}

class _optionItem extends StatelessWidget {
  final Icon icon ;
  final String name;
  final VoidCallback onTap;
  const _optionItem({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: () => onTap(),
      child: Padding(
        padding:  EdgeInsets.only(
            left:mq.width * 0.5,
            top: mq.height * .015,
            bottom: mq.height * .015 ),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text('    $name',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    letterSpacing: 0.5)))]),
      ),
    );
  }
}
