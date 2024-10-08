
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyDateUtil{
  static String getFormattedTime({  required BuildContext context, required String time }){
    final date =  DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }


  // for getting formatted time for sent & read
  static String getMessageTime(
      {required BuildContext context, required String time}) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final formattedTime = TimeOfDay.fromDateTime(sent).format(context);
    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }

    return now.year == sent.year
        ? '$formattedTime - ${sent.day} ${_getMonth(sent)}'
        : '$formattedTime - ${sent.day} ${_getMonth(sent)} ${sent.year}';
  }

  //get la date du dernier message dans le home screen

  static String getLastMessageTime({required BuildContext context, required String time }){
    final DateTime sent =  DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    if(now.day == sent.day && now.month == sent.month &&  now.year == sent.year){
      return TimeOfDay.fromDateTime(sent).format(context);
    }
    return '${sent.day} ${_getMonth(sent)}';
  }
  // retourner le mois devant une discussion
  static String _getMonth(DateTime date){

    switch (date.month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sept';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return 'NA';
  }

  //formatter  le last active time of user dans le chat chat screen
  static String getLastActiveTime(
      {required BuildContext context, required String lastActive}) {
    final int i = int.tryParse(lastActive) ?? -1;

    //if time is not available then return below statement
    if (i == -1) return 'Dernière vue non disponible';

    DateTime time = DateTime.fromMillisecondsSinceEpoch(i);
    DateTime now = DateTime.now();

    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == time.year) {
      return 'En ligne aujourd\'hui  à $formattedTime';
    }

    if ((now.difference(time).inHours / 24).round() == 1) {
      return ' En ligne hier à $formattedTime';
    }

    String month = _getMonth(time);

    return 'Vu le ${time.day} $month à $formattedTime';
  }



}