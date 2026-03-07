import 'package:flutter_bangla_math/flutter_bangla_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BanglaMathParser', () {
    test('keeps escaped dollars as plain text', () {
      expect(parseBanglaMath(r'মূল্য \$100 এবং সূত্র $x+y$'), const [
        TextToken(r'মূল্য $100 এবং সূত্র '),
        InlineMathToken('x+y'),
      ]);
    });

    test('parses adjacent inline expressions', () {
      expect(parseBanglaMath(r'$a$$b$'), const [
        InlineMathToken('a'),
        InlineMathToken('b'),
      ]);
    });

    test('prioritizes block delimiters and allows newlines', () {
      expect(
        parseBanglaMath(r'''শুরু $$a+b
=c$$ শেষ'''),
        const [
          TextToken('শুরু '),
          BlockMathToken('a+b\n=c'),
          TextToken(' শেষ'),
        ],
      );
    });

    test('leaves unmatched delimiters as text', () {
      expect(parseBanglaMath(r'অসমাপ্ত $x+1'), const [
        TextToken(r'অসমাপ্ত $x+1'),
      ]);
    });

    test('keeps escaped dollar inside math content', () {
      expect(parseBanglaMath(r'$x+\$y$'), const [InlineMathToken(r'x+\$y')]);
    });
  });
}
