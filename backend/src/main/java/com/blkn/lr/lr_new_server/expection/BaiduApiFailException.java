package com.blkn.lr.lr_new_server.expection;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
public class BaiduApiFailException extends Exception{
    String message;


    @Override
    public String getMessage() {
        return message;
    }
}
