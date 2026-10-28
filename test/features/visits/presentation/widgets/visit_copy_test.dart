import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/visits/presentation/widgets/visit_mode_selector.dart';
import 'package:app/features/visits/presentation/widgets/visit_sticky_footer.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );

  testWidgets('the mode selector says what each choice means', (tester) async {
    await tester.pumpWidget(
      host(
        VisitModeSelector(
          isSaleSelected: false,
          onSelectSale: () {},
          onSelectVisit: () {},
        ),
      ),
    );

    expect(find.text('Registrar venta'), findsOneWidget);
    expect(find.text('Cobrás productos ahora'), findsOneWidget);
    expect(find.text('Solo visita'), findsOneWidget);
    expect(find.text('Sin venta: entrega, gestión o ausente'), findsOneWidget);
  });

  Widget footer({
    bool isDone = false,
    bool hasSales = false,
    bool isSaleSelected = false,
    bool hasSoloResult = false,
  }) => host(
    VisitStickyFooter(
      isDone: isDone,
      hasSales: hasSales,
      isSaleSelected: isSaleSelected,
      hasSoloResult: hasSoloResult,
      onBackToRoute: () {},
      onPrimaryPressed: () {},
    ),
  );

  testWidgets('the footer names the next step in plain words', (tester) async {
    await tester.pumpWidget(footer(isSaleSelected: true));
    expect(find.text('Cargar la venta'), findsOneWidget);

    await tester.pumpWidget(footer(hasSoloResult: true));
    expect(find.text('Cerrar visita'), findsOneWidget);

    await tester.pumpWidget(footer());
    expect(find.text('Elegí qué pasó para cerrar la visita'), findsOneWidget);

    await tester.pumpWidget(footer(isDone: true));
    expect(find.text('Volver a la ruta'), findsOneWidget);
  });
}
