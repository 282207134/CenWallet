import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Local demo ledger; replace with an idempotent server API for production.
class WalletStore extends ChangeNotifier {
  WalletStore({this.preferences});
  final SharedPreferences? preferences;
  static const storageKey = 'cen_wallet_demo_v1';
  List<Wallet> wallets = [
    Wallet(Currency.usd, 1200000),
    Wallet(Currency.jpy, 348000),
    Wallet(Currency.btc, 2000000000),
  ];
  List<Activity> activities = [
    Activity(
      id: 'receive',
      title: 'Receive money',
      subtitle: 'From: Harry Jame',
      amount: 100000,
      currency: Currency.usd,
      date: DateTime(2026, 10, 9),
    ),
    Activity(
      id: 'electric',
      title: 'Pay electric bill',
      subtitle: 'From: USD wallet',
      amount: -10000,
      currency: Currency.usd,
      date: DateTime(2026, 10, 9),
    ),
    Activity(
      id: 'flight',
      title: 'Booking flight',
      subtitle: 'From: Japan wallet',
      amount: -3400,
      currency: Currency.jpy,
      date: DateTime(2026, 10, 9),
    ),
  ];
  List<Contact> contacts = const [
    Contact('Hermione Granger', 'BN123848593'),
    Contact('Albus Dumbledore', 'AB123848593'),
    Contact('Ron Weasley', 'BM123848593'),
    Contact('Gellert Grindelwald', 'AT123848593'),
  ];
  Set<String> paidBills = {}, completedRequests = {};
  String name = 'Leo Johnson',
      email = 'leo@example.com',
      phone = '+1 202 555 0123',
      address = 'Kirkland, Washington',
      language = 'English',
      linkedAccountName = 'Wells Fargo';
  List<String> reports = [];
  bool biometricUnlock = true, biometricPayment = false, _committing = false;
  bool fastPayment = true,
      notifications = false,
      verified = false,
      bankLinked = false,
      signedIn = false;
  int unread = 3;
  Wallet wallet(Currency c) => wallets.firstWhere((w) => w.currency == c);
  static Future<WalletStore> load() async {
    final store = WalletStore(
      preferences: await SharedPreferences.getInstance(),
    );
    try {
      final raw = store.preferences!.getString(storageKey);
      if (raw != null) store.restore(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      /* Fall back to a usable demo for invalid local data. */
    } on TypeError {
      /* Incompatible snapshot schema. */
    } on ArgumentError {
      /* Unknown currency. */
    }
    return store;
  }

  void restore(Map<String, dynamic> j) {
    // Parse everything before committing to avoid partial restoration.
    final ws = (j['wallets'] as List).map((e) => Wallet.fromJson(e)).toList();
    if (!{
          Currency.usd,
          Currency.jpy,
          Currency.btc,
        }.every((c) => ws.any((w) => w.currency == c)) ||
        ws.map((w) => w.currency).toSet().length != ws.length ||
        ws.any((w) => w.balance < 0)) {
      throw const FormatException('Invalid wallet snapshot');
    }
    final acts = (j['activities'] as List)
        .map((e) => Activity.fromJson(e))
        .toList();
    final cs = (j['contacts'] as List)
        .map((e) => Contact(e['name'], e['code']))
        .toList();
    final bills = Set<String>.from(j['paidBills'] as List),
        requests = Set<String>.from(j['requests'] as List);
    final p = Map<String, String>.from(j['profile'] as Map),
        s = Map<String, dynamic>.from(j['settings'] as Map);
    final lang = s['language'] as String,
        fast = s['fastPayment'] as bool,
        notify = s['notifications'] as bool,
        verify = s['verified'] as bool,
        bank = s['bankLinked'] as bool;
    final restoredReports = List<String>.from(j['reports'] as List? ?? []);
    final linkedName = s['linkedAccountName'] as String? ?? 'Wells Fargo';
    final unlock = s['biometricUnlock'] as bool? ?? true,
        pay = s['biometricPayment'] as bool? ?? false;
    wallets = ws;
    activities = acts;
    contacts = cs;
    paidBills = bills;
    completedRequests = requests;
    name = p['name'] ?? name;
    email = p['email'] ?? email;
    phone = p['phone'] ?? phone;
    address = p['address'] ?? address;
    language = lang;
    fastPayment = fast;
    notifications = notify;
    verified = verify;
    bankLinked = bank;
    linkedAccountName = linkedName;
    reports = restoredReports;
    biometricUnlock = unlock;
    biometricPayment = pay;
  }

  Map<String, Object> snapshot() => {
    'wallets': wallets.map((w) => w.toJson()).toList(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'contacts': contacts.map((c) => c.toJson()).toList(),
    'paidBills': paidBills.toList(),
    'requests': completedRequests.toList(),
    'reports': reports,
    'profile': {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    },
    'settings': {
      'language': language,
      'fastPayment': fastPayment,
      'notifications': notifications,
      'verified': verified,
      'bankLinked': bankLinked,
      'linkedAccountName': linkedAccountName,
      'biometricUnlock': biometricUnlock,
      'biometricPayment': biometricPayment,
    },
  };
  Future<void> save() async {
    if (preferences != null &&
        !await preferences!.setString(storageKey, jsonEncode(snapshot()))) {
      throw StateError('Could not save. Please try again.');
    }
    notifyListeners();
  }

  Future<Activity> commit(PaymentDraft d, String requestId) async {
    if (completedRequests.contains(requestId)) {
      throw StateError('This payment was already completed.');
    }
    if (d.amount <= 0 || d.recipient.trim().isEmpty) {
      throw ArgumentError('Enter a valid payment.');
    }
    if (_committing) throw StateError('A payment is being saved. Please wait.');
    final source = wallet(d.currency);
    if (d.kind != PaymentKind.recharge && source.balance < d.amount) {
      throw StateError('Insufficient balance.');
    }
    if (d.kind == PaymentKind.exchange &&
        (d.target == null || d.target == d.currency || d.converted <= 0)) {
      throw ArgumentError('Choose different wallets and a valid amount.');
    }
    if (d.billIds.any(paidBills.contains)) {
      throw StateError('This bill has already been paid.');
    }
    final destination = d.kind == PaymentKind.exchange
        ? wallet(d.target!)
        : null;
    final before = snapshot();
    _committing = true;
    source.balance += d.kind == PaymentKind.recharge ? d.amount : -d.amount;
    if (d.kind == PaymentKind.exchange) {
      destination!.balance += d.converted;
    }
    paidBills.addAll(d.billIds);
    completedRequests.add(requestId);
    final a = Activity(
      id: requestId,
      title: d.title,
      subtitle: 'To: ${d.recipient}',
      amount: d.kind == PaymentKind.recharge ? d.amount : -d.amount,
      currency: d.currency,
      date: DateTime.now(),
    );
    activities.insert(0, a);
    try {
      await save();
    } catch (_) {
      restore(before);
      notifyListeners();
      rethrow;
    } finally {
      _committing = false;
    }
    return a;
  }

  Future<void> createWallet(Currency c) async {
    if (wallets.any((w) => w.currency == c)) {
      throw StateError('This wallet already exists.');
    }
    await mutate(() => wallets.add(Wallet(c, 0)));
  }

  Future<void> addContact(String contactName, String code) async {
    if (contacts.any((c) => c.code == code)) {
      throw StateError('This contact already exists.');
    }
    await mutate(
      () => contacts = [...contacts, Contact(contactName.trim(), code.trim())],
    );
  }

  Future<void> mutate(VoidCallback change) async {
    final before = snapshot();
    change();
    try {
      await save();
    } catch (_) {
      restore(before);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> editContact(
    Contact original,
    String newName,
    String newCode,
  ) async {
    if (contacts.any((c) => c.code == newCode && c.code != original.code)) {
      throw StateError('This contact already exists.');
    }
    await mutate(
      () => contacts = contacts
          .map(
            (c) => c.code == original.code
                ? Contact(newName.trim(), newCode.trim())
                : c,
          )
          .toList(),
    );
  }
}

class WalletScope extends InheritedNotifier<WalletStore> {
  const WalletScope({
    super.key,
    required WalletStore store,
    required super.child,
  }) : super(notifier: store);
  static WalletStore of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<WalletScope>()!.notifier!;
}
