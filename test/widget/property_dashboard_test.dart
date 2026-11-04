import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/property/presentation/property_dashboard_screen.dart';
import 'package:mobile/shared/models/models.dart';

class _SelectedProperty extends SelectedProperty {
  @override
  String? build() => 'property-1';
}

class _PropertyRepository extends PgRepository {
  _PropertyRepository() : super(ApiClient(const FlutterSecureStorage()));
  final sample = const Room(
    id: 'room-1',
    roomNumber: '101',
    sharingType: 'DOUBLE',
    rentAmount: 1200000,
    status: 'PARTIALLY_OCCUPIED',
    beds: [Bed(id: 'bed-1', bedNumber: 'A', status: 'AVAILABLE')],
  );
  @override
  Future<List<Property>> properties() async => [
    const Property(
      id: 'property-1',
      name: 'Vanaliika',
      type: 'PG',
      roomCount: 1,
    ),
  ];
  @override
  Future<List<Room>> rooms(
    String propertyId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String? floor,
  }) async => [sample];
  @override
  Future<Room> room(String id) async => sample;
}

void main() {
  testWidgets('property dashboard renders room data and bed details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWith((ref) => _PropertyRepository()),
          selectedPropertyProvider.overrideWith(_SelectedProperty.new),
        ],
        child: const MaterialApp(home: PropertyDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vanaliika'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);
    expect(find.text('Total Rooms'), findsOneWidget);
    await tester.drag(find.text('101'), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit Room'), findsOneWidget);
    await tester.drag(find.text('101'), const Offset(240, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('101'));
    await tester.pumpAndSettle();
    expect(find.text('Occupancy Status'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });
}
