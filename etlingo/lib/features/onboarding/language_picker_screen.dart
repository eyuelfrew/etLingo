import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/et_strings.dart';
import '../../core/widgets/tibeb_band.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../home/curriculum_screen.dart';

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
      widget.state.loadBaseLanguages();
    });
  }

  Future<void> _pick(Language lang) async {
    await widget.state.chooseLanguage(lang);
    if (!mounted) return;
    await widget.state.loadBaseLanguages();
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
          if (!mounted) return;
          // After language + base language, let the user pick a chapter/lesson
          // (or continue the guided path) instead of dumping them on the path.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CurriculumScreen(
                state: widget.state,
                showPathCta: true,
              ),
            ),
          );
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EtStrings.welcome,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${EtStrings.pickLanguage}\n${EtStrings.pickLanguageSub}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: EtColors.muted,
                      height: 1.45,
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
                label: const Text('እንደገና ሞክር',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      itemCount: state.languages.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final lang = state.languages[i];
        return _LanguageCard(lang: lang, onTap: () => _pick(lang));
      },
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language lang;
  final VoidCallback onTap;
  const _LanguageCard({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EtColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EtColors.line, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [lang.color, lang.dark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(lang.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.nativeName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lang.name + (lang.speakers.isNotEmpty ? ' · ${lang.speakers}' : ''),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: EtColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (lang.helloTarget.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${lang.helloTarget} · ${lang.helloMeaning}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: lang.dark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: lang.dark, size: 26),
            ],
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

  @override
  Widget build(BuildContext context) {
    final baseLangs = state.baseLanguages;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
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
              'ምን ቋንቋ ተናግራሉ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'የሚያውቁትን ቋንቋ ይምረጡ — ትርጉሞች በዚህ ቋንቋ ይታያሉ።\nChoose the language you already speak for prompts and meanings.',
              style: TextStyle(
                fontSize: 13,
                color: EtColors.muted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ...baseLangs.map((l) {
              final isSelected = state.baseLanguage == l.code;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () async {
                    await state.chooseBaseLanguage(l.code);
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
                                l.nativeName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? EtColors.greenDark : EtColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l.name,
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
                          const Icon(Icons.check_circle_rounded,
                              color: EtColors.green, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
