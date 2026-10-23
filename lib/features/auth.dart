import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext c) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      body: Container(
        key: const ValueKey('welcome-background'),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff8d14ae), Color(0xffd34d9f)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(left: -70, top: -20, child: circle(320)),
            Positioned(right: -110, bottom: -80, child: circle(300)),
            Positioned(right: 90, bottom: 100, child: circle(80)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 43),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To the wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: 245,
                      child: Text(
                        'Your money, wherever life takes you. Pay, transfer and explore with everything in one wallet.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    TextButton(
                      onPressed: () => go(c, AppPage.onboarding),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Let’s begin   →',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget circle(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0x21ffffff),
      shape: BoxShape.circle,
    ),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingScreen> {
  int index = 0;
  final controller = PageController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => go(c, AppPage.login),
              child: const Text('Skip'),
            ),
          ),
          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (i) => setState(() => index = i),
              children: [
                slide(
                  'Fast payment',
                  'Just visit any of the growing number of outlets who accept money and make your purchase within a second.',
                  'onboarding_pay.svg',
                ),
                slide(
                  'Investment effectively',
                  'Follow your wallets and explore currency markets, all in one place.',
                  'onboarding_invest.png',
                ),
                slide(
                  'Security',
                  'Stay in control of your wallet with account verification and payment confirmations.',
                  'onboarding_security.png',
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.all(4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == index
                      ? AppColors.purple
                      : const Color(0xffd3d3d5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 55, 28, 30),
            child: GradientButton(
              index == 2 ? 'Get started' : 'Continue',
              onPressed: () {
                if (index == 2) {
                  go(c, AppPage.login);
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
  Widget slide(String title, String text, String art) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 45, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 35),
          Center(child: Art(art, height: 235)),
          const SizedBox(height: 44),
          Text(text, style: const TextStyle(fontSize: 14, height: 2.1)),
        ],
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen(this.page, {super.key, this.purpose});
  final AppPage page;
  final String? purpose;
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final phone = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      name = TextEditingController(),
      code = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final t in [phone, password, confirm, name, code]) {
      t.dispose();
    }
    super.dispose();
  }

  void enterDemo() {
    WalletScope.of(context).signedIn = true;
    goHome(context);
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    final store = WalletScope.of(context);
    setState(() => busy = true);
    try {
      switch (widget.page) {
        case AppPage.login:
          enterDemo();
        case AppPage.signup:
          store.name = name.text.trim();
          store.phone = phone.text.trim();
          await store.save();
          if (mounted) await go(context, AppPage.verify, 'signup');
        case AppPage.forgot:
          await go(context, AppPage.verify, 'reset');
        case AppPage.verify:
          if (code.text.trim().toUpperCase() != 'F2368') {
            toast(context, 'Use the demo code F2368.');
            break;
          }
          if (widget.purpose == 'reset') {
            await go(context, AppPage.password, 'reset');
          } else if (widget.purpose == 'identity') {
            store.verified = true;
            await store.save();
            if (mounted) goHome(context);
          } else {
            enterDemo();
          }
        default:
          break;
      }
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) {
    final login = widget.page == AppPage.login,
        signup = widget.page == AppPage.signup,
        verify = widget.page == AppPage.verify;
    final title = login
        ? 'Login'
        : signup
        ? 'Sign up'
        : verify
        ? 'Verify'
        : 'Forgot\npassword';
    return PageFrame(
      title: title,
      subtitle: verify
          ? 'Enter your verification code. This demo uses F2368.'
          : login
          ? null
          : signup
          ? 'Create your wallet account.'
          : 'Enter your phone number to reset your demo access.',
      children: [
        if (login) const SizedBox(height: 32),
        Form(
          key: form,
          child: Column(
            children: [
              if (signup) FormFieldLine('Full name', controller: name),
              if (!verify)
                FormFieldLine(
                  'Phone',
                  controller: phone,
                  validator: (v) =>
                      RegExp(r'^\+?[\d\s-]{7,20}$').hasMatch(v ?? '')
                      ? null
                      : 'Enter a valid phone number',
                ),
              if (login || signup)
                FormFieldLine(
                  'Password',
                  controller: password,
                  password: true,
                  validator: (v) =>
                      (v?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
                ),
              if (signup)
                FormFieldLine(
                  'Confirm password',
                  controller: confirm,
                  password: true,
                  validator: (v) =>
                      v != password.text ? 'Passwords do not match' : null,
                ),
              if (verify) FormFieldLine('Verification code', controller: code),
            ],
          ),
        ),
        if (login)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => go(c, AppPage.forgot),
              child: const Text('Forgot?'),
            ),
          ),
        const SizedBox(height: 30),
        GradientButton(
          verify
              ? 'Done'
              : signup
              ? 'Create'
              : login
              ? 'Login'
              : 'Continue',
          onPressed: submit,
          busy: busy,
        ),
        if (signup) ...[
          gap,
          const Text(
            'By tapping on CREATE, you agree to the demo Terms of Use and Privacy Policy. No real account is created.',
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
        if (verify)
          TextButton(
            onPressed: () => toast(c, 'Demo verification code: F2368'),
            child: const Text('Resend code'),
          ),
        if (login) ...[
          gap,
          Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet(
                context: c,
                showDragHandle: true,
                builder: (c) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fingerprint,
                          size: 72,
                          color: AppColors.purple,
                        ),
                        gap,
                        const Text(
                          'Fingerprint preview',
                          style: TextStyle(fontSize: 22),
                        ),
                        gap,
                        const Text(
                          'Biometric authentication is a visual demo. Use Explore demo to continue.',
                        ),
                        gap,
                        GradientButton(
                          'Explore demo',
                          onPressed: () {
                            Navigator.pop(c);
                            enterDemo();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Column(
                children: [
                  Text('touch sensor instead'),
                  SizedBox(height: 14),
                  Icon(Icons.fingerprint, size: 72, color: AppColors.purple),
                ],
              ),
            ),
          ),
          gap,
          TextButton(onPressed: enterDemo, child: const Text('Explore demo')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Don’t have an account?',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () => go(c, AppPage.signup),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
