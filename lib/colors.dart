import 'dart:ui';

import 'package:flutter/material.dart';

// These colors come from the web version of Kite and we calculate them the same way here.
// .topic-color-1{color:#c33}
// .topic-color-2{color:#b85c2e}
// .topic-color-3{color:#07c}
// .topic-color-4{color:#663}
// .topic-color-5{color:#82c}
// .topic-color-6{color:#b8288f}
// .topic-color-7{color:#e60039}
// .topic-color-8{color:#00855a}
// .topic-color-9{color:#d14900}

const color1 = Color(0xFFCC3333);
const color2 = Color(0xFFB85C2E);
const color3 = Color(0xFF0077CC);
const color4 = Color(0xFF666633);
const color5 = Color(0xFF8822CC);
const color6 = Color(0xFFB8288F);
const color7 = Color(0xFFE60039);
const color8 = Color(0xFF00855A);
const color9 = Color(0xFFD14900);

const subCategoryColors = [
  color1,
  color2,
  color3,
  color4,
  color5,
  color6,
  color7,
  color8,
  color9,
];

Color colorFromText(String text) {
  return subCategoryColors[(text.codeUnitAt(0) +
          text.codeUnitAt(1) +
          text.length) %
      subCategoryColors.length];
}
