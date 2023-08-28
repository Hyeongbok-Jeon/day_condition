import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class UserSetting {
  StartingDayOfWeek startingDayOfWeek = StartingDayOfWeek.sunday;

  UserSetting(this.startingDayOfWeek);

  UserSetting.fromDataSnapshot(DataSnapshot snapshot) {
    for (var snapshot in snapshot.children) {
      if (snapshot.key == 'startingDayOfWeek') {
        if (snapshot.value == 'sunday') {
          startingDayOfWeek = StartingDayOfWeek.sunday;
        } else if (snapshot.value == 'monday') {
          startingDayOfWeek = StartingDayOfWeek.monday;
        }
      }
    }
  }
}