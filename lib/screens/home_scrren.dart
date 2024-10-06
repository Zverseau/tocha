import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tocha/helper/dialogs.dart';
import 'package:tocha/models/chat_user.dart';
import 'package:tocha/screens/profile_screen.dart';
import 'package:tocha/widgets/chat_user_card.dart';
import '../api/api.dart';
import 'auth/login_screen.dart';

class homeScreen extends StatefulWidget {
  const homeScreen({super.key});

  @override
  State<homeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
  List<ChatUser> list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    //resume -- active or online
    //pause  -- inactive or offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return  GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      
      child: WillPopScope(
        onWillPop: () {
          if(_isSearching){
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          }
          else{
            return Future.value(true);
          }

        },

        child: Scaffold(
          // the AppBar
            appBar: AppBar(
              title: _isSearching ?  TextField(
        
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'Nom, mail, ...',
                    hintStyle: TextStyle(color: Colors.white)),
                autofocus: true,
                style: const TextStyle(fontSize: 16, letterSpacing:  0.5),
                onChanged: (val){
                  //search logic
                  _searchList.clear();
        
                  for(var i in list ){
                    if(i.name.toLowerCase().contains(val.toLowerCase()) || i.email.toLowerCase().contains(val.toLowerCase())){
                      _searchList.add(i);
                    }
                    setState(() {
        
                      _searchList;
                    });
                  }
        
        
                },
              ) : const Text('Tocha'),
              centerTitle: true,
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
              leading: Icon(CupertinoIcons.home),
              actions: [
                IconButton(onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                }, icon: Icon( _isSearching ? CupertinoIcons.clear_circled_solid : Icons.search)),
                IconButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => profileScreen(user: APIs.me)));
                }, icon: const Icon(Icons.more_vert))],
              elevation: 6.0,
            ),
        
        
            // Floating button to add new user
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton( onPressed: () {
                _addChatUserDialog();
              },
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_comment_rounded),
              ),
            ),
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),

            //get id of only known users
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
              //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

              //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),

                    //get only those user, who's ids are provided
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                      //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return const Center(
                        //     child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          list = data
                              ?.map((e) => ChatUser.fromJson(e.data()))
                              .toList() ??
                              [];

                          if (list.isNotEmpty) {
                            return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchList.length
                                    : list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return chatUserCard(
                                      user: _isSearching
                                          ? _searchList[index]
                                          : list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(fontSize: 20)),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );

  }
  //dialog for updating message content
  void _addChatUserDialog() {
    String email = '';

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
                Icons.person_add_alt_1,
                color: Colors.blue,
                size: 28,
              ),
              Text('  Ajouter utilisateur')
            ],
          ),

          //content
          content: TextFormField(
            maxLines: null,
            onChanged: (value) => email = value,
            decoration: const InputDecoration(
                hintText: 'Email ',
                prefixIcon: Icon(Icons.email_outlined, color: Colors.blue,),
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
                  'Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                )),

            //add button
            MaterialButton(
                onPressed: () async {
                  //hide alert dialog
                  Navigator.pop(context);
                  if(email.isNotEmpty) {
                    await  APIs.addChatUser(email).then((value){
                      if(!value){
                        Dialogs.showSnackbar(context, ' le Email L\'utilisateur n\'exite pas ');
                      }
                    });
                  }
                },
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ))
          ],
        ));
  }
}
