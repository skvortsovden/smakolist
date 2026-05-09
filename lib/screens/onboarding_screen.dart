import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../providers/app_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _finish() {
    final provider = context.read<AppProvider>();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) provider.setUsername(name);
    provider.markLaunched();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _ProgressDots(current: _page),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _NamePage(
                    controller: _nameController,
                    onNext: _nextPage,
                  ),
                  _WelcomePage(
                    nameController: _nameController,
                    onNext: _nextPage,
                  ),
                  _GuidePage(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int current;

  const _ProgressDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.black : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _NamePage({required this.controller, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            S.onboardingNameTitle,
            style: const TextStyle(
              fontFamily: 'FixelDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: S.onboardingNameHint,
              hintStyle: const TextStyle(color: Colors.black38),
              counterStyle: const TextStyle(color: Colors.black38, fontSize: 11),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
          const Spacer(),
          _PrimaryButton(label: S.onboardingNameBtn, onTap: onNext),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onNext;

  const _WelcomePage({required this.nameController, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim();
    final title =
        name.isNotEmpty ? S.welcomeTitle(name) : S.welcomeTitleDefault;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'FixelDisplay',
              fontWeight: FontWeight.w800,
              fontSize: 36,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.welcomeBody,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 18,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          _PrimaryButton(label: S.welcomeBtn, onTap: onNext),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final VoidCallback onFinish;

  const _GuidePage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            S.onboardingGuideTitle,
            style: const TextStyle(
              fontFamily: 'FixelDisplay',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.onboardingGuideText,
            style: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: S.onboardingGuideBtn, onTap: onFinish),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'FixelText',
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
