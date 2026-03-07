import 'package:flutter/material.dart';
import 'package:flutter_bangla_math/flutter_bangla_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inline math uses baseline aligned widget spans', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: BanglaMathText(
              data: r'ধরি $a+b=c$ এখন সমান।',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText).first);
    final spans = _collectWidgetSpans(richText.text as TextSpan);

    expect(spans, hasLength(1));
    expect(spans.single.alignment, PlaceholderAlignment.baseline);
    expect(spans.single.baseline, TextBaseline.alphabetic);
  });

  testWidgets('renders block math separately from inline content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: BanglaMathText(data: r'শুরু $$x^2+y^2=z^2$$ শেষ'),
          ),
        ),
      ),
    );

    final column = tester.widget<Column>(
      find.descendant(
        of: find.byType(BanglaMathText),
        matching: find.byType(Column),
      ),
    );

    expect(column.children, hasLength(3));
    expect(column.children[0], isA<RichText>());
    expect(column.children[1], isA<Padding>());
    expect(column.children[2], isA<RichText>());
  });

  testWidgets(
    'fraction centers numerator and denominator with baseline-aligned inline math',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.ltr,
              child: BanglaMathFraction(
                numerator: r'লব $x+1$',
                denominator: r'হর $y+2$',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richTexts = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byType(BanglaMathFraction),
              matching: find.byType(RichText),
            ),
          )
          .where(
            (richText) =>
                richText.textAlign == TextAlign.center &&
                richText.text is TextSpan &&
                _collectWidgetSpans(richText.text as TextSpan).isNotEmpty,
          )
          .toList();

      expect(richTexts, hasLength(2));
      expect(richTexts[0].textAlign, TextAlign.center);
      expect(richTexts[1].textAlign, TextAlign.center);

      final numeratorSpans = _collectWidgetSpans(richTexts[0].text as TextSpan);
      final denominatorSpans = _collectWidgetSpans(
        richTexts[1].text as TextSpan,
      );

      expect(numeratorSpans, hasLength(1));
      expect(denominatorSpans, hasLength(1));
      expect(numeratorSpans.single.alignment, PlaceholderAlignment.baseline);
      expect(numeratorSpans.single.baseline, TextBaseline.alphabetic);
      expect(denominatorSpans.single.alignment, PlaceholderAlignment.baseline);
      expect(denominatorSpans.single.baseline, TextBaseline.alphabetic);
    },
  );

  testWidgets('fraction divider honors inherited and custom bar styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: BanglaMathFraction(
              numerator: r'লব $x$',
              denominator: r'হর $y$',
              style: TextStyle(fontSize: 18, color: Colors.teal),
              barThickness: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inheritedBar = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(BanglaMathFraction),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(inheritedBar.color, Colors.teal);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.height == 2 &&
            widget.child is ColoredBox,
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: BanglaMathFraction(
              numerator: r'লব $x$',
              denominator: r'হর $y$',
              style: TextStyle(fontSize: 18, color: Colors.teal),
              barColor: Colors.deepOrange,
              barThickness: 3,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final customBar = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(BanglaMathFraction),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(customBar.color, Colors.deepOrange);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.height == 3 &&
            widget.child is ColoredBox,
      ),
      findsOneWidget,
    );
  });

  testWidgets('matches golden for mixed Bangla and math', (tester) async {
    tester.view.physicalSize = const Size(560, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: const BanglaMathText(
                  data: r'''যদি $a^2+b^2=c^2$ হয়, তবে এটি সমকোণী ত্রিভুজ।

$$\int_0^1 x^2\,dx=\frac{1}{3}$$

মূল্য \$50 এবং সূত্র $x+y=z$।''',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/bangla_math_text.png'),
    );
  });
}

List<WidgetSpan> _collectWidgetSpans(InlineSpan span) {
  final spans = <WidgetSpan>[];

  void visit(InlineSpan current) {
    if (current case final WidgetSpan widgetSpan) {
      spans.add(widgetSpan);
      return;
    }

    if (current case final TextSpan textSpan) {
      for (final child in textSpan.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(span);
  return spans;
}
