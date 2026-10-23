import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key, this.transport = false});
  final bool transport;
  @override
  State<ServicesScreen> createState() => _ServicesState();
}

class _ServicesState extends State<ServicesScreen> {
  String query = '';
  @override
  Widget build(BuildContext c) {
    final options = widget.transport
        ? [
            (Icons.flight_takeoff_rounded, 'Booking flight', AppPage.booking),
            (Icons.train_outlined, 'Train', AppPage.booking),
            (Icons.directions_bus_outlined, 'Bus', AppPage.booking),
            (Icons.local_taxi_outlined, 'Taxi', AppPage.booking),
          ]
        : [
            (Icons.directions_bus_outlined, 'Transport', AppPage.services),
            (Icons.home_rounded, 'Home', AppPage.bills),
            (Icons.shopping_cart_outlined, 'Shopping', AppPage.incentives),
            (Icons.live_tv_outlined, 'Entertainment', AppPage.incentives),
          ];
    final list = options
        .where((o) => o.$2.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return PageFrame(
      title: widget.transport ? 'Transport' : 'Services',
      subtitle: widget.transport
          ? 'Book your next journey with your wallet.'
          : 'Everyday services, right at your fingertips.',
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 48),
        if (list.isEmpty)
          const EmptyState('No services found')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 20,
            ),
            itemBuilder: (c, i) {
              final item = list[i],
                  color = [
                    const Color(0xffd696e7),
                    const Color(0xffffab9e),
                    const Color(0xffffa4cb),
                    AppColors.cyan,
                  ][i % 4];
              return Surface(
                padding: EdgeInsets.zero,
                onTap: () {
                  if (!widget.transport && item.$2 == 'Transport') {
                    Navigator.push(
                      c,
                      MaterialPageRoute<void>(
                        builder: (_) => const ServicesScreen(transport: true),
                        settings: const RouteSettings(name: '/transport'),
                      ),
                    );
                  } else if (widget.transport && item.$2 != 'Booking flight') {
                    toast(
                      c,
                      '${item.$2} bookings are coming soon. Flight booking is available.',
                    );
                  } else {
                    go(c, item.$3);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -28,
                        top: -28,
                        child: Container(
                          width: 85,
                          height: 85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: .3),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.$1, size: 36, color: color),
                            const SizedBox(height: 18),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

const bills = [
  ('internet', 'Internet', 10000, Icons.wifi),
  ('tv', 'TV', 11200, Icons.tv_outlined),
  ('electricity', 'Electricity', 10000, Icons.bolt_outlined),
];

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final store = WalletScope.of(c),
        unpaid = bills
            .where((b) => !WalletScope.of(c).paidBills.contains(b.$1))
            .toList();
    void pay(List<(String, String, int, IconData)> items) => go(
      c,
      AppPage.review,
      PaymentDraft(
        kind: PaymentKind.bill,
        currency: Currency.usd,
        amount: items.fold(0, (sum, b) => sum + b.$3),
        recipient: items.map((b) => b.$2).join(', '),
        billIds: items.map((b) => b.$1).toList(),
      ),
    );
    return PageFrame(
      title: 'Bills',
      subtitle: '${unpaid.length} bills waiting for payment.',
      footer: unpaid.isEmpty
          ? null
          : GradientButton(
              'Pay all · ${Currency.usd.format(unpaid.fold(0, (sum, b) => sum + b.$3))}',
              onPressed: () => pay(unpaid),
            ),
      children: [
        for (final b in bills) ...[
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(b.$4, color: AppColors.purple, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        b.$2,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      Currency.usd.format(b.$3),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Auto pay on 15th Jul',
                  style: TextStyle(color: AppColors.hint, fontSize: 11),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.paidBills.contains(b.$1) ? 'Paid' : 'Unpaid',
                        style: TextStyle(
                          color: store.paidBills.contains(b.$1)
                              ? Colors.teal
                              : AppColors.coral,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: store.paidBills.contains(b.$1)
                          ? null
                          : () => pay([b]),
                      child: Text(
                        store.paidBills.contains(b.$1) ? 'PAID' : 'PAY',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          gap,
        ],
        const DetailRow('Fee', '\$0.00'),
        DetailRow(
          'Total unpaid',
          Currency.usd.format(unpaid.fold(0, (sum, b) => sum + b.$3)),
          emphasis: true,
        ),
      ],
    );
  }
}

class BookingPlan {
  BookingPlan({
    this.from = 'Paris',
    this.to = 'Bangkok',
    DateTime? date,
    this.travellers = 1,
    this.travelClass = 'Economy',
    this.roundTrip = false,
    this.luggage = 10,
    this.firstName = '',
    this.lastName = '',
    this.currency = Currency.usd,
    this.airline = 'Qatar airways',
    this.baseFare = 10000,
  }) : date = date ?? DateTime.now().add(const Duration(days: 7));
  String from, to, travelClass, firstName, lastName, airline;
  int baseFare;
  DateTime date;
  int travellers, luggage;
  bool roundTrip;
  Currency currency;
  String get fromCode => code(from);
  String get toCode => code(to);
  String code(String city) =>
      {
        'Paris': 'CDG',
        'Bangkok': 'BKK',
        'Barcelona': 'BCN',
        'Tokyo': 'NRT',
        'New York': 'JFK',
      }[city] ??
      city.substring(0, city.length.clamp(0, 3)).toUpperCase();
  int get price =>
      (travelClass == 'First class'
          ? 30000
          : travelClass == 'Business'
          ? 20000
          : baseFare) *
      travellers *
      (roundTrip ? 2 : 1);
  int get luggageFee => luggage > 0 ? 1000 * travellers : 0;
  int get total =>
      ((price + luggageFee + 200) / 100 * currency.unitsPerUsd * currency.scale)
          .round();
  String get dateLabel =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class BookingScreen extends StatefulWidget {
  const BookingScreen(this.page, {super.key, this.plan});
  final AppPage page;
  final BookingPlan? plan;
  @override
  State<BookingScreen> createState() => _BookingState();
}

class _BookingState extends State<BookingScreen> {
  late final plan = widget.plan ?? BookingPlan();
  final form = GlobalKey<FormState>();
  late final first = TextEditingController(text: plan.firstName),
      last = TextEditingController(text: plan.lastName);
  @override
  void dispose() {
    first.dispose();
    last.dispose();
    super.dispose();
  }

  Widget route() => Surface(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(plan.from, style: const TextStyle(fontSize: 12)),
            const Icon(Icons.flight_takeoff, color: AppColors.purple),
            Text(plan.to, style: const TextStyle(fontSize: 12)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              plan.fromCode,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const Expanded(
              child: Text(
                '················',
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              plan.toCode,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    ),
  );
  void next() {
    if (widget.page == AppPage.booking) {
      if (plan.from == plan.to) {
        toast(context, 'Choose different departure and destination cities.');
        return;
      }
      go(context, AppPage.flights, plan);
    } else if (widget.page == AppPage.bookingDetails) {
      go(context, AppPage.bookingPassenger, plan);
    } else if (widget.page == AppPage.bookingPassenger) {
      if (!form.currentState!.validate()) return;
      plan.firstName = first.text.trim();
      plan.lastName = last.text.trim();
      go(context, AppPage.bookingReceipt, plan);
    } else {
      go(
        context,
        AppPage.review,
        PaymentDraft(
          kind: PaymentKind.booking,
          currency: plan.currency,
          amount: plan.total,
          recipient: '${plan.fromCode} → ${plan.toCode}',
          note:
              '${plan.firstName} ${plan.lastName} · ${plan.dateLabel} · ${plan.travellers} traveller(s)',
        ),
      );
    }
  }

  Future<void> city(bool from) async {
    final result = await choose(context, from ? 'From' : 'To', [
      'Paris',
      'Bangkok',
      'Barcelona',
      'Tokyo',
      'New York',
    ], (v) => v);
    if (result != null && mounted) {
      setState(() {
        if (from) {
          plan.from = result;
        } else {
          plan.to = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext c) {
    final start = widget.page == AppPage.booking,
        detail = widget.page == AppPage.bookingDetails,
        passenger = widget.page == AppPage.bookingPassenger;
    return PageFrame(
      title: 'Booking\nflight',
      subtitle: start
          ? 'Find your next destination and plan your trip.'
          : detail
          ? 'Step 1: Basic information'
          : passenger
          ? 'Step 2: Necessary information'
          : 'Step 3: Confirm',
      footer: GradientButton(start ? 'Next step' : 'Continue', onPressed: next),
      children: [
        if (start) ...[
          ChoiceTile(
            'From',
            plan.from,
            icon: Icons.flight_takeoff,
            onTap: () => city(true),
          ),
          ChoiceTile(
            'To',
            plan.to,
            icon: Icons.flight_land,
            onTap: () => city(false),
          ),
          gap,
          heading('Suggested place'),
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (c, i) {
                final city = ['Bangkok', 'Barcelona', 'Paris'][i],
                    art = ['bangkok.png', 'barcelona.jpg', 'paris.jpg'][i];
                return InkWell(
                  onTap: () => setState(() => plan.to = city),
                  child: Container(
                    width: 156,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Art(art, fit: BoxFit.cover),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x55e98593), Colors.transparent],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Text(
                            city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          route(),
          gap,
          if (detail) ...[
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('One way'),
                    selected: !plan.roundTrip,
                    onSelected: (_) => setState(() => plan.roundTrip = false),
                  ),
                ),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Round trip'),
                    selected: plan.roundTrip,
                    onSelected: (_) => setState(() => plan.roundTrip = true),
                  ),
                ),
              ],
            ),
            gap,
            ChoiceTile(
              'Departure date',
              plan.dateLabel,
              icon: Icons.calendar_today_outlined,
              onTap: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: c,
                  initialDate: plan.date,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (date != null && mounted) setState(() => plan.date = date);
              },
            ),
            if (plan.roundTrip)
              const Text(
                'Return flight: 7 days after departure',
                style: TextStyle(fontSize: 12),
              ),
            ChoiceTile(
              'Traveller',
              '${plan.travellers} adult(s)',
              onTap: () async {
                final value = await choose(c, 'Traveller', [
                  1,
                  2,
                  3,
                  4,
                ], (v) => '$v adult(s)');
                if (value != null && mounted) {
                  setState(() => plan.travellers = value);
                }
              },
            ),
            ChoiceTile(
              'Class',
              plan.travelClass,
              onTap: () async {
                final value = await choose(c, 'Class', [
                  'Economy',
                  'Business',
                  'First class',
                ], (v) => v);
                if (value != null && mounted) {
                  setState(() => plan.travelClass = value);
                }
              },
            ),
          ] else if (passenger) ...[
            Form(
              key: form,
              child: Column(
                children: [
                  FormFieldLine('Last name', controller: last),
                  FormFieldLine('Middle and first name', controller: first),
                ],
              ),
            ),
            gap,
            ChoiceTile(
              'Luggage (kg)',
              '${plan.luggage} kg',
              onTap: () async {
                final value = await choose(c, 'Luggage', [
                  0,
                  10,
                  20,
                  30,
                ], (v) => '$v kg');
                if (value != null && mounted) {
                  setState(() => plan.luggage = value);
                }
              },
            ),
            WalletChoice(
              value: plan.currency,
              onChanged: (v) => setState(() => plan.currency = v),
            ),
          ] else ...[
            Surface(
              child: Column(
                children: [
                  DetailRow('Passenger', '${plan.firstName} ${plan.lastName}'),
                  DetailRow('Date', plan.dateLabel),
                  DetailRow('Class', plan.travelClass),
                  DetailRow('Travellers', '${plan.travellers}'),
                  DetailRow(
                    'Journey',
                    plan.roundTrip ? 'Round trip · return +7 days' : 'One way',
                  ),
                  DetailRow('Flight', '${plan.airline} · demo'),
                  const DetailRow('Boarding time', '10:00 AM'),
                  const DetailRow('Seat / Gate', '20 / H'),
                  const Divider(),
                  DetailRow('Price', Currency.usd.format(plan.price)),
                  DetailRow('Luggage', Currency.usd.format(plan.luggageFee)),
                  const DetailRow('Fee', '\$2.00'),
                  DetailRow(
                    'Total',
                    plan.currency.format(plan.total),
                    emphasis: true,
                  ),
                ],
              ),
            ),
            gap,
            const Text(
              'This is a flight booking preview. No reservation is issued.',
              style: TextStyle(fontSize: 11, color: AppColors.hint),
            ),
          ],
        ],
      ],
    );
  }
}
