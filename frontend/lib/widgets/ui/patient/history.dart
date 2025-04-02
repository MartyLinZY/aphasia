import 'package:aphasia_recovery/widgets/ui/patient/exam_record_history.dart';
import 'package:flutter/material.dart';

import '../../../mixin/widgets_mixin.dart';
import '../login.dart';

class HistoryPage extends StatefulWidget {
  final CommonStyles? commonStyles;
  const HistoryPage({super.key, required this.commonStyles});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with UseCommonStyles {
  var selectedIndex = 0;
  static const _navRailWidth = 72.0;
  static const _cardRadius = 16.0;
  // 添加导航项配置
  final _navItems = const [
    _NavigationItem(
      icon: Icons.play_lesson,
      label: "测评记录",
      selectedColor: Colors.blueAccent,
    ),
    _NavigationItem(
      icon: Icons.edit,
      label: "康复记录",
      selectedColor: Colors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;
    
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(title: Text("查看历史记录", style: commonStyles?.titleStyle?.copyWith(
          fontSize: 20,
          color: Colors.blueGrey[800]
        )),
        elevation: 0,
        centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 优化后的导航栏
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  child: Container(
                    width: _navRailWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIconTheme: IconThemeData(
                        color: _navItems[selectedIndex].selectedColor,
                        size: 28
                      ),
                      unselectedIconTheme: const IconThemeData(
                        size: 24,
                        color: Colors.grey
                      ),
                      extended: constraints.maxWidth >= 800,
                      minExtendedWidth: 175,
                      destinations: _navItems.map((item) => 
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(item.label),
                          ),
                        )).toList(),
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (value) => 
                        setState(() => selectedIndex = value),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 优化内容区域
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      key: ValueKey<int>(selectedIndex),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_cardRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildContentPage(selectedIndex),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  
  Widget _buildContentPage(int index) {
    switch (index) {
      case 0:
        return ExamRecordHistoryPage(commonStyles: commonStyles);
      case 1:
        return ExamRecordHistoryPage(
          recoveryMode: true,
          commonStyles: commonStyles,
        );
      default:
        return const Center(child: Text('页面不存在'));
    }
  }
}

// 新增私有类和方法
class _NavigationItem {
  final IconData icon;
  final String label;
  final Color selectedColor;

  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selectedColor = Colors.blueAccent,
  });
}