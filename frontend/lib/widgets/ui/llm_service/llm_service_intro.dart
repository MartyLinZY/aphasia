import 'package:flutter/material.dart';
import 'package:aphasia_recovery/widgets/ui/llm_service/llm_navigation.dart';
import '../../../mixin/widgets_mixin.dart';

class LLMServiceIntroPage extends StatelessWidget {
  final CommonStyles? commonStyles;
  const LLMServiceIntroPage({Key? key, this.commonStyles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bodyStyle =
        commonStyles?.bodyStyle ?? Theme.of(context).textTheme.bodyMedium;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.green[700], size: 32),
                const SizedBox(width: 12),
                Text('人工智能服务',
                    style: bodyStyle?.copyWith(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '本系统使用了大语言模型(LLM)等人工智能技术，为医生与失语症患者提供针对性的服务。',
              style: bodyStyle?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              '功能简介：',
              style: bodyStyle?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              '1. 对话诊断：分析医生与患者的对话内容，判断患病类型与严重程度。\n'
              '2. 语句修复：修复患者的语句，使其更易于理解。\n',
              style: bodyStyle?.copyWith(fontSize: 15, color: Colors.grey[700]),
            ),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LLMNavigation(
                        bodyStyle: commonStyles?.bodyStyle,
                      ),
                    ),
                  );
                },
                child: const Text('进入人工智能服务'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}