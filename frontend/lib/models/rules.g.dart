// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScoreRange _$ScoreRangeFromJson(Map<String, dynamic> json) => ScoreRange(
      min: (json['min'] as num?)?.toDouble() ?? double.negativeInfinity,
      max: (json['max'] as num?)?.toDouble() ?? double.infinity,
    );

Map<String, dynamic> _$ScoreRangeToJson(ScoreRange instance) =>
    <String, dynamic>{
      'min': instance.min,
      'max': instance.max,
    };

DiagnoseByScoreRange _$DiagnoseByScoreRangeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['aphasiaType'],
  );
  return DiagnoseByScoreRange(
    aphasiaType: json['aphasiaType'] as String,
  )
    ..typeName = json['typeName'] as String
    ..categoryIndices =
        (json['categoryIndices'] as List<dynamic>).map((e) => e as int).toList()
    ..ranges = (json['ranges'] as List<dynamic>)
        .map((e) => ScoreRange.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$DiagnoseByScoreRangeToJson(
        DiagnoseByScoreRange instance) =>
    <String, dynamic>{
      'typeName': instance.typeName,
      'categoryIndices': instance.categoryIndices,
      'ranges': instance.ranges.map((e) => e.toJson()).toList(),
      'aphasiaType': instance.aphasiaType,
    };

ExamEvalByCategoryScoreSum _$ExamEvalByCategoryScoreSumFromJson(
        Map<String, dynamic> json) =>
    ExamEvalByCategoryScoreSum(
      resultDimensionName: json['resultDimensionName'] as String? ?? "总分",
    )
      ..categoryIndices = (json['categoryIndices'] as List<dynamic>)
          .map((e) => e as int)
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$ExamEvalByCategoryScoreSumToJson(
        ExamEvalByCategoryScoreSum instance) =>
    <String, dynamic>{
      'categoryIndices': instance.categoryIndices,
      'resultDimensionName': instance.resultDimensionName,
      'typeName': instance.typeName,
    };

EvalBySubCategoryScoreSum _$EvalBySubCategoryScoreSumFromJson(
        Map<String, dynamic> json) =>
    EvalBySubCategoryScoreSum()..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalBySubCategoryScoreSumToJson(
        EvalBySubCategoryScoreSum instance) =>
    <String, dynamic>{
      'typeName': instance.typeName,
    };

EvalSubCategoryByQuestionScoreSum _$EvalSubCategoryByQuestionScoreSumFromJson(
        Map<String, dynamic> json) =>
    EvalSubCategoryByQuestionScoreSum()..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalSubCategoryByQuestionScoreSumToJson(
        EvalSubCategoryByQuestionScoreSum instance) =>
    <String, dynamic>{
      'typeName': instance.typeName,
    };

ContinuousWrongAnswerTerminate _$ContinuousWrongAnswerTerminateFromJson(
    Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['errorCountThreshold'],
  );
  return ContinuousWrongAnswerTerminate(
    reason: json['reason'] as String,
    equivalentScore: (json['equivalentScore'] as num).toDouble(),
    errorCountThreshold: json['errorCountThreshold'] as int,
  )..typeName = json['typeName'] as String;
}

Map<String, dynamic> _$ContinuousWrongAnswerTerminateToJson(
        ContinuousWrongAnswerTerminate instance) =>
    <String, dynamic>{
      'reason': instance.reason,
      'equivalentScore': instance.equivalentScore,
      'typeName': instance.typeName,
      'errorCountThreshold': instance.errorCountThreshold,
    };

HintRule _$HintRuleFromJson(Map<String, dynamic> json) => HintRule(
      hintText: json['hintText'] as String?,
      hintAudioUrl: json['hintAudioUrl'] as String?,
      hintImageUrl: json['hintImageUrl'] as String?,
      hintImageAssetPath: json['hintImageAssetPath'] as String?,
      scoreLowBound: (json['scoreLowBound'] as num?)?.toDouble() ?? 0.0,
      scoreHighBound: (json['scoreHighBound'] as num?)?.toDouble() ?? 1.0,
      scoreAdjustType: json['scoreAdjustType'] as int? ?? 1,
      adjustValue: (json['adjustValue'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$HintRuleToJson(HintRule instance) => <String, dynamic>{
      'hintText': instance.hintText,
      'hintAudioUrl': instance.hintAudioUrl,
      'hintImageUrl': instance.hintImageUrl,
      'hintImageAssetPath': instance.hintImageAssetPath,
      'scoreLowBound': instance.scoreLowBound,
      'scoreHighBound': instance.scoreHighBound,
      'adjustValue': instance.adjustValue,
      'scoreAdjustType': instance.scoreAdjustType,
    };

EvalCondition _$EvalConditionFromJson(Map<String, dynamic> json) =>
    EvalCondition(
      score: (json['score'] as num).toDouble(),
      isHinted: json['isHinted'] as bool? ?? false,
    )..ranges = (json['ranges'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();

Map<String, dynamic> _$EvalConditionToJson(EvalCondition instance) =>
    <String, dynamic>{
      'score': instance.score,
      'ranges': instance.ranges,
      'isHinted': instance.isHinted,
    };

EvalAudioQuestionByKeywordsMatchesCount
    _$EvalAudioQuestionByKeywordsMatchesCountFromJson(
            Map<String, dynamic> json) =>
        EvalAudioQuestionByKeywordsMatchesCount(
          defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
          keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
          enforceOrder: json['enforceOrder'] as bool? ?? false,
        )
          ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
          ..fullScore = (json['fullScore'] as num).toDouble()
          ..timeLimit = json['timeLimit'] as num
          ..conditions = (json['conditions'] as List<dynamic>)
              .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
              .toList()
          ..hintRules = (json['hintRules'] as List<dynamic>)
              .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
              .toList()
          ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionByKeywordsMatchesCountToJson(
        EvalAudioQuestionByKeywordsMatchesCount instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'keywords': instance.keywords,
      'enforceOrder': instance.enforceOrder,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalAudioQuestionByKeywordMatch _$EvalAudioQuestionByKeywordMatchFromJson(
        Map<String, dynamic> json) =>
    EvalAudioQuestionByKeywordMatch(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
      keyword: json['keyword'] as String? ?? "关键词",
    )
      ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionByKeywordMatchToJson(
        EvalAudioQuestionByKeywordMatch instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'keyword': instance.keyword,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalAudioQuestionByPronunciation _$EvalAudioQuestionByPronunciationFromJson(
        Map<String, dynamic> json) =>
    EvalAudioQuestionByPronunciation(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
      keyword: json['keyword'] as String? ?? "关键词",
    )
      ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionByPronunciationToJson(
        EvalAudioQuestionByPronunciation instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'keyword': instance.keyword,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalAudioQuestionByFluency _$EvalAudioQuestionByFluencyFromJson(
        Map<String, dynamic> json) =>
    EvalAudioQuestionByFluency(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
    )
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionByFluencyToJson(
        EvalAudioQuestionByFluency instance) =>
    <String, dynamic>{
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalAudioQuestionBySimilarity _$EvalAudioQuestionBySimilarityFromJson(
        Map<String, dynamic> json) =>
    EvalAudioQuestionBySimilarity(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
      fullScoreThreshold:
          (json['fullScoreThreshold'] as num?)?.toDouble() ?? 0.8,
      answerText: json['answerText'] as String?,
    )
      ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionBySimilarityToJson(
        EvalAudioQuestionBySimilarity instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'answerText': instance.answerText,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
      'fullScoreThreshold': instance.fullScoreThreshold,
    };

EvalAudioQuestionByWordType _$EvalAudioQuestionByWordTypeFromJson(
        Map<String, dynamic> json) =>
    EvalAudioQuestionByWordType(
      wordType: json['wordType'] as int? ?? 1,
    )
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..defaultScore = (json['defaultScore'] as num).toDouble()
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalAudioQuestionByWordTypeToJson(
        EvalAudioQuestionByWordType instance) =>
    <String, dynamic>{
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
      'wordType': instance.wordType,
    };

Choice _$ChoiceFromJson(Map<String, dynamic> json) => Choice(
      imageUrl: json['imageUrl'] as String?,
      imageAssetPath: json['imageAssetPath'] as String?,
      text: json['text'] as String? ?? "新选项",
    );

Map<String, dynamic> _$ChoiceToJson(Choice instance) => <String, dynamic>{
      'imageUrl': instance.imageUrl,
      'imageAssetPath': instance.imageAssetPath,
      'text': instance.text,
    };

EvalChoiceQuestionByCorrectChoiceCount
    _$EvalChoiceQuestionByCorrectChoiceCountFromJson(
            Map<String, dynamic> json) =>
        EvalChoiceQuestionByCorrectChoiceCount(
          defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
          enforceOrder: json['enforceOrder'] as bool? ?? false,
        )
          ..fullScore = (json['fullScore'] as num).toDouble()
          ..timeLimit = json['timeLimit'] as num
          ..conditions = (json['conditions'] as List<dynamic>)
              .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
              .toList()
          ..hintRules = (json['hintRules'] as List<dynamic>)
              .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
              .toList()
          ..typeName = json['typeName'] as String
          ..choices = (json['choices'] as List<dynamic>)
              .map((e) => Choice.fromJson(e as Map<String, dynamic>))
              .toList()
          ..correctChoices = (json['correctChoices'] as List<dynamic>)
              .map((e) => e as int)
              .toList();

Map<String, dynamic> _$EvalChoiceQuestionByCorrectChoiceCountToJson(
        EvalChoiceQuestionByCorrectChoiceCount instance) =>
    <String, dynamic>{
      'enforceOrder': instance.enforceOrder,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
      'choices': instance.choices.map((e) => e.toJson()).toList(),
      'correctChoices': instance.correctChoices,
    };

ItemSlot _$ItemSlotFromJson(Map<String, dynamic> json) => ItemSlot(
      itemName: json['itemName'] as String?,
      itemImageUrl: json['itemImageUrl'] as String?,
      itemImageAssetPath: json['itemImageAssetPath'] as String?,
    );

Map<String, dynamic> _$ItemSlotToJson(ItemSlot instance) => <String, dynamic>{
      'itemName': instance.itemName,
      'itemImageUrl': instance.itemImageUrl,
      'itemImageAssetPath': instance.itemImageAssetPath,
    };

CommandActions _$CommandActionsFromJson(Map<String, dynamic> json) =>
    CommandActions(
      sourceSlotIndex: json['sourceSlotIndex'] as int,
      firstAction: $enumDecode(_$ClickActionEnumMap, json['firstAction']),
      targetSlotIndex: json['targetSlotIndex'] as int?,
      secondAction:
          $enumDecodeNullable(_$PutDownActionEnumMap, json['secondAction']),
    );

Map<String, dynamic> _$CommandActionsToJson(CommandActions instance) =>
    <String, dynamic>{
      'sourceSlotIndex': instance.sourceSlotIndex,
      'firstAction': _$ClickActionEnumMap[instance.firstAction]!,
      'targetSlotIndex': instance.targetSlotIndex,
      'secondAction': _$PutDownActionEnumMap[instance.secondAction],
    };

const _$ClickActionEnumMap = {
  ClickAction.touch: 'touch',
  ClickAction.turnOver: 'turnOver',
  ClickAction.take: 'take',
};

const _$PutDownActionEnumMap = {
  PutDownAction.putDown: 'putDown',
  PutDownAction.cover: 'cover',
  PutDownAction.switchPlace: 'switchPlace',
};

EvalCommandQuestionByCorrectActionCount
    _$EvalCommandQuestionByCorrectActionCountFromJson(
            Map<String, dynamic> json) =>
        EvalCommandQuestionByCorrectActionCount(
          defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
          invalidActionPunishment:
              (json['invalidActionPunishment'] as num?)?.toDouble() ?? 0,
          detailMode: json['detailMode'] as bool? ?? false,
        )
          ..fullScore = (json['fullScore'] as num).toDouble()
          ..timeLimit = json['timeLimit'] as num
          ..conditions = (json['conditions'] as List<dynamic>)
              .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
              .toList()
          ..hintRules = (json['hintRules'] as List<dynamic>)
              .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
              .toList()
          ..typeName = json['typeName'] as String
          ..slots = (json['slots'] as List<dynamic>)
              .map((e) => ItemSlot.fromJson(e as Map<String, dynamic>))
              .toList()
          ..actions = (json['actions'] as List<dynamic>)
              .map((e) => CommandActions.fromJson(e as Map<String, dynamic>))
              .toList()
          ..commandText = json['commandText'] as String?;

Map<String, dynamic> _$EvalCommandQuestionByCorrectActionCountToJson(
        EvalCommandQuestionByCorrectActionCount instance) =>
    <String, dynamic>{
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
      'slots': instance.slots.map((e) => e.toJson()).toList(),
      'actions': instance.actions.map((e) => e.toJson()).toList(),
      'invalidActionPunishment': instance.invalidActionPunishment,
      'detailMode': instance.detailMode,
      'commandText': instance.commandText,
    };

EvalWritingQuestionByCorrectKeywordCount
    _$EvalWritingQuestionByCorrectKeywordCountFromJson(
            Map<String, dynamic> json) =>
        EvalWritingQuestionByCorrectKeywordCount(
          defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
          keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
        )
          ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
          ..fullScore = (json['fullScore'] as num).toDouble()
          ..timeLimit = json['timeLimit'] as num
          ..conditions = (json['conditions'] as List<dynamic>)
              .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
              .toList()
          ..hintRules = (json['hintRules'] as List<dynamic>)
              .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
              .toList()
          ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalWritingQuestionByCorrectKeywordCountToJson(
        EvalWritingQuestionByCorrectKeywordCount instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'keywords': instance.keywords,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalWritingQuestionByMatchRate _$EvalWritingQuestionByMatchRateFromJson(
        Map<String, dynamic> json) =>
    EvalWritingQuestionByMatchRate(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
      keyword: json['keyword'] as String? ?? "关键词",
    )
      ..enableFuzzyEvaluation = json['enableFuzzyEvaluation'] as bool
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String;

Map<String, dynamic> _$EvalWritingQuestionByMatchRateToJson(
        EvalWritingQuestionByMatchRate instance) =>
    <String, dynamic>{
      'enableFuzzyEvaluation': instance.enableFuzzyEvaluation,
      'keyword': instance.keyword,
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
    };

EvalItemFoundQuestion _$EvalItemFoundQuestionFromJson(
        Map<String, dynamic> json) =>
    EvalItemFoundQuestion(
      defaultScore: (json['defaultScore'] as num?)?.toDouble() ?? 0,
    )
      ..fullScore = (json['fullScore'] as num).toDouble()
      ..timeLimit = json['timeLimit'] as num
      ..conditions = (json['conditions'] as List<dynamic>)
          .map((e) => EvalCondition.fromJson(e as Map<String, dynamic>))
          .toList()
      ..hintRules = (json['hintRules'] as List<dynamic>)
          .map((e) => HintRule.fromJson(e as Map<String, dynamic>))
          .toList()
      ..typeName = json['typeName'] as String
      ..imageUrl = json['imageUrl'] as String?
      ..coordinates = (json['coordinates'] as List<dynamic>)
          .map((e) =>
              (e as List<dynamic>).map((e) => (e as num).toDouble()).toList())
          .toList();

Map<String, dynamic> _$EvalItemFoundQuestionToJson(
        EvalItemFoundQuestion instance) =>
    <String, dynamic>{
      'fullScore': instance.fullScore,
      'timeLimit': instance.timeLimit,
      'defaultScore': instance.defaultScore,
      'conditions': instance.conditions.map((e) => e.toJson()).toList(),
      'hintRules': instance.hintRules.map((e) => e.toJson()).toList(),
      'typeName': instance.typeName,
      'imageUrl': instance.imageUrl,
      'coordinates': instance.coordinates,
    };
