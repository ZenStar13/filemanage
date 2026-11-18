import 'package:file_manager/domain/models/directory_path.dart';
import 'package:file_manager/domain/navigation/navigation_history.dart';
import 'package:flutter_test/flutter_test.dart';

DirectoryPath path(String raw) => DirectoryPath.tryParse(raw)!;

void main() {
  group('NavigationHistory', () {
    test('back and forward round trip', () {
      final history = NavigationHistory(path('/a'))
        ..visit(path('/a/b'))
        ..visit(path('/a/b/c'));
      expect(history.goBack(), isTrue);
      expect(history.current, path('/a/b'));
      expect(history.goForward(), isTrue);
      expect(history.current, path('/a/b/c'));
      expect(history.canGoForward, isFalse);
    });

    test('a new visit clears the forward stack', () {
      final history = NavigationHistory(path('/a'))
        ..visit(path('/b'))
        ..goBack()
        ..visit(path('/c'));
      expect(history.canGoForward, isFalse);
      expect(history.peekBack, path('/a'));
    });

    test('visiting the current location is a no-op', () {
      final history = NavigationHistory(path('/a'))..visit(path('/a'));
      expect(history.canGoBack, isFalse);
    });
  });

  group('DirectoryPath', () {
    test('rejects relative paths', () {
      expect(DirectoryPath.tryParse('relative/dir'), isNull);
    });

    test('builds breadcrumb segments', () {
      final segments = path('/home/user/docs').segments;
      expect(segments.map((s) => s.label), ['/', 'home', 'user', 'docs']);
      expect(segments[1].path, path('/home'));
    });

    test('resolves location-bar input', () {
      final current = path('/home/user/docs');
      final home = path('/home/user');
      String? resolve(String input) => DirectoryPath.resolveUserInput(
        input,
        current: current,
        home: home,
      )?.value;
      expect(resolve('/etc/'), '/etc');
      expect(resolve('  ~ '), '/home/user');
      expect(resolve('~/Music'), '/home/user/Music');
      expect(resolve('../Pictures/./x'), '/home/user/Pictures/x');
      expect(resolve('/../..'), '/');
      expect(resolve('   '), isNull);
    });

    test('root has no parent', () {
      expect(DirectoryPath.root.parent, isNull);
    });
  });
}
