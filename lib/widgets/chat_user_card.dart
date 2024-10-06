import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tocha/api/api.dart';
import 'package:tocha/helper/my_date_util.dart';
import 'package:tocha/models/chat_user.dart';
import 'package:tocha/models/message.dart';
import '../screens/auth/login_screen.dart';
import '../screens/chat_screen.dart';


class chatUserCard extends StatefulWidget {
  final ChatUser user;
  const chatUserCard({super.key, required this.user});

  @override
  State<chatUserCard> createState() => _chatUserCardState();
}

class _chatUserCardState extends State<chatUserCard> {

  Message?  _message;
  @override
  Widget build(BuildContext context) {
    var mq = MediaQuery.of(context).size;

    return  Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .03, vertical: 3),
        color: Colors.white70,
        elevation: 0.5,
        child: InkWell(
          onTap: () {
            // Naviguer vers le chat screen
            Navigator.push(context, MaterialPageRoute(builder:(_) => chatScreen(user: widget.user)));
          },
          child: StreamBuilder(
              stream: APIs.getLastMessage(widget.user),
              builder: (context, snapshot){
                final data  = snapshot.data?.docs;

               final    list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
                if(list.isNotEmpty) _message = list[0];

                return ListTile(

                  //leading: const CircleAvatar(child: Icon( CupertinoIcons.person_alt)),
                    leading:ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .3),
                      child: CachedNetworkImage(
                        imageUrl: widget.user.image,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        width: mq.height * .050,
                        height: mq.height *.050,
                        //fit: BoxFit.cover,
                      ),
                    ),


                    title: Text(widget.user.name),
                    subtitle: Text(
                        _message != null ?
                        _message!.type == Type.image
                            ? 'Photo'
                        : _message!.msg : widget.user.about, maxLines: 1),
                    trailing: _message == null ? null : _message!.read.isEmpty && _message!.fromId !=APIs.user.uid?
                    Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10)
                      ),
                    ): Text(
                      MyDateUtil.getLastMessageTime(context: context, time:_message!.sent ),
                      style: const TextStyle(color: Colors.black45),
                    )

                );
          },)
        ),
    );
  }
}
