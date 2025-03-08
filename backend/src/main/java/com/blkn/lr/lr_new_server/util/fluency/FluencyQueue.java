package com.blkn.lr.lr_new_server.util.fluency;

import java.util.LinkedList;
import java.util.Queue;
import java.util.Random;

/**
 * 构造一个队列，用于判断音段是否有效
 */
public class FluencyQueue {

    /**
     * Integer队列
     */
    private Queue<Integer> queue;

    /**
     * 队列长度
     */
    private int max_length;

    /**
     * 队列中当前元素个数
     */
    private int length;

    /**
     * 队列中值为1(有效)的元素个数
     */
    private int valid;

    /**
     * 构造函数
     * @param size
     */
    public FluencyQueue(int size){
        queue=new LinkedList<>();
        //设置长度
        this.max_length=size;
        //初始化长度0
        length=0;
        //初始化有效长度0
        valid=0;
    }

    /**
     * 新增元素
     * @param number
     */
    public void add(int number){
        //如果没有到达队列最大值，直接添加
        if(length<max_length){
            queue.add(number);
            length++;
            //如果有效，有效个数++
            if(number==1)
                valid++;
        //如果队列已满，则需要取出队头元素，再添加元素
        }else {
            int current=queue.poll();
            queue.add(number);
            //队头是1，队尾是0，valid--
            if(current==1 && number==0)
                valid--;
            //对头是0，队尾是1，valid++
            else if(current==0 && number==1)
                valid++;
            }
    }

    /**
     * 清空队列
     */
    public void clear(){
        queue.clear();
        length=0;
        valid=0;
    }


    public void display(){
        System.out.println("长度："+length+"有效："+valid);
    }

    /**
     * 统计当前元素是否有效
     * 有效元素个数是否达到阈值
     * @return
     */
    public boolean isValidTrue(double threshold){
        return valid>=threshold*max_length;
    }


    /**
     * 统计当前元素是否无效
     * 无效元素个数是否达到阈值
     */
    public boolean isValidFalse(double threshold){
        return (length-valid)>=threshold*max_length;
    }


    public static void main(String[] args) {
        FluencyQueue f=new FluencyQueue(10);
        Random r=new Random();
        for (int i=0;i<1000;i++){
                int j=r.nextInt(2);
                System.out.print(j);
                f.add(j);
                f.display();
                if(f.isValidTrue(0.6))
                    f.clear();
        }
    }

}
