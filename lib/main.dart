import 'package:flutter/material.dart';

void main() {
  runApp(TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English → Yorùbá Translator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: TranslatorHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TranslatorHomePage extends StatefulWidget {
  @override
  State<TranslatorHomePage> createState() => _TranslatorHomePageState();
}

class _TranslatorHomePageState extends State<TranslatorHomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _translation;

  final allowedDeterminers = {'the', 'a', ''};

  final nounMap = {
    'cat': {'singular': 'olóngbọ̀', 'plural': 'olóngbọ̀'},
    'dog': {'singular': 'aja', 'plural': 'aja'},
    'lion': {'singular': 'kìnnìún', 'plural': 'kìnnìún'},
    'moon': {'singular': 'oṣùpá', 'plural': 'oṣùpá'},
    'fish': {'singular': 'ẹja', 'plural': 'ẹja'},
    'child': {'singular': 'ọmọ', 'plural': 'ọmọ'},
    'children': {'singular': 'ọmọ', 'plural': 'ọmọ'},
  };

  final pluralNouns = {'cats', 'dogs', 'lions', 'moons', 'fish', 'children'};

  final pluralToSingular = {
    'cats': 'cat',
    'dogs': 'dog',
    'lions': 'lion',
    'moons': 'moon',
    'fish': 'fish', // fish is both
    'children': 'child',
  };

  final verbMap = {
    'saw': 'rí',
    'sees': 'wò',
    'see': 'rí',
    'chased': 'lé',
    'ate': 'jẹ',
    'eats': 'jẹ',
    'eat': 'jẹ',
  };

  // Helper to identify determiners
  bool isDeterminer(String word) => allowedDeterminers.contains(word);

  // Yoruba determiner logic
  String getYorubaDeterminer(String englishDeterminer, String nounWord) {
    if (englishDeterminer == 'the') {
      if (pluralNouns.contains(nounWord)) return 'àwọn';
      return '';
    }
    if (englishDeterminer == 'a') return 'ọ̀kan';
    return '';
  }

  // Yoruba noun (normalize to singular)
  String? getYorubaNoun(String nounWord) {
    String normalized = pluralToSingular[nounWord] ?? nounWord;
    var nounForms = nounMap[normalized];
    if (nounForms == null) return null;
    if (pluralNouns.contains(nounWord)) {
      return nounForms['plural'];
    } else {
      return nounForms['singular'];
    }
  }

  // Only for object: handle "fish children" => "ọmọ ẹja"
  String? getYorubaObjectNounCompound(List<String> nouns) {
    // Accept exactly 'fish children'
    if (nouns.length == 2 &&
        ((nouns[0] == 'fish' && nouns[1] == 'children') ||
            (nouns[0] == 'fish' && nouns[1] == 'child'))) {
      String? first = getYorubaNoun(nouns[0]);
      String? second = getYorubaNoun(nouns[1]);
      if (first != null && second != null) {
        // 'fish children' => 'ọmọ ẹja'
        return '$second $first';
      }
    }
    return null;
  }

  void _translate() {
    final input = _controller.text.trim().toLowerCase();
    final words = input.split(RegExp(r'\s+'));

    if (words.length < 3 || words.length > 6) {
      setState(() {
        _translation =
            'Sentence must follow SVO pattern (subject must not be a noun-noun compound), e.g.:\n'
            '- the lions eat fish children\n'
            '- lion chased dog\n'
            '- cat sees the dog\n'
            '- the cat chased fish';
      });
      return;
    }

    // Parse subject (no compound allowed)
    String subjectDeterminer = '', subjectNoun = '', verb = '';
    String objectDeterminer = '';
    List<String> objectNounParts = [];

    int i = 0;
    // Subject
    if (isDeterminer(words[i])) {
      subjectDeterminer = words[i];
      i++;
    }
    subjectNoun = words[i];
    i++;
    // Prevent compound subject
    if (i < words.length &&
        !verbMap.containsKey(words[i]) &&
        nounMap.containsKey(words[i])) {
      setState(() {
        _translation = 'Subject must not be a noun-noun compound!';
      });
      return;
    }

    // Verb
    if (i >= words.length) {
      setState(() {
        _translation = 'Incomplete sentence.';
      });
      return;
    }
    verb = words[i];
    i++;
    // Object
    if (i < words.length && isDeterminer(words[i])) {
      objectDeterminer = words[i];
      i++;
    }
    while (i < words.length) {
      objectNounParts.add(words[i]);
      i++;
    }

    // Subject translation
    final yorubaSubjectDeterminer = getYorubaDeterminer(subjectDeterminer, subjectNoun);
    final yorubaSubjectNoun = getYorubaNoun(subjectNoun);
    if (yorubaSubjectNoun == null) {
      setState(() {
        _translation =
            'Unknown subject noun! Please use: cat(s), dog(s), lion(s), moon(s), fish, child(ren)';
      });
      return;
    }

    // Verb translation
    final yorubaVerb = verbMap[verb];
    if (yorubaVerb == null) {
      setState(() {
        _translation =
            'Unknown verb! Please use: saw, see, sees, chased, ate, eats, eat';
      });
      return;
    }

    // Object translation (support only "fish children" or "fish child")
    String yorubaObject = '';
    if (objectNounParts.length == 2) {
      final compound = getYorubaObjectNounCompound(objectNounParts);
      if (compound != null) {
        yorubaObject = compound;
      } else {
        setState(() {
          _translation =
              'Only "fish children" or "fish child" is supported as object noun compound!';
        });
        return;
      }
    } else if (objectNounParts.length == 1) {
      final yorubaObjectDeterminer =
          getYorubaDeterminer(objectDeterminer, objectNounParts[0]);
      final yorubaObjectNoun = getYorubaNoun(objectNounParts[0]);
      if (yorubaObjectNoun == null) {
        setState(() {
          _translation =
              'Unknown object noun! Please use: cat(s), dog(s), lion(s), moon(s), fish, child(ren)';
        });
        return;
      }
      yorubaObject = yorubaObjectDeterminer.isNotEmpty
          ? '${yorubaObjectDeterminer} $yorubaObjectNoun'
          : yorubaObjectNoun;
    } else {
      setState(() {
        _translation = 'Object noun not recognized!';
      });
      return;
    }

    // Compose subject phrase
    String subjectPhrase = yorubaSubjectDeterminer.isNotEmpty
        ? '${yorubaSubjectDeterminer} $yorubaSubjectNoun'
        : yorubaSubjectNoun;

    setState(() {
      _translation = '$subjectPhrase $yorubaVerb $yorubaObject';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple English → Yorùbá Translator'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter an English sentence in SVO order:\n'
                'Subject must not be a noun-noun compound.\n',
                // 'Object can be a single noun or "fish children"/"fish child".\n'
                // 'e.g.,\n'
                // 'the lions eat fish children\n'
                // 'lion chased dog\n'
                // 'cat sees the dog\n'
                // 'the cat chased fish',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., the lions eat fish children',
                ),
                onSubmitted: (_) => _translate(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _translate,
                icon: const Icon(Icons.translate),
                label: const Text('Translate'),
              ),
              const SizedBox(height: 24),
              if (_translation != null)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _translation!,
                      style: const TextStyle(fontSize: 18, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Supported determiners: the, a (or leave blank)\n'
                'Supported subject nouns: cat(s), dog(s), lion(s), moon(s), fish, child(ren)\n'
                'Supported object nouns: cat(s), dog(s), lion(s), moon(s), fish, child(ren), fish children, fish child\n'
                'Supported verbs: saw, see, sees, chased, ate, eats, eat',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
