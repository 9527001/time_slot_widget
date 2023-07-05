library time_slot_widget;

import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 自定义时间区块，构建指定格式的实体
typedef TimeItemBuilder = TimeItemEntity Function(int index);

/// 时间轴
class TimeSlotWidget extends StatefulWidget {
  /// 控制当前实际时间
  final DateTime? currentDateTime;

  ///  时间段的总数
  final int? count;

  /// 时间段自定义
  final TimeItemBuilder timeItemBuilder;

  /// 各项参数配置
  final TimeStyle? timeStyle;

  const TimeSlotWidget({
    Key? key,
    required this.timeItemBuilder,
    this.currentDateTime,
    this.count,
    this.timeStyle,
  }) : super(key: key);

  @override
  TimeSlotWidgetState createState() => TimeSlotWidgetState();
}

class TimeSlotWidgetState extends State<TimeSlotWidget> {
  TimeStyle get _timeStyle {
    return widget.timeStyle ?? TimeStyle();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints boxConstraints) {
      return SizedBox(
        height: _timeStyle.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _TimeZonePainter(
            boxConstraints.maxWidth,
            widget.currentDateTime ?? DateTime.now(),
            timeStyle: _timeStyle,
            itemCount: widget.count,
            timeItemBuilder: widget.timeItemBuilder,
          ),
        ),
      );
    });
  }
}

class _TimeZonePainter extends CustomPainter with RatioFromTimeMixin {
  final TimeItemBuilder timeItemBuilder;
  final double width;
  final int? itemCount;
  final TimeStyle timeStyle;

  _TimeZonePainter(
      this.width,
      DateTime currentDateTime, {
        required this.timeItemBuilder,
        required this.timeStyle,
        this.itemCount,
      }) : super() {
    bgPainter = Paint()..strokeWidth = 1;
    this.currentDateTime = currentDateTime;
    start = timeStyle.start;
    end = timeStyle.end;
  }

  late Paint bgPainter;

  /// 计算背景显示区块数
  int get allCount {
    return ((timeStyle.end - timeStyle.start).abs() / timeStyle.space).floor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    /// 绘制背景
    drawBg(canvas, size, timeStyle.bgFillColor);

    /// 绘制时间线刻度
    drawBgZone(canvas, size, timeStyle.timeLineFillColor);

    /// 绘制刻度对应的数字
    drawNumber(canvas, size, timeStyle.numberTextColor);

    /// 绘制需要显示的内容
    drawTime(canvas, size);

    /// 绘制当前时间
    drawCurrentTime(canvas, size);
  }

  /// 指定颜色的背景
  void drawBg(Canvas canvas, Size size, Color bgColor) {
    Rect zone1 = Rect.fromLTWH(0, 0, size.width, size.height);
    bgPainter
      ..style = PaintingStyle.fill
      ..color = bgColor;
    canvas.drawRect(zone1, bgPainter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  void drawBgZone(Canvas canvas, Size size, Color color) {
    int i = 0;
    Paint painter = Paint()
      ..strokeWidth = 1
      ..color = color
      ..style = PaintingStyle.fill;
    int num = allCount;
    double itemWidth = width / allCount;
    while (i < num) {
      Rect zone1 = Rect.fromLTWH(itemWidth * i, 0,
          itemWidth - timeStyle.timeSpace, timeStyle.timeHeight);
      canvas.drawRect(zone1, painter);
      i++;
    }
  }

  void drawNumber(Canvas canvas, Size size, Color textColor) {
    int i = 1;
    int num = allCount;
    double itemWidth = width / num;
    while (i < num) {
      _paintText(
        canvas,
        size,
        Offset(itemWidth * i, timeStyle.timeHeight + timeStyle.numberTop),
        info: (timeStyle.start + timeStyle.space * i).toString(),
        textColor: textColor,
        fontSize: timeStyle.numberFontSize,
        textMaxWidth: timeStyle.textMaxWidth,
      );
      i++;
    }
  }

  // 绘制文字
  void _paintText(
      Canvas canvas,
      Size size,
      Offset offset, {
        required String info,
        double textMaxWidth = 20,
        TextAlign? textAlign,
        double? fontSize,
        Color? textColor,
      }) {
    ui.ParagraphBuilder pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: textAlign ?? TextAlign.center,
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.normal,
        fontSize: fontSize ?? 12,
        height: 1,
        maxLines: 1,
      ),
    )
      ..pushStyle(ui.TextStyle(color: textColor ?? const Color(0xFF999999)))
      ..addText(info);
    ui.ParagraphConstraints pc = ui.ParagraphConstraints(width: textMaxWidth);
    ui.Paragraph paragraph = pb.build()..layout(pc);
    canvas.drawParagraph(
        paragraph, Offset(offset.dx - textMaxWidth / 2, offset.dy));
  }

  void drawTime(ui.Canvas canvas, ui.Size size) {
    if (itemCount == null || itemCount == 0) {
      return;
    }
    int count = itemCount!;
    for (int i = 0; i < count; i++) {
      TimeItemEntity timeItemEntity = timeItemBuilder.call(i);
      double start = offsetFromDateTime(timeItemEntity.start);
      double end = offsetFromDateTime(timeItemEntity.end);
      Paint painter = Paint()
        ..strokeWidth = 1
        ..color = timeItemEntity.fillColor
        ..style = PaintingStyle.fill;
      Rect zone = Rect.fromLTWH(
        width * start,
        0,
        width * (end - start),
        timeStyle.timeHeight,
      );
      canvas.drawRect(zone, painter);
    }
  }

  void drawCurrentTime(
      Canvas canvas,
      Size size, {
        double dashHeight = 4,
        double dashSpace = 2,
        double startY = 0.5,
      }) {
    if (!DateUtils.isSameDay(DateTime.now(), currentDateTime)) {
      return;
    }
    double begin = offsetFromDateTime(DateTime.now());
    var paint = Paint() // 创建一个画笔并配置其属性
      ..strokeWidth = 1 // 画笔的宽度
      ..isAntiAlias = true // 是否抗锯齿
      ..color = const Color(0xFFFF4A4A); // 画笔颜色
    var max = timeStyle.timeHeight;
    double startX = width * begin;
    int count = 0;
    while (startY < max) {
      canvas.drawLine(
          Offset(startX, startY),
          Offset(
              startX,
              min(
                  count == 0
                      ? startY + timeStyle.dashLineSeparate
                      : startY + dashHeight,
                  max)),
          paint);
      startY +=
          (count == 0 ? timeStyle.dashLineSeparate : dashHeight) + dashSpace;
      count++;
    }
  }
}

mixin RatioFromTimeMixin {
  late DateTime currentDateTime;
  late int start;
  late int end;

  /// 计算时间所占UI的距离左侧的偏移量，最大为1，0-1范围内
  double offsetFromDateTime(DateTime fromTime) {
    int all = maxTime.difference(minTime).inMinutes;
    return correctDuration(fromTime, minTime).inMinutes / all;
  }

  DateTime get minTime {
    return DateTime(currentDateTime.year, currentDateTime.month,
        currentDateTime.day, start, 00, 00);
  }

  DateTime get maxTime {
    return DateTime(currentDateTime.year, currentDateTime.month,
        currentDateTime.day, end, 00, 00);
  }

  Duration correctDuration(DateTime dateTime, DateTime minDateTime) {
    Duration endDuration = dateTime.difference(minDateTime);

    if (endDuration.inMinutes < 0) {
      endDuration = const Duration(minutes: 0);
    }
    return endDuration;
  }
}

class TimeItemEntity {
  /// 填充颜色
  final Color fillColor;

  /// 开始时间
  final DateTime start;

  /// 结束时间
  final DateTime end;

  TimeItemEntity({
    this.fillColor = const Color(0xffDDDDDD),
    required this.start,
    required this.end,
  });
}

class TimeStyle {
  /// 背景色，默认透明色
  final Color bgFillColor;

  /// 刻度色块
  final Color timeLineFillColor;

  /// 记录的时间区块的颜色
  final Color showTimeLineFillColor;

  /// 刻度对应的文字的颜色
  final Color numberTextColor;

  /// 限制时间开始，默认8点
  final int start;

  /// 限制时间结束，默认24点
  final int end;

  /// 限制时间 时间间隔，默认2小时
  final int space;

  /// 整体高度 默认50
  final double height;

  /// 时间区块的高度，默认24
  final double timeHeight;

  /// 时间区块的间隔 默认1.62
  final double timeSpace;

  /// 刻度文字距离上间距，默认8
  final double numberTop;

  /// 刻度文字的字体大小 默认12
  final double numberFontSize;

  /// 刻度文字的最大宽度 默认20；可以根据世界内容调整
  final double textMaxWidth;

  /// 虚线间隔间距
  final double dashLineSeparate;

  TimeStyle({
    this.bgFillColor = Colors.transparent,
    this.timeLineFillColor = const Color(0xfff2f2f2),
    this.showTimeLineFillColor = const Color(0xFFDDDDDD),
    this.numberTextColor = const Color(0xFF999999),
    this.height = 50,
    this.timeHeight = 24,
    this.timeSpace = 1.62,
    this.start = 8,
    this.end = 24,
    this.space = 2,
    this.numberTop = 8,
    this.numberFontSize = 12,
    this.textMaxWidth = 20,
    this.dashLineSeparate = 2,
  });
}
