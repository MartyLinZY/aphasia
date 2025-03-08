mixin FuzzyEvalSetting {
  bool enableFuzzyEvaluation = false;

  void enableFuzzy() {
    enableFuzzyEvaluation = true;
  }

  void disableFuzzy() {
    enableFuzzyEvaluation = false;
  }
}

mixin RuleKeyword {
  String keyword = "关键字";
}

mixin KeywordList {
  List<String> keywords = ["关键字"];
}

mixin AnswerOrder {
  bool enforceOrder = false;
}

mixin LongAnswer {
  String answerText = "请输入答案文本";
}