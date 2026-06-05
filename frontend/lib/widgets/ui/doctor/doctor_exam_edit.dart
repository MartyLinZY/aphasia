import 'dart:async';
import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/states/exam_edit_selection_state.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/exam/category.dart';
import '../../../models/exam/sub_category.dart';
import '../../../utils/common_widget_function.dart';
import 'doctor_exam_setting_edit_sub_page.dart';
import 'doctor_question_category_edit_sub_page.dart';
import 'doctor_question_sub_category_edit_sub_page.dart';
import 'exam_edit_left_menu/exam_category_list.dart';


/// 新建套题引导页
class DoctorExamEditInstructionPage extends StatefulWidget {
  final bool recoveryMode;
  const DoctorExamEditInstructionPage({super.key, this.recoveryMode = false});

  @override
  State<DoctorExamEditInstructionPage> createState() => _DoctorExamEditInstructionPageState();
}

class _DoctorExamEditInstructionPageState extends State<DoctorExamEditInstructionPage> with UseCommonStyles {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController nameFieldCtrl = TextEditingController();
  TextEditingController descFieldCtrl = TextEditingController();

  TextEditingController templateExamIdField = TextEditingController();

  int currentStep = 0;

  bool isRecovery = false;

  @override
  void initState() {
    super.initState();
    isRecovery = widget.recoveryMode;
  }

  @override
  Widget build(BuildContext context) {
    initStyles(context);

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text("创建新套题引导", style: commonStyles?.titleStyle,)),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return Stepper(
                // type: StepperType.horizontal,
                // stepIconBuilder: (context, stepState) {
                //
                // },
                controlsBuilder: (context, ctrlDetail) {
                  if (ctrlDetail.currentStep == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("返回", style: commonStyles!.bodyStyle,),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ctrlDetail.onStepContinue!();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                            child: Text("创建", style: commonStyles!.bodyStyle?.copyWith(color: theme.colorScheme.onPrimary),),
                          )
                        ],
                      ),
                    );
                  } else {
                    return const Text("");
                  }
                },
                currentStep: currentStep,
                onStepCancel: () {
                  if (currentStep == 0) {
                    Navigator.pop(context);
                  }
                },
                onStepContinue: () {
                  if (currentStep == 0) {
                    if ( _formKey.currentState!.validate()) {
                      setState(() {
                        currentStep++;

                        ExamQuestionSet
                            .createExam(name: nameFieldCtrl.text, description: descFieldCtrl.text, isRecovery: isRecovery)
                            .then((exam) async {
                          Timer(const Duration(milliseconds: 750),
                                  () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
                                  create: (BuildContext context) => ExamState(exam),
                                  child: const DoctorExamEditPage()
                              ))));
                        });
                      });
                    }
                  }
                },
                onStepTapped: (index) { },
                steps: [
                  // Step(
                  //   title: Text("基本信息", style: commonStyles!.titleStyle,),
                  //   content: Form(
                  //     key: _formKey,
                  //     child: ConstrainedBox(
                  //       constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                  //       child: Align(
                  //         heightFactor: 1.0,
                  //         alignment: Alignment.centerLeft,
                  //         child: Column(
                  //           mainAxisSize: MainAxisSize.min,
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text("套题方案名和简介", style: commonStyles!.titleStyle,),
                  //             const SizedBox(
                  //               height: 16,
                  //             ),
                  //             Container(
                  //               constraints: const BoxConstraints(
                  //                   maxWidth: 600
                  //               ),
                  //               child: TextFormField(
                  //                 decoration: const InputDecoration(
                  //                   hintText: "套题方案名称（必填）",
                  //                 ),
                  //                 controller: nameFieldCtrl,
                  //                 validator: (String? value) {
                  //                   if (value == null || value == "") {
                  //                     return "请输入套题方案名称";
                  //                   }
                  //                   return null;
                  //                 },
                  //               ),
                  //             ),
                  //             const SizedBox(
                  //               height: 16,
                  //             ),
                  //             Container(
                  //               constraints: const BoxConstraints(
                  //                   maxWidth: 600
                  //               ),
                  //               child: TextFormField(
                  //                 decoration: const InputDecoration(
                  //                   hintText: "简介",
                  //                 ),
                  //                 controller: descFieldCtrl,
                  //               ),
                  //             ),
                  //             const SizedBox(height: 16,),
                  //             Row(
                  //               children: [
                  //                 Text("是否为康复方案：", style: commonStyles?.bodyStyle),
                  //                 Checkbox(value: isRecovery, onChanged: (bool? value) {
                  //                   setState(() {
                  //                     isRecovery = value ?? false;
                  //                   });
                  //                 }),
                  //               ],
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  Step(
                    title: Text("基本信息", style: commonStyles!.titleStyle,),
                    content: Form(
                      key: _formKey,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                        child: Align(
                          heightFactor: 1.0,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("套题方案名和简介", style: commonStyles!.titleStyle,),
                              const SizedBox(height: 24),  // 增大间距
                              Container(
                                constraints: BoxConstraints(  // 响应式宽度
                                  maxWidth: constraints.maxWidth * 0.8,
                                  minWidth: 300
                                ),
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    hintText: "套题方案名称（必填）",
                                    border: OutlineInputBorder(),  // 添加边框
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: nameFieldCtrl,
                                  validator: (String? value) => value?.isEmpty ?? true ? "请输入有效的套题方案名称" : null,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.8,
                                  minWidth: 300
                                ),
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    hintText: "简介",
                                    border: OutlineInputBorder(),  // 统一输入框样式
                                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: descFieldCtrl,
                                  maxLines: 3,  // 允许多行输入
                                  minLines: 2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildRecoveryToggle(constraints),  // 提取复用组件
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: Text("创建", style: commonStyles!.titleStyle,),
                    content: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('创建中，请稍候', style: commonStyles!.hintTextStyle,),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
        ),
      ),
    );
  }

  // 新增复用组件方法
  Widget _buildRecoveryToggle(BoxConstraints constraints) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      constraints: BoxConstraints(  // 新增宽度约束
        maxWidth: constraints.maxWidth * 0.8,
        minWidth: 300
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // 新增垂直居中
        children: [
          Padding(  // 新增文本内边距
            padding: const EdgeInsets.only(left: 16), 
            child: Text("是否为康复方案：", style: commonStyles?.bodyStyle),
          ),
          Padding(  // 新增开关内边距
            padding: const EdgeInsets.only(right: 8),
            child: Switch(
              value: isRecovery,
              onChanged: (bool value) => setState(() => isRecovery = value),
              activeThumbColor: commonStyles?.primaryColor,
            )
          )
        ],
      ),
    );
  }
}


/// 套题编辑页面
class DoctorExamEditPage extends StatefulWidget {
  const DoctorExamEditPage({super.key});

  @override
  State<DoctorExamEditPage> createState() => _DoctorExamEditPageState();
}

class _DoctorExamEditPageState extends State<DoctorExamEditPage> with UseCommonStyles {
  double _menuWidth = 240.0;
  // final double _menuItemHeight = 50;
  double listTileCommonHeight = 32;
  double listTilePaddingBase = 8.0;
  late double tileLeadingWidth;
  late double tileContentWidth;

  /// 选中态 ChangeNotifier。T2 引入、T3 起子页/左栏 widgets 通过 Provider 订阅；
  /// 本 State 直接持有 instance，build 中读 `_selectionState.editItem` 等渲染
  /// `_buildSettingTile`（"通用设置"标签 Icon）与 `_buildActionArea`（右栏 sub
  /// page 路由）。变化通过 `_onSelectionChanged` listener 触发 setState。
  final ExamEditSelectionState _selectionState = ExamEditSelectionState();

  @override
  void initState() {
    super.initState();
    // 左栏菜单树（T4–T6 拆出的 3 个 widget）自带 selectionState 写入路径，
    // 父 State 不再通过显式 setState 链路得到通知。但 `_buildSettingTile`
    // 仍读 `_selectionState.editItem` 决定"通用设置" Icon，`_buildActionArea`
    // 仍读 editItem / editCategoryIndex / editSubCategoryIndex 路由右栏 sub
    // page，因此必须订阅 ChangeNotifier 才能在左栏写入选中态后及时重画。
    // 想彻底删此 listener 需进一步把上述两段也拆成 Provider descendant。
    _selectionState.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _selectionState.removeListener(_onSelectionChanged);
    _selectionState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tileLeadingWidth = 7 * listTilePaddingBase + 100;// 100是为expand按钮预留的宽度
    tileContentWidth = max(_menuWidth - tileLeadingWidth, 0);

    var examState = context.watch<ExamState>(); // 用于监听下层widget对Exam的修改

    commonStyles = initStyles(context);
    final paddingWidth = commonStyles?.commonPaddingWidth ?? 16.0;

    return Scaffold(
      appBar: AppBar(title: Text("编辑套题方案", style: commonStyles?.titleStyle,),),
      body: SafeArea(
        // T2: 将 [_selectionState] 暴露给整棵子树，便于 T3+ 的子页与左栏拆出
        // 的 Widget 用 `context.read/watch<ExamEditSelectionState>()` 订阅，
        // 而无需再经由 `widget._parentState` / `parentState: this` 这条桥。
        child: ChangeNotifierProvider<ExamEditSelectionState>.value(
          value: _selectionState,
          child: Padding(
          padding: EdgeInsets.all(paddingWidth),
          child: LayoutBuilder(
              builder: (context, constraints) {
                return wrappedByCard (
                  elevation: 8.0,
                  child: Row(
                    children: [
                      GestureDetector(
                        onHorizontalDragUpdate: (detail) {
                          setState(() {
                            _menuWidth = max(tileLeadingWidth, min(600, _menuWidth + detail.primaryDelta!));
                          });
                        },
                        child: SizedBox(
                          width: _menuWidth,
                          height: constraints.maxHeight,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text("菜单", style: commonStyles?.titleStyle,),
                                const Divider(),
                                _buildSettingTile(examState),
                                const Divider(),
                                ExamCategoryList(
                                  commonStyles: commonStyles!,
                                  listTileCommonHeight: listTileCommonHeight,
                                  listTilePaddingBase: listTilePaddingBase,
                                  tileContentWidth: tileContentWidth,
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: _buildActionArea(),
                      )
                    ],
                  ),
                );
              }
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(ExamState examState) {
    return ListTile(
      title: buildListTileContentWithActionButtons(
        body: Text("通用设置", style: commonStyles?.bodyStyle, overflow: TextOverflow.ellipsis,),
        textAreaMaxHeight: listTileCommonHeight,
        textAreaMaxWidth: tileContentWidth + 60,
        commonStyles: commonStyles,
        firstBtnAction: () {
          continueAction() {
            setState(() {
              _selectionState.editItem = examState.exam;
            });
          }

          if (_selectionState.editingItem) {
            confirm(context,
              title: "确认",
              body: "当前有未保存的编辑内容，是否丢弃这些内容并继续打开通用设置？",
              commonStyles: commonStyles,
              onConfirm: (context) {
                continueAction();
                Navigator.pop(context);
              }
            );
          } else {
            continueAction();
          }
        },
        firstBtnIcon: _selectionState.editItem.runtimeType == ExamQuestionSet ? const Icon(Icons.edit_document): const Icon(Icons.edit),
        firstBtnTooltipMsg: "编辑"
      ),
      contentPadding: const EdgeInsets.only(left: 44),
    );
  }

  Widget _buildActionArea() {
    Widget child;
    var editItem = _selectionState.editItem;

    if (editItem == null) {
      child = const SizedBox.shrink();
    } else if (editItem.runtimeType == ExamQuestionSet) {
      child = ExamSettingEditSubPage(editItem);
    } else if (editItem.runtimeType == QuestionCategory) {
      assert(_selectionState.editCategoryIndex != null);
      child = QuestionCategoryEditSubPage(editItem, categoryIndex: _selectionState.editCategoryIndex!);
    } else if (editItem.runtimeType == QuestionSubCategory) {
      child = QuestionSubCategoryEditSubPage(editItem, categoryIndex: _selectionState.editCategoryIndex!, subCategoryIndex: _selectionState.editSubCategoryIndex!);
    } else {
      throw UnimplementedError("unexpected editItem");
    }

    return SizedBox.expand(
      child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.blueGrey),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 16.0,
              child: child,
            ),
          )
      ),
    );
  }
}
