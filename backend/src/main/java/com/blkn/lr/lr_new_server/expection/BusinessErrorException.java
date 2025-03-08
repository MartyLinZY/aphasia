package com.blkn.lr.lr_new_server.expection;

import lombok.AllArgsConstructor;

public class BusinessErrorException extends RuntimeException {
    String message;
    public BusinessErrorException(String message) {
        this.message = message;
    }

    @Override
    public String getMessage() {
        return message;
    }
}
