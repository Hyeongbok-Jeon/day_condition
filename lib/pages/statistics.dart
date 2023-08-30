import 'package:day_condition/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../globalVariables.dart';
import '../models/userData.dart';

class Statistics extends StatefulWidget {
  late bool isReTap;

  Statistics({Key? key, required this.isReTap}) : super(key: key);

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final ref = FirebaseDatabase.instance.ref('$G_uid');
  Map<String, dynamic> snapshot = {};
  late List<UserData> chartData;

  @override
  void initState() {
    super.initState();

    ref.child('data').onValue.listen((DatabaseEvent event) {
      setState(() {
        snapshot.clear();
        for (DataSnapshot child in event.snapshot.children) {
          snapshot['${child.key}'] = child.value;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    chartData = List<UserData>.generate(
        30,
        (int index) => UserData(
            DateTime(
                getKoreanTime().subtract(Duration(days: index)).year,
                getKoreanTime().subtract(Duration(days: index)).month,
                getKoreanTime().subtract(Duration(days: index)).day),
            '',
            '',
            0,
            '',
            0));
    DateTime sevenDaysAgo = getKoreanTime().subtract(const Duration(days: 7));

    if (snapshot.isNotEmpty) {
      for (UserData element in chartData) {
        snapshot.forEach((key, value) {
          UserData userData = UserData.fromJson(value);
          if (DateFormat('yyyyMMdd').format(element.date) == DateFormat('yyyyMMdd').format(userData.date)) {
            element.timeDiff = userData.timeDiff;
          }
        });
      }

      chartData.sort((a, b) => a.date.compareTo(b.date));
    }

    return Container(
      padding: const EdgeInsets.all(30),
      child: Container(
          decoration: borderForDebug,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Container(
                  alignment: AlignmentDirectional.topStart,
                  decoration: borderForDebug,
                  child: Text(
                    "수면 시간",
                    style: Theme.of(context).textTheme.titleLarge,
                  )),
              const SizedBox(
                height: 10,
              ),
              snapshot.isEmpty
                  ? Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
                      height: 250,
                      child: const Center(
                        child: Text('No Data'),
                      ),
                    )
                  : SizedBox(
                      height: 250,
                      child: SfCartesianChart(
                        series: <ChartSeries>[
                          // Renders line chart
                          ColumnSeries<UserData, DateTime>(
                            dataSource: chartData,
                            xValueMapper: (UserData data, _) => data.date,
                            yValueMapper: (UserData data, _) => data.timeDiff,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                double timeDiff = data.timeDiff;
                                String HH = (timeDiff ~/ 60).toString();
                                int MM = (timeDiff % 60).truncate();
                                String label = '$HH시간';
                                if (MM > 0) {
                                  label += ' ${MM.toString()}분';
                                }
                                return Text(timeDiff != 0 ? label : '0');
                              },
                            ),
                            width: 0.5,
                          )
                        ],
                        primaryXAxis: DateTimeCategoryAxis(
                          visibleMinimum: DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
                          dateFormat: DateFormat.d(),
                          maximumLabels: 30,
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: NumericAxis(
                          interval: 1,
                          majorGridLines: const MajorGridLines(width: 0),
                          isVisible: false,
                          // visibleMaximum: 12
                        ),
                        zoomPanBehavior: ZoomPanBehavior(
                          enablePanning: true,
                        ),
                        enableAxisAnimation: false,
                      ),
                    )
            ],
          )),
    );
  }
}
