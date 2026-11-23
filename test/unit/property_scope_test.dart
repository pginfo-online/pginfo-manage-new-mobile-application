import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/di/providers.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/shared/models/models.dart';

class FakeRepository extends PgRepository {
  FakeRepository() : super(ApiClient(const FlutterSecureStorage()));
  @override
  Future<List<Room>> rooms(
    String propertyId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String? floor,
  }) async => [
    Room(
      id: propertyId,
      roomNumber: propertyId,
      sharingType: 'SINGLE',
      rentAmount: 10000,
      status: 'AVAILABLE',
    ),
  ];
}

class FakePagedRepository extends FakeRepository {
  @override
  Future<List<Resident>> residents({
    String? propertyId,
    String? search,
    int page = 1,
  }) async {
    if (propertyId == 'property-a' && page == 1) {
      return List.generate(
        20,
        (index) => Resident(
          id: 'a-$index',
          firstName: 'A',
          mobile: '9876543210',
          monthlyRent: 10000,
        ),
      );
    }
    if (propertyId == 'property-a' && page == 2) {
      return [
        const Resident(
          id: 'a-20',
          firstName: 'A',
          mobile: '9876543210',
          monthlyRent: 10000,
        ),
      ];
    }
    return [
      const Resident(
        id: 'b-1',
        firstName: 'B',
        mobile: '9876543210',
        monthlyRent: 10000,
      ),
    ];
  }
}

class FakeGenericPagedRepository extends FakeRepository {
  final requests = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requests.add({...?query});
    final page = query?['page'] as int? ?? 1;
    if (page == 1) {
      return List.generate(20, (index) => {'id': 'item-$index'});
    }
    return [
      {'id': 'item-20'},
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'accessToken': tokenFor('org-a'),
    }),
  );

  test(
    'restores the selected property scoped to the signed-in organization',
    () async {
      var container = ProviderContainer();
      await container.read(sessionProvider.future);
      await container
          .read(selectedPropertyProvider.notifier)
          .select('property-a');
      container.dispose();

      container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(sessionProvider.future);
      expect(container.read(selectedPropertyProvider), 'property-a');

      await const FlutterSecureStorage().write(
        key: 'accessToken',
        value: tokenFor('org-b'),
      );
      container.invalidate(sessionProvider);
      await container.read(sessionProvider.future);
      expect(container.read(selectedPropertyProvider), isNull);
    },
  );

  test('changing property refetches scoped room data', () async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
    );
    addTearDown(container.dispose);
    await container.read(sessionProvider.future);
    await container
        .read(selectedPropertyProvider.notifier)
        .select('property-a');
    expect(
      (await container.read(roomsProvider.future)).single.id,
      'property-a',
    );
    await container
        .read(selectedPropertyProvider.notifier)
        .select('property-b');
    expect(
      (await container.read(roomsProvider.future)).single.id,
      'property-b',
    );
  });
  test('resident pagination is cleared by property switch', () async {
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(FakePagedRepository())],
    );
    addTearDown(container.dispose);
    await container.read(sessionProvider.future);
    await container
        .read(selectedPropertyProvider.notifier)
        .select('property-a');
    expect((await container.read(residentsProvider.future)).length, 20);
    await container.read(residentsProvider.notifier).loadMore();
    expect(container.read(residentsProvider).asData!.value.length, 21);
    await container
        .read(selectedPropertyProvider.notifier)
        .select('property-b');
    expect((await container.read(residentsProvider.future)).single.id, 'b-1');
  });
  test(
    'generic paged ViewModel preserves server search and loads next page',
    () async {
      final repository = FakeGenericPagedRepository();
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      const query = PagedQuery(
        path: '/payments',
        propertyId: 'property-a',
        search: 'Aarav',
        filterName: 'mode',
        filterValue: 'UPI',
      );
      final subscription = container.listen(
        pagedListProvider(query),
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(
        (await container.read(pagedListProvider(query).future)).length,
        20,
      );
      await container.read(pagedListProvider(query).notifier).loadMore();
      expect(container.read(pagedListProvider(query)).value!.length, 21);
      expect(repository.requests, hasLength(2));
      expect(repository.requests.first, containsPair('page', 1));
      expect(
        repository.requests.first,
        containsPair('propertyId', 'property-a'),
      );
      expect(repository.requests.first, containsPair('search', 'Aarav'));
      expect(repository.requests.first, containsPair('mode', 'UPI'));
      expect(repository.requests.last, containsPair('page', 2));
    },
  );
}

String tokenFor(String orgId) {
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'sub': 'user-a', 'orgId': orgId})),
  );
  return 'header.$payload.signature';
}
