import 'package:flutter/material.dart';
import 'package:flutter_bangla_math/flutter_bangla_math.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureBanglaMathFontsLoaded(disableRuntimeFetching: true);
  runApp(const ExampleApp());
}

enum _FontPreset { notoSans, notoSerif }

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  _FontPreset _preset = _FontPreset.notoSans;

  @override
  Widget build(BuildContext context) {
    final fontFamily = switch (_preset) {
      _FontPreset.notoSans => null,
      _FontPreset.notoSerif => notoSerifBengaliFamily,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B6E4F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4EC),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_bangla_math')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font Toggle',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_FontPreset>(
                      segments: const [
                        ButtonSegment<_FontPreset>(
                          value: _FontPreset.notoSans,
                          label: Text('Noto Sans'),
                        ),
                        ButtonSegment<_FontPreset>(
                          value: _FontPreset.notoSerif,
                          label: Text('Noto Serif'),
                        ),
                      ],
                      selected: {_preset},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _preset = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ExampleSection(
              title: 'Inline Math',
              child: BanglaMathText(
                data:
                    r'যদি $a^2+b^2=c^2$ হয়, তবে এটি সমকোণী ত্রিভুজ। আবার $\sqrt{2}$ একটি অমূলদ সংখ্যা।',
                style: const TextStyle(fontSize: 20, height: 1.5),
                fontFamily: fontFamily,
              ),
            ),
            _ExampleSection(
              title: 'Block Math',
              child: BanglaMathText(
                data: r'''সমাকলনের একটি সহজ উদাহরণ:

$$\int_0^1 x^2\,dx=\frac{1}{3}$$

এই ফলটি ক্ষেত্রফলের ধারণার সাথে মিলে যায়।''',
                style: const TextStyle(fontSize: 20, height: 1.5),
                fontFamily: fontFamily,
              ),
            ),
            _ExampleSection(
              title: 'Long Paragraph',
              child: BanglaMathText(
                data:
                    r'''ধরি একটি বৃত্তের ব্যাসার্ধ $r$। তবে ক্ষেত্রফল $A=\pi r^2$ এবং পরিধি $C=2\pi r$।
যদি $r=7$ ধরা হয়, তবে $A=49\pi$ এবং $C=14\pi$।
এখন যদি একটি আয়তের দৈর্ঘ্য $l=10$ ও প্রস্থ $w=4$ হয়, তবে ক্ষেত্রফল $lw=40$।
একই অনুচ্ছেদের মধ্যে গণিত ও বাংলা টেক্সটের মিশ্রণ যেন আলাদা আলাদা ভেঙে না যায়,
এই প্যাকেজের মূল উদ্দেশ্য সেটিই।''',
                style: const TextStyle(fontSize: 19, height: 1.7),
                fontFamily: fontFamily,
              ),
            ),
            _ExampleSection(
              title: 'Escaped Delimiter',
              child: BanglaMathText(
                data:
                    r'মূল্য \$100, কিন্তু সূত্রটি $x+y=z$। এখানে প্রথম \$ একটি সাধারণ ডলার চিহ্ন।',
                style: const TextStyle(fontSize: 18, height: 1.5),
                fontFamily: fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleSection extends StatelessWidget {
  const _ExampleSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
