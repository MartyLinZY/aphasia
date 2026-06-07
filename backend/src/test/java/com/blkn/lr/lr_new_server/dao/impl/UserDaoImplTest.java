package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.exception.UserExistException;
import com.blkn.lr.lr_new_server.models.common.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.mongodb.core.ExecutableFindOperation.ExecutableFind;
import org.springframework.data.mongodb.core.ExecutableFindOperation.TerminatingFind;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * UserDaoImpl 单元测试。
 *
 * <p>覆盖 3 个方法：① findByIdentity 走 fluent query+firstValue 链 ② findById 透传
 * ③ register 把任何 insert 异常（含 duplicate key）翻成 UserExistException——这是登录
 * 注册路径上唯一的"业务异常翻译"，下游 Service 完全依赖这条来识别"该 identity 已被占用"。
 */
class UserDaoImplTest {

    private MongoTemplate template;
    private UserDaoImpl dao;

    @BeforeEach
    void setUp() {
        template = mock(MongoTemplate.class);
        dao = new UserDaoImpl(template);
    }

    @Test
    @SuppressWarnings("unchecked")
    void findByIdentityShouldReturnFirstValueFromFluentQuery() {
        ExecutableFind<User> exec = mock(ExecutableFind.class);
        TerminatingFind<User> terminating = mock(TerminatingFind.class);
        User u = new User();

        when(template.query(User.class)).thenReturn(exec);
        when(exec.matching(any(Query.class))).thenReturn(terminating);
        when(terminating.firstValue()).thenReturn(u);

        assertSame(u, dao.findByIdentity("alice"));
    }

    @Test
    @SuppressWarnings("unchecked")
    void findByIdentityShouldReturnNullWhenNotFound() {
        ExecutableFind<User> exec = mock(ExecutableFind.class);
        TerminatingFind<User> terminating = mock(TerminatingFind.class);

        when(template.query(User.class)).thenReturn(exec);
        when(exec.matching(any(Query.class))).thenReturn(terminating);
        when(terminating.firstValue()).thenReturn(null);

        assertNull(dao.findByIdentity("nobody"));
    }

    @Test
    void findByIdShouldPassThroughTemplate() {
        User u = new User();
        when(template.findById("uid-1", User.class)).thenReturn(u);
        assertSame(u, dao.findById("uid-1"));
    }

    @Test
    void registerShouldPassThroughWhenInsertSucceeds() {
        User input = new User();
        User saved = new User();
        when(template.insert(input)).thenReturn(saved);
        assertSame(saved, dao.register(input));
    }

    @Test
    void registerShouldTranslateAnyExceptionToUserExistException() {
        // 当前实现是 catch (Exception)——把"任何插入失败"全翻译成 UserExistException。
        // 这里用通用 RuntimeException 模拟 duplicate key index error，验证翻译路径。
        User input = new User();
        when(template.insert(input)).thenThrow(new RuntimeException("E11000 duplicate key"));

        assertThrows(UserExistException.class, () -> dao.register(input));
    }
}
