import 'dart:async';
import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_colors.dart';
import 'globalVariables.dart';

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  Map<dynamic, dynamic> snapshotValue = <dynamic, dynamic>{};

  @override
  void initState() {
    super.initState();

    final query = FirebaseDatabase.instance.ref("$G_uid").orderByKey().limitToLast(7);
    query.onValue.listen((event) {
      if(mounted) {
        setState(() {
          for (final child in event.snapshot.children) {
            snapshotValue[child.key] = child.value;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> setBarGroupsData() {
      List<BarChartGroupData> processedData = [];
      for (int i = 0; i < 7; i++) {
        final today = DateTime.now();
        final dayAgo = DateFormat('yyyyMMdd').format(today.subtract(Duration(days: 6 - i)));
        processedData.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: snapshotValue[dayAgo] != null ? snapshotValue[dayAgo]['timeDiff'].toDouble() / 60 : 0,
                gradient: _barsGradient,
              )
            ],
            showingTooltipIndicators: [0],
          ),
        );
      }

      // int index = 0;
      // snapshotValue.forEach((key, value) {
      //   processedData.add(
      //     BarChartGroupData(
      //       x: index,
      //       barRods: [
      //         BarChartRodData(
      //           toY: value['timeDiff'].toDouble() / 60,
      //           gradient: _barsGradient,
      //         )
      //       ],
      //       showingTooltipIndicators: [0],
      //     ),
      //   );
      //   index++;
      // });
      return processedData;
    }

    Widget getTitles(double value, TitleMeta meta) {
      const style = TextStyle(
        color: AppColors.contentColorBlue,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
      final today = DateTime.now();
      String text = DateFormat('MM/dd').format(today.subtract(Duration(days: 6 - value.toInt())));
      // String text;
      // switch (value.toInt()) {
      //   case 0: text = '08/04'; break;
      //   case 1: text = '08/05'; break;
      //   case 2: text = '08/06'; break;
      //   case 3: text = '08/07'; break;
      //   case 4: text = '08/08'; break;
      //   case 5: text = '08/09'; break;
      //   case 6: text = '08/10'; break;
      //   default: text = ''; break;
      // }
      // String text = snapshotValue.keys.elementAtOrNull(value.toInt()) ?? 'tmp';
      // if (text != 'tmp') {
      //   text = '${text.substring(4, 6)}/${text.substring(6, 8)}';
      // }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(text, style: style),
      );
    }

    FlTitlesData setTitlesData() {
      return FlTitlesData(
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
    }

    return Scaffold(
      appBar: AppBar(title: const Text("차트")),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: borderForDebug,
          child: Column(
            children: [
              Container(
                alignment: AlignmentDirectional.topStart,
                decoration: borderForDebug,
                child: const Text("지난 7일 수면 시간", style: TextStyle(fontSize: 30),)
              ),
              Container(
                decoration: borderForDebug,
                height: 200,
                child: BarChart(
                  BarChartData(
                    barTouchData: barTouchData,
                    titlesData: setTitlesData(),
                    borderData: borderData,
                    barGroups: setBarGroupsData(),
                    gridData: const FlGridData(show: false),
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 20,
                  ),
                ),
              ),
            ],
          ),
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
            color: AppColors.contentColorCyan,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  );

  FlBorderData get borderData => FlBorderData(
    show: false,
  );

  LinearGradient get _barsGradient => const LinearGradient(
    colors: [
      AppColors.contentColorBlue,
      AppColors.contentColorCyan,
    ],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}