import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/tenants/presentation/add_tenant_screen.dart';
import 'package:mobile/shared/models/models.dart';

class _SelectedProperty extends SelectedProperty {
  @override
  String? build() => 'property-1';
}

class _TenantRepository extends PgRepository {
  _TenantRepository() : super(ApiClient(const FlutterSecureStorage()));
  @override
  Future<List<Property>> properties() async => [
    const Property(id: 'property-1', name: 'Vanaliika', type: 'PG'),
  ];
  @override
  Future<List<Room>> rooms(
    String propertyId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String? floor,
  }) async => [
    const Room(
      id: 'room-1',
      roomNumber: '101',
      sharingType: 'DOUBLE',
      rentAmount: 1200000,
      status: 'AVAILABLE',
      beds: [Bed(id: 'bed-1', bedNumber: 'A', status: 'AVAILABLE')],
    ),
  ];
}

void main() {
  testWidgets(
    'tenant form selects an available bed and shows payment details',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWith((ref) => _TenantRepository()),
            selectedPropertyProvider.overrideWith(_SelectedProperty.new),
          ],
          child: const MaterialApp(home: AddTenantScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vanaliika'), findsOneWidget);
      await tester.ensureVisible(find.text('Room / Bed'));
      await tester.tap(find.text('Room / Bed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Room 101'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bed A'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bed A'), findsOneWidget);
      await tester.tap(find.text('Payment\nDetails'));
      await tester.pumpAndSettle();
      expect(find.text('Opening Balance'), findsOneWidget);
    },
  );
}
