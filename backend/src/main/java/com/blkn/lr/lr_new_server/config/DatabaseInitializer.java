package com.blkn.lr.lr_new_server.config;

import com.blkn.lr.lr_new_server.models.common.User;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.stereotype.Component;

@Component
public class DatabaseInitializer implements ApplicationListener<ApplicationReadyEvent>{
    @Autowired
    MongoTemplate mongoTemplate;

    @Override
    public void onApplicationEvent(@NotNull ApplicationReadyEvent applicationReadyEvent) {
        if (!mongoTemplate.getCollectionNames().contains("user")) {
            mongoTemplate.createCollection(User.class);
        }
        mongoTemplate.indexOps(User.class).ensureIndex(new Index().on("identity", Sort.Direction.ASC).unique());

        if (!mongoTemplate.getCollectionNames().contains("exam")) {
            mongoTemplate.createCollection(Exam.class);
        }
        mongoTemplate.indexOps(Exam.class).ensureIndex(new Index().on("ownerId", Sort.Direction.ASC));

        if (!mongoTemplate.getCollectionNames().contains("question")) {
            mongoTemplate.createCollection(Question.class);
        }
        mongoTemplate.indexOps(Question.class).ensureIndex(new Index().on("ownerId", Sort.Direction.ASC));

        if (!mongoTemplate.getCollectionNames().contains("examResult")) {
            mongoTemplate.createCollection(ExamResult.class);
        }
        mongoTemplate.indexOps(ExamResult.class).ensureIndex(new Index().on("ownerId", Sort.Direction.ASC));
    }
}
