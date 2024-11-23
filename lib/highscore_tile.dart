import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HighscoreTile extends StatelessWidget {
  final String documentId;
  const HighscoreTile({
    super.key,
    required this.documentId
  });
  @override
  Widget build(BuildContext context) {

    CollectionReference highscores = 
    FirebaseFirestore.instance.collection('highscores');

    return FutureBuilder<DocumentSnapshot>(
      future: highscores.doc(documentId).get(), 
      builder: (context, snapshot){
        if(snapshot.connectionState == ConnectionState.done){
          Map<String, dynamic> data = 
          snapshot.data!.data() as Map<String, dynamic>;
          return Row(
            children: [
              Text(data ['score']),
              Text(data ['name']),
            ],
          );
        }
        else{
          return const Text('loading....');
        }
      }
      );
  }
}