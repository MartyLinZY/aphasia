package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.dao.QuestionDao;
import com.blkn.lr.lr_new_server.models.question.Question;
import lombok.RequiredArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Objects;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@Repository
@RequiredArgsConstructor
public class QuestionDaoImpl implements QuestionDao {
    private final MongoTemplate template;

    public Question findById(String id) {
        return template.findById(id, Question.class);
    }

    public List<Question> findAllByIds(Collection<String> ids) {
        if (ids == null || ids.isEmpty()) {
            return List.of();
        }
        // 与 deleteById 保持一致：手动把 String id 转 ObjectId 后用 $in 一次拉取
        List<ObjectId> objectIds = ids.stream()
                .filter(Objects::nonNull)
                .filter(ObjectId::isValid)
                .map(ObjectId::new)
                .toList();
        if (objectIds.isEmpty()) {
            return List.of();
        }
        return template.find(query(where("_id").in(objectIds)), Question.class);
    }

    public Question save(Question q) {
        return template.save(q);
    }

    public Question deleteById(String id) {
        return template.findAndRemove(query(where("_id").is(new ObjectId(id))), Question.class);
    }
}
