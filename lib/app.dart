import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/models.dart';
import 'core/navigation.dart';
import 'core/theme.dart';
import 'core/wallet_store.dart';
import 'features/account.dart';
import 'features/auth.dart';
import 'features/dashboard.dart';
import 'features/finance.dart';
import 'features/services.dart';
import 'features/secondary.dart';

class CenWalletApp extends StatelessWidget {
  const CenWalletApp({
    super.key,
    required this.store,
    this.initialPage = AppPage.welcome,
  });
  final WalletStore store;
  final AppPage initialPage;
  @override
  Widget build(BuildContext c) => WalletScope(
    store: store,
    child: MaterialApp(
      title: 'CenWallet',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: child!,
      ),
      navigatorKey: navigatorKey,
      initialRoute: '/${initialPage.name}',
      onGenerateInitialRoutes: (name) => [
        MaterialPageRoute<dynamic>(
          settings: RouteSettings(name: name),
          builder: (_) => screen(RouteSettings(name: name)),
        ),
      ],
      onGenerateRoute: (s) =>
          MaterialPageRoute<dynamic>(settings: s, builder: (_) => screen(s)),
    ),
  );
  Widget screen(RouteSettings s) {
    final p =
        AppPage.values.where((p) => '/${p.name}' == s.name).firstOrNull ??
        AppPage.welcome;
    final args = s.arguments;
    return switch (p) {
      AppPage.welcome => const WelcomeScreen(),
      AppPage.onboarding => const OnboardingScreen(),
      AppPage.login ||
      AppPage.signup ||
      AppPage.forgot ||
      AppPage.verify => AuthScreen(p, purpose: args as String?),
      AppPage.home => const ShellScreen(),
      AppPage.incentives => const ShellScreen(initialIndex: 1),
      AppPage.payment => const ShellScreen(initialIndex: 2),
      AppPage.friends => const ShellScreen(initialIndex: 3),
      AppPage.market => const ShellScreen(initialIndex: 4),
      AppPage.transfer => const TransferScreen(),
      AppPage.recharge ||
      AppPage.transferWallet ||
      AppPage.transferBank ||
      AppPage.exchange => MoneyFormScreen(
        p,
        contact: args is Contact ? args : null,
        initialCurrency: args is Currency ? args : null,
      ),
      AppPage.review =>
        args is PaymentDraft ? ReviewScreen(args) : const TransferScreen(),
      AppPage.success =>
        args is Activity ? SuccessScreen(args) : const ShellScreen(),
      AppPage.transaction =>
        args is Activity
            ? TransactionScreen(args)
            : store.activities.isEmpty
            ? const HistoryScreen()
            : TransactionScreen(store.activities.first),
      AppPage.history => const HistoryScreen(),
      AppPage.manage => const ManageScreen(),
      AppPage.linkAccount => const LinkAccountScreen(),
      AppPage.linkBank => LinkFormScreen(
        bank: args as String? ?? 'Wells Fargo',
      ),
      AppPage.linkCard => const LinkFormScreen(card: true),
      AppPage.createWallet => const CreateWalletScreen(),
      AppPage.services => const ServicesScreen(),
      AppPage.bills => const BillsScreen(),
      AppPage.booking ||
      AppPage.bookingDetails ||
      AppPage.bookingPassenger ||
      AppPage.bookingReceipt => BookingScreen(p, plan: args as BookingPlan?),
      AppPage.profile => const ProfileScreen(),
      AppPage.settings => const SettingsScreen(),
      AppPage.account ||
      AppPage.password ||
      AppPage.addContact ||
      AppPage.identity => AccountFormScreen(
        p,
        reset: args == 'reset',
        contact: args is Contact ? args : null,
      ),
      AppPage.contactDetail =>
        args is Contact
            ? ContactDetailScreen(args)
            : store.contacts.isEmpty
            ? const ShellScreen(initialIndex: 3)
            : ContactDetailScreen(store.contacts.first),
      AppPage.filter => FilterScreen(
        filter: args is ActivityFilter ? args : null,
      ),
      AppPage.receipt => const MerchantReceiptScreen(),
      AppPage.report => const ReportScreen(),
      AppPage.reportSuccess => const ReportSuccessScreen(),
      AppPage.fingerprints => const FingerprintsScreen(),
      AppPage.bankLinks => const BankLinksScreen(),
      AppPage.flights => FlightsScreen(
        plan: args is BookingPlan ? args : BookingPlan(),
      ),
      AppPage.support => const SupportScreen(),
      AppPage.notifications => const NotificationsScreen(),
      AppPage.qr => const QrScreen(),
    };
  }
}
