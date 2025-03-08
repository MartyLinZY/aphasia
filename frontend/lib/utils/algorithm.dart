import 'dart:math';

import 'package:flutter/cupertino.dart';

List<double> normalizePosition(double px, double py, double maxX, double maxY) {
  if (maxX < 0) {
    throw RangeError.value(maxX, "x轴坐标最大值不可小于0");
  }
  if (maxY < 0) {
    throw RangeError.value(maxX, "y轴坐标最大值不可小于0");
  }
  if (px < 0 || px > maxX) {
    throw RangeError.value(px, "x轴坐标须在0至$maxX之间");
  }
  if (py < 0 || py > maxY) {
    throw RangeError.value(px, "y轴坐标须在0至$maxY之间");
  }
  return [px / maxX, py / maxY];
}

double crossProduct(List<double> p1, List<double> p2, List<double> p) {
  double x1 = p1.first;
  double x2 = p2.first;
  double x3 = p.first;
  double y1 = p1.last;
  double y2 = p2.last;
  double y3 = p.last;

  // debugPrint((x1 * y2 + x3 * y1 + x2 * y3 - x3 * y2 - x2 * y1 - x1 * y3).toString());
  return x1 * y2 + x3 * y1 + x2 * y3 - x3 * y2 - x2 * y1 - x1 * y3;
}

List<List<double>> convexHull(List<List<double>> points) {
  final convexHull = <List<double>>{};
  for (var p1 in points) {
    if (!convexHull.contains(p1)) {
      for (var p2 in points) {
        if (p1 != p2) {
          if (points.where((p) => p1 != p && p2 != p && crossProduct(p1, p2, p) > 0).isEmpty
              || points.where((p) => p1 != p && p2 != p && crossProduct(p1, p2, p) < 0).isEmpty) {
            convexHull.add(p1);
            convexHull.add(p2);
          }
        }
      }
    }
  }

  return convexHull.toList();
}

int LCS(List<Object> list1, List<Object> list2) {
  List<List<int>> dp = List.generate(list1.length + 1, (_) => List<int>.filled(list2.length + 1, 0));

  for (int i = 1;i <= list1.length;i++) {
    for (int j = 1; j <= list2.length; j++) {
      if (list1[i - 1] == list2[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = max(dp[i - 1][j], max(dp[i][j - 1], dp[i - 1][j - 1]));
      }
    }
  }

  return dp[list1.length][list2.length];
}

bool checkPointInPolygon(List<double> point, List<List<double>> poly) {
  double x = point[0];
  double y = point[1];
  //flag 设置为false，记录位置点与直线相交个数，奇数在多边形内，偶数在外，
  // valid==true表示该点是否在多边形边上,可直接跳出循环
  bool flag = false, valid = false;
  //遍历所有的点，每两个点连成一条直线与坐标点进行判断
  int size = poly.length;
  for (int i = 0; i < size; i++) {
    //两点坐标
    double x1 = poly[i][0];
    double y1 = poly[i][1];
    double x2 = poly[(i + 1) % size][0];
    double y2 = poly[(i + 1) % size][1];
    //如果当前两个点为水平线，计算线段方程会出现被除数为0的异常，直接下一次计算
    if (y1 == y2) {
      continue;
    }
    //如果水平线与线段没有交点
    if (y < min(y1, y2)) {
      continue;
    }
    //如果水平线与线段没有交点，等于的情况其实是有交点的，但可能会出现交点在端点上而计算两次，导致结果出错，所以只计算一次
    if (y >= max(y1, y2)) {
      continue;
    }
    //计算交点的x值
    double cur_x = (y - y1) * (x2 - x1) / (y2 - y1) + x1;
    //坐标点在线段上
    if (cur_x == x) {
      valid = true;
      break;
    }
    //如果大于x（假设射线水平向右，因此大于x有交点），记录交点次数加1，即flag改变其值
    if (cur_x > x) {
      flag = !flag;
    }
  }
  if(flag || valid) {
    return true;
  }

  return false;
}


void main () {
  print(LCS([1,2,3,4,5,6,7], [3,4,2,3,1,11,2, 3,5,7,9]));
}