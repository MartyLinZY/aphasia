import 'dart:async';
import 'dart:ui' as ui;

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:aphasia_recovery/utils/io/assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/question/question.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';

class ItemFindingQuestionAreaSettingPage extends StatefulWidget {
  final ItemFindingQuestion question;
  const ItemFindingQuestionAreaSettingPage({super.key, required this.question});

  @override
  State<ItemFindingQuestionAreaSettingPage> createState() => _ItemFindingQuestionAreaSettingPageState();
}

class _ItemFindingQuestionAreaSettingPageState extends State<ItemFindingQuestionAreaSettingPage> with UseCommonStyles {
  static const int maxPointCount = 20;
  late ItemFindingQuestion currQuestion;

  int pointCount = 0;

  late List<List<double>> coordinates;
  bool convexHullFinished = false;

  void resetState() {
    clearState();
    final rule = currQuestion.evalRule as EvalItemFoundQuestion;
    pointCount = rule.coordinates.isEmpty ? 0 : maxPointCount - rule.coordinates.length;

    coordinates = rule.coordinates.isEmpty ? [] : []..addAll(rule.coordinates);
  }

  void clearState() {
    currQuestion = widget.question;

    pointCount = 0;

    coordinates = [];
    convexHullFinished = false;
  }

  void addCoordinate(double px, double py, double maxX, double maxY) {
    if (pointCount == maxPointCount) {
      toast(context, msg: "至多指定20个顶点，当前顶点数量已达上限。", btnText: "确认");
      return;
    }

    coordinates.add(normalizePosition(px, py, maxX, maxY));
    pointCount++;
  }

  @override
  void initState() {
    super.initState();
    resetState();
  }

  Future<ui.Image> getImageFromProvider(ImageProvider imageProvider) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) async {
        ByteData? byteData = await info.image.toByteData();
        Uint8List? uint8List = byteData?.buffer.asUint8List();
        ui.Codec codec = await ui.instantiateImageCodec(uint8List!);
        ui.FrameInfo frameInfo = await codec.getNextFrame();
        completer.complete(frameInfo.image);
      }),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    final imageCompleter = Completer<ui.Image>();
    Image questionImage;
    if (isImageUrlAssets(currQuestion.imageUrl)) {
      questionImage = Image(image: AssetImage(currQuestion.imageUrl!), fit: BoxFit.contain,);
    } else {
      questionImage = Image(
        image: NetworkImage(currQuestion.imageUrl!),
        fit: BoxFit.contain,
      );
    }

    questionImage.image.resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, _) {
      imageCompleter.complete(imageInfo.image);
    }));

    if (currQuestion != widget.question) {
      resetState();
    }


    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text("场景寻物题点击区域设置", style: commonStyles?.titleStyle,)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("仅支持设置凸多边形区域，请在图片上点击设置多边形区域的顶点（至多20个顶点），设置完毕后点击“完成”按钮以生成区域，系统会自动根据设置的顶点求出一个最大的凸多边形区域，区域生成后点击“确认设置”按钮保存并返回到规则设置页面", style: commonStyles?.bodyStyle,),
                Text("顶点数：$pointCount/$maxPointCount", style: commonStyles?.bodyStyle,),
                const Divider(height: 32,),
                FutureBuilder<ui.Image>(
                  future: imageCompleter.future,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      toast(context, msg: "图片加载失败，请重试。", btnText: "确认");
                      return Center(
                        child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                      );
                    } else if (!snapshot.hasData) {
                      return Center(
                        child: Text("加载中，请稍候", style: commonStyles?.hintTextStyle,),
                      );
                    }

                    final image = snapshot.data!;
                    final mediaSize = MediaQuery.of(context).size;
                    double maxWidth = mediaSize.width * 0.7;
                    double maxHeight = mediaSize.height * 0.7;
                    double boxWidth;
                    double boxHeight;
                    if (image.height * (maxWidth / image.width) <= maxHeight) {
                      boxWidth = maxWidth;
                      boxHeight = image.height * (maxWidth / image.width);
                    } else {
                      boxWidth = image.width * (maxHeight / image.height);
                      boxHeight = maxHeight;
                    }

                    return Container(
                      width: boxWidth,
                      height: boxHeight,
                      decoration: BoxDecoration(
                        border: Border.all(width: 1.0)
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTapDown: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              // find the coordinate
                              final Offset localOffset = box.globalToLocal(details.globalPosition);
                              final posX = localOffset.dx;
                              final posY = localOffset.dy;
                              setState(() {
                                addCoordinate(posX, posY, boxWidth, boxHeight);
                              });
                            },
                            child: questionImage
                          ),
                          ...coordinates.map((e) => Positioned(
                              left: e.first * boxWidth - 9,
                              top: e.last * boxHeight - 9,
                              width: 18,
                              height: 18,
                              // child: Text("${(e.first * 1000).roundToDouble() / 1000};${(e.last * 1000).roundToDouble() / 1000}",)
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.circle_rounded, color: Colors.green, size: 12.0,)
                                ),
                              ),
                          )).toList(),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 32,),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            clearState();
                          });
                        },
                        child: Text("重设", style: commonStyles?.bodyStyle,)
                      ),
                      const SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (coordinates.length < 3) {
                              toast(context, msg: "请至少设置3个顶点，至少3个顶点才能形成一个封闭区域", btnText: "确认");
                              return;
                            }
                            coordinates = convexHull(coordinates);
                            // debugPrint(coordinates.toString());
                            convexHullFinished = true;
                          });
                        },
                        child: Text("完成", style: commonStyles?.bodyStyle,)
                      ),
                      const SizedBox(width: 16,),
                      ElevatedButton(
                        onPressed: () {
                          if (convexHullFinished) {
                            Navigator.pop(context, coordinates);
                          } else {
                            toast(context, msg: "请先点击“完成”按钮生成区域再确认设置", btnText: "确认");
                          }
                        },
                        child: Text("确认设置", style: commonStyles?.bodyStyle,)
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        )
      ),
    );
  }
}
