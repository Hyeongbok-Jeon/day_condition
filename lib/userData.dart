class UserData {
  DateTime date;
  String bedTime;
  String wakeupTime;
  int energy;
  String memo;
  double timeDiff;

  UserData(this.date, this.bedTime, this.wakeupTime, this.energy, this.memo, this.timeDiff);

  UserData.fromJson(dynamic json)
      : date = DateTime.parse(json['date']),
        bedTime = json['bedTime'],
        wakeupTime = json['wakeupTime'],
        energy = json['energy'],
        memo = json['memo'],
        timeDiff = json['timeDiff'].toDouble() / 60;

  @override
  toString() {
    return '$date, $bedTime, $wakeupTime, $energy, $memo, $timeDiff';
  }
}