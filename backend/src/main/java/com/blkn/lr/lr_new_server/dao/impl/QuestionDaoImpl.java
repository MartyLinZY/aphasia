package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.models.question.Question;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@Repository
public class QuestionDaoImpl {
    @Autowired
    MongoTemplate template;

    public Question findById(String id) {
        return template.findById(id, Question.class);
    }

    public Question save(Question q) {
        return template.save(q);
    }

    public Question deleteById(String id) {
        return template.findAndRemove(query(where("_id").is(new ObjectId(id))), Question.class);
    }
}
