package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.services.AccountServices;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/")
public class AccountController {

    @Autowired
    AccountServices service;
    @PostMapping("/auth")
    public UserDto login(HttpServletRequest request) {
        String token = request.getHeader("Token");
        return service.login(token, request.getHeader("identity"), request.getHeader("password"));
    }

    @PostMapping("/register")
    public UserDto register(@RequestBody UserDto dto) {
        return service.register(dto);
    }
}
