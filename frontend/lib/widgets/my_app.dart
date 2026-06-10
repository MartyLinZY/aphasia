import 'dart:math';

import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/question_set_states.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../states/user_identity.dart';
import 'ui/patient/home.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with UseCommonStyles {
  late Future<UserIdentity?> loginFuture = Future(() => null);

  @override
  void initState() {
    super.initState();
    loginFuture = UserIdentity.authWithToken();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SingleModelState<UserIdentity>>(
      create: (context) => SingleModelState<UserIdentity>(null),
      child: MaterialApp(
        title: '灵光',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        ),
        home: Builder(
          builder: (context) {
            var mediaSize = MediaQuery.of(context).size;
            commonStyles = initStyles(context);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 400, minHeight: 150, maxHeight: max(150, mediaSize.height), maxWidth: max(400,mediaSize.width)),
                child: FutureBuilder(
                  future: loginFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final identity = snapshot.data!;
                      context.read<SingleModelState<UserIdentity>>().model = identity;

                      debugPrint("已登录，用户信息：uid = ${identity.uid}；role = ${identity.isDoctor ? "医生": "患者"}；identity = ${identity.identity}");

                      return ChangeNotifierProvider<UserIdentity>.value(
                        value: identity,
                        child: Builder(
                          builder: (context) {
                            return identity.isDoctor
                                ? DoctorExamsManagementPage(commonStyles: commonStyles)
                                : HomePage(commonStyles: commonStyles,);
                          },
                        ),
                      );
                    } else if (snapshot.hasError) {
                      debugPrint(snapshot.error.toString());

                      return const Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator()
                              ),
                              SizedBox(height: 16,),
                              Text("网络错误，请重启应用尝试。", style: TextStyle(fontSize: 20),)
                            ],
                          ),
                        ),
                      );
                    } else {
                      debugPrint("没有有效的Token，前往登录页面");
                      return LoginPage(commonStyles: commonStyles,);
                    }
                  }
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
