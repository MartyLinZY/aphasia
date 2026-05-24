package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.models.question.Question;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@Repository
@RequiredArgsConstructor
public class QuestionDaoImpl implements QuestionDao {
    private final MongoTemplate template;

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
