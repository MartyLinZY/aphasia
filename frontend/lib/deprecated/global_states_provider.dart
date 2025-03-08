import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 全局状态管理
class GlobalStatesProviders extends StatelessWidget {
  final Widget _child;

  const GlobalStatesProviders({
    super.key,
    required Widget child
  })  :  _child = child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
      ],
      child: _child,
    );
  }
}