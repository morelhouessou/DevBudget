import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devbudget/logic/security.dart';
import 'package:devbudget/presentation/screens/onboarding_screen.dart';
import 'package:devbudget/presentation/screens/pin_screens.dart';

void main() {
  testWidgets('onboarding : 4 pages, autorisations avant la sécurité',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onFinished: () => finished++),
    ));

    expect(find.textContaining('magnifiquement sous contrôle'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('budgets qui vous préviennent'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    // Page 3 : autorisations, exactement ce que l'application utilise.
    expect(find.text('Vos autorisations'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('Empreinte digitale'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    // Dernière page : lancement de la sécurité.
    expect(find.text('Protégez vos finances.'), findsOneWidget);
    expect(find.text('Créer mon code PIN'), findsOneWidget);
    expect(find.text('Suivant'), findsNothing);

    await tester.tap(find.text('Plus tard'));
    expect(finished, 1);
  });

  testWidgets('onboarding : « Passer » saute à la page sécurité',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onFinished: () {}),
    ));
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('Protégez vos finances.'), findsOneWidget);
  });

  testWidgets('pavé PIN : renvoie le code complet puis affiche l\'erreur',
      (tester) async {
    String? received;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PinPad(
            title: 'Code',
            onCompleted: (pin) async {
              received = pin;
              return 'Code incorrect';
            },
          ),
        ),
      ),
    ));

    for (final d in '123456'.split('')) {
      await tester.tap(find.text(d));
    }
    await tester.pump();

    expect(Security.pinLength, 6);
    expect(received, '123456');
    expect(find.text('Code incorrect'), findsOneWidget);
  });

  testWidgets('pavé PIN : effacer retire le dernier chiffre', (tester) async {
    String? received;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PinPad(
            title: 'Code',
            onCompleted: (pin) async {
              received = pin;
              return null;
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.text('9'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    for (final d in '123456'.split('')) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(received, '123456');
  });
}
