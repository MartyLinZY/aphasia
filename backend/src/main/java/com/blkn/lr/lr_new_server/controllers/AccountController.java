package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.services.AccountServices;
import jakarta.validation.Valid;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/")
@RequiredArgsConstructor
public class AccountController {

    private final AccountServices service;
    @PostMapping("/auth")
    public UserDto login(HttpServletRequest request) {
        String token = request.getHeader("Token");
        return service.login(token, request.getHeader("identity"), request.getHeader("password"));
    }

    @PostMapping("/register")
    public UserDto register(@Valid @RequestBody UserDto dto) {
        return service.register(dto);
    }
}
