package com.blkn.lr.lr_new_server.advices;

import com.blkn.lr.lr_new_server.expection.FlyTekApiException;
import com.blkn.lr.lr_new_server.expection.UserExistException;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;

@ControllerAdvice
public class ProxyControllerAdvice {
    @ExceptionHandler(FlyTekApiException.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public void loginFailException(FlyTekApiException e) {}


}
