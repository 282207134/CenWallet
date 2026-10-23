import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cen_wallet/app.dart';
import 'package:cen_wallet/core/models.dart';
import 'package:cen_wallet/core/navigation.dart';
import 'package:cen_wallet/core/wallet_store.dart';
import 'package:cen_wallet/features/services.dart';

void main() {
  testWidgets('all app routes render without layout errors on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = WalletStore();
    await tester.pumpWidget(CenWalletApp(store: s, initialPage: AppPage.home));
    await tester.pumpAndSettle();
    final draft = const PaymentDraft(
      kind: PaymentKind.transfer,
      currency: Currency.usd,
      amount: 10000,
      recipient: 'Harry James',
    );
    for (final p in AppPage.values) {
      final Object? arg = switch (p) {
        AppPage.review => draft,
        AppPage.success || AppPage.transaction => s.activities.first,
        AppPage.bookingReceipt => BookingPlan(
          firstName: 'Harry',
          lastName: 'James',
        ),
        _ => null,
      };
      navigatorKey.currentState!.pushNamed('/${p.name}', arguments: arg);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: p.name);
      if (p == AppPage.welcome) {
        expect(
          tester
              .getSize(find.byKey(const ValueKey('welcome-background')))
              .width,
          375,
        );
      }
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'invalid transfer shows validation, valid transfer completes once',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = WalletStore();
      await tester.pumpWidget(
        CenWalletApp(store: s, initialPage: AppPage.transferWallet),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 6 characters'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'BN12345678');
      await tester.enterText(fields.at(1), 'Harry James');
      await tester.enterText(fields.at(2), '100');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Review\npayment'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Successful\ntransaction'), findsOneWidget);
      expect(s.wallet(Currency.usd).balance, 1190000);
      expect(s.activities.length, 4);
      await tester.tap(find.text('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('\$11,900.00'), findsOneWidget);
    },
  );
  testWidgets(
    'history filter returns date and amount constraints through navigation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        CenWalletApp(store: WalletStore(), initialPage: AppPage.history),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Received'));
      await tester.enterText(find.byType(TextFormField).at(0), '200');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Received · 1 transactions'), findsOneWidget);
      expect(find.text('Pay electric bill'), findsNothing);
    },
  );
}
