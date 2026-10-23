import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';
import '../widgets/chart.dart';
import 'dashboard.dart';
import 'secondary.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Transfer\nmoney',
    subtitle: 'Send money to a friend’s wallet or a bank account.',
    children: [
      gap,
      for (final row in [
        (
          Icons.account_balance_wallet_outlined,
          'To wallet',
          'Send directly to a wallet',
          AppPage.transferWallet,
        ),
        (
          Icons.account_balance_outlined,
          'To bank',
          'Send to a bank account',
          AppPage.transferBank,
        ),
      ]) ...[
        Surface(
          onTap: () => go(c, row.$4),
          child: Row(
            children: [
              Icon(row.$1, size: 40, color: AppColors.purple),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(row.$3, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        gap,
      ],
    ],
  );
}

class MoneyFormScreen extends StatefulWidget {
  const MoneyFormScreen(
    this.page, {
    super.key,
    this.contact,
    this.initialCurrency,
  });
  final AppPage page;
  final Contact? contact;
  final Currency? initialCurrency;
  @override
  State<MoneyFormScreen> createState() => _MoneyFormState();
}

class _MoneyFormState extends State<MoneyFormScreen> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(),
      recipient = TextEditingController(),
      holder = TextEditingController(),
      note = TextEditingController();
  late Currency currency = widget.initialCurrency ?? Currency.usd;
  Currency target = Currency.jpy;
  String bank = 'Wells Fargo', branch = 'New York';
  bool get exchange => widget.page == AppPage.exchange;
  bool get recharge => widget.page == AppPage.recharge;
  bool get toBank => widget.page == AppPage.transferBank;
  @override
  void initState() {
    super.initState();
    recipient.text = widget.contact?.code ?? '';
    holder.text = widget.contact?.name ?? '';
  }

  @override
  void dispose() {
    for (final t in [amount, recipient, holder, note]) {
      t.dispose();
    }
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    final minor = currency.parse(amount.text)!;
    if (!recharge && WalletScope.of(context).wallet(currency).balance < minor) {
      toast(
        context,
        'Insufficient balance. Choose a different wallet or amount.',
      );
      return;
    }
    final d = PaymentDraft(
      kind: exchange
          ? PaymentKind.exchange
          : recharge
          ? PaymentKind.recharge
          : PaymentKind.transfer,
      currency: currency,
      amount: minor,
      recipient: exchange
          ? '${target.code} wallet'
          : recharge
          ? '$bank → ${currency.code} wallet'
          : toBank
          ? '${holder.text.trim()} · $bank · ${recipient.text.trim()}'
          : '${holder.text.trim().isEmpty ? 'Wallet' : holder.text.trim()} · ${recipient.text.trim()}',
      target: exchange ? target : null,
      note: note.text.trim(),
    );
    if (exchange && d.converted <= 0) {
      toast(context, 'Amount is too small for the destination currency.');
      return;
    }
    go(context, AppPage.review, d);
  }

  @override
  Widget build(BuildContext c) {
    final store = WalletScope.of(c);
    final title = exchange
        ? 'Exchange\nmoney'
        : recharge
        ? 'Recharge\nmoney'
        : toBank
        ? 'Transfer\nto bank'
        : 'Transfer\nto wallet';
    return PageFrame(
      title: title,
      subtitle: exchange
          ? 'Move money between your currency wallets.'
          : recharge
          ? 'Add money to your wallet from a linked account.'
          : 'Enter the recipient information and review your transfer.',
      footer: GradientButton(
        exchange ? 'Convert' : 'Continue',
        onPressed: submit,
      ),
      children: [
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (recharge) ...[
                ChoiceTile(
                  'Source',
                  '$bank · Demo account',
                  icon: Icons.account_balance_outlined,
                  onTap: () async {
                    final value = await choose(c, 'Choose source', [
                      'Wells Fargo',
                      'Visa',
                      'Link another account',
                    ], (v) => v);
                    if (value == 'Link another account' && c.mounted) {
                      go(c, AppPage.linkAccount);
                    } else if (value != null && mounted) {
                      setState(() => bank = value);
                    }
                  },
                ),
                if (!store.bankLinked)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => go(c, AppPage.linkAccount),
                      child: const Text('Link bank or card'),
                    ),
                  ),
              ],
              WalletChoice(
                value: currency,
                label: exchange ? 'Exchange from' : 'Choose wallet',
                exclude: exchange ? target : null,
                onChanged: (v) => setState(() => currency = v),
              ),
              if (exchange) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Swap currencies',
                    icon: const Icon(Icons.swap_vert, color: AppColors.coral),
                    onPressed: () => setState(() {
                      final previous = currency;
                      currency = target;
                      target = previous;
                    }),
                  ),
                ),
                WalletChoice(
                  value: target,
                  exclude: currency,
                  label: 'To wallet',
                  onChanged: (v) => setState(() => target = v),
                ),
              ],
              if (toBank) ...[
                heading('Information'),
                ChoiceTile(
                  'Bank',
                  bank,
                  onTap: () async {
                    final b = await choose(c, 'Bank', [
                      'Wells Fargo',
                      'Bank of America',
                      'Chase',
                    ], (v) => v);
                    if (b != null && mounted) setState(() => bank = b);
                  },
                ),
                ChoiceTile(
                  'Branch',
                  branch,
                  onTap: () async {
                    final b = await choose(c, 'Branch', [
                      'New York',
                      'Washington',
                      'San Francisco',
                    ], (v) => v);
                    if (b != null && mounted) setState(() => branch = b);
                  },
                ),
              ],
              if (!exchange && !recharge) ...[
                if (!toBank) ...[
                  heading('Find friend'),
                  SizedBox(
                    height: 85,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: store.contacts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 20),
                      itemBuilder: (c, i) => InkWell(
                        onTap: () => setState(() {
                          recipient.text = store.contacts[i].code;
                          holder.text = store.contacts[i].name;
                        }),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xfff6e8fa),
                              child: Text(
                                store.contacts[i].name[0],
                                style: const TextStyle(color: AppColors.purple),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              store.contacts[i].name.split(' ').first,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  gap,
                ],
                FormFieldLine(
                  toBank ? 'Account number' : 'Received wallet code',
                  controller: recipient,
                  validator: (v) => (v?.trim().length ?? 0) < 6
                      ? 'Enter at least 6 characters'
                      : null,
                ),
                FormFieldLine(
                  toBank ? 'Account holder' : 'Recipient name',
                  controller: holder,
                ),
              ],
              FormFieldLine(
                'Amount',
                controller: amount,
                numeric: true,
                onChanged: (_) => setState(() {}),
                validator: (v) => currency.parse(v ?? '') == null
                    ? 'Enter a positive amount (${currency.decimals} decimal places maximum)'
                    : null,
              ),
              Text(
                'Available: ${currency.format(store.wallet(currency).balance)}',
                style: const TextStyle(fontSize: 11, color: AppColors.hint),
              ),
              if (exchange) ...[
                gap,
                DetailRow(
                  'You receive',
                  target.format(
                    PaymentDraft(
                      kind: PaymentKind.exchange,
                      currency: currency,
                      amount: currency.parse(amount.text) ?? 0,
                      recipient: '',
                      target: target,
                    ).converted,
                  ),
                  emphasis: true,
                ),
                Text(
                  '1 ${currency.code} ≈ ${(target.unitsPerUsd / currency.unitsPerUsd).toStringAsFixed(target.decimals > 4 ? 8 : 4)} ${target.code}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Text(
                  'Demo exchange rate · no service fee',
                  style: TextStyle(color: AppColors.hint, fontSize: 11),
                ),
              ],
              if (!exchange && !recharge)
                FormFieldLine(
                  'Content (optional)',
                  controller: note,
                  validator: (_) => null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen(this.draft, {super.key});
  final PaymentDraft draft;
  @override
  State<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewScreen> {
  late final requestId = 'CW-${DateTime.now().microsecondsSinceEpoch}';
  bool busy = false;
  Future<void> confirm() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final activity = await WalletScope.of(
        context,
      ).commit(widget.draft, requestId);
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/success', arguments: activity);
      }
    } catch (e) {
      if (mounted) {
        toast(context, errorText(e));
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    final d = widget.draft;
    return PageFrame(
      title:
          'Review\n${d.kind == PaymentKind.exchange ? 'exchange' : 'payment'}',
      subtitle: 'Check the details before you confirm.',
      footer: GradientButton('Confirm', onPressed: confirm, busy: busy),
      children: [
        Surface(
          child: Column(
            children: [
              DetailRow('Type', d.title),
              DetailRow(
                'From',
                d.kind == PaymentKind.recharge
                    ? 'Linked demo account'
                    : '${d.currency.code} wallet',
              ),
              DetailRow('To', d.recipient),
              if (d.note.isNotEmpty) DetailRow('Content', d.note),
              const Divider(),
              DetailRow('Amount', d.currency.format(d.amount)),
              const DetailRow('Fee', '\$0.00'),
              DetailRow('Total', d.currency.format(d.amount), emphasis: true),
              if (d.target != null)
                DetailRow(
                  'You receive',
                  d.target!.format(d.converted),
                  emphasis: true,
                ),
            ],
          ),
        ),
        gap,
        const Center(
          child: Text(
            'Secure payment preview',
            style: TextStyle(color: AppColors.hint, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen(this.activity, {super.key});
  final Activity activity;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: '',
    back: false,
    footer: GradientButton('Back to home', onPressed: () => goHome(c)),
    children: [
      const SizedBox(height: 50),
      Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.gradient,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 58),
        ),
      ),
      const SizedBox(height: 34),
      const Text(
        'Successful\ntransaction',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 30,
          height: 1.5,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      gap,
      Text(
        activity.currency.format(activity.amount.abs()),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          color: AppColors.purple,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 32),
      Surface(
        child: Column(
          children: [
            DetailRow('Type', activity.title),
            DetailRow('Recipient', activity.subtitle.replaceFirst('To: ', '')),
            const DetailRow('Status', 'Success'),
            DetailRow('Reference', activity.id),
          ],
        ),
      ),
      gap,
      TextButton(
        onPressed: () => go(c, AppPage.transaction, activity),
        child: const Text('View receipt'),
      ),
    ],
  );
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryScreen> {
  String query = '', filter = 'All';
  ActivityFilter details = const ActivityFilter();
  @override
  Widget build(BuildContext c) {
    final store = WalletScope.of(c);
    final list = store.activities
        .where(
          (a) =>
              '${a.title} ${a.subtitle}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              details.matches(a) &&
              (filter == 'All' ||
                  filter == 'Received' && a.amount > 0 ||
                  filter == 'Sent' && a.amount < 0),
        )
        .toList();
    return PageFrame(
      title: 'Transaction\nhistory',
      subtitle: 'Your wallet activity, all in one place.',
      trailing: IconButton(
        tooltip: 'Filter',
        onPressed: () async {
          final value = await go<ActivityFilter>(c, AppPage.filter, details);
          if (value != null && mounted) {
            setState(() {
              details = value;
              filter = value.type;
            });
          }
        },
        icon: Badge(
          isLabelVisible: filter != 'All' || details.hasBounds,
          child: const Icon(Icons.filter_alt_outlined),
        ),
      ),
      footer: store.activities.isEmpty
          ? null
          : GradientButton(
              'Clear all history',
              coral: true,
              onPressed: () async {
                final clear = await showDialog<bool>(
                  context: c,
                  builder: (c) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                      'This removes the local activity list. Wallet balances stay the same.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (clear == true) {
                  await store.mutate(() => store.activities = []);
                }
              },
            ),
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search transactions',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        gap,
        Text('$filter · ${list.length} transactions'),
        gap,
        if (list.isEmpty)
          const EmptyState('No transactions found')
        else
          ...list.map((a) => ActivityTile(a, card: true)),
      ],
    );
  }
}

class TransactionScreen extends StatelessWidget {
  const TransactionScreen(this.activity, {super.key});
  final Activity activity;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Transaction\ndetail',
    footer: GradientButton(
      'Copy receipt',
      onPressed: () async {
        await Clipboard.setData(
          ClipboardData(
            text:
                '${activity.title}\n${activity.currency.format(activity.amount)}\n${activity.subtitle}\nReference: ${activity.id}',
          ),
        );
        if (c.mounted) toast(c, 'Receipt copied');
      },
    ),
    children: [
      const Center(
        child: Icon(
          Icons.receipt_long_outlined,
          size: 66,
          color: AppColors.purple,
        ),
      ),
      gap,
      Surface(
        child: Column(
          children: [
            DetailRow(
              'Amount',
              activity.currency.format(activity.amount),
              emphasis: true,
            ),
            DetailRow('Transaction', activity.title),
            DetailRow('Description', activity.subtitle),
            const DetailRow('Status', 'Success'),
            DetailRow('Date', activity.date.toIso8601String().split('T').first),
            DetailRow('Reference', activity.id),
          ],
        ),
      ),
    ],
  );
}

class ManageScreen extends StatelessWidget {
  const ManageScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Manage\nwallet',
    footer: GradientButton(
      'Create wallet',
      onPressed: () => go(c, AppPage.createWallet),
    ),
    children: [
      const WalletChart(),
      gap,
      Wrap(
        spacing: 16,
        runSpacing: 20,
        children: WalletScope.of(c).wallets
            .map(
              (w) => SizedBox(
                width: (MediaQuery.sizeOf(c).width.clamp(0, 600) - 72) / 2,
                child: Surface(
                  onTap: () => go(c, AppPage.history),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name.replaceFirst(' ', '\n'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        w.currency.format(w.balance),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.hint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const WalletChart(compact: true),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

class LinkAccountScreen extends StatelessWidget {
  const LinkAccountScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Link\naccount',
    subtitle: 'Choose a bank or international card for your wallet.',
    children: [
      heading('Bank account'),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: .9,
        children:
            ['Wells Fargo', 'Chase', 'Citi', 'Capital One', 'HSBC', 'More']
                .asMap()
                .entries
                .map(
                  (e) => Surface(
                    padding: const EdgeInsets.all(10),
                    onTap: () => go(
                      c,
                      AppPage.linkBank,
                      e.value == 'More' ? 'Wells Fargo' : e.value,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          color: e.key.isEven
                              ? AppColors.purple
                              : const Color(0xffffa424),
                          size: 30,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
      const SizedBox(height: 30),
      heading('International card'),
      Surface(
        onTap: () => go(c, AppPage.linkCard),
        child: const Row(
          children: [
            Text(
              'VISA',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Color(0xff7757b8),
              ),
            ),
            SizedBox(width: 25),
            Expanded(child: Text('Visa / Mastercard / …')),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
      gap,
      TextButton(
        onPressed: () => Navigator.pop(c),
        child: const Text('Link card later'),
      ),
    ],
  );
}

class LinkFormScreen extends StatefulWidget {
  const LinkFormScreen({
    super.key,
    this.card = false,
    this.bank = 'Wells Fargo',
  });
  final bool card;
  final String bank;
  @override
  State<LinkFormScreen> createState() => _LinkFormState();
}

class _LinkFormState extends State<LinkFormScreen> {
  final form = GlobalKey<FormState>();
  final number = TextEditingController(),
      holder = TextEditingController(),
      identity = TextEditingController(),
      expiry = TextEditingController(),
      cvv = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    for (final t in [number, holder, identity, expiry, cvv]) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => PageFrame(
    title: widget.card ? 'Link\ncard' : '${widget.bank}\nbank',
    subtitle:
        'Preview linking with sample details. No bank connection is made.',
    footer: GradientButton(
      'Continue',
      busy: busy,
      onPressed: () async {
        if (!form.currentState!.validate() || busy) return;
        setState(() => busy = true);
        final store = WalletScope.of(c);
        try {
          await store.mutate(() {
            store.bankLinked = true;
            store.linkedAccountName = widget.card ? 'Visa' : widget.bank;
          });
          if (c.mounted) {
            toast(c, 'Demo account linked');
            Navigator.of(c).pushReplacementNamed('/recharge');
          }
        } catch (e) {
          if (c.mounted) {
            toast(c, errorText(e));
            setState(() => busy = false);
          }
        }
      },
    ),
    children: [
      Form(
        key: form,
        child: Column(
          children: [
            FormFieldLine(
              widget.card ? 'Card number' : 'Account number',
              controller: number,
              numeric: true,
              validator: (v) =>
                  RegExp(
                    widget.card ? r'^\d{12,19}$' : r'^\d{6,20}$',
                  ).hasMatch((v ?? '').replaceAll(' ', ''))
                  ? null
                  : 'Enter a valid number',
            ),
            FormFieldLine('Card holder', controller: holder),
            if (!widget.card)
              FormFieldLine('Identity Card / Passport', controller: identity),
            if (widget.card) ...[
              FormFieldLine(
                'Expiry (MM/YY)',
                controller: expiry,
                validator: (v) =>
                    RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '')
                    ? null
                    : 'Use MM/YY',
              ),
              FormFieldLine(
                'CVV',
                controller: cvv,
                password: true,
                numeric: true,
                validator: (v) => RegExp(r'^\d{3,4}$').hasMatch(v ?? '')
                    ? null
                    : 'Use 3 or 4 digits',
              ),
            ],
          ],
        ),
      ),
      gap,
      const Text(
        'Card, account and identity numbers are not stored.',
        style: TextStyle(fontSize: 12, color: AppColors.hint),
      ),
    ],
  );
}

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});
  @override
  State<CreateWalletScreen> createState() => _CreateWalletState();
}

class _CreateWalletState extends State<CreateWalletScreen> {
  Currency currency = Currency.eur;
  bool busy = false;
  @override
  Widget build(BuildContext c) {
    final available = Currency.values
        .where((cc) => !WalletScope.of(c).wallets.any((w) => w.currency == cc))
        .toList();
    return PageFrame(
      title: 'Create wallet',
      subtitle: 'Add a wallet in a new currency.',
      footer: available.isEmpty
          ? null
          : GradientButton(
              'Create',
              busy: busy,
              onPressed: () async {
                setState(() => busy = true);
                try {
                  await WalletScope.of(c).createWallet(currency);
                  if (c.mounted) {
                    Navigator.pop(c);
                    toast(c, 'Wallet created');
                  }
                } catch (e) {
                  if (c.mounted) {
                    toast(c, errorText(e));
                    setState(() => busy = false);
                  }
                }
              },
            ),
      children: [
        if (available.isEmpty)
          const EmptyState(
            'You have a wallet for every available currency.',
            icon: Icons.account_balance_wallet_outlined,
          )
        else
          ChoiceTile(
            'Choose currency',
            currency.code,
            onTap: () async {
              final result = await choose(
                c,
                'Choose currency',
                available,
                (cc) => cc.code,
              );
              if (result != null && mounted) setState(() => currency = result);
            },
          ),
        gap,
        const Text(
          'By tapping on CREATE, you agree to the demo Terms of Use and Privacy Policy.',
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
