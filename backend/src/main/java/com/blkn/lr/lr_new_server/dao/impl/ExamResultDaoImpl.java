package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.BasicQuery;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Repository;

import java.util.List;

import static org.springframework.data.mongodb.core.query.Criteria.where;

@Repository
public class ExamResultDaoImpl {
    @Autowired
    private MongoTemplate template;


    public ExamResult save(ExamResult model) {
        return template.save(model);
    }

    public List<ExamResult> findByOwnerId(String ownerId, boolean isRecovery) {
        return template.find(new BasicQuery("{ownerId: \"" + ownerId + "\", isRecovery: " + isRecovery + ", isDisabled: " + false + "}"), ExamResult.class);
    }

    public void deleteByIdWithOwnerId(String ownerId, String resultId) {
        template.update(ExamResult.class).matching(where("_id").is(new ObjectId(resultId)).and("ownerId").is(ownerId)).apply(new Update().set("isDisabled", true)).all().getModifiedCount();
    }
}
