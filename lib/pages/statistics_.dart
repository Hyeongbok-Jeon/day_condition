import 'package:day_condition/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../globalVariables.dart';
import '../userData.dart';

class Statistics_ extends StatefulWidget {
  late bool isReTap;

  Statistics_({Key? key, required this.isReTap}) : super(key: key);

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics_> {
  late ZoomPanBehavior _zoomPanBehavior;
  List<UserData> chartData = List<UserData>.generate(
      30, (int index) => UserData(DateTime.now().subtract(Duration(days: index)), '', '', 0, '', 0));
  final ref = FirebaseDatabase.instance.ref('$G_uid');

  @override
  void initState() {
    super.initState();

    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
    );
  }

  Future<Map<dynamic, dynamic>?> future() async {
    DataSnapshot snapshot = await ref.child('data').get();
    if (snapshot.exists) {
      return snapshot.value as Map<dynamic, dynamic>;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("차트")),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: borderForDebug,
          child: FutureBuilder(
              future: future(),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.hasData) {
                  for (UserData element in chartData) {
                    for (final child in asyncSnapshot.data!.entries) {
                      UserData userData = UserData.fromJson(child.value);
                      if (DateFormat('yyyyMMdd').format(element.date) == DateFormat('yyyyMMdd').format(userData.date)) {
                        element.timeDiff = userData.timeDiff;
                      }
                    }
                  }
                  chartData.sort((a, b) => a.date.compareTo(b.date));
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                        alignment: AlignmentDirectional.topStart,
                        decoration: borderForDebug,
                        child: const Text(
                          "수면 시간 통계",
                          style: TextStyle(fontSize: 25),
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                    SfCartesianChart(
                      series: <ChartSeries>[
                        // Renders line chart
                        ColumnSeries<UserData, DateTime>(
                          dataSource: chartData,
                          xValueMapper: (UserData data, _) => data.date,
                          yValueMapper: (UserData data, _) => data.timeDiff,
                          width: 0.5,
                        )
                      ],
                      primaryXAxis: DateTimeCategoryAxis(
                        visibleMinimum: getKoreanTime().subtract(const Duration(days: 7)),
                        visibleMaximum: getKoreanTime(),
                        dateFormat: DateFormat.d(),
                        maximumLabels: 7,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        interval: 1,
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      zoomPanBehavior: _zoomPanBehavior,
                      enableAxisAnimation: true,
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
