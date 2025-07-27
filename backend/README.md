# 服务端启动手册

## 环境准备

1. mongoDB环境：7.0.2
2. redis环境：7.2.3
3. IDEA安装LOMBOK插件

## 修改配置

1. APPSetting.java中HOSTNAME静态变量设置为运行时本机的IP或域名
2. application.properties中各中间件的IP和port，改成环境所在的机器的IP和port，如果都在本地就不用改
3. config目录下面，不修改的话AI能力用不了无法正常答题
   a. BaiduApiConfig.java：按照百度开放平台的手册修改各变量
   b. FlyTekApiConfig.java：按照讯飞开放平台的手册修改各变量
   c. FlyTekAudioRecognizer.java：静态变量hostUrl，需要区讯飞开放平台确认一下API地址是否还有变化

4. APPSetting.java中，Pyhton解释器的路径按照实际情况设置
5. APPSetting.java中，LLM/diagnose.py与LLM/repair.py的路径按照实际情况设置
