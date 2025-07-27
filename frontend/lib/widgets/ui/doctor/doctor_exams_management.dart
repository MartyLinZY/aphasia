import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_all_exams.dart';
import 'package:flutter/material.dart';
import '../login.dart';
import 'package:aphasia_recovery/widgets/ui/llm_service/llm_service_intro.dart';

class DoctorExamsManagementPage extends StatefulWidget {
  final CommonStyles? commonStyles;
  const DoctorExamsManagementPage({super.key, required this.commonStyles});

  @override
  State<DoctorExamsManagementPage> createState() =>
      DoctorExamsManagementPageState();
}

class DoctorExamsManagementPageState extends State<DoctorExamsManagementPage>
    with UseCommonStyles {
  var selectedIndex = 0;
  // 新增样式常量
  static const _navRailWidth = 72.0;
  static const _extendedNavWidth = 200.0;
  static const _sectionPadding = EdgeInsets.all(16.0);
  static const _cardRadius = 12.0;

  final List<_DoctorNavItem> _navItems = const [
    _DoctorNavItem(icon: Icons.play_lesson_sharp, label: '我的测评方案'),
    _DoctorNavItem(icon: Icons.edit, label: '我的康复方案'),
    _DoctorNavItem(icon: Icons.smart_toy, label: '人工智能服务'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;
    final theme = Theme.of(context);
    var navigationRailTitleStyle = theme.textTheme.bodyLarge;

    // Widget page;

    // switch (selectedIndex) {
    //   case 0:
    //     page = DoctorAllExamsListPage(commonStyles: commonStyles);
    //     break;
    //   case 1:
    //     page = DoctorAllExamsListPage(commonStyles: commonStyles, isRecovery: true);
    //     break;
    //   default:
    //     throw UnimplementedError("Unsupported Index $selectedIndex");
    // }

    // var navigationRailTitleStyle = theme.textTheme.bodyLarge?.copyWith();

    // return LayoutBuilder(builder: (context, constraints) {
    //   return Scaffold(
    //     body: SafeArea(
    //       child: Row(
    //         children: [
    //           Container(
    //             decoration: const BoxDecoration(
    //               border: Border(
    //                 right: BorderSide(color: Colors.grey, width: 2.0),
    //                 top: BorderSide(color: Colors.grey, width: 2.0)
    //               )
    //             ),
    //             child: Column(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Expanded(
    //                   child: NavigationRail(
    //                     extended: constraints.maxWidth >= 800,
    //                     minExtendedWidth: 175,
    //                     destinations: [
    //                       NavigationRailDestination(
    //                         icon: const Icon(Icons.play_lesson_sharp),
    //                         label: Text("我的测评方案", style: navigationRailTitleStyle,),
    //                       ),
    //                       NavigationRailDestination(
    //                         icon: const Icon(Icons.edit),
    //                         label: Text("我的康复方案", style: navigationRailTitleStyle,),
    //                       ),
    //                     ],
    //                     selectedIndex: selectedIndex,
    //                     onDestinationSelected: (value) {
    //                       setState(() {
    //                         selectedIndex = value;
    //                       });
    //                     },
    //                   ),
    //                 ),
    //                 Row(
    //                   mainAxisAlignment: MainAxisAlignment.center,
    //                   mainAxisSize: MainAxisSize.max,
    //                   children: [
    //                     Padding(
    //                       padding: const EdgeInsets.all(16.0),
    //                       child: ElevatedButton(
    //                         onPressed: (){
    //                           showDialog(context: context, builder: (context) => AlertDialog(
    //                             title: Text("退出登录", style: commonStyles?.bodyStyle,),
    //                             content: const Text("确认要退出当前账号吗"),
    //                             actions: [
    //                               ElevatedButton(
    //                                 onPressed: () {
    //                                   Navigator.pop(context);
    //                                 },
    //                                 child: const Text("取消"),
    //                               ),

    //                               ElevatedButton(
    //                                 onPressed: () async {
    //                                   await UserIdentity.logout();

    //                                   if (!context.mounted) {
    //                                     return;
    //                                   }

    //                                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(commonStyles: commonStyles,)));
    //                                 },
    //                                 style: ElevatedButton.styleFrom(
    //                                   backgroundColor: commonStyles?.primaryColor,
    //                                   // foregroundColor: theme.buttonTheme.colorScheme?.primary,
    //                                 ),
    //                                 child: Text("确认",
    //                                   style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),
    //                                 ),
    //                               ),

    //                             ],
    //                           ));
    //                         },
    //                         child: Text("退出登录", style: commonStyles?.bodyStyle,),
    //                       ),
    //                     ),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),
    //           Expanded(
    //             child: Container(
    //               decoration: const BoxDecoration(
    //                 border: Border(
    //                   top: BorderSide(color: Colors.grey, width: 2.0)
    //                 ),
    //               ),
    //               child: page
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // });

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                    border: Border(
                        right: BorderSide(color: Colors.grey, width: 2.0),
                        top: BorderSide(color: Colors.grey, width: 2.0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NavigationRail(
                        extended: constraints.maxWidth >= 800,
                        minExtendedWidth: 175,
                        destinations: _navItems
                            .map((item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label,
                              style: navigationRailTitleStyle),
                        ))
                            .toList(),
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (value) {
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                      ),
                    ),
                    _buildLogoutSection(),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: _sectionPadding,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildCurrentPage(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 封装的导航栏组件
  Widget _buildNavigationRail(BoxConstraints constraints) {
    return Container(
      width: constraints.maxWidth >= 800 ? _extendedNavWidth : _navRailWidth,
      decoration:
      BoxDecoration(color: Colors.grey.withOpacity(0.1), boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(2, 0))
      ]),
      child: Column(
        children: [
          Expanded(
            child: NavigationRail(
              extended: constraints.maxWidth >= 800,
              minExtendedWidth: _extendedNavWidth,
              backgroundColor: Colors.white.withOpacity(0.4),
              selectedIconTheme:
              IconThemeData(color: Colors.black.withOpacity(0.8)),
              unselectedIconTheme:
              IconThemeData(color: Colors.grey.withOpacity(0.8)),
              labelType: constraints.maxWidth >= 800
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              destinations: [
                _buildNavDestination(Icons.play_lesson_sharp, "我的测评方案"),
                _buildNavDestination(Icons.edit, "我的康复方案"),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => selectedIndex = value),
            ),
          ),
          _buildLogoutSection()
        ],
      ),
    );
  }

  // 统一的导航项样式
  NavigationRailDestination _buildNavDestination(IconData icon, String label) {
    return NavigationRailDestination(
      icon: Icon(icon, size: 24),
      selectedIcon: Icon(icon, size: 28),
      label: Text(label,
          style:
          commonStyles?.bodyStyle?.copyWith(fontWeight: FontWeight.w500)),
    );
  }

  // 优化退出登录区块
  Widget _buildLogoutSection() {
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

  // 封装的退出确认弹窗
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

  // 新增当前页面构建方法
  Widget _buildCurrentPage() {
    switch (selectedIndex) {
      case 0:
        return DoctorAllExamsListPage(
            commonStyles: commonStyles, cardRadius: _cardRadius);
      case 1:
        return DoctorAllExamsListPage(
            commonStyles: commonStyles,
            isRecovery: true,
            cardRadius: _cardRadius);
      case 2:
        return LLMServiceIntroPage(commonStyles: commonStyles);
      default:
        return Center(
            child: Text('页面未找到',
                style: commonStyles?.titleStyle
                    ?.copyWith(color: commonStyles?.errorColor)));
    }
  }
}

class _DoctorNavItem {
  final IconData icon;
  final String label;
  const _DoctorNavItem({required this.icon, required this.label});
}
