import 'dart:convert';

import 'package:aphasia_recovery/exceptions/http_exceptions.dart';
import 'package:aphasia_recovery/exceptions/local_exceptions.dart';
import 'package:aphasia_recovery/models/exam/sub_category.dart';
import 'package:aphasia_recovery/models/question/question.dart';
import 'package:aphasia_recovery/models/rules.dart';
import 'package:aphasia_recovery/utils/http/http_manager.dart';
import 'package:aphasia_recovery/settings.dart';
import 'package:json_annotation/json_annotation.dart';

import 'category.dart';

part 'exam_recovery.g.dart';

@JsonSerializable(explicitToJson: true)
class ExamQuestionSet {
  String? _id;
  String name;
  String description;
  bool recovery;
  bool published;
  List<QuestionCategory> categories = [];
  // Client? _httpClient;

  String? get id => _id;

  set id(String? testId) {
    if (AppSettings.testMode) {
      _id = testId;
    } else {
      throw Exception(AppSettings.notInTestModeErrMsg);
    }
  }

  List<DiagnosisRule> diagnosisRules = [];
  List<ExamEvalRule> rules = [];

  /// 构造器中必须要带id参数，json_serialization包需要调用id setter来赋值，
  ExamQuestionSet(
      {String? id,
      this.name = "新测评",
      this.description = "",
      this.recovery = false})
      : published = false,
        _id = id;

  factory ExamQuestionSet.fromJson(Map<String, dynamic> jsonData) {
    return _$ExamQuestionSetFromJson(jsonData);
  }

  Map<String, dynamic> toJson() {
    return _$ExamQuestionSetToJson(this);
  }

  ExamQuestionSet copy() {
    return ExamQuestionSet.fromJson(jsonDecode(jsonEncode(toJson())));
  }

  static Future<ExamQuestionSet?> getById({required String id}) async {
    try {
      Map<String, dynamic> jsonData = await HttpClientManager()
          .get(url: "${HttpConstants.backendBaseUrl}/api/exams/$id");

      return ExamQuestionSet.fromJson(jsonData);
    } on HttpRequestException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  static Future<List<ExamQuestionSet>> getByDoctorUserId(
      {required String userId, bool getRecovery = false}) async {
    // List<dynamic> jsonArr;
    // TODO: uncomment these two line
    List<dynamic> jsonData;
    if (!getRecovery) {
      jsonData = await HttpClientManager().get(
          url: "${HttpConstants.backendBaseUrl}/api/doctors/$userId/exams");
    } else {
      jsonData = await HttpClientManager().get(
          url:
              "${HttpConstants.backendBaseUrl}/api/doctors/$userId/recoveries");
    }

    // TODO: remove fakeData
    // var fakeExam = ExamQuestionSet.fromJson(jsonDecode('{"name":"新测评","description":"测试用测评", "recovery": true, "published":false,"categories":[{"description":"第一项","subCategories":[{"description":"第一子项","questions":[{"alias":"叉子","questionText":"写出刚刚展示的图片中的物体的名字","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/fork.jpg","omitImageAfterSeconds":5,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"叉子","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":false},{"score":8,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":6,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"写出刚刚展示的物体的名字","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByMatchRate"},"id":null},{"alias":"梳子","questionText":"选出梳子","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想想，梳头发的梳子是哪一个？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/comb.png","text":"梳子"},{"imageUrl":"https://photo.16pic.com/00/75/74/16pic_7574368_b.jpg","imageAssetPath":null,"text":"向日葵"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/cup.jpg","text":"其他"}],"correctChoices":[0]},"id":null},{"alias":"多关键词","questionText":"老人和小孩在一起放风筝","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["老人","小孩","一起","放风筝"],"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":false},{"score":8,"ranges":[{"lowBound":3,"highBound":3}],"isHinted":false},{"score":6,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"老人和小孩在一起放风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":6,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByCorrectKeywordCount"},"id":null},{"alias":"空调","questionText":"指出空调","audioUrl":null,"imageUrl":"assets/images/for_question_setting/furniture.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false}],"hintRules":[{"hintText":"空调","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5.9,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/furniture.jpg","coordinates":[[0.15661047027506655,0.2780242531795327],[0.13797692990239574,0.25140490979000296],[0.17790594498669032,0.2780242531795327],[0.20008873114463177,0.27062999112688557],[0.2160603371783496,0.21147589470570838],[0.20629991126885536,0.1611949127477078],[0.19210292812777285,0.1212658976634132],[0.1725820763087844,0.07098491570541261],[0.1557231588287489,0.048802129547471165],[0.12821650399290152,0.04732327713694174],[0.1157941437444543,0.053238686779059456],[0.10159716060337179,0.10351966873706005],[0.09982253771073647,0.14788524105294293],[0.11135758651286602,0.20408163265306126]]},"id":null},{"alias":"指令题：梳子","questionText":"先指一下梳子，再拿起梳子盖在书本上","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/comb.png","omitImageAfterSeconds":5,"typeName":"CommandQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":0,"highBound":10}],"isHinted":false},{"score":5,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":11,"highBound":20}],"isHinted":false},{"score":4,"ranges":[{"lowBound":4,"highBound":5},{"lowBound":0,"highBound":20}],"isHinted":false},{"score":3,"ranges":[{"lowBound":0,"highBound":7}],"isHinted":false},{"score":3,"ranges":[{"lowBound":6,"highBound":6}],"isHinted":true},{"score":2,"ranges":[{"lowBound":4,"highBound":5}],"isHinted":true},{"score":1,"ranges":[{"lowBound":0,"highBound":3}],"isHinted":true}],"hintRules":[{"hintText":"指一下梳子，然后把梳子放在书本上","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":3,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalCommandQuestionByCorrectActionCount","slots":[{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"香烟","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/cigarettes.jpg"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"书本","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/book.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"梳子","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/comb.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null}],"actions":[{"sourceSlotIndex":7,"firstAction":"touch","targetSlotIndex":null,"secondAction":null},{"sourceSlotIndex":7,"firstAction":"take","targetSlotIndex":3,"secondAction":"putDown"}],"invalidActionPunishment":0,"detailMode":true,"commandText":"先指一下梳子，再拿起梳子盖在书本上"},"id":null}],"terminateRules":[{"reason":"连续答错","equivalentScore":0,"typeName":"ContinuousWrongAnswerTerminate","errorCountThreshold":2}],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"录音题：照相机","questionText":"这是什么","audioUrl":null,"imageUrl":"assets/images/for_question_setting/camera.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["照相机","拍照的","拍照","录像机","相机"],"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是照...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordsMatchesCount"},"id":null},{"alias":"录音题：单关键字","questionText":"球","audioUrl":null,"imageUrl":"assets/images/for_question_setting/ball.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"球","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是qi...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordMatch"},"id":null},{"alias":"录音题：流畅度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝、人、房子、树？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByFluency"},"id":null},{"alias":"录音题：相似度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"answerText":"两个人在地上野餐，一个人在放风筝","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionBySimilarity","fullScoreThreshold":0.8},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]},{"description":"新亚项","subCategories":[{"description":"新子项","questions":[{"alias":"选择题：球","questionText":"球是哪一个？","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":2,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想一想，球是哪一个，可以拍的球","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":1,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/ball.jpg","text":"球"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/type4_cup.jpg","text":"其他"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/bicycle.jpg","text":"其他"}],"correctChoices":[0]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"场景寻物题：找风筝","questionText":"请指出风筝在哪里","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":3,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false}],"hintRules":[{"hintText":"再想一想，连着线的风筝在哪里","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/type2_view.jpg","coordinates":[[0.7860103626943006,0.16580310880829016],[0.8002220577350111,0.2664692820133235],[0.8597335307179867,0.15544041450777202],[0.8881569207994079,0.2768319763138416]]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]}],"id":null,"diagnosisRules":[{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":10,"max":12}],"aphasiaType":"无失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":50,"max":74}],"aphasiaType":"轻度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":35,"max":49}],"aphasiaType":"中度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":15,"max":34}],"aphasiaType":"重度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":0,"max":9}],"aphasiaType":"第二亚项分数不满"}],"rules":[{"categoryIndices":[],"resultDimensionName":"测试","typeName":"ExamEvalByCategoryScoreSum"}]}'));
    // var fakeExam1 = ExamQuestionSet.fromJson(jsonDecode('{"name":"新测评","description":"测试用测评", "recovery": true, "published":false,"categories":[{"description":"第一项","subCategories":[{"description":"第一子项","questions":[{"alias":"叉子","questionText":"写出刚刚展示的图片中的物体的名字","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/fork.jpg","omitImageAfterSeconds":5,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"叉子","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":false},{"score":8,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":6,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"写出刚刚展示的物体的名字","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByMatchRate"},"id":null},{"alias":"梳子","questionText":"选出梳子","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想想，梳头发的梳子是哪一个？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/comb.png","text":"梳子"},{"imageUrl":"https://photo.16pic.com/00/75/74/16pic_7574368_b.jpg","imageAssetPath":null,"text":"向日葵"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/cup.jpg","text":"其他"}],"correctChoices":[0]},"id":null},{"alias":"多关键词","questionText":"老人和小孩在一起放风筝","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["老人","小孩","一起","放风筝"],"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":false},{"score":8,"ranges":[{"lowBound":3,"highBound":3}],"isHinted":false},{"score":6,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"老人和小孩在一起放风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":6,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByCorrectKeywordCount"},"id":null},{"alias":"空调","questionText":"指出空调","audioUrl":null,"imageUrl":"assets/images/for_question_setting/furniture.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false}],"hintRules":[{"hintText":"空调","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5.9,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/furniture.jpg","coordinates":[[0.15661047027506655,0.2780242531795327],[0.13797692990239574,0.25140490979000296],[0.17790594498669032,0.2780242531795327],[0.20008873114463177,0.27062999112688557],[0.2160603371783496,0.21147589470570838],[0.20629991126885536,0.1611949127477078],[0.19210292812777285,0.1212658976634132],[0.1725820763087844,0.07098491570541261],[0.1557231588287489,0.048802129547471165],[0.12821650399290152,0.04732327713694174],[0.1157941437444543,0.053238686779059456],[0.10159716060337179,0.10351966873706005],[0.09982253771073647,0.14788524105294293],[0.11135758651286602,0.20408163265306126]]},"id":null},{"alias":"指令题：梳子","questionText":"先指一下梳子，再拿起梳子盖在书本上","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/comb.png","omitImageAfterSeconds":5,"typeName":"CommandQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":0,"highBound":10}],"isHinted":false},{"score":5,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":11,"highBound":20}],"isHinted":false},{"score":4,"ranges":[{"lowBound":4,"highBound":5},{"lowBound":0,"highBound":20}],"isHinted":false},{"score":3,"ranges":[{"lowBound":0,"highBound":7}],"isHinted":false},{"score":3,"ranges":[{"lowBound":6,"highBound":6}],"isHinted":true},{"score":2,"ranges":[{"lowBound":4,"highBound":5}],"isHinted":true},{"score":1,"ranges":[{"lowBound":0,"highBound":3}],"isHinted":true}],"hintRules":[{"hintText":"指一下梳子，然后把梳子放在书本上","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":3,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalCommandQuestionByCorrectActionCount","slots":[{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"香烟","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/cigarettes.jpg"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"书本","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/book.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"梳子","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/comb.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null}],"actions":[{"sourceSlotIndex":7,"firstAction":"touch","targetSlotIndex":null,"secondAction":null},{"sourceSlotIndex":7,"firstAction":"take","targetSlotIndex":3,"secondAction":"putDown"}],"invalidActionPunishment":0,"detailMode":true,"commandText":"先指一下梳子，再拿起梳子盖在书本上"},"id":null}],"terminateRules":[{"reason":"连续答错","equivalentScore":0,"typeName":"ContinuousWrongAnswerTerminate","errorCountThreshold":2}],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"录音题：照相机","questionText":"这是什么","audioUrl":null,"imageUrl":"assets/images/for_question_setting/camera.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["照相机","拍照的","拍照","录像机","相机"],"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是照...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordsMatchesCount"},"id":null},{"alias":"录音题：单关键字","questionText":"球","audioUrl":null,"imageUrl":"assets/images/for_question_setting/ball.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"球","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是qi...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordMatch"},"id":null},{"alias":"录音题：流畅度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝、人、房子、树？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByFluency"},"id":null},{"alias":"录音题：相似度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"answerText":"两个人在地上野餐，一个人在放风筝","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionBySimilarity","fullScoreThreshold":0.8},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]},{"description":"新亚项","subCategories":[{"description":"新子项","questions":[{"alias":"选择题：球","questionText":"球是哪一个？","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":2,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想一想，球是哪一个，可以拍的球","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":1,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/ball.jpg","text":"球"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/type4_cup.jpg","text":"其他"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/bicycle.jpg","text":"其他"}],"correctChoices":[0]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"场景寻物题：找风筝","questionText":"请指出风筝在哪里","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":3,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false}],"hintRules":[{"hintText":"再想一想，连着线的风筝在哪里","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/type2_view.jpg","coordinates":[[0.7860103626943006,0.16580310880829016],[0.8002220577350111,0.2664692820133235],[0.8597335307179867,0.15544041450777202],[0.8881569207994079,0.2768319763138416]]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]}],"id":null,"diagnosisRules":[{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":10,"max":12}],"aphasiaType":"无失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":50,"max":74}],"aphasiaType":"轻度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":35,"max":49}],"aphasiaType":"中度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":15,"max":34}],"aphasiaType":"重度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":0,"max":9}],"aphasiaType":"第二亚项分数不满"}],"rules":[{"categoryIndices":[],"resultDimensionName":"测试","typeName":"ExamEvalByCategoryScoreSum"}]}'));
    // if (getRecovery) {
    //   fakeExam = ExamQuestionSet.fromJson(jsonDecode('{"name":"新康复","description":"测试用测评", "recovery": true, "published":false,"categories":[{"description":"第一项","subCategories":[{"description":"第一子项","questions":[{"alias":"叉子","questionText":"写出刚刚展示的图片中的物体的名字","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/fork.jpg","omitImageAfterSeconds":5,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"叉子","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":false},{"score":8,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":6,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"写出刚刚展示的物体的名字","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByMatchRate"},"id":null},{"alias":"梳子","questionText":"选出梳子","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想想，梳头发的梳子是哪一个？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/comb.png","text":"梳子"},{"imageUrl":"https://photo.16pic.com/00/75/74/16pic_7574368_b.jpg","imageAssetPath":null,"text":"向日葵"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/cup.jpg","text":"其他"}],"correctChoices":[0]},"id":null},{"alias":"多关键词","questionText":"老人和小孩在一起放风筝","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["老人","小孩","一起","放风筝"],"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":false},{"score":8,"ranges":[{"lowBound":3,"highBound":3}],"isHinted":false},{"score":6,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"老人和小孩在一起放风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":6,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByCorrectKeywordCount"},"id":null},{"alias":"空调","questionText":"指出空调","audioUrl":null,"imageUrl":"assets/images/for_question_setting/furniture.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false}],"hintRules":[{"hintText":"空调","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5.9,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/furniture.jpg","coordinates":[[0.15661047027506655,0.2780242531795327],[0.13797692990239574,0.25140490979000296],[0.17790594498669032,0.2780242531795327],[0.20008873114463177,0.27062999112688557],[0.2160603371783496,0.21147589470570838],[0.20629991126885536,0.1611949127477078],[0.19210292812777285,0.1212658976634132],[0.1725820763087844,0.07098491570541261],[0.1557231588287489,0.048802129547471165],[0.12821650399290152,0.04732327713694174],[0.1157941437444543,0.053238686779059456],[0.10159716060337179,0.10351966873706005],[0.09982253771073647,0.14788524105294293],[0.11135758651286602,0.20408163265306126]]},"id":null},{"alias":"指令题：梳子","questionText":"先指一下梳子，再拿起梳子盖在书本上","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/comb.png","omitImageAfterSeconds":5,"typeName":"CommandQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":0,"highBound":10}],"isHinted":false},{"score":5,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":11,"highBound":20}],"isHinted":false},{"score":4,"ranges":[{"lowBound":4,"highBound":5},{"lowBound":0,"highBound":20}],"isHinted":false},{"score":3,"ranges":[{"lowBound":0,"highBound":7}],"isHinted":false},{"score":3,"ranges":[{"lowBound":6,"highBound":6}],"isHinted":true},{"score":2,"ranges":[{"lowBound":4,"highBound":5}],"isHinted":true},{"score":1,"ranges":[{"lowBound":0,"highBound":3}],"isHinted":true}],"hintRules":[{"hintText":"指一下梳子，然后把梳子放在书本上","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":3,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalCommandQuestionByCorrectActionCount","slots":[{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"香烟","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/cigarettes.jpg"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"书本","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/book.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"梳子","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/comb.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null}],"actions":[{"sourceSlotIndex":7,"firstAction":"touch","targetSlotIndex":null,"secondAction":null},{"sourceSlotIndex":7,"firstAction":"take","targetSlotIndex":3,"secondAction":"putDown"}],"invalidActionPunishment":0,"detailMode":true,"commandText":"先指一下梳子，再拿起梳子盖在书本上"},"id":null}],"terminateRules":[{"reason":"连续答错","equivalentScore":0,"typeName":"ContinuousWrongAnswerTerminate","errorCountThreshold":2}],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"录音题：照相机","questionText":"这是什么","audioUrl":null,"imageUrl":"assets/images/for_question_setting/camera.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["照相机","拍照的","拍照","录像机","相机"],"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是照...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordsMatchesCount"},"id":null},{"alias":"录音题：单关键字","questionText":"球","audioUrl":null,"imageUrl":"assets/images/for_question_setting/ball.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"球","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是qi...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordMatch"},"id":null},{"alias":"录音题：流畅度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝、人、房子、树？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByFluency"},"id":null},{"alias":"录音题：相似度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"answerText":"两个人在地上野餐，一个人在放风筝","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionBySimilarity","fullScoreThreshold":0.8},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]},{"description":"新亚项","subCategories":[{"description":"新子项","questions":[{"alias":"选择题：球","questionText":"球是哪一个？","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":2,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想一想，球是哪一个，可以拍的球","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":1,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/ball.jpg","text":"球"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/type4_cup.jpg","text":"其他"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/bicycle.jpg","text":"其他"}],"correctChoices":[0]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"场景寻物题：找风筝","questionText":"请指出风筝在哪里","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":3,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false}],"hintRules":[{"hintText":"再想一想，连着线的风筝在哪里","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/type2_view.jpg","coordinates":[[0.7860103626943006,0.16580310880829016],[0.8002220577350111,0.2664692820133235],[0.8597335307179867,0.15544041450777202],[0.8881569207994079,0.2768319763138416]]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]}],"id":null,"diagnosisRules":[{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":10,"max":12}],"aphasiaType":"无失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":50,"max":74}],"aphasiaType":"轻度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":35,"max":49}],"aphasiaType":"中度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":15,"max":34}],"aphasiaType":"重度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":0,"max":9}],"aphasiaType":"第二亚项分数不满"}],"rules":[{"categoryIndices":[],"resultDimensionName":"测试","typeName":"ExamEvalByCategoryScoreSum"}]}'));
    //   fakeExam1 = ExamQuestionSet.fromJson(jsonDecode('{"name":"新康复","description":"测试用测评", "recovery": true, "published":false,"categories":[{"description":"第一项","subCategories":[{"description":"第一子项","questions":[{"alias":"叉子","questionText":"写出刚刚展示的图片中的物体的名字","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/fork.jpg","omitImageAfterSeconds":5,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"叉子","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":false},{"score":8,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":6,"ranges":[{"lowBound":2,"highBound":2}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"写出刚刚展示的物体的名字","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByMatchRate"},"id":null},{"alias":"梳子","questionText":"选出梳子","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想想，梳头发的梳子是哪一个？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/comb.png","text":"梳子"},{"imageUrl":"https://photo.16pic.com/00/75/74/16pic_7574368_b.jpg","imageAssetPath":null,"text":"向日葵"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/cup.jpg","text":"其他"}],"correctChoices":[0]},"id":null},{"alias":"多关键词","questionText":"老人和小孩在一起放风筝","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"WritingQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["老人","小孩","一起","放风筝"],"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":false},{"score":8,"ranges":[{"lowBound":3,"highBound":3}],"isHinted":false},{"score":6,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":4,"highBound":4}],"isHinted":true},{"score":4,"ranges":[{"lowBound":1,"highBound":2}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"老人和小孩在一起放风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":6,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalWritingQuestionByCorrectKeywordCount"},"id":null},{"alias":"空调","questionText":"指出空调","audioUrl":null,"imageUrl":"assets/images/for_question_setting/furniture.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false}],"hintRules":[{"hintText":"空调","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5.9,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/furniture.jpg","coordinates":[[0.15661047027506655,0.2780242531795327],[0.13797692990239574,0.25140490979000296],[0.17790594498669032,0.2780242531795327],[0.20008873114463177,0.27062999112688557],[0.2160603371783496,0.21147589470570838],[0.20629991126885536,0.1611949127477078],[0.19210292812777285,0.1212658976634132],[0.1725820763087844,0.07098491570541261],[0.1557231588287489,0.048802129547471165],[0.12821650399290152,0.04732327713694174],[0.1157941437444543,0.053238686779059456],[0.10159716060337179,0.10351966873706005],[0.09982253771073647,0.14788524105294293],[0.11135758651286602,0.20408163265306126]]},"id":null},{"alias":"指令题：梳子","questionText":"先指一下梳子，再拿起梳子盖在书本上","audioUrl":"http://localhost:8080/audio_1710342468507.wav","imageUrl":"assets/images/for_question_setting/comb.png","omitImageAfterSeconds":5,"typeName":"CommandQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":0,"highBound":10}],"isHinted":false},{"score":5,"ranges":[{"lowBound":6,"highBound":6},{"lowBound":11,"highBound":20}],"isHinted":false},{"score":4,"ranges":[{"lowBound":4,"highBound":5},{"lowBound":0,"highBound":20}],"isHinted":false},{"score":3,"ranges":[{"lowBound":0,"highBound":7}],"isHinted":false},{"score":3,"ranges":[{"lowBound":6,"highBound":6}],"isHinted":true},{"score":2,"ranges":[{"lowBound":4,"highBound":5}],"isHinted":true},{"score":1,"ranges":[{"lowBound":0,"highBound":3}],"isHinted":true}],"hintRules":[{"hintText":"指一下梳子，然后把梳子放在书本上","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":3,"adjustValue":3,"scoreAdjustType":1}],"typeName":"EvalCommandQuestionByCorrectActionCount","slots":[{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"香烟","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/cigarettes.jpg"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"书本","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/book.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":"梳子","itemImageUrl":null,"itemImageAssetPath":"assets/images/for_question_setting/comb.png"},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null},{"itemName":null,"itemImageUrl":null,"itemImageAssetPath":null}],"actions":[{"sourceSlotIndex":7,"firstAction":"touch","targetSlotIndex":null,"secondAction":null},{"sourceSlotIndex":7,"firstAction":"take","targetSlotIndex":3,"secondAction":"putDown"}],"invalidActionPunishment":0,"detailMode":true,"commandText":"先指一下梳子，再拿起梳子盖在书本上"},"id":null}],"terminateRules":[{"reason":"连续答错","equivalentScore":0,"typeName":"ContinuousWrongAnswerTerminate","errorCountThreshold":2}],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"录音题：照相机","questionText":"这是什么","audioUrl":null,"imageUrl":"assets/images/for_question_setting/camera.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keywords":["照相机","拍照的","拍照","录像机","相机"],"enforceOrder":false,"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是照...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":9,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordsMatchesCount"},"id":null},{"alias":"录音题：单关键字","questionText":"球","audioUrl":null,"imageUrl":"assets/images/for_question_setting/ball.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"keyword":"球","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[{"score":10,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":5,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"这是qi...","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":0,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByKeywordMatch"},"id":null},{"alias":"录音题：流畅度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝、人、房子、树？","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionByFluency"},"id":null},{"alias":"录音题：相似度","questionText":"请描述一下图里的内容","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":-1,"typeName":"AudioQuestion","evalRule":{"enableFuzzyEvaluation":true,"answerText":"两个人在地上野餐，一个人在放风筝","fullScore":10,"timeLimit":20,"defaultScore":0,"conditions":[],"hintRules":[{"hintText":"野餐、风筝","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalAudioQuestionBySimilarity","fullScoreThreshold":0.8},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]},{"description":"新亚项","subCategories":[{"description":"新子项","questions":[{"alias":"选择题：球","questionText":"球是哪一个？","audioUrl":null,"imageUrl":null,"omitImageAfterSeconds":20,"typeName":"ChoiceQuestion","evalRule":{"enforceOrder":false,"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":4,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":2,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":true}],"hintRules":[{"hintText":"再想一想，球是哪一个，可以拍的球","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":1,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalChoiceQuestionByCorrectChoiceCount","choices":[{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/ball.jpg","text":"球"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/type4_cup.jpg","text":"其他"},{"imageUrl":null,"imageAssetPath":"assets/images/for_question_setting/bicycle.jpg","text":"其他"}],"correctChoices":[0]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]},{"description":"新子项","questions":[{"alias":"场景寻物题：找风筝","questionText":"请指出风筝在哪里","audioUrl":null,"imageUrl":"assets/images/for_question_setting/type2_view.jpg","omitImageAfterSeconds":20,"typeName":"ItemFindingQuestion","evalRule":{"fullScore":6,"timeLimit":20,"defaultScore":0,"conditions":[{"score":6,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":false},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false},{"score":3,"ranges":[{"lowBound":1,"highBound":1}],"isHinted":true},{"score":0,"ranges":[{"lowBound":0,"highBound":0}],"isHinted":false}],"hintRules":[{"hintText":"再想一想，连着线的风筝在哪里","hintAudioUrl":null,"hintImageUrl":null,"hintImageAssetPath":null,"scoreLowBound":0,"scoreHighBound":5,"adjustValue":0,"scoreAdjustType":1}],"typeName":"EvalItemFoundQuestion","imageUrl":"assets/images/for_question_setting/type2_view.jpg","coordinates":[[0.7860103626943006,0.16580310880829016],[0.8002220577350111,0.2664692820133235],[0.8597335307179867,0.15544041450777202],[0.8881569207994079,0.2768319763138416]]},"id":null}],"terminateRules":[],"evalRules":[{"typeName":"EvalSubCategoryByQuestionScoreSum"}]}],"rules":[{"typeName":"EvalBySubCategoryScoreSum"}]}],"id":null,"diagnosisRules":[{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":10,"max":12}],"aphasiaType":"无失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":50,"max":74}],"aphasiaType":"轻度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":35,"max":49}],"aphasiaType":"中度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0],"ranges":[{"min":15,"max":34}],"aphasiaType":"重度失语"},{"typeName":"DiagnoseByScoreRange","categoryIndices":[0,1],"ranges":[{"min":75,"max":82},{"min":0,"max":9}],"aphasiaType":"第二亚项分数不满"}],"rules":[{"categoryIndices":[],"resultDimensionName":"测试","typeName":"ExamEvalByCategoryScoreSum"}]}'));
    // }

    // var jsonData = [fakeExam.toJson(), fakeExam1.toJson()];

    return jsonData.map((e) => ExamQuestionSet.fromJson(e)).toList();
  }

  static Future<ExamQuestionSet> createExam(
      {required String name,
      String description = "",
      bool isRecovery = false}) async {
    var exam = ExamQuestionSet(
        name: name, description: description, recovery: isRecovery);

    var jsonData = await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams",
        body: jsonEncode(exam.toJson()));

    return ExamQuestionSet.fromJson(jsonData);
  }

  /// 仅本地添加测评亚项，不与后端同步
  void addCategoryLocally({String description = "新亚项"}) {
    categories.add(QuestionCategory(description: description));
  }

  void _checkPublished() {
    if (published) {
      throw EditPublishedQuestionSetException();
    }
  }

  void _checkCategoryIndex(int index) {
    if (index < 0 || index >= categories.length) {
      throw RangeError.index(index, categories);
    }
  }

  Future<void> updateName({required String newName}) async {
    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/name/$newName",
        body: '{}');

    name = newName;
  }

  Future<void> updateDescription({required String newDescription}) async {
    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/desc/$newDescription",
        body: '{}');

    description = newDescription;
  }

  /// 新增测评亚项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionCategory> addCategory(
      {String description = "新亚项", int? insertAt}) async {
    insertAt ??= categories.length;

    _checkPublished();
    if (insertAt != categories.length) {
      // 允许插入到亚项列表末尾
      _checkCategoryIndex(insertAt);
    }

    // 默认添加一条按子项得分求和得评分规则
    var newCategory = QuestionCategory(description: description)
      ..rules.add(EvalBySubCategoryScoreSum());
    await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/category",
        body: jsonEncode(newCategory.toJson()));

    categories.insert(insertAt, newCategory);

    return categories[insertAt];
  }

  /// 删除亚项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionCategory> deleteCategory({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex");

    // TODO: 检查诊断规则是否需要移除

    for (int i = 0; i < diagnosisRules.length; i++) {
      var diagnosisRule = diagnosisRules[i];
      var removeAt = diagnosisRule.removeCategory(categoryIndex);
      if (removeAt != -1) {
        await updateDiagnosisRule(updatedRule: diagnosisRule, ruleIndex: i);
      }
    }

    return categories.removeAt(categoryIndex);
  }

  Future<void> updateCategory(
      {required QuestionCategory updatedCategory,
      required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex",
        body: jsonEncode(updatedCategory.toJson()));

    // debugPrint(categories.fold("", (previousValue, element) => "$previousValue\n${element.toJson()}"));
    categories[categoryIndex] = updatedCategory;
  }

  Future<void> moveCategoryUp({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/up",
        body: '{}');

    if (categoryIndex > 0) {
      var tmp = categories[categoryIndex - 1];
      categories[categoryIndex - 1] = categories[categoryIndex];
      categories[categoryIndex] = tmp;
    }
  }

  Future<void> moveCategoryDown({required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/down",
        body: '{}');

    if (categoryIndex < categories.length - 1) {
      var tmp = categories[categoryIndex + 1];
      categories[categoryIndex + 1] = categories[categoryIndex];
      categories[categoryIndex] = tmp;
    }
  }

  void _checkSubCategoryIndex(int categoryIndex, int subCategoryIndex) {
    _checkCategoryIndex(categoryIndex);
    var category = categories[categoryIndex];
    if (subCategoryIndex < 0 ||
        subCategoryIndex >= category.subCategories.length) {
      throw RangeError.index(subCategoryIndex, category.subCategories);
    }
  }

  Future<QuestionSubCategory> addSubCategory(
      {String description = "新子项", required int categoryIndex}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);
    QuestionCategory category = categories[categoryIndex];

    // 默认添加一条评分规则：下属所有题目得分之和
    var newSubCategory = QuestionSubCategory(description: description)
      ..evalRules.add(EvalSubCategoryByQuestionScoreSum());
    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategory",
        body: jsonEncode(newSubCategory.toJson()));

    category.subCategories.add(newSubCategory);

    return category.subCategories.last;
  }

  /// 修改测评子项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<void> updateSubCategory(
      {required QuestionSubCategory updatedSubCategory,
      required int categoryIndex,
      required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    QuestionCategory category = categories[categoryIndex];

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex",
        body: jsonEncode(updatedSubCategory.toJson()));

    category.subCategories[subCategoryIndex] = updatedSubCategory;
  }

  /// 删除指定测评子项，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<QuestionSubCategory> deleteSubCategory(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    QuestionCategory category = categories[categoryIndex];

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex");

    return category.subCategories.removeAt(subCategoryIndex);
  }

  Future<void> moveSubCategoryUp(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/up",
        body: '{}');

    if (subCategoryIndex > 0) {
      QuestionSubCategory tmp =
          categories[categoryIndex].subCategories[subCategoryIndex - 1];
      categories[categoryIndex].subCategories[subCategoryIndex - 1] =
          categories[categoryIndex].subCategories[subCategoryIndex];
      categories[categoryIndex].subCategories[subCategoryIndex] = tmp;
    }
  }

  Future<void> moveSubCategoryDown(
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/down",
        body: '{}');
    if (subCategoryIndex < categories[categoryIndex].subCategories.length - 1) {
      QuestionSubCategory tmp =
          categories[categoryIndex].subCategories[subCategoryIndex + 1];
      categories[categoryIndex].subCategories[subCategoryIndex + 1] =
          categories[categoryIndex].subCategories[subCategoryIndex];
      categories[categoryIndex].subCategories[subCategoryIndex] = tmp;
    }
  }

  _checkQuestionIndex(int categoryIndex, int subCateIndex, int questionIndex) {
    _checkSubCategoryIndex(categoryIndex, subCateIndex);
    if (questionIndex < 0 ||
        questionIndex >=
            categories[categoryIndex]
                .subCategories[subCateIndex]
                .questions
                .length) {
      throw RangeError.index(questionIndex,
          categories[categoryIndex].subCategories[subCateIndex].questions);
    }
  }

  /// 新增问题，发送http请求更新后台数据库，若http请求失败，本地数据不变。要求测评未发布，否则抛出[EditPublishedQuestionSetException]异常
  Future<Question> addQuestion(Question questionToAdd,
      {required int categoryIndex, required int subCategoryIndex}) async {
    _checkPublished();
    if (categoryIndex >= categories.length ||
        subCategoryIndex >= categories[categoryIndex].subCategories.length) {
      if (categoryIndex >= categories.length) {
        throw RangeError.index(categoryIndex, categories);
      } else {
        throw RangeError.index(
            subCategoryIndex, categories[categoryIndex].subCategories);
      }
    }

    var jsonData = await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/question",
        body: jsonEncode(questionToAdd.toJson()));
    // 测试
    // var jsonData = questionToAdd.toJson();

    // debugPrint(jsonEncode(questionToAdd.toJson()));
    var newQuestion = Question.fromJson(jsonData);
    // debugPrint(jsonEncode(newQuestion.toJson()));
    categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions
        .add(newQuestion);

    return newQuestion;
  }

  Future<void> updateQuestion(Question updated,
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkPublished();
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/questions/${updated.id}",
        body: jsonEncode(updated.toJson()));

    categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions[questionIndex] = updated;
  }

  Future<Question> deleteQuestion(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex");

    return categories[categoryIndex]
        .subCategories[subCategoryIndex]
        .questions
        .removeAt(questionIndex);
  }

  Future<void> moveQuestionUp(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex/up",
        body: '{}');

    var subCategoryToUpdate =
        categories[categoryIndex].subCategories[subCategoryIndex];
    if (questionIndex > 0) {
      var tmp = subCategoryToUpdate.questions[questionIndex - 1];
      subCategoryToUpdate.questions[questionIndex - 1] =
          subCategoryToUpdate.questions[questionIndex];
      subCategoryToUpdate.questions[questionIndex] = tmp;
    }
  }

  Future<void> moveQuestionDown(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int questionIndex}) async {
    _checkQuestionIndex(categoryIndex, subCategoryIndex, questionIndex);

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/questions/$questionIndex/down",
        body: '{}');

    var subCategoryToUpdate =
        categories[categoryIndex].subCategories[subCategoryIndex];
    if (questionIndex < subCategoryToUpdate.questions.length - 1) {
      var tmp = subCategoryToUpdate.questions[questionIndex + 1];
      subCategoryToUpdate.questions[questionIndex + 1] =
          subCategoryToUpdate.questions[questionIndex];
      subCategoryToUpdate.questions[questionIndex] = tmp;
    }
  }

  /// 仅设置published = ture, 目前仅用于测试
  void _setPublished() {
    published = true;
  }

  /// remote method, 发送http请求到后端保存
  Future<void> publish() async {
    checkSettingBeforePublish();

    await HttpClientManager().patch(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id", body: '{}');

    _setPublished();
  }

  void _checkDiagnosisRuleIndex({required int ruleIndex}) {
    if (ruleIndex < 0 || ruleIndex >= diagnosisRules.length) {
      throw RangeError.index(ruleIndex, diagnosisRules);
    }
  }

  Future<void> addDiagnosisRule(
      {required DiagnosisRule newRule, int? ruleIndex}) async {
    _checkPublished();
    ruleIndex ??= diagnosisRules.length;
    if (ruleIndex != diagnosisRules.length) {
      _checkDiagnosisRuleIndex(ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url: "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRule",
        body: jsonEncode(newRule.toJson()));

    diagnosisRules.insert(ruleIndex, newRule);
  }

  Future<DiagnosisRule> deleteDiagnosisRule({required int ruleIndex}) async {
    _checkPublished();
    _checkDiagnosisRuleIndex(ruleIndex: ruleIndex);

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRules/$ruleIndex");

    return diagnosisRules.removeAt(ruleIndex);
  }

  Future<void> updateDiagnosisRule(
      {required DiagnosisRule updatedRule, required int ruleIndex}) async {
    _checkPublished();

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/diagnosisRules/$ruleIndex",
        body: jsonEncode(updatedRule.toJson()));

    diagnosisRules[ruleIndex] = updatedRule;
  }

  _checkCategoryEvalRuleIndex(
      {required int categoryIndex, required int ruleIndex}) {
    _checkCategoryIndex(categoryIndex);
    var category = categories[categoryIndex];
    if (ruleIndex < 0 || ruleIndex >= category.rules.length) {
      throw RangeError.index(ruleIndex, category.rules);
    }
  }

  Future<void> addCategoryEvalRule(
      {required int categoryIndex,
      int? ruleIndex,
      required ExamCategoryEvalRule newRule}) async {
    _checkPublished();
    _checkCategoryIndex(categoryIndex);

    ruleIndex ??= categories[categoryIndex].rules.length;

    if (ruleIndex != categories[categoryIndex].rules.length) {
      _checkCategoryEvalRuleIndex(
          categoryIndex: categoryIndex, ruleIndex: ruleIndex);
    }

    // TODO: http请求

    categories[categoryIndex].rules.insert(ruleIndex, newRule);
  }

  Future<void> updateCategoryEvalRule(
      {required int categoryIndex,
      required int ruleIndex,
      required ExamCategoryEvalRule updatedEvalRule}) async {
    _checkPublished();
    _checkCategoryEvalRuleIndex(
        categoryIndex: categoryIndex, ruleIndex: ruleIndex);

    // TODO: http请求

    categories[categoryIndex].rules[ruleIndex] = updatedEvalRule;
  }

  Future<ExamCategoryEvalRule> deleteCategoryEvalRule(
      {required int categoryIndex, required int ruleIndex}) async {
    _checkPublished();
    _checkCategoryEvalRuleIndex(
        categoryIndex: categoryIndex, ruleIndex: ruleIndex);

    // TODO: http请求

    var categoryToUpdate = categories[categoryIndex];
    return categoryToUpdate.rules.removeAt(ruleIndex);
  }

  _checkSubCategoryEvalRuleIndex(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) {
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    var subCategory = categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex < 0 || ruleIndex >= subCategory.evalRules.length) {
      throw RangeError.index(ruleIndex, subCategory.evalRules);
    }
  }

  Future<void> addSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      int? ruleIndex,
      required ExamSubCategoryEvalRule newRule}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];
    ruleIndex ??= subCategory.evalRules.length;

    if (ruleIndex != subCategory.evalRules.length) {
      _checkSubCategoryEvalRuleIndex(
          categoryIndex: categoryIndex,
          subCategoryIndex: subCategoryIndex,
          ruleIndex: ruleIndex);
    }

    // TODO: http请求

    subCategory.evalRules.insert(ruleIndex, newRule);
  }

  Future<void> updateSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex,
      required ExamSubCategoryEvalRule updatedEvalRule}) async {
    _checkPublished();
    _checkSubCategoryEvalRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    // TODO: http请求

    subCategory.evalRules[ruleIndex] = updatedEvalRule;
  }

  Future<ExamSubCategoryEvalRule> deleteSubCategoryEvalRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) async {
    _checkPublished();
    _checkSubCategoryEvalRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    // TODO: http请求

    // TODO: 检查所有子项中是否有需要移除的终止规则

    return subCategory.evalRules.removeAt(ruleIndex);
  }

  _checkSubCategoryTerminateRuleIndex(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) {
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);
    var subCategory = categories[categoryIndex].subCategories[subCategoryIndex];
    if (ruleIndex < 0 || ruleIndex >= subCategory.terminateRules.length) {
      throw RangeError.index(ruleIndex, subCategory.terminateRules);
    }
  }

  Future<void> addSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      int? ruleIndex,
      required TerminateRule newRule}) async {
    _checkPublished();
    _checkSubCategoryIndex(categoryIndex, subCategoryIndex);

    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];
    ruleIndex ??= subCategory.terminateRules.length;

    if (ruleIndex != subCategory.terminateRules.length) {
      _checkSubCategoryTerminateRuleIndex(
          categoryIndex: categoryIndex,
          subCategoryIndex: subCategoryIndex,
          ruleIndex: ruleIndex);
    }

    await HttpClientManager().post(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRule",
        body: jsonEncode(newRule.toJson()));

    subCategory.terminateRules.insert(ruleIndex, newRule);
  }

  Future<void> updateSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex,
      required TerminateRule updatedEvalRule}) async {
    _checkPublished();
    _checkSubCategoryTerminateRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().patch(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRules/$ruleIndex",
        body: jsonEncode(updatedEvalRule.toJson()));

    subCategory.terminateRules[ruleIndex] = updatedEvalRule;
  }

  Future<TerminateRule> deleteSubCategoryTerminateRule(
      {required int categoryIndex,
      required int subCategoryIndex,
      required int ruleIndex}) async {
    _checkPublished();
    _checkSubCategoryTerminateRuleIndex(
        categoryIndex: categoryIndex,
        subCategoryIndex: subCategoryIndex,
        ruleIndex: ruleIndex);
    QuestionSubCategory subCategory =
        categories[categoryIndex].subCategories[subCategoryIndex];

    await HttpClientManager().delete(
        url:
            "${HttpConstants.backendBaseUrl}/api/exams/$_id/categories/$categoryIndex/subCategories/$subCategoryIndex/terminateRules/$ruleIndex");

    return subCategory.terminateRules.removeAt(ruleIndex);
  }

  void checkSettingBeforePublish() {
    bool needCategory = categories.isEmpty;
    bool needDiagnosisRule = diagnosisRules.isEmpty;
    bool needEvalRule = false;
    bool needSubCategory = false;
    bool needCateEvalRule = false;
    bool needQuestion = false;
    bool needSubCateEvalRule = false;

    // 这里没有记录所有的缺失，只记录了部分，后面可以改
    _passOrThrowIncompleteException(
        needSubCategory,
        needSubCateEvalRule,
        needQuestion,
        needCateEvalRule,
        needEvalRule,
        needDiagnosisRule,
        needCategory);
    for (int i = 0; i < categories.length; i++) {
      var category = categories[i];
      needSubCategory = category.subCategories.isEmpty;
      needCateEvalRule = category.rules.isEmpty;
      _passOrThrowIncompleteException(
          needSubCategory,
          needSubCateEvalRule,
          needQuestion,
          needCateEvalRule,
          needEvalRule,
          needDiagnosisRule,
          needCategory,
          cateIndex: i);
      for (var j = 0; j < category.subCategories.length; j++) {
        var subCategory = category.subCategories[j];
        needSubCateEvalRule = subCategory.evalRules.isEmpty;
        needQuestion = subCategory.questions.isEmpty;
        _passOrThrowIncompleteException(
            needSubCategory,
            needSubCateEvalRule,
            needQuestion,
            needCateEvalRule,
            needEvalRule,
            needDiagnosisRule,
            needCategory,
            cateIndex: i,
            subCateIndex: j);
      }
    }
  }

  void _passOrThrowIncompleteException(
    bool needSubCategory,
    bool needSubCateEvalRule,
    bool needQuestion,
    bool needCateEvalRule,
    bool needEvalRule,
    bool needDiagnosisRule,
    bool needCategory, {
    int? cateIndex,
    int? subCateIndex,
  }) {
    if (needSubCategory ||
        needSubCateEvalRule ||
        needQuestion ||
        needCateEvalRule ||
        needEvalRule ||
        needDiagnosisRule ||
        needCategory) {
      throw InCompleteExamException(
        needCategory: needCategory,
        needDiagnosisRule: needDiagnosisRule,
        needEvalRule: needEvalRule,
        needSubCategory: needSubCategory,
        needCateEvalRule: needCateEvalRule,
        needQuestion: needQuestion,
        needSubCateEvalRule: needSubCateEvalRule,
        categoryIndex: cateIndex,
        subCategoryIndex: subCateIndex,
      );
    }
  }
}
