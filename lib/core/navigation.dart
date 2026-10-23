import 'package:flutter/material.dart';

enum AppPage {
  welcome,
  onboarding,
  login,
  signup,
  forgot,
  verify,
  home,
  incentives,
  payment,
  friends,
  market,
  recharge,
  transfer,
  transferWallet,
  transferBank,
  exchange,
  review,
  success,
  history,
  transaction,
  services,
  bills,
  booking,
  bookingDetails,
  bookingPassenger,
  bookingReceipt,
  linkAccount,
  linkBank,
  linkCard,
  createWallet,
  manage,
  profile,
  settings,
  account,
  password,
  support,
  notifications,
  qr,
  addContact,
  identity,
  contactDetail,
  filter,
  receipt,
  report,
  reportSuccess,
  fingerprints,
  bankLinks,
  flights,
}

final navigatorKey = GlobalKey<NavigatorState>();
Future<T?> go<T>(
  BuildContext context,
  AppPage page, [
  Object? arguments,
]) async =>
    (await Navigator.of(
          context,
        ).pushNamed<dynamic>('/${page.name}', arguments: arguments))
        as T?;
void goHome(BuildContext context) =>
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
