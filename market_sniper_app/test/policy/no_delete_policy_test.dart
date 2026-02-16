import 'package:flutter_test/flutter_test.dart';

// Logic Simulation class for the test
class DeletePolicySimulator {
  static bool check(String gitStatusOutput, bool hasFounderApproval) {
    bool hasDeletes = gitStatusOutput.split('\n').any((line) {
      return line.startsWith('D ') || line.startsWith(' D');
    });

    if (hasDeletes) {
      return hasFounderApproval;
    }
    return true; // No deletes = Pass
  }
}

void main() {
  group('Artifact Preservation Law (No-Delete) Logic', () {
    test('Passes when no files are deleted', () {
      const gitStatus = "M  file1.dart\n?? new_file.dart";
      expect(DeletePolicySimulator.check(gitStatus, false), isTrue);
    });

    test('Fails when file is deleted (D ) and no approval', () {
      const gitStatus = "D  important_widget.dart";
      expect(DeletePolicySimulator.check(gitStatus, false), isFalse);
    });

    test('Fails when file is deleted ( D) and no approval', () {
      const gitStatus = " D important_widget.dart";
      expect(DeletePolicySimulator.check(gitStatus, false), isFalse);
    });

    test('Passes when file is deleted BUT founder approval exists', () {
      const gitStatus = "D  deprecated_logic.dart";
      expect(DeletePolicySimulator.check(gitStatus, true), isTrue);
    });
  });
}
