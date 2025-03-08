package com.blkn.lr.lr_new_server.util.fluency;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.blkn.lr.lr_new_server.util.BaiduApiManager;
import com.blkn.lr.lr_new_server.util.HanziToPinyin;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.*;
import java.util.*;

/**
 * 流畅度处理
 */
@Component
public class FluencyProcessor {
    @Autowired
    private BaiduApiManager baiduApi;

//     Set<String> tancis=new HashSet<>(Arrays.asList(new String[]{"en","a","o","dui","shi","ai","pei","ha","ya","hen","yao","ke","wei",""}));
//
    /**
     *
     *
     * 声明：
     *   //采样率： 16Khz （1s采样16000次）
     *   //每16位采样一次，每两字节采样一次
     *   //每20ms作为一帧，即1s有50帧
     *   //每帧大小： 16000/50=320
     *   //计算帧数:总大小
     *
     *   音频文件获取能量数组
     *
     * 1 读取二进制文件
     * 2 根据采样率、帧长、位数来计算帧数
     * 3 统计帧能量并保存
     *
     * @param rawPcm16  文件数据
     * @return 能量数组
     */
    public double[] getEnergyMatrix(byte[] rawPcm16){
        DataInputStream dis;
        try {
            dis=new DataInputStream(new BufferedInputStream(new ByteArrayInputStream(rawPcm16)));
            //计算文件长度，除以2是每两字节、16位采样一次，每字节占8位
            int size=(int)rawPcm16.length/2;
            //总帧数
            int length = size%320==0?size/320:size/320+1;
            //能量数组
            double[] res = new double[length];
            //每16位采样，每次读取两字节
            byte[] temp = new byte[2];
            long len = 0;
            int index = 0;
            double sum = 0;
            int count = 0;
            while ( dis.read(temp) != -1){
                //合并成一个short数
                short r=(short) (((temp[0] & 0xff) << 8) | (temp[1] & 0xff));
                //统计帧能量，r有正负，故采用平方和计算
                sum += r*r;
                //个数加1
                count++;
                len++;
                //达到320，记录帧能量
                if(count == 320){
                    res[index++] = sum;
                    sum = 0;
                    count = 0;
                }
            }
            if(index < length)
                res[index++] = sum/count*320;
            return res;
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * 一般而言，记录用户答案的语音，前面肯定存在一段"静音"的数据,可以将静音能量作为判别有声无声的阈值
     * 前0.4s 一般都是"静音"的
     * @param energy
     * @return
     */
    public double get_static_energy(double[] energy){
        int len;
        if(energy.length>20)
            len=20;
        else
            len=energy.length;
        /**
         * 统计静音段帧能量
         */
        double static_energy=0;
        for(int i=0;i<len;i++)
            static_energy+=energy[i];
        return static_energy/len*1.2;

    }


    /**
     * 能量数组->0/1数组
     * @param energy
     * @return
     */
    public int[] process(double[] energy){
        if(energy==null || energy.length==0)
            return null;
        int[] res=new int[energy.length];
        double static_energy=get_static_energy(energy);
        for (int i=0;i<energy.length;i++){
            if(energy[i]>static_energy)
                res[i]=1;
            else
                res[i]=0;
        }
        return res;
    }




    /**
     * 统计停顿次数
     * 思路： 若某个时间段内，超过80%的帧都是有效的，则认为这一段是有声音的/相反，80%无效，则这一段无声
     *      循环找无声->有声->无声->有声......并记录下有声的个数
     * @param energy：能量数组
     * @param valid_length: 有效长度：20的整数倍，即在这一长度内超过阈值则认为这一段是有声或无声
     * @param threshold:阈值 0-1
     * @return
     */
    public int get_stop_times(double[] energy,int valid_length,double threshold){
        if(energy==null || energy.length==0)
            return 0;
        //队列长度
        int size=valid_length/20;
        //定义队列
        FluencyQueue fluencyQueue=new FluencyQueue(size);
        //先找无声
        boolean valid=false;
        //记录有声段个数
        int count=0;
        //处理能量数组：即转变为0/1数组
        int[] result=process(energy);
        //遍历数组
        for (int i=0;i<result.length;i++){
//            System.out.print(result[i]);
            //找有声段
            if (valid){
                //加入队列
                fluencyQueue.add(result[i]);
                //判断有效个数是否大于等于阈值*队列最大长度
                if(fluencyQueue.isValidTrue(threshold))
                {
                    //当前队列满足有声段，将队列清空
                    fluencyQueue.clear();
                    //开始找无声段
                    valid=false;
                    count++;
                }
            //找无声段
            }else {
                //判断无效个数是否大于等于阈值*队列最大长度
                fluencyQueue.add(result[i]);
                if (fluencyQueue.isValidFalse(threshold))
                {
                    //开始找有声段
                    fluencyQueue.clear();
                    valid=true;
                }
            }
        }
        return count;
    }


    /**
     * 获取语音的停顿次数
     * @param rawPcm16 是否存在在调用这个方法前判断过了
     * @return
     */
    public int get_stop_times(byte[] rawPcm16){
        return get_stop_times(getEnergyMatrix(rawPcm16),1000,0.8);
    }

    /**
     * 是否为重复较高
     *
     * @param string
     * @return
     */
    public boolean repeat(String string){
        if(string==null ||"".equals(string) || string.length()<=4)
            return false;
        if(string.length()>=6){
            double max_repeat=0;
            List<String> stringList= HanziToPinyin.getHanziPinYinList(string);
            int size=stringList.size();
            int i=1;
            while (i<4){
                int max=0;
                Map<String,Integer> map=new HashMap<>();
                for (int j=0;j<size;j+=i){
                    StringBuilder sb=new StringBuilder();
                    for(int o=j;o<j+i && o<size;o++)
                        sb.append(stringList.get(o));
                    if(map.containsKey(sb.toString())){
                        int cur=map.get(sb.toString())+1;
                        map.put(sb.toString(),cur);
                        max=Math.max(max,cur);
                    }else{
                        map.put(sb.toString(),1);
                        max=Math.max(max,1);
                    }
                }
                int count;
                if(size%i==0)
                    count=size/i;
                else
                    count=size/i+1;
                double res= (float) max/count;
                max_repeat=Math.max(max_repeat,res);
                i++;
            }
            return max_repeat>=0.75;
        }
        return false;
    }

    /**
     * 是否为电报式语言
     * @param string
     * @return
     */
    public JSONObject Telegram_Language(String string){
        /**
         *  调用词性分析接口
         */
        if(string==null || string.length()<=4)
            return null;
        JSONArray result=baiduApi.verbalAnalysis(string).getJSONArray("items");
        /**
         * 名词简称
         */
        Set<String> ns=new HashSet<>(Arrays.asList("n,t,f,s,r".split(",")));
        int n_count=0;
        for(int i=0;i<result.size();i++){
            if (ns.contains(result.getJSONObject(i).get("pos").toString()))
                n_count++;
        }
//        System.out.println("名词:"+n_count+",总数:"+result.size());
        JSONObject res=new JSONObject();
        boolean value=(double)n_count/result.size()>0.8;
        res.put("value",value);
        res.put("counts",result.size());
        System.out.println("value:" + value);
        System.out.println("counts:" + result.size());
        return res;

    }

    public double fluency_score(double integrity, int stopingtimes, boolean repeat, JSONObject telegrams, double dnn_score, StringBuilder detail_fluency) {
        double fluency;
        boolean telegram=telegrams.getBoolean("value");
        int counts=telegrams.getInteger("counts");
        if (integrity == 0) {
            fluency = 0;
            detail_fluency.append("完全无词或短而无意义的言语");
        } else {
            if (stopingtimes >= 10 && repeat) {
                if(counts <3){
                    fluency = 1;
                    detail_fluency.append("以不同的音调反复刻板的言语，有一些意义");
                }else{
                    fluency = 2;
                    detail_fluency.append("单个词, 常为错语, 费力并犹豫");
                }
            }
            else if (stopingtimes < 10 && repeat) {
                fluency = 3;
                detail_fluency.append("流畅反复的咕哝，有极少量奇特语");
            } else if (stopingtimes >= 10 && telegram) {
                fluency = 4;
                detail_fluency.append("踌躇，电报式的言语，大多数为一些单个的词，常有错语，但偶有动词和介词短语，仅有“奥，我不知道“等自发语言");
            } else if (stopingtimes >= 10 || telegram) {
                fluency = 5;
                detail_fluency.append("电报式的、有一些文法结构的较为流畅的言语，仍可能有明显错语，有少数陈述性句子");
            } else if (dnn_score > 1000) {
                fluency = 6;
                detail_fluency.append("有较完整的陈述句，可出现正常的句型，仍有错语");
            } else if (dnn_score > 500) {
                fluency = 7;
                detail_fluency.append("流畅，可能滔滔不绝，在6分的基础上可有句法和节律与汉语相似的音素奇特语，伴有不同的音素错语和新造语");
            } else if (dnn_score > 100) {
                fluency = 8;
                detail_fluency.append("流畅，句子常完整，但可与主题无关，有明显的找词困难和迂回说法，有语义错语，可有语义奇特语");
            } else if (dnn_score > 50) {
                fluency = 9;
                detail_fluency.append("大多数是完整的与主题有关的句子，偶有踌躇或错语，找词有写困难，，可有一些发音错误");
            } else {
                fluency = 10;
                detail_fluency.append("句子有正常的长度和复杂性，无确定的缓慢、踌躇或发音困难，无错语");
            }
        }
        return fluency;
    }



    public static void main(String[] args) {
        FluencyProcessor f=new FluencyProcessor();
//        System.out.println(f.repeat("你好啊,你好啊，你在干什么"));
////        double[] data=f.getEnergyMatrix("/Users/hanfei/Documents/毕业设计/自发性II语音文件/1558505639.wav");
////        double[] data=f.getEnergyMatrix("/Users/hanfei/Documents/毕业设计/自发性II语音文件/1557815793.wav");
////        double[] data=f.getEnergyMatrix("/Users/hanfei/Documents/毕业设计/自发性II语音文件/1562744821255.wav");
        long start=System.currentTimeMillis();
//        System.out.println(f.get_stop_times());
        long end=System.currentTimeMillis();
        System.out.println(end-start);
//        List<String> res=new ArrayList<>();
//        res.add("dsa");
//        System.out.println("res="+res);
    }

}
