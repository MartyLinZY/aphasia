package com.blkn.lr.lr_new_server.config;

import com.blkn.lr.lr_new_server.models.common.User;
import com.blkn.lr.lr_new_server.models.question.Question;
import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.results.ExamResult;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.jetbrains.annotations.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.index.CompoundIndexDefinition;
import org.springframework.data.mongodb.core.index.Index;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DatabaseInitializer implements ApplicationListener<ApplicationReadyEvent> {
    @Autowired
    MongoTemplate mongoTemplate;

    @Override
    public void onApplicationEvent(@NotNull ApplicationReadyEvent event) {
        ensureCollections();
        ensureIndexes();
        log.info("MongoDB 集合与索引初始化完成");
    }

    private void ensureCollections() {
        createIfAbsent("user", User.class);
        createIfAbsent("exam", Exam.class);
        createIfAbsent("question", Question.class);
        createIfAbsent("examResult", ExamResult.class);
    }

    private void ensureIndexes() {
        // user.identity — 登录时高频查询
        mongoTemplate.indexOps(User.class)
                .ensureIndex(new Index().on("identity", Sort.Direction.ASC).unique());

        // exam.{ownerId, isRecovery, isDisabled} — 医生获取考试列表的核心查询
        mongoTemplate.indexOps(Exam.class)
                .ensureIndex(new CompoundIndexDefinition(
                        new Document("ownerId", 1).append("isRecovery", 1).append("isDisabled", 1)));

        // question.ownerId — 按属主查题目
        mongoTemplate.indexOps(Question.class)
                .ensureIndex(new Index().on("ownerId", Sort.Direction.ASC));

        // examResult.{ownerId, isRecovery, isDisabled} — 患者查历史记录的核心查询
        mongoTemplate.indexOps(ExamResult.class)
                .ensureIndex(new CompoundIndexDefinition(
                        new Document("ownerId", 1).append("isRecovery", 1).append("isDisabled", 1)));
    }

    private void createIfAbsent(String name, Class<?> clazz) {
        if (!mongoTemplate.getCollectionNames().contains(name)) {
            mongoTemplate.createCollection(clazz);
        }
    }
}
