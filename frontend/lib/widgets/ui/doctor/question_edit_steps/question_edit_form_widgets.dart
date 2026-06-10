import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:flutter/material.dart';

class DecoratedTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final GlobalKey<FormFieldState> fieldKey;
  final FormFieldValidator<String?> validator;
  final int? maxLength;
  final CommonStyles commonStyles;

  const DecoratedTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.fieldKey,
    required this.validator,
    required this.commonStyles,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: TextFormField(
        controller: controller,
        key: fieldKey,
        validator: validator,
        maxLength: maxLength,
        style: commonStyles.bodyStyle,
      ),
    );
  }
}

class MediaSection extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback setAction;
  final VoidCallback clearAction;
  final IconData icon;
  final Widget? extraContent;
  final CommonStyles commonStyles;

  const MediaSection({
    super.key,
    required this.title,
    required this.value,
    required this.setAction,
    required this.clearAction,
    required this.icon,
    required this.commonStyles,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: commonStyles.titleStyle),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value ?? "未设置",
                    style: commonStyles.bodyStyle?.copyWith(
                      color: value != null
                          ? commonStyles.primaryColor
                          : commonStyles.primaryColor?.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                _MediaButton(
                  label: value != null ? "重新设置" : "设置",
                  icon: icon,
                  onPressed: setAction,
                  commonStyles: commonStyles,
                ),
                if (value != null) ...[
                  const SizedBox(width: 8),
                  _MediaButton(
                    label: "清除",
                    icon: Icons.delete,
                    color: commonStyles.errorColor,
                    onPressed: clearAction,
                    commonStyles: commonStyles,
                  )
                ]
              ],
            ),
          ),
        ),
        if (extraContent != null) extraContent!,
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;
  final CommonStyles commonStyles;

  const _MediaButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.commonStyles,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: TextButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: color ?? commonStyles.primaryColor,
          backgroundColor: color?.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class ImageOmitTimeField extends StatelessWidget {
  final bool visible;
  final TextEditingController controller;
  final GlobalKey<FormFieldState> fieldKey;
  final FormFieldValidator<String?> validator;
  final CommonStyles commonStyles;

  const ImageOmitTimeField({
    super.key,
    required this.visible,
    required this.controller,
    required this.fieldKey,
    required this.validator,
    required this.commonStyles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Visibility(
          visible: visible,
          child: Column(
            children: [
              DecoratedTextField(
                label: "图片展示时间（秒）：",
                controller: controller,
                fieldKey: fieldKey,
                validator: validator,
                commonStyles: commonStyles,
              ),
              const SizedBox(height: 8),
              Text(
                "提示：场景寻物题设为-1保持显示\n其他题型最大${Question.maxOmitTime}秒",
                style: commonStyles.hintTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
