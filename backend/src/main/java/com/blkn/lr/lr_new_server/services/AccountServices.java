package com.blkn.lr.lr_new_server.services;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.blkn.lr.lr_new_server.dao.impl.UserDaoImpl;
import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.expection.BusinessErrorException;
import com.blkn.lr.lr_new_server.models.common.User;
import com.blkn.lr.lr_new_server.util.TokenUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.UUID;

@Service
public class AccountServices {
    @Autowired
    UserDaoImpl userDao;

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

                if (!user.getPassword().equals(createMD5Password(password, user.getSalt()))) {
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

        String salt = UUID.randomUUID().toString();
        String md5Password = createMD5Password(password,salt);
        User user = new User();

        //add log data
        user.setIdentity(dto.getIdentity());
        user.setRole(dto.getRole());
        user.setPassword(md5Password);
        user.setSalt(salt);

        User created = userDao.register(user);
        UserDto dtoToReturn = new UserDto(created);
        dtoToReturn.setToken(TokenUtil.getToken(created.getId(), user.getRole()));
        return dtoToReturn;
    }

    public String createMD5Password(String password,String salt) {
        String passwordWithSalt = salt+password+salt;
        String md5Password = DigestUtils.md5DigestAsHex(passwordWithSalt.getBytes());
        return md5Password;
    }
}
