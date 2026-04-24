import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatDateTime(BuildContext context, DateTime dt) {
  final locale = Localizations.localeOf(context).toString();
  return '${DateFormat.yMd(locale).format(dt)} at ${DateFormat.jm(locale).format(dt)}';
}