import 'package:firebase_database/firebase_database.dart';

class Holiday {
  String locdate;
  String dateName;

  Holiday(this.locdate, this.dateName);

  static List<Holiday> holidayListfromDataSnapshot(DataSnapshot dataSnapshot) {
    /// response.body
    /// {"response":{"header":{"resultCode":"00","resultMsg":"NORMAL SERVICE."},"body":{"items":{"item":{"dateKind":"01","dateName":"ê´ë³µì ","isHoliday":"Y","locdate":20230815,"seq":1}},"numOfRows":10,"pageNo":1,"totalCount":1}}}
    Map<dynamic, dynamic> map = dataSnapshot.value as Map<dynamic, dynamic>;
    final body = map['response']['body'];
    final totalCount = body['totalCount'];
    final items = body['items'];

    List<Holiday> holidays = [];

    if (items != '') {
      var item = items['item'];
      if (totalCount == 1) {
        item = items['item'];
        holidays.add(Holiday(item['locdate'].toString(), item['dateName']));
      } else if (totalCount > 1) {
        final item = items['item'];
        for (var row in item) {
          holidays.add(Holiday(row['locdate'].toString(), row['dateName']));
        }
      }
    }

    return holidays;
  }
}