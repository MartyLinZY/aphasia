import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:aphasia_recovery/widgets/ui/doctor/doctor_exams_management.dart';
import 'package:aphasia_recovery/widgets/ui/register.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mixin/widgets_mixin.dart';
import '../../states/question_set_states.dart';
import '../../states/user_identity.dart';
import 'patient/home.dart';

class LoginPage extends StatelessWidget {
  final bool isEntry;
  final CommonStyles? commonStyles;
  const LoginPage({super.key, this.isEntry = true, required this.commonStyles});

  @override
  Widget build(BuildContext context) {
    // final userIdentity = context.read<UserIdentity>();
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
    //   bool authed = await Us.authWithToken();
    //   if (authed && context.mounted) {
    //     final updatedUserIdentity = context.read<UserIdentity>();
    //
    //     Navigator.pushReplacement(context,
    //         MaterialPageRoute(
    //             builder: (context) => updatedUserIdentity.isDoctor
    //                 ? DoctorExamsManagementPage(commonStyles: commonStyles)
    //                 : HomePage(commonStyles: commonStyles,)));
    //   }
    // });

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: SingleChildScrollView(child: LoginForm(isEntry: isEntry, commonStyles: commonStyles,)),
          ),
        ),
      ),
    );
  }

}

class LoginForm extends StatefulWidget {
  final bool isEntry;
  final CommonStyles? commonStyles;
  const LoginForm({super.key, this.isEntry = true, required this.commonStyles});

  @override
  State<StatefulWidget> createState() => _LoginFormState();

}

class _LoginFormState extends State<LoginForm> with UseCommonStyles {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var usernameController = TextEditingController();
  var validateCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        hintText: '手机号/邮箱',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return '请输入手机号和邮箱';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: validateCodeController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: '密码',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                  ),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextFormField(
                  //         controller: validateCodeController,
                  //         decoration: const InputDecoration(
                  //           hintText: '验证码',
                  //         ),
                  //         validator: (String? value) {
                  //           if (value == null || value.isEmpty) {
                  //             return '请输入验证码';
                  //           }
                  //           return null;
                  //         },
                  //       ),
                  //     ),
                  //     const SizedBox(width: 5,),
                  //     ElevatedButton(
                  //         onPressed: () {
                  //           setState(() {
                  //             validateCodeController.value = const TextEditingValue(text: "123456");
                  //           });
                  //         },
                  //         child: const Text("获取验证码"))
                  //   ],
                  // ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                                    builder: (context) => const RegisterPage()));
                          },
                          child: Text('注册', style: commonStyles?.bodyStyle,),
                        ),
                        const SizedBox(width: 16,),
                        ElevatedButton(
                          onPressed: () async {
                            // Validate will return true if the form is valid, or false if
                            // the form is invalid.
                            if (_formKey.currentState!.validate()) {
                              // Process data.
                              final userIdentity = await UserIdentity.login(
                                identity: usernameController.text,
                                password: validateCodeController.text,
                              );

                              if (!context.mounted) {
                                return;
                              }

                              if (userIdentity == null) {
                                toast(context, msg: "用户名或密码错误，请重新输入", btnText: "确认");
                                return;
                              }

                              context.read<SingleModelState<UserIdentity>>().model = userIdentity;

                              if (widget.isEntry) {
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(
                                        builder: (context) => ChangeNotifierProvider<UserIdentity>.value(
                                          value: userIdentity,
                                          child: userIdentity.isDoctor
                                              ? DoctorExamsManagementPage(commonStyles: commonStyles)
                                              : HomePage(commonStyles: commonStyles,),
                                        )));
                              } else {
                                // 现在应该不会到这个分支
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: Text("登录", style: commonStyles?.bodyStyle,),
                        ),
                        // TextButton(
                        //   onPressed: () {
                        //     // TODO: 做一个单独的测评入口，导到内置测评界面即可
                        //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Placeholder()));
                        //   },
                        //   child: const Text("快速体验测评>>")
                        // ),
                        // Expanded(
                        //   child: Align(
                        //     alignment: Alignment.centerRight,
                        //     child: TextButton(
                        //       onPressed: () {
                        //         Navigator.push(context, MaterialPageRoute(builder: (context) => const Placeholder()));
                        //       },
                        //       child: const Text("我是医生")
                        //     ),
                        //   ),
                        // )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}