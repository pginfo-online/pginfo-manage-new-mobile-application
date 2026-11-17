import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/design_system/theme.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/property/presentation/property_dashboard_screen.dart';
import 'package:mobile/features/property/presentation/room_form_screen.dart';
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
    dailyStayMinPaise: 50000,
    dailyStayMaxPaise: 80000,
    areaSqft: 250,
    amenities: ['AC', 'WiFi', 'Washroom'],
    remarks: 'Corner room',
    beds: [Bed(id: 'bed-1', bedNumber: 'A', status: 'AVAILABLE')],
  );

  @override
  Future<List<Property>> properties() async => [
    const Property(
      id: 'property-1',
      name: 'Vanalilka',
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

  @override
  Future<Room> createRoom(String propertyId, Map<String, dynamic> body) async =>
      sample.copyWith(
        id: 'room-new',
        roomNumber: body['roomNumber'] as String,
      );

  @override
  Future<void> update(String path, Map<String, dynamic> body) async {}

  @override
  Future<void> delete(String path) async {}
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
        child: MaterialApp(
          theme: PgTheme.build(Brightness.light),
          darkTheme: PgTheme.build(Brightness.dark),
          home: const PropertyDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vanalilka'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);
    expect(find.text('Total Rooms'), findsOneWidget);
    await tester.drag(find.text('101'), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit Room'), findsOneWidget);
    expect(find.text('Disable for Rent'), findsOneWidget);
    expect(find.text('Unpublish'), findsOneWidget);
    expect(find.text('Delete Room'), findsOneWidget);
    await tester.drag(find.text('101'), const Offset(240, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('101'));
    await tester.pumpAndSettle();
    expect(find.text('Occupancy Status'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('Add Room screen matches reference UI fields exactly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWith((ref) => _PropertyRepository()),
          selectedPropertyProvider.overrideWith(_SelectedProperty.new),
        ],
        child: MaterialApp(
          theme: PgTheme.build(Brightness.light),
          darkTheme: PgTheme.build(Brightness.dark),
          home: const RedesignedRoomFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Property Subtitle
    expect(find.text('Add Room'), findsWidgets);
    expect(find.text('Vanalilka'), findsOneWidget);

    // Verify Accordion Section 1
    expect(find.text('Room Renting Details'), findsOneWidget);

    // Verify Row 1: Room Name & Unit Type
    expect(find.text('Room Name'), findsOneWidget);
    expect(find.text('Unit Type'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);

    // Verify Row 2: Floor
    expect(find.text('Floor'), findsOneWidget);
    expect(find.text('Ground Floor'), findsOneWidget);

    // Verify Row 3: Sharing Type & Rent
    expect(find.text('Sharing Type'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);

    // Verify Daily Stay Charges Section
    expect(find.text('Daily Stay Charges?'), findsOneWidget);
    expect(find.text('Minimum'), findsOneWidget);
    expect(find.text('Maximum'), findsOneWidget);

    // Verify Area & Availability & Remarks
    expect(find.text('Area(Sqft)'), findsOneWidget);
    expect(find.text('Is this Room available to Rent'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Remarks'), findsOneWidget);

    // Verify Accordion Section 2 & Chips
    expect(find.text('Room Facilities'), findsOneWidget);
    expect(find.text('AC'), findsOneWidget);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
    expect(find.text('Washroom'), findsOneWidget);
    expect(find.text('Balcony'), findsOneWidget);
    expect(find.text('Fridge'), findsOneWidget);
    expect(find.text('Almirah'), findsOneWidget);
    expect(find.text('Chair'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Microwave'), findsOneWidget);
    expect(find.text('Geyser'), findsOneWidget);
    expect(find.text('Laundry'), findsOneWidget);

    // Verify Bottom Action Button
    expect(find.widgetWithText(FilledButton, 'Add Room'), findsOneWidget);
  });

  testWidgets('Add Room screen supports dark mode flawlessly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWith((ref) => _PropertyRepository()),
          selectedPropertyProvider.overrideWith(_SelectedProperty.new),
        ],
        child: MaterialApp(
          theme: PgTheme.build(Brightness.dark),
          home: const RedesignedRoomFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Room'), findsWidgets);
    expect(find.text('Room Renting Details'), findsOneWidget);
    expect(find.text('Room Facilities'), findsOneWidget);
  });
}
