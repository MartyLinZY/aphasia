import 'package:aphasia_recovery/models/exam/category.dart';
import 'package:aphasia_recovery/models/exam/exam_recovery.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/models/rules.dart';

String identity = "identity";
String validateCode = "123456";
String uid = "1";
String token = "?fakeToken\$";
String oldToken = "?oldToken\$";

String examId1 = "2143223252543";
String examId2 = "2";
String examId3 = "3";

String aphasiaType = "测试";
DiagnoseByScoreRange diagnoseByScoreRange = DiagnoseByScoreRange(aphasiaType: aphasiaType);
DiagnoseByScoreRange fakeDiagnoseByScoreRange() {
  diagnoseByScoreRange.categoryIndices.add(0);
  diagnoseByScoreRange.categoryIndices.add(2);
  diagnoseByScoreRange.ranges.add(ScoreRange(min: 0.0, max: 4.0));
  diagnoseByScoreRange.ranges.add(ScoreRange(min: 7.0, max: 10.0));
  return diagnoseByScoreRange;
}

String examEvalByCategoryScoreSumResultDimensionName = "亚项分数和";
ExamEvalRule examEvalRule = ExamEvalByCategoryScoreSum(resultDimensionName: examEvalByCategoryScoreSumResultDimensionName);
ExamEvalRule fakeExamEvalRule() {
 examEvalRule.categoryIndices.add(0);
 examEvalRule.categoryIndices.add(2);
 return examEvalRule;
}

EvalBySubCategoryScoreSum evalBySubCategoryScoreSum = EvalBySubCategoryScoreSum();

EvalSubCategoryByQuestionScoreSum evalSubCategoryByQuestionScoreSum = EvalSubCategoryByQuestionScoreSum();

var terminateReason = "测试终止";
var terminateEquivScore = 1.0;
var terminateThreshold = 1;
ContinuousWrongAnswerTerminate continuousWrongAnswerTerminate = ContinuousWrongAnswerTerminate(reason: terminateReason, equivalentScore: terminateEquivScore, errorCountThreshold: terminateThreshold);

int timeLimit = 10;
String hintText = "测试";
String hintAudioUrl = "fake://test";
String hintImageUrl = "fake://test";
double hintScoreLowBound = 0.0;
double hintScoreHighBound = 3.0;
double hintScoreAdjustValue = 1;
int hintScoreAdjustType = 1;
HintRule hintRule = HintRule(
  hintText: hintText,
  hintImageUrl: hintImageUrl,
  hintAudioUrl: hintAudioUrl,
  scoreAdjustType: hintScoreAdjustType,
  scoreHighBound: hintScoreHighBound,
  scoreLowBound: hintScoreLowBound,
);

String subCate1Name = "测试子项";
QuestionSubCategory Function() subCate = () => QuestionSubCategory(description: subCate1Name);

String cate1Name = "测试亚项";
QuestionCategory Function() category = () => QuestionCategory(description: cate1Name);

String examName = "测试测评";
String examDesc = "测试测评描述";
ExamQuestionSet Function() exam = () => ExamQuestionSet(name: examName, description: examDesc);


String examJsonData = '{'
    '"id": "$examId1", '
    '"name": "测试测评", '
    '"description": "测试测评描述",'
    '"published": false,'
    '"rules": [],'
    '"categories": [{'
    '  "description": "第一个大项",'
    '  "rules": [],'
    '  "terminateRules": [],'
    '  "subCategories": [{'
    '    "description": "子项1",'
    '    "rules": [],'
    '    "questions": [{'
    '       "id": "1",'
    '       "type": 1,'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }, {'
    '       "id": "2",'
    '       "type": 2,'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }]'
    '  }]'
    '}]'
'}';
String examListJsonData = '[{'
    '"id": "$examId1", '
    '"name": "测试测评1", '
    '"description": "测试测评描述1",'
    '"published": false,'
    '"rules": [],'
    '"categories": [{'
    '  "description": "测评1第一个大项",'
    '  "rules": [],'
    '  "terminateRules": [],'
    '  "subCategories": [{'
    '    "description": "子项1",'
    '    "rules": [],'
    '    "questions": [{'
    '       "id": "3",'
    '       "type": 1,'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }, {'
    '       "id": "4",'
    '       "type": 2,'
    '       "alias": "题目2",'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }]'
    '  }]'
    '}]'
    '},'
    '{'
    '"id": "$examId2", '
    '"name": "测试测评2", '
    '"description": "测试测评描述2",'
    '"published": false,'
    '"rules": [],'
    '"categories": [{'
    '  "description": "测评2第一个大项",'
    '  "rules": [],'
    '  "terminateRules": [],'
    '  "subCategories": [{'
    '    "description": "子项1",'
    '    "rules": [],'
    '    "questions": [{'
    '       "id": "5",'
    '       "type": 3,'
    '       "audioUrl": "test2.mp3",'
    '       "imageUrl": "test2.png"'
    '     }, {'
    '       "id": "6",'
    '       "type": 4,'
    '       "audioUrl": "test2.mp3",'
    '       "imageUrl": "test2.png"'
    '     }]'
    '  }]'
    '}]'
'}]';

String publishedExamJsonData = '{'
    '"id": "$examId3", '
    '"name": "测试测评", '
    '"description": "测试测评描述",'
    '"published": true,'
    '"rules": [],'
    '"categories": [{'
    '  "description": "第一个大项",'
    '  "rules": [],'
    '  "terminateRules": [],'
    '  "subCategories": [{'
    '    "description": "子项1",'
    '    "rules": [],'
    '    "questions": [{'
    '       "id": "1",'
    '       "type": 1,'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }, {'
    '       "id": "2",'
    '       "type": 2,'
    '       "audioUrl": "test.mp3",'
    '       "imageUrl": "test.png"'
    '     }]'
    '  }]'
    '}]'
'}';

String createExamResponseBody ({required int expectedId, required String name, required String description}) {
  return '{'
      '"id": "$expectedId", '
      '"name": "$name", '
      '"description": "$description",'
      '"published": false,'
      '"rules": [],'
      '"categories": [{'
      '  "description": "新亚项",'
      '  "rules": [],'
      '  "terminateRules": [],'
      '  "subCategories": [{'
      '    "description": "新子项",'
      '    "rules": [],'
      '    "questions": []'
      '  }]'
      '}]'
  '}';
}

String createQuestionResponseBody({
  required int expectedId, String? alias, required String questionText,
  String? imageUrl, String? audioUrl}) {

  return '{'
      '"type": 1,'
      '"id": "$expectedId",'
      '"alias": "$alias",'
      '"questionText": "$questionText",'
      '"imageUrl": "$imageUrl",'
      '"audioUrl": "$audioUrl"'
  '}';
}
