import 'package:flutter_test/flutter_test.dart';
import 'package:share_location_realtime/main.dart';

void main() {
  testWidgets('shows location sharing dashboard', (tester) async {
    await tester.pumpWidget(const ShareLocationApp());

    expect(find.text('Share Location'), findsOneWidget);
    expect(find.text('Friends nearby'), findsOneWidget);
    expect(find.text('Stop sharing'), findsOneWidget);
  });
}
