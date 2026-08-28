import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';

class LanguagePickerScreen extends StatefulWidget {
  final AppState state;
  const LanguagePickerScreen({super.key, required this.state});

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.state.languages.isEmpty) widget.state.loadLanguages();
    });
  }

  void _pick(Language lang) async {
    await widget.state.chooseLanguage(lang);
    if (!mounted) return;
    _showBaseLanguagePicker();
  }

  void _showBaseLanguagePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BaseLanguageSheet(
        state: widget.state,
        onDone: () {
          Navigator.of(ctx).pop();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'እንኳን ደህና መጡ!',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Welcome! Which Ethiopian language do you want to learn first?',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: EtColors.muted,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: TibebBand(height: 16, opacity: 0.9),
            ),
            Expanded(child: _buildList(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, AppState state) {
    if (state.loadingLanguages) {
      return const Center(
        child: CircularProgressIndicator(color: EtColors.green),
      );
    }

    if (state.error != null || state.languages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 44, color: EtColors.locked),
              const SizedBox(height: 12),
              Text(
                state.error ?? 'No languages available yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: EtColors.muted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: state.loadLanguages,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: EtColors.green,
      onRefresh: state.loadLanguages,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: state.languages.length,
        itemBuilder: (context, i) => _LangCard(
          lang: state.languages[i],
          onTap: () => _pick(state.languages[i]),
        ),
      ),
    );
  }
}

class _LangCard extends StatefulWidget {
  final Language lang;
  final VoidCallback onTap;
  const _LangCard({required this.lang, required this.onTap});

  @override
  State<_LangCard> createState() => _LangCardState();
}

class _LangCardState extends State<_LangCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EtColors.line, width: 1.5),
            boxShadow: [BoxShadow(color: lang.dark.withValues(alpha: 0.10), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Row(
              children: [
                Container(width: 12, color: lang.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [lang.color, lang.dark]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(lang.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeName,
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: EtColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lang.name} · ${lang.speakers} speakers',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: EtColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: lang.color.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lang.scriptPreview,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: lang.dark,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: lang.dark, size: 26),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BaseLanguageSheet extends StatelessWidget {
  final AppState state;
  final VoidCallback onDone;

  const _BaseLanguageSheet({required this.state, required this.onDone});

  static const _baseLangs = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'am', 'name': 'Amharic', 'native': 'አማርኛ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EtColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How do you speak?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose your native language — lessons will explain words in this language.',
            style: TextStyle(
              fontSize: 13,
              color: EtColors.muted,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ..._baseLangs.map((l) {
            final isSelected = state.baseLanguage == l['code'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () async {
                  await state.chooseBaseLanguage(l['code']!);
                  onDone();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EtColors.green.withValues(alpha: 0.08)
                        : EtColors.paper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? EtColors.green : EtColors.line,
                      width: isSelected ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l['native']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? EtColors.greenDark : EtColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l['name']!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: EtColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: EtColors.green, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
