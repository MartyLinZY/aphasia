package com.blkn.lr.lr_new_server.dao.impl;

import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.LinkedList;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class ExamDaoImplTest {
    @Test
    void addCategoryIntoExam(@Autowired ExamDaoImpl examDao) {
        for(int i = 0;i < 3;i++) {
            System.out.println(examDao.addCategoryIntoExam("65fd1356b701f92700322553", new QuestionCategory("亚项"+i, new LinkedList<>(), new LinkedList<>())));
        }
    }

    @Test
    void addSubCategoryIntoExam(@Autowired ExamDaoImpl examDao) {
        for(int i = 0;i < 3;i++) {
            System.out.println(examDao.addSubCategoryIntoExam("65fd1356b701f92700322553", 0,
                    new QuestionSubCategory("子项" + i, new LinkedList<>(), new LinkedList<>(), new LinkedList<>())));
        }
    }


    @Test
    void deleteSubCategoryFromExam(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.deleteSubCategoryFromExam("65fd1356b701f92700322553", 0, 3));
    }

    @Test
    void deleteCategoryFromExam(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.deleteCategoryFromExam("65fd1356b701f92700322553", 2));
    }

    @Test
    void moveSubCategoryUp(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveSubCategoryUp("65fd1356b701f92700322553", 0, 0));
    }

    @Test
    void moveSubCategoryDown(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveSubCategoryDown("65fd1356b701f92700322553", 0, 3));
    }

    @Test
    void moveCategoryUp(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveCategoryUp("65fd1356b701f92700322553", 2));
    }

    @Test
    void moveCategoryDown(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveCategoryDown("65fd1356b701f92700322553", 1));
    }

    @Test
    void addQuestionIntoExam(@Autowired ExamDaoImpl examDao) {
        for(int i = 0;i < 3;i++) {
            System.out.println(examDao.addQuestionIntoExam("65fd1356b701f92700322553", 0, 0, "testQuestion" + i));
        }
    }

    @Test
    void deleteQuestion(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.deleteQuestion("65fd1356b701f92700322553", 0, 0, 1));
    }

    @Test
    void moveQuestionDown(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveQuestionDown("65fd1356b701f92700322553", 0, 0, 0));
    }

    @Test
    void moveQuestionUp(@Autowired ExamDaoImpl examDao) {
        System.out.println(examDao.moveQuestionUp("65fd1356b701f92700322553", 0, 0, 1));
    }
}