import 'package:aviso_vital_2/app/app.dart';
import 'package:aviso_vital_2/shared/widgets/aviso_vital_logo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows role selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AvisoVitalApp());

    expect(find.byType(AvisoVitalLogo), findsOneWidget);
    expect(find.text('Soy usuario'), findsOneWidget);
    expect(find.text('Soy administrador'), findsOneWidget);
  });
}
