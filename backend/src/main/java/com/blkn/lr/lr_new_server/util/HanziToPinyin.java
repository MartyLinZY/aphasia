package com.blkn.lr.lr_new_server.util;

import net.sourceforge.pinyin4j.PinyinHelper;

import java.util.ArrayList;
import java.util.List;

/**
 * 中文转拼音
 */
public class HanziToPinyin {






    /**
     * 单个中文转拼音：string
     * @param hanzi
     * @return
     */
    public static String getHanziPinYin(String hanzi) {
        String res=null;
        if(hanzi!=null && !"".equals(hanzi)) {
            char[] charArray = hanzi.toCharArray();
            StringBuilder sb=new StringBuilder();
            for (char ch : charArray) {
                // 逐个汉字进行转换， 每个汉字返回值为一个String数组（因为有多音字）
                String[] stringArray = PinyinHelper.toHanyuPinyinStringArray(ch);
                if(null != stringArray) {
                    sb.append(stringArray[0]);
                }
            }
            if(sb.length()>0)
                res=sb.toString();
        }
        return res;
    }


    /**
     * 中文转拼音，去掉声调  String->List
     * @param hanzi
     * @return
     */
    public static List<String[]> getHanziPinYinLists(String hanzi) {
        if(hanzi!=null && !"".equals(hanzi)) {
            List<String[]> result=new ArrayList<>();
            char[] charArray = hanzi.toCharArray();
            for (char ch : charArray) {
                String[] stringArray = PinyinHelper.toHanyuPinyinStringArray(ch);
                if(null != stringArray) {
                    result.add(stringArray);
                }
            }
            if(result.size()>0)
                return result;
        }
        return null;
    }



    /**
     * 中文转拼音，去掉声调  String->List
     * @param hanzi
     * @return
     */
    public static List getHanziPinYinList(String hanzi) {
        if(null != hanzi && !"".equals(hanzi)) {
            List<String> result=new ArrayList<>();
            char[] charArray = hanzi.toCharArray();
            for (char ch : charArray) {
                //逐个汉字转换，每个汉字返回值为一个String数组（因为有多音字）
                String[] stringArray = PinyinHelper.toHanyuPinyinStringArray(ch);
                if(null != stringArray) {
                    //去掉声调
                    result.add(stringArray[0].replaceAll("\\d", ""));
                }
            }
            if(result.size()>0)
                return result;
        }
        return null;
    }

    /**
     * 中文转拼音，去掉声调  String->List
     * @param hanzi
     * @return
     */
    public static List getHanziPinYinListIII(String hanzi) {
        if(null != hanzi && !"".equals(hanzi)) {
            List<String> result=new ArrayList<>();
            char[] charArray = hanzi.toCharArray();
            for (char ch : charArray) {
                //逐个汉字转换，每个汉字返回值为一个String数组（因为有多音字）
                String[] stringArray = PinyinHelper.toHanyuPinyinStringArray(ch);
                if(null != stringArray) {
                    //去掉声调
                    result.add(stringArray[0].replaceAll("\\d", "").replaceAll("ng","n"));
                }
            }
            if(result.size()>0)
                return result;
        }
        return null;
    }








    /**
     * 中文转拼音，去掉前后鼻音、声调
     * @param hanzi
     * @return
     */
    public static String getHanziPinYinI(String hanzi) {
        String res=null;
        if(null != hanzi && !"".equals(hanzi)) {
            char[] charArray = hanzi.toCharArray();
            StringBuilder sb=new StringBuilder();
            for (char ch : charArray) {
                // 逐个汉字进行转换， 每个汉字返回值为一个String数组（因为有多音字）
                String[] stringArray = PinyinHelper.toHanyuPinyinStringArray(ch);
                if(null != stringArray) {
                    //去掉声调、前后鼻音
                    sb.append(stringArray[0].replaceAll("\\d", "").replaceAll("ng","n"));
                }
            }
            if(sb.length()>0)
                res=sb.toString();
        }
        return res;
    }



    /**
     * 中文数组转拼音数组
     * @param hanzi
     * @return
     */
    public static List<String> getHanziPinYinII(List<String> hanzi) {
        List<String> res=new ArrayList<>();
        if(null != hanzi && hanzi.size()>0){
            for (String str: hanzi){
                if(!"".equals(str) && str.matches("[\\u4E00-\\u9FA5]+"))
                    res.add(getHanziPinYinI(str));
                else
                    res.add("none");
            }
        }
        return res;
    }


    /**
     * 中文转拼音数组
     * @param hanzi
     * @return
     */
    public static List<String> getHanziPinYinIII(String hanzi) {
        List<String> res=new ArrayList<>();
        if(null != hanzi && hanzi.length()>0){
            for (int i=0;i<hanzi.length();i++){
                res.add(getHanziPinYinI(hanzi.charAt(i)+""));
            }
        }
        return res;
    }




    
     static int find(int n,int[] nums){
        int l=0,r=nums.length-1;
        while (l<=r){
            int mid=l+(r-l)/2;
            if(nums[mid]==n)
                return mid;
            //后面有序
            else if(nums[mid]<nums[r]) {
                //在mid到r之间
                if (n>nums[mid] && n<=nums[r])
                    l=mid+1;
                else
                    r=mid-1;
            }
            //后边无序，前面有序
            else{
                //在l和mid之间
                if(n>=nums[l] && n<nums[mid])
                    r=mid-1;
                else
                    l=mid+1;
            }
        }
        return -1;
     }


    public static void main(String[] args) {
//        System.out.println(HanziToPinyin.getHanziPinYinI("鹰疯让008。。。"));
        List<String[]> res=HanziToPinyin.getHanziPinYinLists("还");
        for (String[] strings:res)
            for (String string:strings)
                System.out.print(string+",");
//        List<String> l=new ArrayList<>();
//        l.add("你哈");
//        l.add("哈啰");
//        l.add("大会");
//        l.add("好的");
//        List<String> res=HanziToPinyin.getHanziPinYinII(l);
//        System.out.println(res);
//        List<String> ss=new ArrayList<>();
//        String s="你哈，草你";
//        ss.add(s);
//        ss.get(0).replace("哈","");
////                ss.get(0).replace();
//        System.out.println(HanziToPinyin.getHanziPinYinI("你好啊，你在，，，"));

//
//        int[] nums=new int[]{16,18,19,1,3,4,5,7,8,10};
//        System.out.println(HanziToPinyin.find(16,nums));
//        System.out.println(HanziToPinyin.getPinYinChar('女'));



    }
}
