package com.blkn.lr.lr_new_server.services;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.blkn.lr.lr_new_server.dao.impl.UserDaoImpl;
import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.models.common.User;
import com.blkn.lr.lr_new_server.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AccountServices {
    @Autowired
    UserDaoImpl userDao;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public UserDto login(String token, String identity, String password) {
        User user = null;
        if (token != null) {
            DecodedJWT decodedJWT = TokenUtil.verifyToken(token);
            if (decodedJWT == null) {
                throw new BusinessErrorException("token过期");
            }
            String uid =  decodedJWT.getClaim("uid").asString();
            user = userDao.findById(uid);
            if (user == null) {
                throw new BusinessErrorException("无效的token");
            }
        }

        if (user == null) {
            if (identity != null) {
                user = userDao.findByIdentity(identity);
                if (user == null) {
                    throw new BusinessErrorException("用户不存在");
                }

                if (!isPasswordValid(user, password)) {
                    throw new BusinessErrorException("用户密码错误");
                }

            } else {
                throw new BusinessErrorException("错误的登录请求");
            }
        }

        UserDto dto = new UserDto(user);
        dto.setToken(TokenUtil.getToken(user.getId(), user.getRole()));
        return dto;
    }


    public UserDto register(UserDto dto) {
        String password = dto.getPassword();

        User user = new User();
        user.setIdentity(dto.getIdentity());
        user.setRole(dto.getRole());
        user.setPassword(passwordEncoder.encode(password));

        User created = userDao.register(user);
        UserDto dtoToReturn = new UserDto(created);
        dtoToReturn.setToken(TokenUtil.getToken(created.getId(), user.getRole()));
        return dtoToReturn;
    }

    private boolean isPasswordValid(User user, String rawPassword) {
        String encodedPassword = user.getPassword();
        if (encodedPassword == null || rawPassword == null) {
            return false;
        }
        return passwordEncoder.matches(rawPassword, encodedPassword);
    }
}
