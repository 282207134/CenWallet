import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/wallet_store.dart';

void toast(BuildContext c, String message) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
String errorText(Object e) => e is StateError
    ? e.message.toString()
    : e is ArgumentError
    ? e.message.toString()
    : 'Could not save. Please try again.';
const gap = SizedBox(height: 24);
Widget heading(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted),
  ),
);

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.trailing,
    this.back = true,
  });
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer, trailing;
  final bool back;
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: PageBody(
        title: title,
        subtitle: subtitle,
        footer: footer,
        trailing: trailing,
        back: back,
        children: children,
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.trailing,
    this.back = true,
  });
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer, trailing;
  final bool back;
  @override
  Widget build(BuildContext c) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 16, 4),
            child: Row(
              children: [
                if (back)
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.canPop(c)) {
                        Navigator.pop(c);
                      } else {
                        Navigator.of(c).pushReplacementNamed('/home');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.muted,
                      size: 23,
                    ),
                  )
                else
                  const SizedBox(height: 48),
                const Spacer(),
                ?trailing,
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('page-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!),
                    gap,
                  ] else if (title.isNotEmpty)
                    gap,
                  ...children,
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: footer,
            ),
        ],
      ),
    ),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.busy = false,
    this.coral = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy, coral;
  @override
  Widget build(BuildContext c) => Container(
    height: 60,
    decoration: BoxDecoration(
      gradient: coral
          ? const LinearGradient(colors: [Color(0xfff17e96), Color(0xfff36b88)])
          : AppColors.gradient,
      borderRadius: BorderRadius.circular(8),
    ),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
    ),
  );
}

class Art extends StatelessWidget {
  const Art(
    this.name, {
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });
  final String name;
  final double? height, width;
  final BoxFit fit;
  @override
  Widget build(BuildContext c) => name.endsWith('.svg')
      ? SvgPicture.asset(
          'assets/images/$name',
          height: height,
          width: width,
          fit: fit,
        )
      : Image.asset(
          'assets/images/$name',
          height: height,
          width: width,
          fit: fit,
        );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  @override
  Widget build(BuildContext c) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      boxShadow: AppColors.shadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class FormFieldLine extends StatefulWidget {
  const FormFieldLine(
    this.label, {
    super.key,
    required this.controller,
    this.password = false,
    this.numeric = false,
    this.validator,
    this.icon,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool password, numeric;
  final String? Function(String?)? validator;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  @override
  State<FormFieldLine> createState() => _FormFieldLineState();
}

class _FormFieldLineState extends State<FormFieldLine> {
  bool hidden = true;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: widget.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      obscureText: widget.password && hidden,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: widget.onChanged,
      validator:
          widget.validator ??
          (v) => v == null || v.trim().isEmpty
              ? 'Enter ${widget.label.toLowerCase()}'
              : null,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    ),
  );
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile(
    this.label,
    this.value, {
    super.key,
    required this.onTap,
    this.icon,
  });
  final String label, value;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading(label),
        Surface(
          onTap: onTap,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.purple),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.hint),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<T?> choose<T>(
  BuildContext c,
  String title,
  List<T> values,
  String Function(T) label,
) => showModalBottomSheet<T>(
  context: c,
  backgroundColor: Colors.white,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (c) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .7),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: Theme.of(c).textTheme.titleLarge),
            ),
            ...values.map(
              (v) => ListTile(
                title: Text(label(v)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(c, v),
              ),
            ),
            gap,
          ],
        ),
      ),
    ),
  ),
);

class WalletChoice extends StatelessWidget {
  const WalletChoice({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Choose wallet',
    this.exclude,
  });
  final Currency value;
  final Currency? exclude;
  final ValueChanged<Currency> onChanged;
  final String label;
  @override
  Widget build(BuildContext c) => ChoiceTile(
    label,
    '${value.code} wallet',
    icon: Icons.account_balance_wallet_outlined,
    onTap: () async {
      final result = await choose(
        c,
        label,
        WalletScope.of(c).wallets.where((w) => w.currency != exclude).toList(),
        (w) => '${w.name} · ${w.currency.format(w.balance)}',
      );
      if (result != null) onChanged(result.currency);
    },
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key, this.emphasis = false});
  final String label, value;
  final bool emphasis;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
              color: emphasis ? AppColors.purple : AppColors.ink,
              fontSize: emphasis ? 22 : 14,
            ),
          ),
        ),
      ],
    ),
  );
}

class WalletCard extends StatelessWidget {
  const WalletCard(this.wallet, {super.key, this.onTap});
  final Wallet wallet;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Semantics(
    label: '${wallet.name}, balance ${wallet.currency.format(wallet.balance)}',
    button: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: wallet.currency == Currency.usd
              ? AppColors.gradient
              : const LinearGradient(
                  colors: [Color(0xfff48a92), Color(0xfff1b59f)],
                ),
          borderRadius: BorderRadius.circular(9),
          boxShadow: AppColors.shadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -45,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14ffffff),
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -70,
              child: Container(
                width: 130,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14ffffff),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    wallet.currency.format(wallet.balance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Wallet no.',
                    style: TextStyle(
                      color: Color(0xaaffffff),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '1234   5678   9012   3273',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.text, {
    super.key,
    this.icon = Icons.receipt_long_outlined,
  });
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        Icon(icon, size: 54, color: AppColors.hint),
        gap,
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}
