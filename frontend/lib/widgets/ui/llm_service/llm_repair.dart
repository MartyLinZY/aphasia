import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/mixin/widgets_mixin.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';

class LLMRepairPage extends StatefulWidget {
  final TextStyle? bodyStyle;
  const LLMRepairPage({Key? key, this.bodyStyle}) : super(key: key);

  @override
  State<LLMRepairPage> createState() => _LLMRepairPageState();
}

class _LLMRepairPageState extends State<LLMRepairPage> with UseCommonStyles {
  final TextEditingController _conversationCtrl = TextEditingController();
  String? repairedConversation;
  bool loading = false;
  String? errorMsg;
  bool repairDone = false;
  String lastInput = '';

  @override
  void initState() {
    super.initState();
    _conversationCtrl.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    final current = _conversationCtrl.text.trim();
    if (current != lastInput) {
      setState(() {
        repairedConversation = null;
        errorMsg = null;
        repairDone = false;
      });
      lastInput = current;
    }
  }

  Future<void> _runRepair() async {
    if (repairDone) return;
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final conversation = _conversationCtrl.text.trim();
    if (conversation.isEmpty) {
      setState(() {
        loading = false;
        errorMsg = '请输入医患对话内容';
      });
      return;
    }
    try {
      // 走 HttpClientManager，自动带上登录后保存的 Token 头，
      // 避免裸 http.post 因没带 token 而被后端拦截器以 401 拒绝。
      final data = await HttpClientManager().post(
            url: '${HttpConstants.backendBaseUrl}/api/repair',
            body: jsonEncode({'conversation': conversation}),
          ) as Map<String, dynamic>;
      setState(() {
        repairedConversation =
            data['repairedConversation']?.toString() ?? jsonEncode(data);
        repairDone = true;
      });
    } on HttpRequestException catch (e) {
      setState(() {
        errorMsg = '修复接口错误: ${_extractMessage(e)}';
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  String _extractMessage(HttpRequestException e) {
    final code = e.response?.statusCode ?? e.streamedResponse?.statusCode;
    if (code == 401) return '登录状态已失效，请重新登录后再试';
    if (code == 403) return '当前账号无权限访问该功能';
    final raw = e.message;
    if (raw == null || raw.isEmpty) return '未知错误';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['message'] is String) {
        final msg = decoded['message'] as String;
        return msg.isEmpty ? raw : msg;
      }
    } catch (_) {/* 旧接口不是 ApiResponse 包装，直接返回原文 */}
    return raw;
  }

  @override
  void dispose() {
    _conversationCtrl.removeListener(_onInputChanged);
    _conversationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF448AFF),
        elevation: 0,
        centerTitle: true,
        title: const Text('语句修复',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFFD6EBF9),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue[400], size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('功能说明',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: Colors.blue[900])),
                                const SizedBox(height: 8),
                                Text(
                                  '使用人工智能技术对医患对话内容进行修复，使表达更清晰、易于理解。',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      color: Colors.blueGrey[900]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(left: 26, bottom: 2),
                  child: Text(
                    '请输入医生与患者的完整对话内容',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  color: Colors.orange[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '逐行输入，每行开头用 "INV:" 表示医生的话，"PAR:" 表示患者的话',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 15,
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: TextField(
                    controller: _conversationCtrl,
                    minLines: 4,
                    maxLines: 7,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16, height: 1.7),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      hintText:
                          'INV: 你叫什么名字？\nPAR: 我叫小明。\nINV: 我手上这张图片里的内容是什么？\nPAR: 图片里是两个苹果。',
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16, height: 1.7, color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ElevatedButton.icon(
                    icon: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.build,
                            size: 22, color: Colors.white),
                    label: Text('大模型修复',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF448AFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 3,
                    ),
                    onPressed: (!loading && !repairDone) ? _runRepair : null,
                  ),
                ),
                const SizedBox(height: 18),
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 15)),
                  ),
                if (repairedConversation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Card(
                      color: const Color(0xFFD6EBF9),
                      margin: const EdgeInsets.only(top: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('修复后的对话：',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(repairedConversation ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}