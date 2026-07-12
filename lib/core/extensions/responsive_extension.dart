import 'package:flutter/material.dart';

extension Responsive on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  bool get isSmallPhone => width < 360;
  bool get isTablet => width >= 600;

  double get titleSize => isSmallPhone ? 22 : 30;
  double get subtitleSize => isSmallPhone ? 14 : 18;

  double get logoRadius => isSmallPhone ? 40 : 50;
  double get logoSize => isSmallPhone ? 70 : 100;

  double get horizontalPadding => isSmallPhone ? 20 : 30;
}