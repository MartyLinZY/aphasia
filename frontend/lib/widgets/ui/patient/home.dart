import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/patient/history.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:aphasia_recovery/deprecated/recovery_entry.dart';
import 'package:aphasia_recovery/widgets/ui/patient/search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../mixin/widgets_mixin.dart';

class HomePage extends StatefulWidget {
  final CommonStyles? commonStyles;
  const HomePage({super.key, required this.commonStyles});

  @override
  State<StatefulWidget> createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> with UseCommonStyles {
  var selectedNavIndex = 0;
  static const _cardRadius = 16.0;
  static const _navRailWidth = 72.0;
  final _navItems = const [
     _NavigationItem(
      icon: Icons.search,
      label: "搜索",
      selectedColor: Colors.blueAccent,
    ),
     _NavigationItem(
      icon: Icons.person,
      label: "我的",
      selectedColor: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    UserIdentity userIdentity = context.watch<UserIdentity>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // 优化导航栏
                      Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(_cardRadius),
                        child: Container(
                          width: _navRailWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_cardRadius),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: NavigationRail(
                                  backgroundColor: Colors.transparent,
                                  selectedIconTheme: IconThemeData(
                                    color: _navItems[selectedNavIndex].selectedColor,
                                    size: 28,
                                  ),
                                  unselectedIconTheme: const IconThemeData(
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                  extended: constraints.maxWidth >= 1200,
                                  destinations: _navItems.map((item) => 
                                    NavigationRailDestination(
                                      icon: Icon(item.icon),
                                      label: Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          userIdentity.isDoctor ? '套题管理' : item.label,
                                          style: commonStyles?.bodyStyle,
                                        ),
                                      ),
                                    )).toList(),
                                  selectedIndex: selectedNavIndex,
                                  onDestinationSelected: (value) => 
                                    setState(() => selectedNavIndex = value),
                                ),
                              ),
                              _buildLogoutButton(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // 优化内容区域
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Card(
                            key: ValueKey<int>(selectedNavIndex),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_cardRadius),
                            ),
                            child: _buildContentPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  Widget _buildContentPage() {
    final userIdentity = context.watch<UserIdentity>();
    
    switch (selectedNavIndex) {
      case 0:
        return userIdentity.isDoctor 
            ? DoctorExamsManagementPage(commonStyles: commonStyles)
            : SearchPage(commonStyles: commonStyles);
      case 1:
        return HistoryPage(commonStyles: commonStyles); // 直接返回历史记录页
      default:
        return const Center(child: Text('页面不存在'));
    }
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: IconButton(
        icon: const Icon(Icons.logout),
        color: Colors.redAccent,
        tooltip: '退出登录',
        onPressed: () => _showLogoutConfirmation(),
      ),
    );
  }

  // 修改后的退出登录弹窗
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("退出登录", style: commonStyles?.titleStyle),
        content: const Text("确认要退出当前账号吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(commonStyles: commonStyles),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("确认退出"),
          ),
        ],
      ),
    );
  }
}
// 新增私有组件和方法
class _NavigationItem {
  final IconData icon;
  final String label;
  final Color selectedColor;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selectedColor,
  });
}