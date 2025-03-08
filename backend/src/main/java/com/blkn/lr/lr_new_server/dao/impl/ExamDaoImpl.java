package com.blkn.lr.lr_new_server.dao.impl;


import com.blkn.lr.lr_new_server.models.exam.Exam;
import com.blkn.lr.lr_new_server.models.exam.QuestionCategory;
import com.blkn.lr.lr_new_server.models.exam.QuestionSubCategory;
import com.blkn.lr.lr_new_server.models.rules.exam.DiagnosisRule;
import com.blkn.lr.lr_new_server.models.rules.subcategory.TerminateRule;
import org.bson.types.ObjectId;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.BasicQuery;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Repository;

import java.util.List;

import static org.springframework.data.mongodb.core.query.Criteria.where;

@Repository
public class ExamDaoImpl {
    @Autowired
    private MongoTemplate template;

    public Exam save(Exam newModel) {
        return template.save(newModel);
    }

    public Exam findPublishedExamById(String examId) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam != null && exam.isPublished()) {
            return exam;
        } else {
            return null;
        }
    }

    public List<Exam> getExamsByDoctorId(String targetUID, boolean isRecovery) {
        return template.find(new BasicQuery("{ownerId: \"" + targetUID + "\", isRecovery: " + isRecovery + "}"), Exam.class);
    }

    public long addCategoryIntoExam(String examId, QuestionCategory model) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().push("categories", model))
                .all().getModifiedCount();
    }

    public long deleteCategoryFromExam(String examId, int categoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getCategories().remove(categoryIndex);

        template.save(exam);
        return 1;
    }

    public long moveCategoryUp(String examId, int categoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        if (categoryIndex == 0) {
            return 1;
        }

        swap(exam.getCategories(), categoryIndex, categoryIndex - 1);

        template.save(exam);
        return 1;
    }

    public long moveCategoryDown(String examId, int categoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<QuestionCategory> categories = exam.getCategories();

        if (categoryIndex == categories.size() - 1) {
            return 1;
        }

        swap(categories, categoryIndex, categoryIndex + 1);

        template.save(exam);
        return 1;
    }

    public long addSubCategoryIntoExam(String examId, int categoryIndex, QuestionSubCategory model) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().push("categories." + categoryIndex + ".subCategories", model))
                .all().getModifiedCount();
    }

    public long deleteSubCategoryFromExam(String examId, int categoryIndex, int subCategoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getCategories().get(categoryIndex).getSubCategories().remove(subCategoryIndex);

        template.save(exam);
        return 1;
    }

    public long moveSubCategoryUp(String examId, int categoryIndex, int subCategoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        if (subCategoryIndex == 0) {
            return 1;
        }

        List<QuestionSubCategory> subCategories = exam.getCategories().get(categoryIndex).getSubCategories();

        swap(subCategories, subCategoryIndex, subCategoryIndex - 1);

        template.save(exam);
        return 1;
    }


    public long moveSubCategoryDown(String examId, int categoryIndex, int subCategoryIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<QuestionSubCategory> subCategories = exam.getCategories().get(categoryIndex).getSubCategories();

        if (subCategoryIndex == subCategories.size() - 1) {
            return 1;
        }

        swap(subCategories, subCategoryIndex, subCategoryIndex + 1);

        template.save(exam);
        return 1;
    }

    public long addQuestionIntoExam(String examId, int categoryIndex, int subCategoryIndex, String questionId) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().push("categories." + categoryIndex + ".subCategories." + subCategoryIndex + ".questions", questionId))
                .all().getModifiedCount();
    }

    public String deleteQuestion(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return null;
        }

        String removedId = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getQuestions().remove(questionIndex);

        template.save(exam);
        return removedId;
    }

    public long moveQuestionUp(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<String> questions = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getQuestions();

        if (questionIndex == 0) {
            return 1;
        }

        swap(questions, questionIndex, questionIndex - 1);

        template.save(exam);
        return 1;
    }

    public long moveQuestionDown(String examId, int categoryIndex, int subCategoryIndex, int questionIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<String> questions = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getQuestions();

        if (questionIndex == questions.size() - 1) {
            return 1;
        }

        swap(questions, questionIndex, questionIndex + 1);

        template.save(exam);
        return 1;
    }

    static void swap(List list, int index1, int index2) {
        Object tmp = list.get(index1);
        list.set(index1, list.get(index2));
        list.set(index2, tmp);
    }

    public long updateCategory(String examId, int categoryIndex, QuestionCategory newCategory) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getCategories().set(categoryIndex, newCategory);

        template.save(exam);
        return 1;
    }

    public long updateExamName(String examId, String newName) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().set("name", newName))
                .all().getModifiedCount();
    }

    public long updateExamDesc(String examId, String desc) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().set("description", desc))
                .all().getModifiedCount();
    }

    public long updateSubCategory(String examId, int categoryIndex, int subCategoryIndex, QuestionSubCategory subCategory) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getCategories().get(categoryIndex).getSubCategories().set(subCategoryIndex, subCategory);

        template.save(exam);
        return 1;
    }

    public long addDiagnosisRule(String examId, DiagnosisRule rule) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().push("diagnosisRules", rule))
                .all().getModifiedCount();
    }

    public long deleteDiagnosisRule(String examId, int ruleIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getDiagnosisRules().remove(ruleIndex);

        template.save(exam);
        return 1;
    }

    public int updateDiagnosisRule(String examId, int ruleIndex, DiagnosisRule rule) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        exam.getDiagnosisRules().set(ruleIndex, rule);

        template.save(exam);
        return 1;
    }

    public long addTerminateRule(String examId, int categoryIndex, int subCategoryIndex, TerminateRule rule) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<TerminateRule> termRules = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getTerminateRules();
        termRules.add(rule);

        template.save(exam);

        return 1;
    }

    public long updateTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex, TerminateRule rule) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<TerminateRule> termRules = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getTerminateRules();
        termRules.set(ruleIndex, rule);

        template.save(exam);

        return 1;
    }

    public long deleteTerminateRule(String examId, int categoryIndex, int subCategoryIndex, int ruleIndex) {
        Exam exam = template.findById(examId, Exam.class);
        if (exam == null) {
            return 0;
        }

        List<TerminateRule> termRules = exam.getCategories().get(categoryIndex).getSubCategories().get(subCategoryIndex).getTerminateRules();
        termRules.remove(ruleIndex);

        template.save(exam);

        return 1;
    }

    public long publishExam(String examId) {
        return template.update(Exam.class)
                .matching(where("_id").is(new ObjectId(examId)))
                .apply(new Update().set("isPublished", true))
                .all().getModifiedCount();
    }
}
