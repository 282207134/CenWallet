enum Currency {
  usd('USD', '\$', 2, 1),
  jpy('JPY', '¥', 0, 113.85),
  eur('EUR', '€', 2, 0.89),
  btc('BTC', '₿', 8, 0.0002456);

  const Currency(this.code, this.symbol, this.decimals, this.unitsPerUsd);
  final String code, symbol;
  final int decimals;
  final double unitsPerUsd;
  int get scale => switch (this) {
    jpy => 1,
    btc => 100000000,
    _ => 100,
  };
  String format(int minor) {
    final parts = [
      (minor.abs() ~/ scale).toString(),
      if (decimals > 0) (minor.abs() % scale).toString().padLeft(decimals, '0'),
    ];
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '${minor < 0 ? '-' : ''}$symbol${parts.join('.')}';
  }

  int? parse(String text) {
    final pattern = decimals == 0 ? r'^\d+$' : '^\\d+(\\.\\d{1,$decimals})?\$';
    if (!RegExp(pattern).hasMatch(text.trim())) return null;
    final parts = text.trim().split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null || whole > 1000000000) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts.last.padRight(decimals, '0'));
    final minor = whole * scale + fraction;
    return minor > 0 && minor <= 1000000000 * scale ? minor : null;
  }
}

class Wallet {
  Wallet(this.currency, this.balance);
  final Currency currency;
  int balance;
  String get name => '${currency.code} wallet';
  Map<String, Object> toJson() => {
    'currency': currency.name,
    'balance': balance,
  };
  factory Wallet.fromJson(Map<String, dynamic> j) =>
      Wallet(Currency.values.byName(j['currency']), j['balance']);
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.currency,
    required this.date,
  });
  final String id, title, subtitle;
  final int amount;
  final Currency currency;
  final DateTime date;
  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'currency': currency.name,
    'date': date.toIso8601String(),
  };
  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'],
    title: j['title'],
    subtitle: j['subtitle'],
    amount: j['amount'],
    currency: Currency.values.byName(j['currency']),
    date: DateTime.parse(j['date']),
  );
}

class Contact {
  const Contact(this.name, this.code);
  final String name, code;
  Map<String, String> toJson() => {'name': name, 'code': code};
}

enum PaymentKind { recharge, transfer, exchange, bill, booking }

class PaymentDraft {
  const PaymentDraft({
    required this.kind,
    required this.currency,
    required this.amount,
    required this.recipient,
    this.target,
    this.note = '',
    this.billIds = const [],
  });
  final PaymentKind kind;
  final Currency currency;
  final int amount;
  final String recipient, note;
  final Currency? target;
  final List<String> billIds;
  String get title => switch (kind) {
    PaymentKind.recharge => 'Recharge money',
    PaymentKind.transfer => 'Transfer money',
    PaymentKind.exchange => 'Exchange money',
    PaymentKind.bill => 'Bill payment',
    PaymentKind.booking => 'Booking flight',
  };
  int get converted => target == null
      ? 0
      : (amount /
                currency.scale /
                currency.unitsPerUsd *
                target!.unitsPerUsd *
                target!.scale)
            .round();
}
