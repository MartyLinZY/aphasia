import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/states/user_identity.dart';
import 'package:aphasia_recovery/utils/common_widget_function.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../states/question_set_states.dart';
import 'doctor/doctor_exams_management.dart';
import 'patient/home.dart';

class RegisterPage extends StatefulWidget {
  final CommonStyles? commonStyles;

  const RegisterPage({
    super.key,
    this.commonStyles,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with StateWithTextFields, TextFieldCommonValidators {
  // 添加样式常量
  static const _inputBorderRadius = 8.0;
  static const _buttonPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 24);
  static const _cardElevation = 4.0;
  Map<String, String> registerInfo = {};

  bool isDoctor = false;

  @override
  void initFieldSettings() {
    fieldsSetting['identity'] = FieldSetting(
      key: GlobalKey<FormFieldState>(debugLabel: "registerPhoneOrEmail"),
      ctrl: TextEditingController(),
      validator: (value) {
        String? errMsg = notEmptyValidator("手机/邮箱")(value);

        if (errMsg == null) {
          String val = value!;
          String emailPattern =
              r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
          RegExp regExp = RegExp(emailPattern);

          RegExp phoneRegex = RegExp(r'\d{11}');
          if (!regExp.hasMatch(val) && !phoneRegex.hasMatch(val)) {
            errMsg = "请输入邮箱或手机号";
          }
        }

        return errMsg;
      },
      reset: () => fieldsSetting['identity']!.ctrl.text = "",
      applyToModel: () => registerInfo['identity'] =
          fieldsSetting['identity']!.ctrl.text,
    );

    fieldsSetting['password'] = FieldSetting(
      key: GlobalKey<FormFieldState>(debugLabel: "registerPassword"),
      ctrl: TextEditingController(),
      validator: (value) {
        value = value ?? "";
        String? errMsg = notEmptyValidator("密码")(value);

        if (errMsg == null && (value.length > 15 || value.length <7)) {
          errMsg = "请设置长度为7-15的密码，当前长度${value.length}";
        }

        return errMsg;
      },
      reset: () => fieldsSetting['password']!.ctrl.text = "",
      applyToModel: () =>
          registerInfo['password'] = fieldsSetting['password']!.ctrl.text,
    );

    fieldsSetting['secondPassword'] = FieldSetting(
      key: GlobalKey<FormFieldState>(debugLabel: "registerPhoneOrEmail"),
      ctrl: TextEditingController(),
      validator: (value) {
        String? errMsg = notEmptyValidator("手机/邮箱")(value);

        if (errMsg == null &&
            fieldsSetting['secondPassword']?.ctrl.text !=
                fieldsSetting['password']?.ctrl.text) {
          return "两次输入的密码不一致";
        }

        return errMsg;
      },
      reset: () => fieldsSetting['secondPassword']!.ctrl.text = "",
      applyToModel: () => registerInfo['secondPassword'] =
          fieldsSetting['secondPassword']!.ctrl.text,
    );
  }

  @override
  void initState() {
    initFieldSettings();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    CommonStyles? commonStyles = widget.commonStyles;

    // return Scaffold(
    //   appBar: AppBar(title: Text("注册新用户", style: commonStyles?.bodyStyle)),
    //   body: SafeArea(
    //     child: Container(
    //       color: Theme.of(context).colorScheme.primaryContainer,
    //       child: Center(
    //         child: Padding(
    //           padding: const EdgeInsets.all(32.0),
    //           child: Container(
    //             constraints: const BoxConstraints(
    //               minWidth: 600,
    //               maxWidth: 1200,
    //               minHeight: 300,
    //             ),
    //             child: wrappedByCard(
    //               elevation: commonStyles?.widgetsElevation,
    //               child: SingleChildScrollView(
    //                 child: Form(
    //                     child: Column(
    //                   mainAxisSize: MainAxisSize.min,
    //                   children: [
    //                     Row(
    //                       children: [
    //                         Text(
    //                           "注册新用户",
    //                           style: commonStyles?.titleStyle,
    //                         ),
    //                       ],
    //                     ),
    //                     const Divider(
    //                       height: 32,
    //                     ),
    //                     Row(
    //                       children: [
    //                         Text(
    //                           "我是医生",
    //                           style: commonStyles?.bodyStyle,
    //                         ),
    //                         Checkbox(
    //                             value: isDoctor,
    //                             onChanged: (value) {
    //                               setState(() {
    //                                 isDoctor = value ?? false;
    //                               });
    //                             }),
    //                       ],
    //                     ),
    //                     const SizedBox(
    //                       height: 16,
    //                     ),
    //                     buildInputFormField(
    //                         "手机号/邮箱：",
    //                         fieldsSetting['identity']!.key,
    //                         fieldsSetting['identity']!.ctrl,
    //                         fieldsSetting['identity']!.validator,
    //                         width: 200,
    //                         commonStyles: commonStyles),
    //                     const SizedBox(
    //                       height: 16,
    //                     ),
    //                     buildInputFormField(
    //                         "密码：",
    //                         fieldsSetting['password']!.key,
    //                         fieldsSetting['password']!.ctrl,
    //                         fieldsSetting['password']!.validator,
    //                         width: 200,
    //                         commonStyles: commonStyles,
    //                         obscureText: true,
    //                         enableSuggestions: false,
    //                         autocorrect: false),
    //                     const SizedBox(
    //                       height: 16,
    //                     ),
    //                     buildInputFormField(
    //                         "再次输入密码：",
    //                         fieldsSetting['secondPassword']!.key,
    //                         fieldsSetting['secondPassword']!.ctrl,
    //                         fieldsSetting['secondPassword']!.validator,
    //                         width: 200,
    //                         commonStyles: commonStyles,
    //                         obscureText: true,
    //                         enableSuggestions: false,
    //                         autocorrect: false),
    //                     const Divider(
    //                       height: 32,
    //                     ),
    //                     Padding(
    //                       padding: const EdgeInsets.only(bottom: 8.0),
    //                       child: Row(
    //                         children: [
    //                           ElevatedButton(
    //                             onPressed: () async {
    //                               if (applyFieldsChangesToModel()) {
    //                                 registerInfo['role'] = isDoctor ? "2" : "1" ;

    //                                 final userIdentity = await UserIdentity.register(registerInfo).catchError((err) {
    //                                   requestResultErrorHandler(context, error: err);
    //                                   return err;
    //                                 });

    //                                 if (!context.mounted) {
    //                                   return;
    //                                 }

    //                                 if (userIdentity == null) {
    //                                   toast(context, msg: "该用户已注册，请返回登录页面登录", btnText: "确认");
    //                                   return;
    //                                 }

    //                                 context.read<SingleModelState<UserIdentity>>().model = userIdentity;

    //                                 Navigator.pushReplacement(context,
    //                                     MaterialPageRoute(
    //                                         builder: (context) => ChangeNotifierProvider<UserIdentity>.value(
    //                                           value: userIdentity,
    //                                           child: userIdentity.isDoctor
    //                                               ? DoctorExamsManagementPage(commonStyles: commonStyles)
    //                                               : HomePage(commonStyles: commonStyles,),
    //                                         )));
    //                               }
    //                             },
    //                             style: ElevatedButton.styleFrom(backgroundColor: commonStyles?.primaryColor),
    //                             child: Text(
    //                               "注册",
    //                               style: commonStyles?.bodyStyle?.copyWith(
    //                                   color: commonStyles.onPrimaryColor),
    //                             ),
    //                           ),
    //                         ],
    //                       ),
    //                     )
    //                   ],
    //                 )),
    //               ),
    //             ),
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(
        title: Text("用户注册", style: commonStyles?.titleStyle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: _cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Form(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRoleToggle(commonStyles),
                            const SizedBox(height: 24),
                            _buildInputField(
                              label: '手机号/邮箱',
                              fieldKey: fieldsSetting['identity']!.key,
                              controller: fieldsSetting['identity']!.ctrl,
                              validator: fieldsSetting['identity']!.validator,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: '密码',
                              controller: fieldsSetting['password']!.ctrl,
                              validator: fieldsSetting['password']!.validator,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              label: '确认密码',
                              controller: fieldsSetting['secondPassword']!.ctrl,
                              validator: fieldsSetting['secondPassword']!.validator,
                            ),
                            const SizedBox(height: 32),
                            _buildRegisterButton(commonStyles),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 新增角色切换组件
  Widget _buildRoleToggle(CommonStyles? commonStyles) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text("普通用户", style: commonStyles?.bodyStyle),
            selected: !isDoctor,
            onSelected: (val) => setState(() => isDoctor = !val),
            selectedColor: commonStyles?.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ChoiceChip(
            label: Text("医疗人员", style: commonStyles?.bodyStyle),
            selected: isDoctor,
            onSelected: (val) => setState(() => isDoctor = val),
            selectedColor: commonStyles?.primaryColor,
          ),
        ),
      ],
    );
  }

  // 新增通用输入框构建方法
  Widget _buildInputField({
    required String label,
    required GlobalKey<FormFieldState> fieldKey,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
        ),
        prefixIcon: const Icon(Icons.person_outline),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // 密码输入框组件
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius),
        ),
        prefixIcon: const Icon(Icons.lock_outline),
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  // 注册按钮组件
  Widget _buildRegisterButton(CommonStyles? commonStyles) {
    bool isLoading = false;
    
    return ElevatedButton.icon(
      icon: isLoading ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.app_registration),
      label: Text(isLoading ? "注册中..." : "立即注册"),
      style: ElevatedButton.styleFrom(
        padding: _buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_inputBorderRadius)
        ),
      ),
      onPressed: () async {
        if (isLoading) return;
        
        setState(() => isLoading = true);
        await _handleRegister(widget.commonStyles);
        if (mounted) setState(() => isLoading = false);
      },
    );
  }

  // 优化后的注册处理逻辑
  Future<void> _handleRegister(CommonStyles? commonStyles) async {  // 添加 Future 返回值
    if (!applyFieldsChangesToModel()) return;
    
    registerInfo['role'] = isDoctor ? "2" : "1";
    
    try {
      final userIdentity = await UserIdentity.register(registerInfo);
      if (!mounted) return;

      if (userIdentity == null) {
        showErrorToast(context, "注册失败，用户已存在", commonStyles);
        return;
      }
      
      _navigateToHome(userIdentity, commonStyles);
    } catch (err) {
      if (!mounted) return;
      showErrorToast(context, "注册失败: ${err.toString()}", commonStyles);
    }
  }

  // 新增错误提示方法
  void showErrorToast(BuildContext context, String msg, CommonStyles? commonStyles) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: commonStyles?.bodyStyle),
        backgroundColor: commonStyles?.errorColor ?? Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 新增导航方法
  void _navigateToHome(UserIdentity identity, CommonStyles? commonStyles) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: identity,
          child: identity.isDoctor
              ? DoctorExamsManagementPage(commonStyles: commonStyles)
              : HomePage(commonStyles: commonStyles),
        ),
      ),
    );
  }
}
