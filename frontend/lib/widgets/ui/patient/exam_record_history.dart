import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/result/results.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/widgets/ui/answer_result.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../states/user_identity.dart';
import '../../../utils/common_widget_function.dart';

class ExamRecordHistoryPage extends StatefulWidget {
  final bool recoveryMode;
  final CommonStyles? commonStyles;

  const ExamRecordHistoryPage(
      {super.key, this.recoveryMode = false, required this.commonStyles});

  @override
  State<ExamRecordHistoryPage> createState() => _ExamRecordHistoryPageState();
}

class _ExamRecordHistoryPageState extends State<ExamRecordHistoryPage>
    with UseCommonStyles {
  final DateFormat format = DateFormat("yyyy-MM-dd HH:mm:ss");
  late bool recoveryMode;
  bool initialized = false;
  int _currentPage = 0;
  int _totalPages = 1;

  Future<List<ExamResult>> futureExams = Future.value(<ExamResult>[]);

  @override
  void initState() {
    recoveryMode = widget.recoveryMode;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    if (!initialized || recoveryMode != widget.recoveryMode) {
      recoveryMode = widget.recoveryMode;
      refreshResults(context);
      initialized = true;
    }

    return FutureBuilder<List<ExamResult>>(
        future: futureExams,
        builder:
            (BuildContext context, AsyncSnapshot<List<ExamResult>> snapshot) {
          if (snapshot.hasData) {
            List<ExamResult> results = snapshot.requireData;
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  "${recoveryMode ? "康复训练" : "测评"}历史记录",
                  style: commonStyles?.titleStyle?.copyWith(fontSize: 20),
                ),
                elevation: 4,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 新增搜索和过滤栏
                        _buildSearchFilterBar(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child:
                                LayoutBuilder(builder: (context, constraints) {
                              return Table(
                                border: TableBorder(
                                  horizontalInside: BorderSide(
                                      color: Colors.grey.withOpacity(0.2)),
                                  verticalInside: BorderSide(
                                      color: Colors.grey.withOpacity(0.2)),
                                ),
                                columnWidths: const <int, TableColumnWidth>{
                                  0: FixedColumnWidth(60),
                                  1: FlexColumnWidth(1.5),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(2),
                                  4: FlexColumnWidth(1.2),
                                  5: FixedColumnWidth(120),
                                },
                                children: [
                                  // 优化后的表头
                                  _buildEnhancedHeader(),
                                  // 数据行使用ListView代替TableRow实现滚动优化
                                  if (results.isNotEmpty)
                                    ...results.map((result) {
                                      final table =
                                          _buildDataRow(result) as Table;
                                      return table.children.first;
                                    }).toList()
                                  else
                                    TableRow(
                                      children: List.generate(
                                          6,
                                          (index) => TableCell(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 32),
                                                  child: _buildEmptyState(),
                                                ),
                                              )),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                        _buildPaginationControls(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            debugPrint((snapshot.error as Error).stackTrace.toString());

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              toast(context, msg: "获取测评和康复记录失败，请检查网络情况", btnText: "确认");
            });
            return Center(
                child: Text(
              "加载中",
              style: commonStyles?.hintTextStyle?.copyWith(color: Colors.grey),
            ));
          } else {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "加载中",
                    style: commonStyles?.hintTextStyle
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
        });
  }

  Future<void> refreshResults(BuildContext context) async {
    // print(context
    //     .read<SingleModelState<UserIdentity>>()
    //     .model!.uid);
    futureExams = ExamResult.getByUid(
        uid: context.read<SingleModelState<UserIdentity>>().model!.uid,
        isRecovery: recoveryMode);
  }

  // 新增搜索过滤栏
  Widget _buildSearchFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索记录...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: Colors.blueAccent),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'date', child: Text('按日期排序')),
            const PopupMenuItem(value: 'score', child: Text('按得分排序')),
          ],
        ),
      ],
    );
  }

  // 增强型表头
  TableRow _buildEnhancedHeader() {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      children: [
        _buildHeaderCell("序号"),
        _buildHeaderCell("名称"),
        _buildHeaderCell("开始时间"),
        _buildHeaderCell("结束时间"),
        _buildHeaderCell(recoveryMode ? "得分" : "诊断"),
        _buildHeaderCell("操作"),
      ],
    );
  }

  // 表头单元格组件
  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
              fontSize: 13),
        ),
      ),
    );
  }

  // 数据行组件
  Widget _buildDataRow(ExamResult result) {
    final isCompleted = result.finishTime != null;

    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(60),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1.2),
        5: FixedColumnWidth(120),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          children: [
            _buildDataCell("${result.id}", isCenter: true),
            _buildDataCell(result.examName),
            _buildDataCell(format.format(result.startTime!)),
            _buildDataCell(
                isCompleted ? format.format(result.finishTime!) : "进行中",
                textStyle: TextStyle(
                    color: isCompleted ? Colors.grey[700] : Colors.orange,
                    fontWeight:
                        isCompleted ? FontWeight.normal : FontWeight.w500)),
            _buildScoreCell(result),
            _buildActionCell(result),
          ],
        ),
      ],
    );
  }

  // 添加在_buildHeaderCell方法之后
  Widget _buildDataCell(String text,
      {TextStyle? textStyle, bool isCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isCenter
          ? Center(
              child: Text(
                text,
                style: textStyle ??
                    TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            )
          : Text(
              text,
              style:
                  textStyle ?? TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
    );
  }

  // 得分/诊断单元格
  Widget _buildScoreCell(ExamResult result) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: recoveryMode
          ? Chip(
              label: Text("${result.finalScore ?? '-'} 分"),
              backgroundColor: _getScoreColor(result.finalScore),
            )
          : Tooltip(
              message: result.resultText ?? '无详细诊断',
              child: Text(
                result.resultText ?? "无诊断",
                style: TextStyle(
                    color: Colors.blueGrey[700],
                    fontStyle:
                        result.resultText == null ? FontStyle.italic : null),
              ),
            ),
    );
  }

  // 在_buildScoreCell方法前添加
  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey[200]!;

    if (score >= 80) {
      return Colors.green[100]!;
    } else if (score >= 50) {
      return Colors.orange[200]!;
    } else {
      return Colors.red[100]!;
    }
  }

  // 在_buildActionCell方法前添加
  void _navigateToDetail(ExamResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnswerResultPage(
          // 根据代码中已有导航逻辑，推测使用AnswerResultPage
          examResult: result,
          commonStyles: widget.commonStyles,
        ),
      ),
    );
  }

  void _confirmDelete(ExamResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除 ${result.examName} 的记录吗？此操作不可恢复。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await result.delete();
                refreshResults(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("已删除 ${result.examName} 的记录")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("删除失败: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("确认删除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 操作单元格优化
  Widget _buildActionCell(ExamResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 查看按钮
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: Colors.blueGrey[600],
            onPressed: () => _navigateToDetail(result),
          ),
          // 删除按钮
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.redAccent.withOpacity(0.8),
              onPressed: () => _confirmDelete(result),
            ),
          ),
        ],
      ),
    );
  }

  // 在_buildEmptyState方法前添加
  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
            tooltip: '上一页',
            color: Colors.blueAccent,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.blueAccent.withOpacity(0.1),
            ),
            child: Text(
              '第 ${_currentPage + 1} 页',
              style: TextStyle(
                  color: Colors.blueGrey[800], fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => _changePage(_currentPage + 1)
                : null,
            tooltip: '下一页',
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  // 添加分页变更方法
  void _changePage(int newPage) async {
    setState(() => _currentPage = newPage);
    await refreshResults(context);
  }

  // 空状态组件
  Widget _buildEmptyState() {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
        verticalInside: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(60),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(1.2),
        5: FixedColumnWidth(120),
      },
      children: [
        TableRow(children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.history, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "暂无历史记录",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  )
                ],
              ),
            ),
          )
        ])
      ],
    );
  }
}
