import 'package:aphasia_recovery/utils/algorithm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("LCS test", () {
    expect(LCS([1,2,3,4,5,6,7], [3,4,2,3,1,11,2, 3,5,7,9]), 5);
    expect(LCS([], [3,4,2,3,1,11,2, 3,5,7,9]), 0);
    expect(LCS([1,2,3,4,5,6,7], []), 0);
  });
}