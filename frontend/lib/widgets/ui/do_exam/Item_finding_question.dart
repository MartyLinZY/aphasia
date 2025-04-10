import 'dart:async';
import 'dart:ui' as ui;

import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../../../models/question/question.dart';
import '../../../models/result/results.dart';
import '../../../models/rules.dart';
import '../../../utils/common_widget_function.dart';
import '../../../utils/io/assets.dart';

class ItemFindingQuestionAnswerArea extends StatefulWidget {
  final Question question;
  final CommonStyles? commonStyles;
  final void Function(QuestionResult) goToNextQuestion;

  const ItemFindingQuestionAnswerArea(
      {super.key,
      required this.question,
      required this.commonStyles,
      required this.goToNextQuestion});

  @override
  State<ItemFindingQuestionAnswerArea> createState() =>
      _ItemFindingQuestionAnswerAreaState();
}

class _ItemFindingQuestionAnswerAreaState
    extends State<ItemFindingQuestionAnswerArea>
    with QuestionAnswerArea
    implements ResettableState {
  // 新增样式常量
  static const _cardRadius = 20.0;
  static const _markerSize = 24.0;
  static const _buttonPadding =
      EdgeInsets.symmetric(horizontal: 32, vertical: 16);

  // 常规变量
  late ItemFindingQuestion currQuestion;
  late ItemFindingQuestionResult result;

  bool answerStart = false;
  List<double>? clickPosition;

  @override
  void resetState() {
    currQuestion = widget.question as ItemFindingQuestion;
    EvalItemFoundQuestion rule = currQuestion.evalRule as EvalItemFoundQuestion;
    result = ItemFindingQuestionResult(sourceQuestion: widget.question);
    answerStart = false;

    initQuestionStem(currQuestion);

    // 关闭答题倒计时，测试用
    // timeLimitCountDown?.cancel();
  }

  @override
  void initQuestionStem(Question currQuestion) {
    super.initQuestionStem(currQuestion);
    // 本题型的题干图片展示方式不同，所以不需要通用的题干图片相关功能
    imageDisplayed = false;
    imageDisplayCounter!.cancel();

    if (timeLimitCountDown != null) {
      Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (timeLimitCountDown!.isComplete == true && !evaluating && mounted) {
          finishAnswer();
          timer.cancel(); // 倒计时结束后取消定时器
        }
      });
    }
    
    if (currQuestion.audioUrl == null) {
      timeLimitCountDown!.start();
    }
  }

  @override
  void finishAnswer() {
    // if (clickPosition == null) {
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       title: const Text("提示"),
    //       content: const Text("请先点击图片选择答案位置"),
    //       actions: [
    //         TextButton(
    //             onPressed: () => Navigator.pop(ctx), child: const Text("确定"))
    //       ],
    //     ),
    //   );
    //   return;
    // }
    if (clickPosition == null) {
      result.clickCoordinate = [-1.0, -1.0]; // 用特殊值标记未点击
    }

    doCommonFinishStep(result);
    evalQuestion(
      clickPosition: clickPosition!,
      result: result,
      question: currQuestion
    );
    // if (!timeLimitCountDown!.isComplete) {
    //   if (clickPosition == null) {
    //     return;
    //   }
    // }
  }

  void evalQuestion(
      {required List<double>? clickPosition,
      required ItemFindingQuestion question,
      required ItemFindingQuestionResult result}) {
    result.clickCoordinate = clickPosition;

    doEvalQuestion(
        question: question,
        result: result,
        goToNextQuestion: widget.goToNextQuestion);
  }

  @override
  void initState() {
    super.initState();

    resetState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    disposePlayerAndCounters();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currQuestion != widget.question) {
      // 题目切换
      resetState();
    }

    final commonStyles = widget.commonStyles;

    if (evaluating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('评分中，请稍候', style: commonStyles?.hintTextStyle),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildContentArea(commonStyles),
        ),
      ),
    );
  }

  Widget _buildContentArea(CommonStyles? commonStyles) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                commonStyles?.primaryColor?.withOpacity(0.03) ?? Colors.white,
                commonStyles?.onPrimaryColor?.withOpacity(0.05) ?? Colors.white,
              ]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (isQuestionTextDisplayed) _buildQuestionText(commonStyles),
              Expanded(child: _buildImageArea(context, commonStyles)),
              _buildActionArea(commonStyles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionText(CommonStyles? commonStyles) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        displayText ?? "不应该为这个",
        style: commonStyles?.titleStyle
            ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionArea(CommonStyles? commonStyles) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check, color: Colors.white),
          label: Text("提交答案",
              style: commonStyles?.bodyStyle
                  ?.copyWith(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: commonStyles?.primaryColor ?? Colors.blueAccent,
            padding: _buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
          ),
          onPressed: finishAnswer,
        ),
        const SizedBox(height: 16),
        timeLimitCountDown!.buildCountWidget(commonStyles: commonStyles)
      ],
    );
  }

  Widget _buildImageArea(BuildContext context, CommonStyles? commonStyles) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(2, 2))
            ]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildInteractiveImage(context, commonStyles),
        ),
      ),
    );
  }

  Widget _buildInteractiveImage(
      BuildContext context, CommonStyles? commonStyles) {
    return Stack(
      fit: StackFit.expand,
      children: [
        buildUrlOrAssetsImage(context,
          imageUrl: currQuestion.imageUrl!,
          commonStyles: commonStyles),
        // Positioned.fill(
        //   child: Listener(
        //     onPointerDown: _handleImageTap,
        //   ),
        // ),
        Positioned.fill(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Listener(
              onPointerDown: _handleImageTap,
              behavior: HitTestBehavior.opaque, // 允许整个区域接收点击
            ),
          ),
        ),
        if (clickPosition != null) _buildPositionMarker(commonStyles),
      ],
    );
  }

  void _handleImageTap(PointerDownEvent event) {
    // final RenderBox box = context.findRenderObject() as RenderBox;
    // final Offset localOffset = box.globalToLocal(event.position);
    // final Size imageSize = box.size; // 改用实际渲染尺寸

    // setState(() {
    //   clickPosition = [
    //     localOffset.dx.clamp(0.0, imageSize.width),
    //     localOffset.dy.clamp(0.0, imageSize.height)
    //   ];

    //   // 强制启动答题计时
    //   if (!answerStart) {
    //     trySetAnswerTime(result, timeLimitCountDown!.timePassed);
    //     answerStart = true;
    //     timeLimitCountDown!.start(); // 确保倒计时已启动
    //   }
    // });
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset rawOffset = box.globalToLocal(event.position);
    
    // 获取图片实际显示区域
    final image = buildUrlOrAssetsImage(context, 
      imageUrl: currQuestion.imageUrl!,
      commonStyles: widget.commonStyles
    ) as Image; // 添加类型转换
    
    image.image.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener((info, _) {
        final imageWidth = info.image.width.toDouble();
        final imageHeight = info.image.height.toDouble();
        final renderWidth = box.size.width;
        final renderHeight = box.size.height;

        // 计算缩放比例
        final scaleX = renderWidth / imageWidth;
        final scaleY = renderHeight / imageHeight;
        final scale = scaleX < scaleY ? scaleX : scaleY;

        // 计算实际显示区域
        final displayedWidth = imageWidth * scale;
        final displayedHeight = imageHeight * scale;
        final offsetX = (renderWidth - displayedWidth) / 2;
        final offsetY = (renderHeight - displayedHeight) / 2;

        // 转换坐标
        final adjustedX = (rawOffset.dx - offsetX) / scale;
        final adjustedY = (rawOffset.dy - offsetY) / scale;

        setState(() {
          clickPosition = [
            adjustedX.clamp(0.0, imageWidth),
            adjustedY.clamp(0.0, imageHeight)
          ];
          
          if (!answerStart) {
            trySetAnswerTime(result, timeLimitCountDown!.timePassed);
            answerStart = true;
            timeLimitCountDown!.start();
          }
        });
      })
    );
  }

  Widget _buildPositionMarker(CommonStyles? commonStyles) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: clickPosition!.first - _markerSize / 2,
      top: clickPosition!.last - _markerSize / 2,
      child: Container(
        width: _markerSize,
        height: _markerSize,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [
            commonStyles?.primaryColor?.withOpacity(0.3) ??
                Colors.blue.withOpacity(0.3),
            commonStyles?.primaryColor ?? Colors.blue,
          ], stops: [
            0.5,
            1.0
          ]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildItemFindingArea(BuildContext context,
      {CommonStyles? commonStyles, required ItemFindingQuestion question}) {
    final imageCompleter = Completer<ui.Image>();
    Image questionImage;
    if (isImageUrlAssets(currQuestion.imageUrl)) {
      questionImage = Image(
        image: AssetImage(currQuestion.imageUrl!),
        fit: BoxFit.contain,
      );
    } else {
      questionImage = Image(
        image: NetworkImage(currQuestion.imageUrl!),
        fit: BoxFit.contain,
      );
    }

    questionImage.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((imageInfo, _) {
      imageCompleter.complete(imageInfo.image);
    }));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<ui.Image>(
              future: imageCompleter.future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  toast(context, msg: "图片加载失败，请重试。", btnText: "确认");
                  return Center(
                    child: Text(
                      "加载中，请稍候",
                      style: commonStyles?.hintTextStyle,
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      "加载中，请稍候",
                      style: commonStyles?.hintTextStyle,
                    ),
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
                  decoration: BoxDecoration(border: Border.all(width: 1.0)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Listener(
                        onPointerDown: (details) {
                          final RenderBox box =
                              context.findRenderObject() as RenderBox;
                          // find the coordinate
                          final Offset localOffset =
                              box.globalToLocal(details.position);
                          final posX = localOffset.dx;
                          final posY = localOffset.dy;
                          setState(() {
                            // debugPrint("click at: $posX;$posY");
                            clickPosition = normalizePosition(
                                posX, posY, boxWidth, boxHeight);
                            if (!answerStart) {
                              trySetAnswerTime(
                                  result, timeLimitCountDown!.timePassed);
                              answerStart = true;
                            }
                          });
                        },
                        child: questionImage,
                      ),
                      ...(clickPosition == null
                          ? []
                          : [
                              Positioned(
                                left: clickPosition!.first * boxWidth - 9,
                                top: clickPosition!.last * boxHeight - 9,
                                width: 18,
                                height: 18,
                                // child: Text("${(e.first * 1000).roundToDouble() / 1000};${(e.last * 1000).roundToDouble() / 1000}",)
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                      child: Icon(
                                    Icons.circle_rounded,
                                    color: Colors.green,
                                    size: 12.0,
                                  )),
                                ),
                              )
                            ]),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
