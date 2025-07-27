import 'package:flutter/material.dart';
import 'package:aphasia_recovery/widgets/ui/llm_service/llm_diagnose.dart';
import 'package:aphasia_recovery/widgets/ui/llm_service/llm_repair.dart';

class LLMNavigation extends StatefulWidget {
  final TextStyle? bodyStyle;
  const LLMNavigation({Key? key, this.bodyStyle}) : super(key: key);

  @override
  State<LLMNavigation> createState() => _LLMNavigationState();
}

class _LLMNavigationState extends State<LLMNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航栏
          Material(
            elevation: 4,
            child: Container(
              width: 72,
              color: const Color(0xFFFFF5F5),
              child: NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.teal),
                    label: Text('对话诊断'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.build, color: Color(0xFFBA68C8)),
                    label: Text('语句修复'),
                  ),
                ],
              ),
            ),
          ),
          
          // 右侧内容区
          Expanded(
            child: _selectedIndex == 0 
              ? LLMDiagnosePage(bodyStyle: widget.bodyStyle)
              : LLMRepairPage(bodyStyle: widget.bodyStyle),
          ),
        ],
      ),
    );
  }
}