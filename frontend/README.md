# 启动教程

## 环境准备
1. Android Studio：Android Studio Giraffe | 2022.3.1 Patch 1
   - 更新的版本不太确定是否有问题，印象里面好像有插件没法安装
2. IDEA安装Dart和Flutter插件
   - 可以到Flutter官网按照教程进行相关环境准备

## 配置修改
1. settings.dart中把IP和port改成服务端所在机器的IP（域名）和port

## 调试手段
1. 直接从Android Studio选择平台后启动即可
   - 安卓真机
   - Chrome
   - Edge
   - Windows
   - 安卓模拟机（理论可行，未尝试）
   - ios/macOS等平台理论也可行，但需要修改项目配置，并且兼容性未经测试
     - 如果要拓展至ios/macOS，注意一下audio_record.platform下面的几个文件，是区分平台的
   
## LLM功能说明
LLM服务在前端实现了两个页面，llm_diagnose 和 llm_repair。
这两个页面都是输入对话内容，然后点击按钮申请服务。
对于同一段对话，只可以点击一次按钮，获取到对应的服务后，按钮将变为未响应状态。
当输入框内的对话内容改变时，按钮恢复为可点击状态，针对新的对话内容提供服务。
