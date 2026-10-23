import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cen_wallet/app.dart';
import 'package:cen_wallet/core/models.dart';
import 'package:cen_wallet/core/navigation.dart';
import 'package:cen_wallet/core/wallet_store.dart';
import 'package:cen_wallet/features/services.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('simulator screen catalog and complete transfer', (tester) async {
    final store = WalletStore()..signedIn = true;
    await tester.pumpWidget(
      CenWalletApp(store: store, initialPage: AppPage.home),
    );
    await tester.pumpAndSettle();
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      await binding.takeScreenshot(name);
      debugPrint("Captured $name");
    }

    await capture('01-home');
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await capture('home-bitcoin-wallet');
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    var i = 2;
    const draft = PaymentDraft(
      kind: PaymentKind.transfer,
      currency: Currency.usd,
      amount: 10000,
      recipient: 'Harry James',
      note: 'Dinner',
    );
    for (final p in AppPage.values.where((p) => p != AppPage.home)) {
      final Object? argument = switch (p) {
        AppPage.review => draft,
        AppPage.success || AppPage.transaction => Activity(
          id: 'CW-20261023-001',
          title: 'Transfer money',
          subtitle: 'To: Harry James',
          amount: -10000,
          currency: Currency.usd,
          date: DateTime(2026, 10, 23),
        ),
        AppPage.bookingReceipt => BookingPlan(
          firstName: 'Harry',
          lastName: 'James',
        ),
        _ => null,
      };
      navigatorKey.currentState!.pushNamed('/${p.name}', arguments: argument);
      await tester.pumpAndSettle();
      await capture('${i.toString().padLeft(2, '0')}-${p.name}');
      i++;
      if (p == AppPage.onboarding) {
        await tester.drag(find.byType(PageView), const Offset(-450, 0));
        await capture('onboarding-investment');
        await tester.drag(find.byType(PageView), const Offset(-450, 0));
        await capture('onboarding-security');
      } else if (p == AppPage.market) {
        await tester.tap(find.text('Live rates'));
        await capture('market-live-rates');
      } else if (p == AppPage.qr) {
        await tester.tap(find.text('Scan'));
        await capture('qr-manual-scan');
      } else if (p == AppPage.services) {
        await tester.tap(find.text('Transport'));
        await capture('services-transport');
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      } else if (p == AppPage.incentives) {
        await tester.tap(find.text('McDonald discount 20%'));
        await capture('incentive-coupon');
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }
      if (p == AppPage.filter) {
        await tester.tap(find.text('Any date').first);
        await capture('filter-calendar');
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      } else if (p == AppPage.contactDetail) {
        await tester.tap(find.text('Change'));
        await capture('contact-edit');
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      } else if (p == AppPage.fingerprints) {
        await tester.tap(find.text('Finger 1'));
        await capture('fingerprint-detail');
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
      } else if (p == AppPage.bankLinks) {
        store.bankLinked = true;
        await store.save();
        await capture('bank-linked');
        store.bankLinked = false;
        await store.save();
      } else if (p == AppPage.bookingReceipt || p == AppPage.settings) {
        await tester.drag(
          find.byKey(const ValueKey('page-scroll')),
          const Offset(0, -600),
        );
        await capture(
          p == AppPage.settings
              ? 'settings-security'
              : 'booking-receipt-details',
        );
      }
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
    }
    navigatorKey.currentState!.pushNamed('/transferWallet');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least 6 characters'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'BN12345678');
    await tester.enterText(fields.at(1), 'Harry James');
    await tester.enterText(fields.at(2), '100');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await capture('transfer-filled');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Successful\ntransaction'), findsOneWidget);
    expect(store.wallet(Currency.usd).balance, 1190000);
    await capture('transfer-success');
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('\$11,900.00'), findsOneWidget);
    await capture('home-after-transfer');
  });
}
