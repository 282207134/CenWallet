import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cen_wallet/core/models.dart';
import 'package:cen_wallet/core/wallet_store.dart';

void main() {
  PaymentDraft transfer(int amount) => PaymentDraft(
    kind: PaymentKind.transfer,
    currency: Currency.usd,
    amount: amount,
    recipient: 'Harry · BN123848593',
  );
  test(
    'currency precision rejects non-finite, negative and excess decimals',
    () {
      expect(Currency.usd.parse('12.34'), 1234);
      expect(Currency.usd.parse('12.345'), isNull);
      expect(Currency.usd.parse('NaN'), isNull);
      expect(Currency.usd.parse('-1'), isNull);
      expect(Currency.usd.parse('0'), isNull);
      expect(Currency.jpy.parse('12.1'), isNull);
      expect(Currency.btc.parse('0.00000001'), 1);
      expect(Currency.usd.format(1200000), '\$12,000.00');
    },
  );
  test(
    'transfer records once and duplicate request cannot debit twice',
    () async {
      final s = WalletStore();
      await s.commit(transfer(10000), 'one');
      expect(s.wallet(Currency.usd).balance, 1190000);
      expect(s.activities.first.amount, -10000);
      await expectLater(s.commit(transfer(10000), 'one'), throwsStateError);
      expect(s.wallet(Currency.usd).balance, 1190000);
    },
  );
  test('insufficient funds leave ledger unchanged', () async {
    final s = WalletStore(), before = WalletStore().snapshot();
    await expectLater(s.commit(transfer(99999999), 'bad'), throwsStateError);
    expect(s.snapshot(), before);
  });
  test('exchange debits and credits using integer minor units', () async {
    final s = WalletStore();
    final before = s.wallet(Currency.jpy).balance;
    await s.commit(
      const PaymentDraft(
        kind: PaymentKind.exchange,
        currency: Currency.usd,
        amount: 10000,
        target: Currency.jpy,
        recipient: 'JPY wallet',
      ),
      'fx',
    );
    expect(s.wallet(Currency.usd).balance, 1190000);
    expect(s.wallet(Currency.jpy).balance, before + 11385);
    await expectLater(
      s.commit(
        const PaymentDraft(
          kind: PaymentKind.exchange,
          currency: Currency.usd,
          amount: 1,
          target: Currency.usd,
          recipient: 'USD wallet',
        ),
        'same',
      ),
      throwsArgumentError,
    );
  });
  test('recharge credits and a paid bill cannot be paid twice', () async {
    final s = WalletStore();
    await s.commit(
      const PaymentDraft(
        kind: PaymentKind.recharge,
        currency: Currency.usd,
        amount: 10000,
        recipient: 'USD wallet',
      ),
      'credit',
    );
    const bill = PaymentDraft(
      kind: PaymentKind.bill,
      currency: Currency.usd,
      amount: 10000,
      recipient: 'Internet',
      billIds: ['internet'],
    );
    await s.commit(bill, 'bill');
    expect(s.wallet(Currency.usd).balance, 1200000);
    await expectLater(s.commit(bill, 'bill-two'), throwsStateError);
  });
  test('balance, contact, wallet and settings survive app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await WalletStore.load();
    await s.commit(transfer(1234), 'persisted');
    await s.createWallet(Currency.eur);
    await s.addContact('Test User', 'TEST123456');
    s.notifications = true;
    await s.save();
    final restored = await WalletStore.load();
    expect(restored.snapshot(), s.snapshot());
    expect(restored.signedIn, isFalse);
    await expectLater(
      restored.addContact('Duplicate', 'TEST123456'),
      throwsStateError,
    );
    await expectLater(restored.createWallet(Currency.eur), throwsStateError);
  });
  test('corrupt snapshots retain usable initial state', () async {
    SharedPreferences.setMockInitialValues({
      WalletStore.storageKey: '{bad json',
    });
    final s = await WalletStore.load();
    expect(s.wallet(Currency.usd).balance, 1200000);
    final before = s.snapshot();
    expect(() => s.restore({'wallets': []}), throwsFormatException);
    expect(s.snapshot(), before);
  });
  test('missing exchange wallet cannot partially debit source', () async {
    final s = WalletStore(), before = WalletStore().snapshot();
    await expectLater(
      s.commit(
        const PaymentDraft(
          kind: PaymentKind.exchange,
          currency: Currency.usd,
          amount: 10000,
          target: Currency.eur,
          recipient: 'EUR wallet',
        ),
        'missing',
      ),
      throwsStateError,
    );
    expect(s.snapshot(), before);
  });
  test('BTC parsing and formatting preserve all eight decimal places', () {
    expect(Currency.btc.parse('90000000.12345678'), 9000000012345678);
    expect(Currency.btc.format(9000000012345678), '₿90,000,000.12345678');
  });
  test(
    'contact editing preserves uniqueness and persists the updated record',
    () async {
      final s = WalletStore(), contact = WalletStore().contacts.first;
      await s.editContact(contact, 'Hermione Updated', 'NEW123456');
      expect(s.contacts.first.name, 'Hermione Updated');
      expect(s.contacts.first.code, 'NEW123456');
      await expectLater(
        s.editContact(s.contacts.first, 'Duplicate', s.contacts.last.code),
        throwsStateError,
      );
    },
  );
}
