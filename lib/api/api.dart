import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:tocha/models/chat_user.dart';
import 'package:tocha/models/message.dart';
import 'notification_access_token.dart';
class APIs{

  // Pour l'authentification
  static FirebaseAuth auth = FirebaseAuth.instance;
  // Pour cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  // Pour firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
  // pour acceder au FCM
   static FirebaseMessaging fMessaging = FirebaseMessaging.instance;
  // pour recevoir le FCM token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token: $t');
      }
    });
  }


  // for sending push notification (Updated Codes)
  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "message": {
          "token": chatUser.pushToken,
          "notification": {
            "title": me.name, //Notre nom sera envoyé
            "body": msg,
          },
        }
      };

      // Firebase Project > Project Settings > General Tab > Project ID
      const projectID = 'tocha-49ef1';

      // get firebase admin token
       final bearerToken = await NotificationAccessToken.getToken;

      log('bearerToken: $bearerToken');

      // handle null token
      if (bearerToken == null) return;

      var res = await post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectID/messages:send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
        },
        body: jsonEncode(body),
      );

      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }

  }

  // return utilisateur actuel
  static User get user =>auth.currentUser!;

  // check si un utilisateur existe deja
  static Future<bool> userExists() async{
    return  (await firestore.collection('users').doc(auth.currentUser!.uid).get()).exists;
  }



  // for adding an chat user for our conversation
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists

      log('user exists: ${data.docs.first.data()}');

      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      //user doesn't exists

      return false;
    }
  }
  //  variable pour enregister info unique
  static late ChatUser me;
  //Get les info du current user
  static Future<void> getSelfInfo() async{
    await firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((user) async{

      if(user.exists){
        me= ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        //for setting user status to active
        APIs.updateActiveStatus(true);
        log('My Data: ${user.data()}');
      } else{
        await creatUser().then((value) => getSelfInfo());
      }

    });
  }
  // creer un nouvel utilisateur

  static Future<bool> creatUser() async {
    try {
      final time = DateTime.now().millisecondsSinceEpoch.toString();
      final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName ?? 'No Name',
        image: user.photoURL ?? '',
        about: 'Hey bonjour je suis dev ',
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '',
        email: user.email ?? '',
      );

      await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
      return true; // Retourne vrai si la création réussit
    } catch (e) {
      print('Erreur lors de la création de l\'utilisateur: $e');
      return false; // Retourne faux en cas d'échec
    }
  }

  // for getting all users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\nUserIds: $userIds');

    return firestore
        .collection('users')
        .where('id',
        whereIn: userIds.isEmpty
            ? ['']
            : userIds) //because empty list throws an error
    // .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for getting id's of known users from firestore database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

  // modifier info utilisateur 
  static Future<void> updateUserInfo() async{
    await firestore.collection('users').doc(auth.currentUser!.uid).update({'name': me.name, 'about': me.about});
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //storage file ref with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }


  // for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update online or last active status of user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///**************les APIS DE CHATSCREEN***************



  //Recuperer le ID de la conversation
   static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
        ? '${user.uid}_$id'
        : '${id}_${user.uid}';
  // retourner tout les messages d'une convesation specifique
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }


  //Pour envoyer un Message

  static Future<void> sendMessage(ChatUser chatUser , String msg, Type type) async {
    // heure d'envoi du message
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    // message à envoyer

    final Message message = Message(msg: msg, read: '', told: chatUser.id, type: type, sent: time, fromId: user.uid);
    final ref = firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value)=> sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }


  static Future<void> updateMessageReadStatus(Message message) async{
    firestore.collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read':  DateTime.now()
        .millisecondsSinceEpoch.toString()});
  }
  // retourner un seul message d'une discussion specifique
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user){
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }


  // Envoyer image dans le chat
static Future<void> sendChatImage(ChatUser chatUser, File file) async {

  //getting image file extension
  final ext = file.path.split('.').last;
  //storage file ref with path
  final ref = storage.ref().child('images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
  //uploading image
  await ref
      .putFile(file, SettableMetadata(contentType: 'image/$ext'))
      .then((p0) {
    log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
  });
  //updating image in firestore database
  final imageUrl = await ref.getDownloadURL();
  await sendMessage(chatUser, imageUrl, Type.image);
}

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }
  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}


