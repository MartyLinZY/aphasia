// mixin TypeNameInJson {
//   get typeName => runtimeType.toString();
//
//   Map<String, dynamic> Function(T instance) toJsonWithTypeName<T>(Map<String, dynamic> Function(T) converter) {
//     // ***Note*** 一些model并未使用该方法实现toJson，集中在rules.dart与question.dart中，若要修改本方法请注意
//     return (instance) => converter(instance)..putIfAbsent("typeName", () => typeName);
//   }
// }
