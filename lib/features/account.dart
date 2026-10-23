import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/navigation.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';
import '../widgets/ui.dart';

Future<bool> persist(BuildContext c, void Function(WalletStore) change) async {
  final s = WalletScope.of(c), before = WalletScope.of(c).snapshot();
  change(s);
  try {
    await s.save();
    return true;
  } catch (e) {
    s.restore(before);
    if (c.mounted) toast(c, errorText(e));
    return false;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = WalletScope.of(c);
    return PageFrame(
      title: '',
      footer: GradientButton(
        'Log out',
        onPressed: () {
          s.signedIn = false;
          Navigator.of(c).pushNamedAndRemoveUntil('/login', (_) => false);
        },
      ),
      children: [
        const SizedBox(height: 65),
        Row(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(s.address, style: const TextStyle(fontSize: 12)),
                  TextButton(
                    onPressed: () => go(c, AppPage.account),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 55),
        Surface(
          color: const Color(0xfff5f4f7),
          onTap: () => go(c, AppPage.identity),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  s.verified
                      ? 'Your account is verified'
                      : 'Do you want to verify your account?',
                ),
              ),
              Icon(
                s.verified ? Icons.verified_outlined : Icons.chevron_right,
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        gap,
        const Text('Levi has transferred \$20 to your USD wallet'),
        const Divider(height: 45),
        const Text('Your electric bill will be paid automatically tomorrow.'),
        gap,
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Setting'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => go(c, AppPage.settings),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final s = WalletScope.of(c);
    Widget link(String text, AppPage page) => Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => go(c, page),
        ),
        const Divider(),
      ],
    );
    return PageFrame(
      title: 'Setting',
      children: [
        link('Account', AppPage.account),
        link('Manage wallet', AppPage.manage),
        link('Manage bank link', AppPage.bankLinks),
        link('Fingerprint', AppPage.fingerprints),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Language'),
          trailing: Text(s.language),
          onTap: () => choose(c, 'Language', ['English'], (v) => v),
        ),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Fast payment',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Remember your payment preferences',
            style: TextStyle(fontSize: 10),
          ),
          value: s.fastPayment,
          onChanged: (v) => persist(c, (s) => s.fastPayment = v),
          activeTrackColor: AppColors.purple,
        ),
        const Divider(),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Local offer reminders',
            style: TextStyle(fontSize: 10),
          ),
          value: s.notifications,
          onChanged: (v) => persist(c, (s) => s.notifications = v),
          activeTrackColor: AppColors.purple,
        ),
        const Divider(),
        link('Support', AppPage.support),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Wallet security',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    s.verified ? '100%' : '40%',
                    style: const TextStyle(
                      color: Color(0xffeac757),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: s.verified ? 1 : .4,
                      color: const Color(0xffffd563),
                      backgroundColor: const Color(0xffeeeeee),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              s.verified
                  ? 'Your demo account information is complete.'
                  : 'Verify information so we can protect your account better',
              style: const TextStyle(color: AppColors.coral, fontSize: 12),
            ),
            ListTile(
              title: const Text(
                'Verify identity',
                style: TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(c, AppPage.identity),
            ),
            ListTile(
              title: const Text(
                'Change password',
                style: TextStyle(fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(c, AppPage.password),
            ),
          ],
        ),
        gap,
        const Text(
          'CenWallet · Demo edition\nPayments, authentication and market prices are simulated.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.hint, fontSize: 11),
        ),
      ],
    );
  }
}

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen(
    this.page, {
    super.key,
    this.reset = false,
    this.contact,
  });
  final AppPage page;
  final bool reset;
  final Contact? contact;
  @override
  State<AccountFormScreen> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountFormScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      password = TextEditingController(),
      newPassword = TextEditingController(),
      confirm = TextEditingController();
  bool initialized = false, busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      if (widget.contact != null) {
        name.text = widget.contact!.name;
        phone.text = widget.contact!.code;
      }
      final s = WalletScope.of(context);
      if (widget.page == AppPage.account) {
        name.text = s.name;
        email.text = s.email;
        phone.text = s.phone;
        address.text = s.address;
      }
      initialized = true;
    }
  }

  @override
  void dispose() {
    for (final t in [
      name,
      email,
      phone,
      address,
      password,
      newPassword,
      confirm,
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    setState(() => busy = true);
    try {
      if (widget.page == AppPage.account) {
        final saved = await persist(context, (s) {
          s.name = name.text.trim();
          s.email = email.text.trim();
          s.phone = phone.text.trim();
          s.address = address.text.trim();
        });
        if (saved && mounted) {
          Navigator.pop(context);
          toast(context, 'Account saved');
        }
      } else if (widget.page == AppPage.addContact) {
        if (widget.contact == null) {
          await WalletScope.of(
            context,
          ).addContact(name.text.trim(), phone.text.trim());
        } else {
          await WalletScope.of(
            context,
          ).editContact(widget.contact!, name.text.trim(), phone.text.trim());
        }
        if (mounted) {
          Navigator.pop(context, Contact(name.text.trim(), phone.text.trim()));
          toast(
            context,
            widget.contact == null ? 'Contact created' : 'Contact saved',
          );
        }
      } else if (widget.page == AppPage.identity) {
        if (mounted) go(context, AppPage.verify, 'identity');
      } else {
        if (mounted) {
          toast(
            context,
            'Demo password form completed. No credentials are stored.',
          );
          if (widget.reset) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (_) => false);
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) toast(context, errorText(e));
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext c) {
    final account = widget.page == AppPage.account,
        contact = widget.page == AppPage.addContact,
        identity = widget.page == AppPage.identity;
    return PageFrame(
      title: account
          ? 'Account'
          : contact
          ? (widget.contact == null ? 'Create\nfriend' : 'Edit\nfriend')
          : identity
          ? 'Identity\ncard'
          : 'Change\npassword',
      subtitle: identity
          ? 'Preview identity verification with sample information.'
          : null,
      footer: GradientButton(
        contact
            ? (widget.contact == null ? 'Create' : 'Save')
            : identity
            ? 'Continue'
            : 'Save',
        busy: busy,
        onPressed: submit,
      ),
      children: [
        if (identity) ...[
          const Icon(Icons.badge_outlined, color: AppColors.purple, size: 80),
          gap,
        ],
        Form(
          key: form,
          child: Column(
            children: [
              if (account || contact || identity) ...[
                FormFieldLine(
                  account ? 'Account' : 'Full name',
                  controller: name,
                ),
                if (account)
                  FormFieldLine(
                    'Email',
                    controller: email,
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v ?? '')
                        ? null
                        : 'Enter a valid email',
                  ),
                FormFieldLine(
                  contact
                      ? 'Wallet code'
                      : identity
                      ? 'Identity Card / Passport'
                      : 'Phone',
                  controller: phone,
                  validator: (v) => (v?.trim().length ?? 0) < 6
                      ? 'Enter at least 6 characters'
                      : null,
                ),
                if (account) FormFieldLine('Address', controller: address),
              ] else ...[
                if (!widget.reset)
                  FormFieldLine(
                    'Current password',
                    controller: password,
                    password: true,
                  ),
                FormFieldLine(
                  'New password',
                  controller: newPassword,
                  password: true,
                  validator: (v) =>
                      (v?.length ?? 0) < 8 ? 'Use at least 8 characters' : null,
                ),
                FormFieldLine(
                  'Confirm new password',
                  controller: confirm,
                  password: true,
                  validator: (v) =>
                      v != newPassword.text ? 'Passwords do not match' : null,
                ),
              ],
            ],
          ),
        ),
        if (identity) ...[
          gap,
          const Text(
            'The identity number is used only for this preview and is not stored.',
            style: TextStyle(fontSize: 11, color: AppColors.hint),
          ),
        ],
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Support',
    footer: GradientButton(
      'Report issue',
      onPressed: () => go(c, AppPage.report),
    ),
    subtitle: 'CenWallet demo application',
    children: const [
      DetailRow('Version', '1.0.0'),
      Divider(),
      DetailRow('Support', 'help@cenwallet.example'),
      Divider(),
      DetailRow('Head office', 'Washington D.C'),
      gap,
      Text(
        'This demo works offline. Account data and transactions are stored on this device. No real money or booking services are connected.',
        style: TextStyle(fontSize: 13),
      ),
    ],
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Notifications',
    trailing: TextButton(
      onPressed: () {
        final s = WalletScope.of(c);
        s.unread = 0;
        s.save();
        toast(c, 'All notifications marked as read');
      },
      child: const Text('Read all'),
    ),
    children: [
      for (final item in [
        ('StarBucks reduce 50%', '10 min ago', Icons.local_cafe_outlined),
        (
          'Rolex reduce 10% in Black Friday',
          '3 days left',
          Icons.watch_outlined,
        ),
        ('Today McDonald promote 20%', '2 min ago', Icons.restaurant_outlined),
      ]) ...[
        Surface(
          onTap: () => go(c, AppPage.incentives),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xfff8e6fb),
                child: Icon(item.$3, color: AppColors.purple),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.hint,
                        fontSize: 11,
                      ),
                    ),
                    const Text(
                      'Get in  →',
                      style: TextStyle(color: AppColors.purple, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        gap,
      ],
    ],
  );
}

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});
  @override
  State<QrScreen> createState() => _QrState();
}

class _QrState extends State<QrScreen> {
  bool scan = false;
  final code = TextEditingController();
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'QR code',
    subtitle: scan
        ? 'Enter a recipient wallet code to continue.'
        : 'Please scan code for payment',
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => scan = false),
              child: Text(
                'Code',
                style: TextStyle(
                  color: scan ? AppColors.hint : AppColors.purple,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () => setState(() => scan = true),
              child: Text(
                'Scan',
                style: TextStyle(
                  color: scan ? AppColors.purple : AppColors.hint,
                ),
              ),
            ),
          ),
        ],
      ),
      gap,
      if (!scan) ...[
        Surface(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              QrImageView(
                data: 'cenwallet://pay?wallet=12355572235&currency=USD',
                size: 190,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.ink,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.ink,
                ),
              ),
              gap,
              const Text(
                '123 555 72235',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.hint,
                ),
              ),
            ],
          ),
        ),
        gap,
        TextButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: '12355572235'));
            if (c.mounted) toast(c, 'Wallet code copied');
          },
          child: const Text('Copy wallet code'),
        ),
      ] else ...[
        Surface(
          child: const SizedBox(
            height: 210,
            child: Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 140,
                color: AppColors.purple,
              ),
            ),
          ),
        ),
        gap,
        const Text(
          'Camera preview · manual entry available below',
          style: TextStyle(fontSize: 11, color: AppColors.hint),
        ),
        FormFieldLine('Received wallet code', controller: code),
        gap,
        GradientButton(
          'Continue',
          onPressed: () {
            if (code.text.trim().length < 6) {
              toast(c, 'Enter at least 6 characters');
              return;
            }
            go(
              c,
              AppPage.transferWallet,
              Contact('Wallet recipient', code.text.trim()),
            );
          },
        ),
      ],
    ],
  );
}
