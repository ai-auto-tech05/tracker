import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/primary_button.dart';

// ─── Slide data (unchanged from original) ─────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.track_changes_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.primarySurface,
    title: 'Your discipline,\namplified.',
    subtitle:
        'Track habits, manage tasks, and own your focus — all in one clean workspace.',
  ),
  _OnboardingPage(
    icon: Icons.local_fire_department_rounded,
    iconColor: AppColors.accent,
    bgColor: AppColors.accentSurface,
    title: 'Build unbreakable\nhabits',
    subtitle:
        'Track daily streaks, visualize consistency, and stay accountable to yourself.',
  ),
  _OnboardingPage(
    icon: Icons.timer_rounded,
    iconColor: AppColors.success,
    bgColor: AppColors.successSurface,
    title: 'Deep work,\non demand',
    subtitle:
        'Structured focus sessions keep you in flow and protect your most valuable hours.',
  ),
  _OnboardingPage(
    icon: Icons.check_circle_rounded,
    iconColor: Color(0xFF7C3AED),
    bgColor: Color(0xFFF5F3FF),
    title: 'Clear tasks,\nclear mind',
    subtitle:
        'Capture everything, prioritize what matters, and finish your day with confidence.',
  ),
];

// ─── Phase enum ────────────────────────────────────────────────────────────────

enum _Phase { slides, name, quiz, reveal }

// ─── Profile types ─────────────────────────────────────────────────────────────

enum _ProfileType {
  lastMinute,
  overthinker,
  chaos,
  silent,
  burnout,
  distraction,
  perfectionist,
}

// ─── Quiz data classes ─────────────────────────────────────────────────────────

class _Choice {
  final String label;
  final _ProfileType profile;
  const _Choice(this.label, this.profile);
}

class _QuizQ {
  final String question;
  final List<_Choice> choices;
  const _QuizQ({required this.question, required this.choices});
}

// ─── Profile definition ────────────────────────────────────────────────────────

class _Profile {
  final _ProfileType type;
  final String name;
  final String emoji;
  final String tagline;
  final String description;
  final String notificationStyle; // gentle | sarcastic | brutal
  final Color color;

  const _Profile({
    required this.type,
    required this.name,
    required this.emoji,
    required this.tagline,
    required this.description,
    required this.notificationStyle,
    required this.color,
  });
}

// ─── Quiz questions ────────────────────────────────────────────────────────────

const _questions = [
  _QuizQ(
    question: "What's your biggest productivity killer?",
    choices: [
      _Choice("Social media / phone distractions", _ProfileType.distraction),
      _Choice("Overthinking before I even start", _ProfileType.overthinker),
      _Choice("Too many things pulling me in all directions", _ProfileType.chaos),
      _Choice("I wait until I absolutely have to move", _ProfileType.lastMinute),
      _Choice("I push too hard and then crash completely", _ProfileType.burnout),
    ],
  ),
  _QuizQ(
    question: "Deadline is tomorrow. You...",
    choices: [
      _Choice("Started weeks ago — basically done already", _ProfileType.silent),
      _Choice("Panic mode ON, but I somehow deliver", _ProfileType.lastMinute),
      _Choice("I've been 'about to start' for three days", _ProfileType.overthinker),
      _Choice("Thrive in the chaos, honestly", _ProfileType.chaos),
      _Choice("Realize I said yes to five other things too", _ProfileType.burnout),
    ],
  ),
  _QuizQ(
    question: "Your task list looks like...",
    choices: [
      _Choice("Perfectly organized, rarely completed", _ProfileType.perfectionist),
      _Choice("47 items and growing by the hour", _ProfileType.chaos),
      _Choice("3 focused items. I keep it surgical", _ProfileType.silent),
      _Choice("Task list? I wing it based on vibes", _ProfileType.lastMinute),
      _Choice("A bunch of tabs I'll 'get to later'", _ProfileType.distraction),
    ],
  ),
  _QuizQ(
    question: "Pick your villain origin story:",
    choices: [
      _Choice("Fell into a YouTube rabbit hole at 9 PM", _ProfileType.distraction),
      _Choice("Spent 2 hours color-coding my planner", _ProfileType.perfectionist),
      _Choice("Said yes to everything, then quietly vanished", _ProfileType.burnout),
      _Choice("Convinced myself I work better under pressure", _ProfileType.lastMinute),
      _Choice("Started 7 projects, shipped exactly 0", _ProfileType.chaos),
    ],
  ),
  _QuizQ(
    question: "After a rough, unproductive day...",
    choices: [
      _Choice("Reset and start fresh — life goes on", _ProfileType.silent),
      _Choice("Spiral and replay what went wrong all night", _ProfileType.overthinker),
      _Choice("Overcommit tomorrow to make up for it", _ProfileType.burnout),
      _Choice("It was fine. I'll figure it out eventually", _ProfileType.lastMinute),
    ],
  ),
  _QuizQ(
    question: "To actually be consistent, you need...",
    choices: [
      _Choice("Less to think about upfront", _ProfileType.overthinker),
      _Choice("Something holding me accountable", _ProfileType.lastMinute),
      _Choice("Fewer distractions around me", _ProfileType.distraction),
      _Choice("More realistic, achievable goals", _ProfileType.perfectionist),
      _Choice("A system that doesn't immediately overwhelm me", _ProfileType.chaos),
    ],
  ),
];

// ─── Profile definitions ───────────────────────────────────────────────────────

const _profiles = {
  _ProfileType.lastMinute: _Profile(
    type: _ProfileType.lastMinute,
    name: 'Last-Minute Survivor',
    emoji: '⏰',
    tagline: "You do your best work at 11:58 PM.",
    description:
        "Deadlines are your fuel. You've shipped things in the last 10 minutes more times than you'd admit. The app will nudge you before the pressure builds — not after.",
    notificationStyle: 'sarcastic',
    color: Color(0xFFF59E0B),
  ),
  _ProfileType.overthinker: _Profile(
    type: _ProfileType.overthinker,
    name: 'Chronic Overthinker',
    emoji: '🌀',
    tagline: "Starting is the hardest part. Every. Single. Time.",
    description:
        "You have a brilliant plan. Several, actually. You just haven't started any of them yet. We'll help you break the loop and take the first step without it feeling like a commitment.",
    notificationStyle: 'gentle',
    color: Color(0xFF6366F1),
  ),
  _ProfileType.chaos: _Profile(
    type: _ProfileType.chaos,
    name: 'Chaos Commander',
    emoji: '🌪️',
    tagline: "You thrive in disorder. The disorder does not thrive back.",
    description:
        "You're doing 14 things and finishing 2. Impressive energy, questionable direction. The app will help you channel that chaos into actual output you can be proud of.",
    notificationStyle: 'sarcastic',
    color: Color(0xFFEC4899),
  ),
  _ProfileType.silent: _Profile(
    type: _ProfileType.silent,
    name: 'Silent Achiever',
    emoji: '🧊',
    tagline: "Consistent, focused, and criminally underrated.",
    description:
        "You don't need motivation speeches — you need a solid system and to stay out of your own way. This app will keep the noise low and your streak very much alive.",
    notificationStyle: 'gentle',
    color: Color(0xFF10B981),
  ),
  _ProfileType.burnout: _Profile(
    type: _ProfileType.burnout,
    name: 'Burnout Machine',
    emoji: '🔋',
    tagline: "You give 200% until you give 0%.",
    description:
        "You're not lazy — you're running on empty. You overcommit, under-rest, and wonder why it keeps happening. We'll help you pace yourself before you hit the wall again.",
    notificationStyle: 'brutal',
    color: Color(0xFFEF4444),
  ),
  _ProfileType.distraction: _Profile(
    type: _ProfileType.distraction,
    name: 'Distraction Magnet',
    emoji: '📱',
    tagline: "You opened this app after three other apps.",
    description:
        "Bright objects, pings, and the fear of missing out are your natural enemies. We'll help you build focus like a muscle — one short session at a time.",
    notificationStyle: 'sarcastic',
    color: Color(0xFF8B5CF6),
  ),
  _ProfileType.perfectionist: _Profile(
    type: _ProfileType.perfectionist,
    name: 'Reluctant Perfectionist',
    emoji: '🎯',
    tagline: "Done is the enemy of perfect, apparently.",
    description:
        "Your standards are impressively high. Too high to actually ship anything. We'll nudge you toward 'good enough to finish' instead of 'perfect and never done'.",
    notificationStyle: 'brutal',
    color: Color(0xFF0EA5E9),
  ),
};

// ─── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  _Phase _phase = _Phase.slides;

  // Name phase
  final _nameController = TextEditingController();

  // Quiz phase
  int _quizIndex = 0;
  final List<int> _selectedAnswers = List.filled(_questions.length, -1);

  // Reveal phase
  _Profile? _resultProfile;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToPhase(_Phase phase) => setState(() => _phase = phase);

  // ── Slides ──────────────────────────────────────────────────────────────────

  void _nextSlide() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToPhase(_Phase.name);
    }
  }

  // ── Quiz ────────────────────────────────────────────────────────────────────

  void _selectAnswer(int answerIndex) {
    setState(() => _selectedAnswers[_quizIndex] = answerIndex);
    // Auto-advance after brief pause so the selection highlight registers
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      if (_quizIndex < _questions.length - 1) {
        setState(() => _quizIndex++);
      } else {
        _computeProfile();
      }
    });
  }

  void _computeProfile() {
    final tally = <_ProfileType, int>{};
    for (var i = 0; i < _questions.length; i++) {
      final sel = _selectedAnswers[i];
      if (sel < 0) continue;
      final type = _questions[i].choices[sel].profile;
      tally[type] = (tally[type] ?? 0) + 1;
    }
    _ProfileType winner = _ProfileType.lastMinute;
    int max = 0;
    tally.forEach((type, count) {
      if (count > max) {
        max = count;
        winner = type;
      }
    });
    setState(() {
      _resultProfile = _profiles[winner];
      _phase = _Phase.reveal;
    });
  }

  // ── Finish ──────────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _resultProfile == null) return;
    setState(() => _saving = true);
    final notifier = ref.read(userProvider.notifier);
    await notifier.createUser(
      name,
      productivityProfile: _resultProfile!.name,
      notificationStyle: _resultProfile!.notificationStyle,
    );
    await notifier.completeOnboarding();
    if (mounted) context.go(AppRoutes.dashboard);
  }

  // ── Build root ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          ),
          child: switch (_phase) {
            _Phase.slides => _buildSlides(),
            _Phase.name   => _buildNameEntry(),
            _Phase.quiz   => _buildQuiz(),
            _Phase.reveal => _buildReveal(),
          },
        ),
      ),
    );
  }

  // ─────────────────────────────── SLIDES ────────────────────────────────────

  Widget _buildSlides() {
    return Column(
      key: const ValueKey('slides'),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _goToPhase(_Phase.name),
            child: Text(
              'Skip',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _buildSlidePage(_pages[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            16,
            AppDimensions.screenPadding,
            24,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onTap: _nextSlide,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlidePage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 56, color: page.iconColor),
          )
              .animate()
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  height: 1.2,
                ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  // ─────────────────────────────── NAME ──────────────────────────────────────

  Widget _buildNameEntry() {
    return Padding(
      key: const ValueKey('name'),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: AppColors.primary, size: 28),
          ).animate().scale(curve: Curves.elasticOut).fadeIn(),
          const SizedBox(height: 32),
          Text(
            "What should we\ncall you?",
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            "Then a quick quiz — no right answers.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: Theme.of(context).textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: 'Your name',
            ),
            onSubmitted: (_) {
              if (_nameController.text.trim().isNotEmpty) {
                _goToPhase(_Phase.quiz);
              }
            },
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const Spacer(),
          PrimaryButton(
            label: 'Next — Quick Quiz',
            onTap: () {
              if (_nameController.text.trim().isNotEmpty) {
                _goToPhase(_Phase.quiz);
              }
            },
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────── QUIZ ──────────────────────────────────────

  Widget _buildQuiz() {
    final q = _questions[_quizIndex];
    final progress = (_quizIndex + 1) / _questions.length;

    return Column(
      key: ValueKey('quiz-$_quizIndex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.screenPadding,
            16,
            AppDimensions.screenPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Quick quiz',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${_quizIndex + 1} / ${_questions.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Scrollable question + choices
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.question,
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                ).animate().fadeIn().slideY(begin: 0.15, end: 0),
                const SizedBox(height: 22),
                ...q.choices.asMap().entries.map((e) => _ChoiceTile(
                      label: e.value.label,
                      isSelected: _selectedAnswers[_quizIndex] == e.key,
                      onTap: () => _selectAnswer(e.key),
                      delay: Duration(milliseconds: 50 + e.key * 50),
                    )),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        // Back navigation
        if (_quizIndex > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.screenPadding,
              0,
              AppDimensions.screenPadding,
              16,
            ),
            child: TextButton.icon(
              onPressed: () => setState(() => _quizIndex--),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────── REVEAL ────────────────────────────────────

  Widget _buildReveal() {
    final profile = _resultProfile!;

    return SingleChildScrollView(
      key: const ValueKey('reveal'),
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'You are a...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                profile.emoji,
                style: const TextStyle(fontSize: 44),
              ).animate().scale(
                    begin: const Offset(0.4, 0.4),
                    curve: Curves.elasticOut,
                    delay: 200.ms,
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  profile.name,
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: profile.color,
                            fontWeight: FontWeight.w800,
                          ),
                ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.2, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: profile.color.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              profile.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: profile.color,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 22),
          Text(
            profile.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.65,
                ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          _NotificationStyleBadge(
            style: profile.notificationStyle,
          ).animate().fadeIn(delay: 560.ms),
          const SizedBox(height: 36),
          PrimaryButton(
            label: "Let's do this",
            isLoading: _saving,
            onTap: _finish,
          ).animate().fadeIn(delay: 660.ms),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ────────────────────────────────────────────────────────

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration delay;

  const _ChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? AppColors.darkSurface
                    : AppColors.surface,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    ).animate(delay: delay).fadeIn().slideX(begin: 0.08, end: 0);
  }
}

class _NotificationStyleBadge extends StatelessWidget {
  final String style; // gentle | sarcastic | brutal

  const _NotificationStyleBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    final (label, desc, icon, color) = switch (style) {
      'gentle' => (
          'Gentle reminders',
          'Supportive nudges — no judgment here.',
          Icons.favorite_rounded,
          const Color(0xFF10B981),
        ),
      'brutal' => (
          'Brutal honesty mode',
          "Zero sugarcoating. You asked for it.",
          Icons.bolt_rounded,
          const Color(0xFFEF4444),
        ),
      _ => (
          'Sarcastic mode',
          "We'll roast you. Lovingly, of course.",
          Icons.emoji_emotions_rounded,
          const Color(0xFFF59E0B),
        ),
    };

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
