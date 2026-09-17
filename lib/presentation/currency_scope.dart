import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';

class CurrencyScope extends InheritedNotifier<ValueNotifier<Currency>> {
  const CurrencyScope({
    super.key,
    required ValueNotifier<Currency> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static Currency of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CurrencyScope>();
    return scope!.notifier!.value;
  }

  static void update(BuildContext context, Currency currency) {
    final scope = context.findAncestorWidgetOfExactType<CurrencyScope>();
    scope?.notifier?.value = currency;
  }
}
