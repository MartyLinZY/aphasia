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
    // 添加样式常量
  static const _inputBorderRadius = 8.0;
  static const _buttonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 24);
  static const _cardElevation = 4.0;
  static const _formMaxWidth = 400.0;
  
  final bool isEntry;
  final CommonStyles? commonStyles;
  const LoginForm({super.key, this.isEntry = true, required this.commonStyles});

  @override
  State<StatefulWidget> createState() => _LoginFormState();

}

class _LoginFormState extends State<LoginForm> with UseCommonStyles {
  // 添加加载状态
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var usernameController = TextEditingController();
  var validateCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    commonStyles = widget.commonStyles;

    // return Container(
    //   constraints: const BoxConstraints(maxHeight: 250),
    //   child: Card(
    //     child: Padding(
    //       padding: const EdgeInsets.all(16.0),
    //       child: SizedBox(
    //         width: 400,
    //         child: Form(
    //           key: _formKey,
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.center,
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             mainAxisSize: MainAxisSize.min,
    //             children: <Widget>[
    //               SizedBox(
    //                 width: 400,
    //                 child: TextFormField(
    //                   controller: usernameController,
    //                   decoration: const InputDecoration(
    //                     hintText: '手机号/邮箱',
    //                   ),
    //                   validator: (String? value) {
    //                     if (value == null || value.isEmpty) {
    //                       return '请输入手机号和邮箱';
    //                     }
    //                     return null;
    //                   },
    //                 ),
    //               ),
    //               const SizedBox(height: 10),
    //               SizedBox(
    //                 width: 400,
    //                 child: TextFormField(
    //                   controller: validateCodeController,
    //                   obscureText: true,
    //                   enableSuggestions: false,
    //                   autocorrect: false,
    //                   decoration: const InputDecoration(
    //                     hintText: '密码',
    //                   ),
    //                   validator: (String? value) {
    //                     if (value == null || value.isEmpty) {
    //                       return '请输入密码';
    //                     }
    //                     return null;
    //                   },
    //                 ),
    //               ),
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
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 16.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.end,
                  //     children: [
                  //       ElevatedButton(
                  //         onPressed: () async {
                  //           Navigator.pushReplacement(context,
                  //               MaterialPageRoute(
                  //                   builder: (context) => const RegisterPage()));
                  //         },
                  //         child: Text('注册', style: commonStyles?.bodyStyle,),
                  //       ),
                  //       const SizedBox(width: 16,),
                  //       ElevatedButton(
                  //         onPressed: () async {
                  //           // Validate will return true if the form is valid, or false if
                  //           // the form is invalid.
                  //           if (_formKey.currentState!.validate()) {
                  //             // Process data.
                  //             final userIdentity = await UserIdentity.login(
                  //               identity: usernameController.text,
                  //               password: validateCodeController.text,
                  //             );

                  //             if (!context.mounted) {
                  //               return;
                  //             }

                  //             if (userIdentity == null) {
                  //               toast(context, msg: "用户名或密码错误，请重新输入", btnText: "确认");
                  //               return;
                  //             }

                  //             context.read<SingleModelState<UserIdentity>>().model = userIdentity;

                  //             if (widget.isEntry) {
                  //               Navigator.pushReplacement(context,
                  //                   MaterialPageRoute(
                  //                       builder: (context) => ChangeNotifierProvider<UserIdentity>.value(
                  //                         value: userIdentity,
                  //                         child: userIdentity.isDoctor
                  //                             ? DoctorExamsManagementPage(commonStyles: commonStyles)
                  //                             : HomePage(commonStyles: commonStyles,),
                  //                       )));
                  //             } else {
                  //               // 现在应该不会到这个分支
                  //               Navigator.pop(context);
                  //             }
                  //           }
                  //         },
                  //         child: Text("登录", style: commonStyles?.bodyStyle,),
                  //       ),
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
    //                   ],
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return Container(
      constraints: const BoxConstraints(maxWidth: LoginForm._formMaxWidth),
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: LoginForm._cardElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 用户名输入框
                _buildInputField(
                  controller: usernameController,
                  label: '手机号/邮箱',
                  icon: Icons.person_outline,
                  validator: _validateUsername,
                ),
                const SizedBox(height: 20),
                // 密码输入框
                _buildPasswordField(),
                const SizedBox(height: 32),
                // 操作按钮区域
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 新增通用输入框构建方法
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: commonStyles?.primaryColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LoginForm._inputBorderRadius),
        ),
      ),
      validator: validator,
    );
  }

  // 优化后的密码输入框
  Widget _buildPasswordField() {
    return TextFormField(
      controller: validateCodeController,
      obscureText: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: commonStyles?.primaryColor),
        labelText: '密码',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LoginForm._inputBorderRadius),
        ),
      ),
      validator: (value) => value?.isEmpty ?? true ? '请输入密码' : null,
    );
  }

  // 操作按钮区域
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 注册按钮
        TextButton(
          onPressed: _isLoading ? null : () => _navigateToRegister(),
          child: Text('立即注册', style: commonStyles?.bodyStyle?.copyWith(
            color: commonStyles?.primaryColor,
            fontWeight: FontWeight.bold
          )),
        ),
        // 登录按钮
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: LoginForm._buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoginForm._inputBorderRadius)
            ),
          ),
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('登录', style: commonStyles?.bodyStyle),
        ),
      ],
    );
  }

  // 用户名验证逻辑
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return '请输入登录信息';
    final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    final isPhone = RegExp(r'^1[3-9]\d{9}$').hasMatch(value);
    return isEmail || isPhone ? null : '请输入有效的手机号或邮箱';
  }

  // 登录处理逻辑
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final userIdentity = await UserIdentity.login(
      identity: usernameController.text,
      password: validateCodeController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userIdentity == null) {
      showErrorToast(context, "用户名或密码错误");
      return;
    }

    // 添加导航逻辑
    if (widget.isEntry) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: userIdentity,
            child: userIdentity.isDoctor
                ? DoctorExamsManagementPage(commonStyles: commonStyles)
                : HomePage(commonStyles: commonStyles),
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _navigateToRegister() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // 添加Toast提示方法
  void showErrorToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: commonStyles?.bodyStyle),
        backgroundColor: commonStyles?.errorColor ?? Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LoginForm._inputBorderRadius),
        ),
      ),
    );
  }
}