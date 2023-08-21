import 'package:flutter/material.dart';

bool G_isDebug = false;

var borderForDebug = G_isDebug
    ? BoxDecoration(
        border: Border.all(width: 0.2, color: Colors.black38),
      )
    : null;

String? G_uid = "";

Color G_wakeUpColor = const Color(0xFFF8DAA0);
Color G_sleepColor = Colors.indigo;
Color G_energyColor = Colors.green;
