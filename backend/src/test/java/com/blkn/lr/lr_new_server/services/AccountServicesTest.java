package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.impl.UserDaoImpl;
import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.exception.BusinessErrorException;
import com.blkn.lr.lr_new_server.models.common.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.util.DigestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountServicesTest {

    @Mock
    private UserDaoImpl userDao;

    @InjectMocks
    private AccountServices accountServices;

    @Test
    void registerShouldUseBcryptPassword() {
        UserDto request = new UserDto();
        request.setIdentity("doctor001");
        request.setPassword("plain-password");
        request.setRole(2);

        when(userDao.register(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId("u-1");
            return user;
        });

        UserDto response = accountServices.register(request);

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userDao).register(captor.capture());
        User savedUser = captor.getValue();

        assertEquals("u-1", response.getUid());
        assertNotNull(response.getToken());
        assertNotNull(response.getIdentity());
        assertNotEquals("plain-password", savedUser.getPassword());
        assertTrue(savedUser.getPassword().startsWith("$2"),
                "密码必须存为 BCrypt 哈希（以 $2 开头）");
    }

    @Test
    void loginShouldSucceedWithBcryptPassword() {
        String bcryptPassword = new BCryptPasswordEncoder().encode("test-password");
        User user = new User("u-2", "patient001", bcryptPassword, 1);
        when(userDao.findByIdentity("patient001")).thenReturn(user);

        UserDto response = accountServices.login(null, "patient001", "test-password");

        assertEquals("u-2", response.getUid());
        assertNotNull(response.getToken());
    }

    @Test
    void loginShouldRejectWrongPassword() {
        String bcryptPassword = new BCryptPasswordEncoder().encode("real-password");
        User user = new User("u-3", "patient001", bcryptPassword, 1);
        when(userDao.findByIdentity("patient001")).thenReturn(user);

        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> accountServices.login(null, "patient001", "wrong-password"));
        assertEquals("用户密码错误", ex.getMessage());
    }

    @Test
    void loginShouldRejectUnknownUser() {
        when(userDao.findByIdentity("not-exist")).thenReturn(null);

        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> accountServices.login(null, "not-exist", "any"));
        assertEquals("用户不存在", ex.getMessage());
    }

    @Test
    void loginShouldRejectLegacyMd5Password() {
        // MD5 残留兜底验证：保证清理后老 MD5 用户登录一定失败
        String legacyMd5 = DigestUtils.md5DigestAsHex(
                ("salt" + "legacy-pass" + "salt").getBytes());
        User user = new User("u-4", "legacy-user", legacyMd5, 2);
        when(userDao.findByIdentity("legacy-user")).thenReturn(user);

        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> accountServices.login(null, "legacy-user", "legacy-pass"));
        assertEquals("用户密码错误", ex.getMessage());
    }

    @Test
    void loginShouldRejectEmptyRequest() {
        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> accountServices.login(null, null, null));
        assertEquals("错误的登录请求", ex.getMessage());
    }

    @Test
    void loginShouldRejectExpiredToken() {
        BusinessErrorException ex = assertThrows(BusinessErrorException.class,
                () -> accountServices.login("not-a-jwt", null, null));
        assertEquals("token过期", ex.getMessage());
    }
}
