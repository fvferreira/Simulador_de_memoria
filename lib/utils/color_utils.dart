import 'package:flutter/material.dart';

Color colorForIndex(int index) {
  const anguloDourado = 137.508;
  final hue = (index * anguloDourado) % 360;
  return HSVColor.fromAHSV(1.0, hue, 0.55, 0.85).toColor();
}

const Color corSemMapeamento = Color(0xFFBDBDBD);
