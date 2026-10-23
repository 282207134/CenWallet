import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';
import '../widgets/chart.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<ShellScreen> createState() => _ShellState();
}

class _ShellState extends State<ShellScreen> {
  late int index = widget.initialIndex;
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: switch (index) {
        0 => const HomeContent(),
        1 => const OffersContent(),
        2 => const PaymentContent(),
        3 => const FriendsContent(),
        _ => const MarketContent(),
      },
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x20aaaaaa),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: IconButton(
                  tooltip: [
                    'Home',
                    'Incentive',
                    'Payment',
                    'Friends',
                    'Market',
                  ][i],
                  onPressed: () => setState(() => index = i),
                  icon: Icon(
                    [
                      Icons.home_rounded,
                      Icons.card_giftcard,
                      Icons.receipt_long_outlined,
                      Icons.link_rounded,
                      Icons.show_chart_rounded,
                    ][i],
                    color: index == i
                        ? AppColors.pink
                        : const Color(0xffd8d9db),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});
  @override
  Widget build(BuildContext c) {
    final store = WalletScope.of(c);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 6, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                InkWell(
                  onTap: () => go(c, AppPage.profile),
                  borderRadius: BorderRadius.circular(24),
                  child: const CircleAvatar(
                    radius: 21,
                    backgroundImage: AssetImage('assets/images/avatar.png'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () => go(c, AppPage.profile),
                    child: Text(
                      'Hi, ${store.name.split(' ').first} !\nWelcome back',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'QR code',
                  onPressed: () => go(c, AppPage.qr),
                  icon: const Icon(Icons.qr_code_rounded),
                ),
                PopupMenuButton<AppPage>(
                  tooltip: 'More options',
                  onSelected: (p) => go(c, p),
                  itemBuilder: (_) => [
                    for (final entry in [
                      (AppPage.settings, 'Setting'),
                      (AppPage.manage, 'Manage wallet'),
                      (AppPage.notifications, 'Notifications'),
                    ])
                      PopupMenuItem(value: entry.$1, child: Text(entry.$2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          WalletCarousel(wallets: store.wallets),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading('Functions'),
                Row(
                  children: [
                    for (final action in [
                      (Icons.savings_outlined, 'RECHARGE', AppPage.recharge),
                      (Icons.ios_share_outlined, 'TRANSFER', AppPage.transfer),
                      (Icons.cached_rounded, 'EXCHANGE', AppPage.exchange),
                    ])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: action.$3 == AppPage.exchange ? 0 : 12,
                          ),
                          child: Surface(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 2,
                            ),
                            onTap: () => go(c, action.$3),
                            child: Column(
                              children: [
                                Icon(
                                  action.$1,
                                  color: AppColors.pink,
                                  size: 30,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  action.$2,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'money',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.hint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent transactions',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => go(c, AppPage.history),
                      child: const Text(
                        'More',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                if (store.activities.isEmpty)
                  const EmptyState('No transactions yet')
                else
                  ...store.activities.take(4).map((a) => ActivityTile(a)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile(this.activity, {super.key, this.card = false});
  final Activity activity;
  final bool card;
  @override
  Widget build(BuildContext c) {
    final a = activity;
    final row = InkWell(
      onTap: () => go(c, AppPage.transaction, a),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    a.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: card ? AppColors.hint : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${a.amount > 0 ? '+ ' : '- '}${a.currency.format(a.amount.abs())}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${a.date.day.toString().padLeft(2, '0')}/${a.date.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.hint),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return card
        ? Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: row,
            ),
          )
        : Column(children: [row, const Divider(height: 1)]);
  }
}

class PaymentContent extends StatelessWidget {
  const PaymentContent({super.key});
  @override
  Widget build(BuildContext c) => PageBody(
    title: 'Payment',
    back: false,
    subtitle:
        'Pay your everyday bills and discover services for your next journey.',
    children: [
      const SizedBox(height: 12),
      paymentCard(
        c,
        'Bills',
        'Keep your everyday bills in one place',
        'bills_art.png',
        AppPage.bills,
      ),
      gap,
      paymentCard(
        c,
        'Services',
        'Booking flight to receive\n20% discount',
        'services_art.png',
        AppPage.services,
      ),
      gap,
      TextButton(
        onPressed: () => go(c, AppPage.receipt),
        child: const Text('Check merchant receipt'),
      ),
    ],
  );
  Widget paymentCard(
    BuildContext c,
    String title,
    String text,
    String art,
    AppPage page,
  ) => Surface(
    padding: EdgeInsets.zero,
    onTap: () => go(c, page),
    child: SizedBox(
      height: 258,
      child: Stack(
        children: [
          Positioned.fill(child: Art(art, fit: BoxFit.cover)),
          Positioned(
            left: 24,
            right: 100,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(text, style: const TextStyle(fontSize: 11, height: 1.7)),
                const SizedBox(height: 22),
                const Text(
                  'Detail  →',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class OffersContent extends StatelessWidget {
  const OffersContent({super.key});
  void coupon(BuildContext c, String partner) => showModalBottomSheet(
    context: c,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: AppColors.purple,
            ),
            gap,
            Text(
              'Discount from $partner',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Text('Demo offer · 5 days left'),
            gap,
            const SelectableText(
              'F26748',
              style: TextStyle(
                fontSize: 34,
                letterSpacing: 6,
                color: AppColors.purple,
              ),
            ),
            gap,
            GradientButton(
              'Copy',
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: 'F26748'));
                if (c.mounted) {
                  Navigator.pop(c);
                  toast(c, 'Promo code copied');
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext c) => PageBody(
    title: 'Incentive',
    back: false,
    trailing: IconButton(
      tooltip: 'Notifications',
      onPressed: () => go(c, AppPage.notifications),
      icon: Badge(
        label: Text('${WalletScope.of(c).unread}'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    ),
    children: [
      TextField(
        decoration: const InputDecoration(
          hintText: 'Enter your promo code',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        onSubmitted: (v) {
          if (v.trim().toUpperCase() == 'F26748') {
            coupon(c, 'McDonald');
          } else {
            toast(c, 'This incentive code was not found. Try F26748.');
          }
        },
      ),
      const SizedBox(height: 30),
      heading('Special preference'),
      Surface(
        padding: EdgeInsets.zero,
        onTap: () => go(c, AppPage.linkAccount),
        child: Container(
          height: 185,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Art('promo.png', fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                top: 12,
                child: Chip(
                  label: Text(
                    'New',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: Color(0xfff25458),
                  side: BorderSide.none,
                ),
              ),
              const Positioned(
                left: 18,
                bottom: 22,
                child: Text(
                  'Link bank card to receive \$10 in\nyour wallet\n\nJoin →',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 34),
      heading('Preference from partner'),
      ...[
        ('McDonald', '20%', const Color(0xffc62d2d)),
        ('StarBucks', '50%', const Color(0xff008265)),
      ].map(
        (offer) => Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Surface(
            padding: EdgeInsets.zero,
            onTap: () => coupon(c, offer.$1),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 114,
                  color: offer.$3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        offer.$1 == 'McDonald' ? 'M' : '✦',
                        style: TextStyle(
                          fontSize: 43,
                          color: offer.$1 == 'McDonald'
                              ? const Color(0xffffc542)
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${offer.$2} OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${offer.$1} discount ${offer.$2}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          'Available this week',
                          style: TextStyle(color: AppColors.hint, fontSize: 10),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Get in  →',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class FriendsContent extends StatefulWidget {
  const FriendsContent({super.key});
  @override
  State<FriendsContent> createState() => _FriendsState();
}

class _FriendsState extends State<FriendsContent> {
  String query = '';
  @override
  Widget build(BuildContext c) {
    final contacts = WalletScope.of(c).contacts
        .where(
          (x) =>
              '${x.name} ${x.code}'.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return PageBody(
      title: 'Friend',
      back: false,
      footer: GradientButton(
        'Create new contact',
        onPressed: () => go(c, AppPage.addContact),
      ),
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Find friend',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        gap,
        heading('Frequently contacted'),
        if (contacts.isEmpty)
          const EmptyState('No contacts found', icon: Icons.people_outline)
        else
          ...contacts.asMap().entries.map(
            (e) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              leading: CircleAvatar(
                backgroundColor: [
                  const Color(0xfffde6e9),
                  const Color(0xffe8defa),
                  const Color(0xffd9f3f4),
                ][e.key % 3],
                child: Text(
                  e.value.name[0],
                  style: const TextStyle(color: AppColors.purple),
                ),
              ),
              title: Text(
                e.value.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                e.value.code,
                style: const TextStyle(fontSize: 11, color: AppColors.hint),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(c, AppPage.contactDetail, e.value),
            ),
          ),
      ],
    );
  }
}

class MarketContent extends StatefulWidget {
  const MarketContent({super.key});
  @override
  State<MarketContent> createState() => _MarketState();
}

class _MarketState extends State<MarketContent> {
  bool live = false;
  @override
  Widget build(BuildContext c) => PageBody(
    title: live ? 'Live rates' : 'Bitcoin\nprice',
    subtitle: 'Demo market snapshot · reference prices',
    back: false,
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => live = false),
              child: Text(
                'Bitcoin market',
                style: TextStyle(
                  color: live ? AppColors.hint : AppColors.purple,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => live = true),
              child: Text(
                'Live rates',
                style: TextStyle(
                  color: live ? AppColors.purple : AppColors.hint,
                ),
              ),
            ),
          ),
        ],
      ),
      gap,
      if (!live) ...[
        const WalletChart(),
        gap,
        heading('Bitcoin market'),
        const DetailRow('Trading floor / Pairs', 'Price'),
        ...[
          'Bitfinex',
          'Binance',
          'Coinbase',
        ].map((s) => Surface(child: DetailRow('$s\nBTC / USD', '\$4,072.30'))),
        gap,
        Row(
          children: [
            Expanded(
              child: GradientButton(
                'Sell',
                coral: true,
                onPressed: () => go(c, AppPage.exchange, Currency.btc),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GradientButton(
                'Buy',
                onPressed: () => go(c, AppPage.exchange),
              ),
            ),
          ],
        ),
      ] else ...[
        heading('Live currency rates'),
        const DetailRow('Major pairs', 'Bid          Ask'),
        for (final row in [
          ('USD / JPY', '113.85     113.86'),
          ('USD / THB', '32.90       33.00'),
          ('EUR / USD', '1.1273     1.1274'),
          ('USD / VND', '23,312      23,382'),
        ]) ...[DetailRow(row.$1, row.$2), const Divider()],
        gap,
        heading('Live central bank rates'),
        const DetailRow('JPY', '− 0.10%'),
        const DetailRow('AUD', '0.75%'),
        const DetailRow('CHF', '− 0.75%'),
        const DetailRow('CAD', '0.10%'),
      ],
    ],
  );
}

class WalletCarousel extends StatefulWidget {
  const WalletCarousel({super.key, required this.wallets});
  final List<Wallet> wallets;
  @override
  State<WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends State<WalletCarousel> {
  final controller = PageController(viewportFraction: .86);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => SizedBox(
    height: 202,
    child: PageView.builder(
      controller: controller,
      itemCount: widget.wallets.length,
      itemBuilder: (c, i) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 22),
        child: WalletCard(
          widget.wallets[i],
          onTap: () => go(c, AppPage.manage),
        ),
      ),
    ),
  );
}
