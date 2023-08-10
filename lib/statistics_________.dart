import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'globalVariables.dart';

class Statistics__ extends StatefulWidget {
  const Statistics__({super.key});

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics__> {
  Map<dynamic, dynamic>? snapshotValue;
  List<BarChartGroupData>? barGroups;

  List<BarChartGroupData> getBarGroupsData (value) {
    List<MapEntry<dynamic, dynamic>> mapEntries = value.entries.toList();
    mapEntries.sort((a, b) => a.key.compareTo(b.key));
    LinkedHashMap<dynamic, dynamic> sortedMap = LinkedHashMap.fromEntries(mapEntries);
    List<BarChartGroupData> processedData = [];
    int index = 0;
    sortedMap.forEach((key, value) {
      processedData.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value['timeDiff'].toDouble() / 60,
              gradient: _barsGradient,
            )
          ],
          showingTooltipIndicators: [0],
        ),
      );
      index++;
    });
    return processedData;
  }

  @override
  void initState() {
    super.initState();
    // 비동기 함수인 getMarkersAsync를 호출하고, 데이터가 준비되면 setState를 호출하여 UI를 갱신합니다.
    getMarkersAsync().then((value) {
      setState(() {
        barGroups = getBarGroupsData(value);
      });
    });
  }

  Future<Map<dynamic, dynamic>> getMarkersAsync() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("$G_uid");
    DataSnapshot snapshot = await ref.get();
    return snapshot.value as Map<dynamic, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("통계")),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
                alignment: AlignmentDirectional.topStart,
                decoration: borderForDebug,
                child: const Text(
                  "수면 시간",
                  style: TextStyle(fontSize: 40),
                )),
            Container(
              decoration: borderForDebug,
              height: 300,
              child: BarChart(
                BarChartData(
                  barTouchData: barTouchData,
                  titlesData: titlesData,
                  borderData: borderData,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarTouchData get barTouchData => BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.round().toString(),
              const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Mn';
        break;
      case 1:
        text = 'Te';
        break;
      case 2:
        text = 'Wd';
        break;
      case 3:
        text = 'Tu';
        break;
      case 4:
        text = 'Fr';
        break;
      case 5:
        text = 'St';
        break;
      case 6:
        text = 'Sn';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  FlBorderData get borderData => FlBorderData(
        show: false,
      );

  LinearGradient get _barsGradient => const LinearGradient(
        colors: [
          Colors.black,
          Colors.black,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
}
