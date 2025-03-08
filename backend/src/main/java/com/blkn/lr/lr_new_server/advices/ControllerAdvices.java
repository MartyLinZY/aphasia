package com.blkn.lr.lr_new_server.advices;

import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.expection.NotFoundException;
import com.blkn.lr.lr_new_server.expection.UserExistException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;

@ControllerAdvice
public class ControllerAdvices {
    @ExceptionHandler(UserExistException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public void userExistException(UserExistException e) {}

    @ExceptionHandler(BusinessErrorException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public void businessErrorException(BusinessErrorException e) {
        System.err.println("业务处理：" + e.getMessage());
    }

    @ExceptionHandler(NotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public void notFoundException(NotFoundException e) {
      System.err.println("未找到实体：" + e.getMessage());
    }
}
