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
            element.energy = userData.energy;
          }
        });
      }

      chartData.sort((a, b) => a.date.compareTo(b.date));
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                    alignment: AlignmentDirectional.topStart,
                    decoration: borderForDebug,
                    child: Text(
                      "수면 시간",
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                // const SizedBox(
                //   height: 10,
                // ),
                snapshot.isEmpty
                    ? Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.onSurface)),
                          child: const Center(
                            child: Text('No Data'),
                          ),
                        ),
                      )
                    : Expanded(
                        child: SfCartesianChart(
                          series: <ChartSeries>[
                            // Renders line chart
                            ColumnSeries<UserData, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (UserData data, _) => data.date,
                              yValueMapper: (UserData data, _) => data.timeDiff,
                              dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                builder:
                                    (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                  double timeDiff = data.timeDiff;
                                  String label = (timeDiff ~/ 60).toString();
                                  int mm = (timeDiff % 60).truncate();
                                  // if (mm > 0) {
                                  //   label += ' ${mm.toString()}M';
                                  // }
                                  return Text(timeDiff != 0 ? label : '');
                                },
                              ),
                              width: 0.5,
                              enableTooltip: true,
                            )
                          ],
                          primaryXAxis: DateTimeCategoryAxis(
                              visibleMinimum: DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
                              // visibleMaximum: DateTime(2023, 9, 4),
                              dateFormat: DateFormat.d(),
                              maximumLabels: 30,
                              majorGridLines: const MajorGridLines(width: 0),
                              axisLabelFormatter: (AxisLabelRenderDetails axisLabelRenderArgs) {
                                return ChartAxisLabel(
                                    '${axisLabelRenderArgs.text}일', const TextStyle(color: Colors.white));
                              }),
                          primaryYAxis: NumericAxis(
                            interval: 1,
                            majorGridLines: const MajorGridLines(width: 0),
                            isVisible: false,
                            // maximum: 1000
                          ),
                          zoomPanBehavior: ZoomPanBehavior(
                            enablePanning: true,
                          ),
                          enableAxisAnimation: false,
                          // borderColor: Theme.of(context).colorScheme.onSurface,
                          tooltipBehavior: TooltipBehavior(
                            enable: false,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              double timeDiff = data.timeDiff;
                              String label = '${(timeDiff ~/ 60).toString()}시간';
                              int mm = (timeDiff % 60).truncate();
                              if (mm > 0) {
                                label += ' ${mm.toString()}분';
                              }
                              return Text(
                                timeDiff != 0 ? label : '0',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              );
                            },
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                const SizedBox(
                  height: 5,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const SizedBox(
                  height: 5,
                ),
                Container(
                    alignment: AlignmentDirectional.topStart,
                    decoration: borderForDebug,
                    child: Text(
                      "컨디션",
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                snapshot.isEmpty
                    ? Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.onSurface)),
                          child: const Center(
                            child: Text('No Data'),
                          ),
                        ),
                      )
                    : Expanded(
                        child: SfCartesianChart(
                          series: <ChartSeries>[
                            // Renders line chart
                            LineSeries<UserData, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (UserData data, _) => data.date,
                              yValueMapper: (UserData data, _) => data.energy,
                              dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                builder:
                                    (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                                  int energy = data.energy;
                                  return Text('${energy > 0 ? data.energy : ''}');
                                },
                              ),
                              width: 3,
                              enableTooltip: true,
                            )
                          ],
                          primaryXAxis: DateTimeCategoryAxis(
                              visibleMinimum: DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
                              dateFormat: DateFormat.d(),
                              maximumLabels: 30,
                              majorGridLines: const MajorGridLines(width: 0),
                              axisLabelFormatter: (AxisLabelRenderDetails axisLabelRenderArgs) {
                                return ChartAxisLabel(
                                    '${axisLabelRenderArgs.text}일', const TextStyle(color: Colors.white));
                              }),
                          primaryYAxis: NumericAxis(
                            interval: 1,
                            majorGridLines: const MajorGridLines(width: 0),
                            isVisible: false,
                            // minimum: -10,
                            // maximum: 10
                          ),
                          zoomPanBehavior: ZoomPanBehavior(
                            enablePanning: true,
                          ),
                          enableAxisAnimation: false,
                          tooltipBehavior: TooltipBehavior(
                            enable: false,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              return Text(
                                '${data.energy}',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              );
                            },
                            color: Colors.transparent,
                          ),
                          // borderColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
