import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_all_exams.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login.dart';

class DoctorExamsManagementPage extends StatefulWidget {
  final CommonStyles? commonStyles;
  const DoctorExamsManagementPage({super.key, required this.commonStyles});

  @override
  State<DoctorExamsManagementPage> createState() => DoctorExamsManagementPageState();
}

class DoctorExamsManagementPageState extends State<DoctorExamsManagementPage> with UseCommonStyles {
  var selectedIndex = 0;

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

    Widget page;

    switch (selectedIndex) {
      case 0:
        page = DoctorAllExamsListPage(commonStyles: commonStyles);
        break;
      case 1:
        page = DoctorAllExamsListPage(commonStyles: commonStyles, isRecovery: true);
        break;
      default:
        throw UnimplementedError("Unsupported Index $selectedIndex");
    }

    var theme = Theme.of(context);
    var navigationRailTitleStyle = theme.textTheme.bodyLarge?.copyWith();

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey, width: 2.0),
                    top: BorderSide(color: Colors.grey, width: 2.0)
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: NavigationRail(
                        extended: constraints.maxWidth >= 800,
                        minExtendedWidth: 175,
                        destinations: [
                          NavigationRailDestination(
                            icon: const Icon(Icons.play_lesson_sharp),
                            label: Text("我的测评方案", style: navigationRailTitleStyle,),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.edit),
                            label: Text("我的康复方案", style: navigationRailTitleStyle,),
                          ),
                        ],
                        selectedIndex: selectedIndex,
                        onDestinationSelected: (value) {
                          setState(() {
                            selectedIndex = value;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
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
                                    onPressed: () async {
                                      await UserIdentity.logout();

                                      if (!context.mounted) {
                                        return;
                                      }

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
                            child: Text("退出登录", style: commonStyles?.bodyStyle,),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 2.0)
                    ),
                  ),
                  child: page
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}