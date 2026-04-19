import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../navigation/app_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/primary_button.dart';

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

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _showNameEntry = false;
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      setState(() => _showNameEntry = true);
    }
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final notifier = ref.read(userProvider.notifier);
    await notifier.createUser(name);
    await notifier.completeOnboarding();
    if (mounted) context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showNameEntry ? _buildNameEntry() : _buildSlides(),
        ),
      ),
    );
  }

  Widget _buildSlides() {
    return Column(
      children: [
        // Skip
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _showNameEntry = true),
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
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),
        ),
        // Dots + button
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
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _currentPage == _pages.length - 1
                    ? 'Get Started'
                    : 'Next',
                onTap: _next,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPage(_OnboardingPage page) {
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

  Widget _buildNameEntry() {
    return Padding(
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
            "We'll personalize your experience.",
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
            onSubmitted: (_) => _finish(),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          const Spacer(),
          PrimaryButton(
            label: "Let's go",
            isLoading: _saving,
            onTap: _finish,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
