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

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    Widget page;

    switch (selectedIndex) {
      case 0:
        page = ExamRecordHistoryPage(commonStyles: commonStyles,);
      case 1:
        page = ExamRecordHistoryPage(recoveryMode: true, commonStyles: commonStyles,);
        break;
      default:
        throw UnimplementedError("Unsupported Index $selectedIndex");
    }

    var theme = Theme.of(context);
    var navigationRailTitleStyle = theme.textTheme.bodyLarge?.copyWith();

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(title: Text("查看历史记录", style: commonStyles?.titleStyle,),),
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
                            icon: const Icon(Icons.play_lesson),
                            label: Text("测评记录", style: navigationRailTitleStyle,),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.edit),
                            label: Text("康复记录", style: navigationRailTitleStyle,),
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: page,
                    )
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}