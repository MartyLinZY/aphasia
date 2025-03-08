package com.blkn.lr.lr_new_server.controllers;

import com.blkn.lr.lr_new_server.models.exam.Exam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

import static org.springframework.data.mongodb.core.query.Criteria.where;
import static org.springframework.data.mongodb.core.query.Query.query;

@RestController()
public class TestController {
    @Autowired
    MongoTemplate template;


    @GetMapping("/api/test")
    public Map<String, String> test() {
        HashMap<String, String> result = new HashMap<>();
        result.put("1", "1");
        return result;
    }

    @GetMapping("/api/test/{id1}/dd/{id2}")
    public Exam test2(@PathVariable String id1, @PathVariable String id2) {
        System.out.println(id2);
        return template.query(Exam.class).matching(query(where("_id").is(id1))).all().get(0);
    }
}
