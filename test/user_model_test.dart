import 'package:flutter_repo/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// 不可变模型测试：验证 freezed + json_serializable 生成的行为。
void main() {
  group('User', () {
    test('fromJson 正确反序列化（含嵌套 Company）', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Leanne Graham',
        'username': 'Bret',
        'email': 'Sincere@april.biz',
        'phone': '1-770-736-8031 x56442',
        'website': 'hildegard.org',
        'company': {
          'name': 'Romaguera-Crona',
          'catchPhrase': 'Multi-layered client-server neural-net',
        },
      });

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
      expect(user.company?.name, 'Romaguera-Crona');
    });

    test('缺失可选字段时使用默认值', () {
      final user = User.fromJson({'id': 1, 'name': 'Leanne Graham'});

      expect(user.email, '');
      expect(user.company, isNull);
    });

    test('copyWith 生成新实例且原对象不变（不可变性）', () {
      const user = User(id: 1, name: 'A');
      final renamed = user.copyWith(name: 'B');

      expect(user.name, 'A');
      expect(renamed.name, 'B');
      expect(identical(user, renamed), isFalse);
    });

    test('值相等性：相同字段即相等', () {
      const a = User(id: 1, name: 'A');
      const b = User(id: 1, name: 'A');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
