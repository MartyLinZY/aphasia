package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.exception.UserExistException;
import com.blkn.lr.lr_new_server.models.common.User;
import com.mongodb.MongoWriteException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Repository;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@Repository
@RequiredArgsConstructor
public class UserDaoImpl {
    private final MongoTemplate template;

    public User findByIdentity(String identity) {
        return template.query(User.class).matching(query(where("identity").is(identity))).firstValue();
    }

    public User findById(String id) {
        return template.findById(id, User.class);
    }

    public User register(User newUser) {
        try {
            return template.insert(newUser);
        } catch (Exception e) {
            throw new UserExistException();
        }
    }
}
