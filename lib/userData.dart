import 'package:firebase_database/firebase_database.dart';

class UserData {
  String? wakeupTime;
  String? bedTime;
  int? enery;

  UserData({this.wakeupTime, this.bedTime, this.enery});

  // Firebase에서 snapshot을 파싱하여 UserData 객체로 변환
  factory UserData.fromSnapshot(DataSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.value as Map<String, dynamic>;
    return UserData(
      wakeupTime: data['wakeupTime'],
      bedTime: data['age'],
      enery: data['email'],
    );
  }
}