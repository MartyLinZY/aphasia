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

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    UserIdentity userIdentity = context.watch<UserIdentity>();
    Widget page;

    switch (selectedNavIndex) {
      case 0:
        page = SearchPage(commonStyles: commonStyles);
        break;
      case 1:
        page = Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryPage(commonStyles: commonStyles,)));
            },
            child: Text("查看测评或康复历史记录", style: commonStyles?.bodyStyle,),
          ),
        );
        break;
      default:
        throw UnimplementedError("No such Navigation Rail index $selectedNavIndex");
    }

    var navigationRailTitleStyle = commonStyles?.bodyStyle;

    return LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: NavigationRail(
                          extended: constraints.maxWidth >= 1200,
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.search),
                              label: Text(userIdentity.isDoctor ? '套题管理' : "搜索", style: navigationRailTitleStyle),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.person),
                              label: Text('我的', style: navigationRailTitleStyle),
                            ),
                          ],
                          selectedIndex: selectedNavIndex,
                          onDestinationSelected: (value) {
                            setState(() {
                              selectedNavIndex = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                            onPressed: (){
                              showDialog(context: context, builder: (context) => AlertDialog(
                                title: Text("退出登录", style: commonStyles?.bodyStyle,),
                                content: const Text("确认要退出当前账号吗"),
                                actions: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("取消"),
                                  ),

                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(commonStyles: commonStyles,)));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: commonStyles?.primaryColor,
                                      // foregroundColor: theme.buttonTheme.colorScheme?.primary,
                                    ),
                                    child: Text("确认",
                                      style: commonStyles?.bodyStyle?.copyWith(color: commonStyles?.onPrimaryColor),
                                    ),
                                  ),

                                ],
                              ));
                            },
                            child: const Text("退出登录"),

                          )
                        )
                      )
                    ],
                  ),
                  Expanded(
                    // take rest of space
                    child: Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: page,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
}