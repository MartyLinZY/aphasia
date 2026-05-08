package com.blkn.lr.lr_new_server.services;

import com.blkn.lr.lr_new_server.dao.impl.UserDaoImpl;
import com.blkn.lr.lr_new_server.dto.common.UserDto;
import com.blkn.lr.lr_new_server.models.common.User;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
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
        assertTrue(savedUser.getPassword().startsWith("$2"));
        assertNull(savedUser.getSalt());
    }

    @Test
    void loginShouldSupportBcryptPassword() {
        String bcryptPassword = new BCryptPasswordEncoder().encode("test-password");
        User user = new User("u-2", "patient001", bcryptPassword, null, 1);
        when(userDao.findByIdentity("patient001")).thenReturn(user);

        UserDto response = accountServices.login(null, "patient001", "test-password");

        assertEquals("u-2", response.getUid());
        assertNotNull(response.getToken());
    }

    @Test
    void loginShouldSupportLegacyMd5Password() {
        String salt = "legacy-salt";
        String md5Password = accountServices.createMD5Password("legacy-pass", salt);
        User user = new User("u-3", "legacy-user", md5Password, salt, 2);
        when(userDao.findByIdentity("legacy-user")).thenReturn(user);

        UserDto response = accountServices.login(null, "legacy-user", "legacy-pass");

        assertEquals("u-3", response.getUid());
        assertNotNull(response.getToken());
    }
}
