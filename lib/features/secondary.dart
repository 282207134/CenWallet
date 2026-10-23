import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';
import 'account.dart';
import 'services.dart';

class ActivityFilter {
  const ActivityFilter({
    this.type = 'All',
    this.from,
    this.to,
    this.minimum,
    this.maximum,
  });
  final String type;
  final DateTime? from, to;
  final int? minimum, maximum;
  bool get hasBounds =>
      from != null || to != null || minimum != null || maximum != null;
  bool matches(Activity a) =>
      (from == null || !a.date.isBefore(from!)) &&
      (to == null || a.date.isBefore(to!.add(const Duration(days: 1)))) &&
      (minimum == null ||
          a.currency == Currency.usd && a.amount.abs() >= minimum!) &&
      (maximum == null ||
          a.currency == Currency.usd && a.amount.abs() <= maximum!);
}

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, this.filter});
  final ActivityFilter? filter;
  @override
  State<FilterScreen> createState() => _FilterState();
}

class _FilterState extends State<FilterScreen> {
  final form = GlobalKey<FormState>();
  late String type = widget.filter?.type ?? 'All';
  late DateTime? from = widget.filter?.from, to = widget.filter?.to;
  late final minimum = TextEditingController(
    text: widget.filter?.minimum == null
        ? ''
        : (widget.filter!.minimum! / 100).toStringAsFixed(2),
  );
  late final maximum = TextEditingController(
    text: widget.filter?.maximum == null
        ? ''
        : (widget.filter!.maximum! / 100).toStringAsFixed(2),
  );
  @override
  void dispose() {
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  String dateLabel(DateTime? date) =>
      date == null ? 'Any date' : '${date.day}/${date.month}/${date.year}';
  Future<void> date(bool start) async {
    final result = await showDatePicker(
      context: context,
      initialDate: (start ? from : to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (result != null && mounted) {
      setState(() {
        if (start) {
          from = result;
        } else {
          to = result;
        }
      });
    }
  }

  int? parse(String s) => s.trim().isEmpty
      ? null
      : s.trim() == '0'
      ? 0
      : Currency.usd.parse(s);
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Filter',
    footer: GradientButton(
      'Apply',
      onPressed: () {
        if (!form.currentState!.validate()) return;
        final min = parse(minimum.text), max = parse(maximum.text);
        if (from != null && to != null && from!.isAfter(to!)) {
          toast(c, 'From date must be before To date.');
          return;
        }
        if (min != null && max != null && min > max) {
          toast(c, 'Minimum must not exceed maximum.');
          return;
        }
        Navigator.pop(
          c,
          ActivityFilter(
            type: type,
            from: from,
            to: to,
            minimum: min,
            maximum: max,
          ),
        );
      },
    ),
    children: [
      Wrap(
        spacing: 10,
        children: ['All', 'Received', 'Sent']
            .map(
              (v) => ChoiceChip(
                label: Text(v),
                selected: type == v,
                onSelected: (_) => setState(() => type = v),
              ),
            )
            .toList(),
      ),
      gap,
      ChoiceTile(
        'From date',
        dateLabel(from),
        icon: Icons.calendar_today_outlined,
        onTap: () => date(true),
      ),
      ChoiceTile(
        'To date',
        dateLabel(to),
        icon: Icons.calendar_today_outlined,
        onTap: () => date(false),
      ),
      heading('Amount of money (USD)'),
      Form(
        key: form,
        child: Column(
          children: [
            FormFieldLine(
              'Minimum (optional)',
              controller: minimum,
              numeric: true,
              validator: (v) => v == null || v.isEmpty || parse(v) != null
                  ? null
                  : 'Enter a valid USD amount',
            ),
            FormFieldLine(
              'Maximum (optional)',
              controller: maximum,
              numeric: true,
              validator: (v) => v == null || v.isEmpty || parse(v) != null
                  ? null
                  : 'Enter a valid USD amount',
            ),
          ],
        ),
      ),
      gap,
      TextButton(
        onPressed: () => setState(() {
          type = 'All';
          from = null;
          to = null;
          minimum.clear();
          maximum.clear();
        }),
        child: const Text('Reset filters'),
      ),
    ],
  );
}

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen(this.contact, {super.key});
  final Contact contact;
  @override
  State<ContactDetailScreen> createState() => _ContactDetailState();
}

class _ContactDetailState extends State<ContactDetailScreen> {
  late Contact contact = widget.contact;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Friends',
    footer: GradientButton(
      'Transfer money',
      onPressed: () => go(c, AppPage.transferWallet, contact),
    ),
    children: [
      gap,
      Center(
        child: CircleAvatar(
          radius: 46,
          backgroundColor: const Color(0xfff4e7fa),
          child: Text(
            contact.name[0],
            style: const TextStyle(fontSize: 38, color: AppColors.purple),
          ),
        ),
      ),
      gap,
      Text(
        contact.name,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
      ),
      Center(
        child: TextButton(
          onPressed: () async {
            final updated = await go<Contact>(c, AppPage.addContact, contact);
            if (updated != null && mounted) setState(() => contact = updated);
          },
          child: const Text('Change'),
        ),
      ),
      gap,
      Surface(
        child: Column(
          children: [
            DetailRow('Wallet no.', contact.code),
            DetailRow('Name', contact.name),
          ],
        ),
      ),
      gap,
      TextButton(
        onPressed: () async {
          final remove = await showDialog<bool>(
            context: c,
            builder: (c) => AlertDialog(
              title: const Text('Delete contact?'),
              content: Text(contact.name),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (remove == true &&
              c.mounted &&
              await persist(
                c,
                (s) => s.contacts = s.contacts
                    .where((cc) => cc.code != contact.code)
                    .toList(),
              ) &&
              c.mounted) {
            Navigator.pop(c);
          }
        },
        child: const Text(
          'Delete contact',
          style: TextStyle(color: AppColors.coral),
        ),
      ),
    ],
  );
}

class MerchantReceiptScreen extends StatefulWidget {
  const MerchantReceiptScreen({super.key});
  @override
  State<MerchantReceiptScreen> createState() => _MerchantReceiptState();
}

class _MerchantReceiptState extends State<MerchantReceiptScreen> {
  Currency currency = Currency.usd;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Receipt',
    subtitle: 'Review your merchant payment.',
    footer: GradientButton(
      'Continue',
      onPressed: () => go(
        c,
        AppPage.review,
        PaymentDraft(
          kind: PaymentKind.bill,
          currency: currency,
          amount: (40 * currency.unitsPerUsd * currency.scale).round(),
          recipient: 'Circle K · John',
          note: 'Snack and VAT',
        ),
      ),
    ),
    children: [
      WalletChoice(
        value: currency,
        onChanged: (v) => setState(() => currency = v),
      ),
      gap,
      heading('Information'),
      const DetailRow('Name of seller', 'John'),
      const DetailRow('Store', 'Circle K'),
      const Divider(),
      heading('List of item'),
      const DetailRow('Snack', '\$20.00'),
      const DetailRow('VAT', '\$20.00'),
      const Divider(),
      DetailRow(
        'TOTAL',
        currency.format((40 * currency.unitsPerUsd * currency.scale).round()),
        emphasis: true,
      ),
    ],
  );
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportState();
}

class _ReportState extends State<ReportScreen> {
  final text = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Report\nissue',
    subtitle: 'Have something wrong? Save the details of your issue.',
    footer: GradientButton(
      'Save report',
      busy: busy,
      onPressed: () async {
        if (!form.currentState!.validate() || busy) return;
        setState(() => busy = true);
        final success = await persist(
          c,
          (s) => s.reports = [...s.reports, text.text.trim()],
        );
        if (success && c.mounted) {
          Navigator.of(c).pushReplacementNamed('/reportSuccess');
        } else if (mounted) {
          setState(() => busy = false);
        }
      },
    ),
    children: [
      heading('Content'),
      Form(
        key: form,
        child: TextFormField(
          controller: text,
          maxLines: 8,
          maxLength: 2000,
          validator: (v) => (v?.trim().length ?? 0) < 10
              ? 'Enter at least 10 characters'
              : null,
          decoration: const InputDecoration(
            hintText: 'Send us troubles',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      gap,
      const Text(
        'Reports are stored locally in this demo. They are not sent to a support team.',
        style: TextStyle(fontSize: 12, color: AppColors.hint),
      ),
    ],
  );
}

class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: '',
    back: false,
    footer: GradientButton('Home', onPressed: () => goHome(c)),
    children: [
      const SizedBox(height: 80),
      const Icon(
        Icons.check_circle_outline_rounded,
        color: AppColors.purple,
        size: 100,
      ),
      gap,
      const Text(
        'Successful',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
      ),
      gap,
      const Text(
        'Your report has been saved on this device.',
        textAlign: TextAlign.center,
      ),
      gap,
      Text(
        '${WalletScope.of(c).reports.length} local report(s)',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.hint),
      ),
    ],
  );
}

class BankLinksScreen extends StatelessWidget {
  const BankLinksScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = WalletScope.of(c);
    return PageFrame(
      title: 'Manage\nbank link',
      footer: GradientButton(
        'Link account',
        onPressed: () => go(c, AppPage.linkAccount),
      ),
      children: [
        heading('Bank account'),
        if (!s.bankLinked)
          const EmptyState(
            'No linked bank account',
            icon: Icons.account_balance_outlined,
          )
        else
          Surface(
            child: Column(
              children: [
                DetailRow('Bank', s.linkedAccountName),
                const DetailRow('Status', 'Linked demo account'),
                TextButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: c,
                      builder: (c) => AlertDialog(
                        title: const Text('Unlink account?'),
                        content: Text(s.linkedAccountName),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Unlink'),
                          ),
                        ],
                      ),
                    );
                    if (result == true && c.mounted) {
                      await persist(c, (s) => s.bankLinked = false);
                    }
                  },
                  child: const Text(
                    'Unlink',
                    style: TextStyle(color: AppColors.coral),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class FingerprintsScreen extends StatelessWidget {
  const FingerprintsScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = WalletScope.of(c);
    return PageFrame(
      title: 'Fingerprint',
      subtitle: 'Biometric settings preview',
      children: [
        const Icon(Icons.fingerprint, size: 90, color: AppColors.purple),
        gap,
        Surface(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Finger 1'),
            subtitle: const Text('Demo fingerprint'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet(
              context: c,
              showDragHandle: true,
              builder: (c) => const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 80,
                        color: AppColors.purple,
                      ),
                      gap,
                      Text('Finger 1', style: TextStyle(fontSize: 24)),
                      gap,
                      Text(
                        'This preview does not enroll or delete device biometrics.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        gap,
        heading('Use for'),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Unlock wallet'),
          value: s.biometricUnlock,
          onChanged: (v) => persist(c, (s) => s.biometricUnlock = v),
          activeTrackColor: AppColors.purple,
        ),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Payment'),
          value: s.biometricPayment,
          onChanged: (v) => persist(c, (s) => s.biometricPayment = v),
          activeTrackColor: AppColors.purple,
        ),
        gap,
        const Text(
          'Preferences are saved locally. Native biometric authentication is not connected in this demo.',
          style: TextStyle(fontSize: 12, color: AppColors.hint),
        ),
      ],
    );
  }
}

class FlightsScreen extends StatelessWidget {
  const FlightsScreen({super.key, required this.plan});
  final BookingPlan plan;
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Booking\nflight',
    subtitle: 'Suggested flight · ${plan.fromCode} → ${plan.toCode}',
    children: [
      gap,
      for (final option in [
        ('Qatar airways', '6:00 AM', '8:45 PM', 10020),
        ('THAI airways', '9:00 AM', '11:45 PM', 12000),
      ]) ...[
        Surface(
          onTap: () {
            plan.airline = option.$1;
            plan.baseFare = option.$4;
            go(c, AppPage.bookingDetails, plan);
          },
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 28,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      option.$1,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              gap,
              DetailRow('Taking off', option.$2),
              DetailRow('Landing', option.$3),
              const DetailRow('Total time', '16:10:00'),
              const Divider(),
              DetailRow(
                'One way',
                Currency.usd.format(option.$4),
                emphasis: true,
              ),
            ],
          ),
        ),
        gap,
      ],
      const Text(
        'Choose a flight to continue with your booking preview.',
        style: TextStyle(fontSize: 12, color: AppColors.hint),
      ),
    ],
  );
}
