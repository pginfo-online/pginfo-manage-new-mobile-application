import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/models.dart';

final sessionProvider = FutureProvider<String?>(
  (ref) => ref.watch(storageProvider).read(key: 'accessToken'),
);
final selectedPropertyProvider = NotifierProvider<SelectedProperty, String?>(
  SelectedProperty.new,
);
final roomSearchProvider = NotifierProvider<RoomSearch, String>(RoomSearch.new);
final roomFloorProvider = NotifierProvider<RoomFloor, String?>(RoomFloor.new);

class RoomSearch extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value.trim();
}

class RoomFloor extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? value) => state = value;
}

final selectedOrganizationProvider =
    NotifierProvider<SelectedOrganization, String?>(SelectedOrganization.new);

class SelectedOrganization extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

class SelectedProperty extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

class AuthRepository {
  AuthRepository(this.api);
  final ApiClient api;
  Future<void> login(String email, String password) async {
    final result = await api.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await api.saveTokens(Map<String, dynamic>.from(result['tokens'] as Map));
  }

  Future<void> register(
    String email,
    String password,
    String firstName,
    String organizationName,
  ) async {
    final result = await api.post('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'organizationName': organizationName,
    }) as Map<String, dynamic>;
    await api.saveTokens(Map<String, dynamic>.from(result['tokens'] as Map));
  }

  Future<void> logout() async {
    final refresh = await api.storage.read(key: 'refreshToken');
    if (refresh != null) {
      try {
        await api.post('/auth/logout', {'refreshToken': refresh});
      } catch (_) {}
    }
    await api.clearTokens();
  }
}

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

class PgRepository {
  PgRepository(this.api);
  final ApiClient api;
  Future<List<Map<String, dynamic>>> organizations() async =>
      pageData(await api.get('/organizations'), (e) => e);
  Future<void> switchOrganization(String id) async {
    final result = Map<String, dynamic>.from(
      await api.post('/organizations/$id/switch', {}) as Map,
    );
    await api.storage.write(
      key: 'accessToken',
      value: result['accessToken'] as String,
    );
  }

  Future<List<Property>> properties() async =>
      pageData(await api.get('/properties'), Property.fromJson);
  Future<({List<Property> items, bool hasMore})> dashboardProperties(
    String search,
    int page,
  ) async {
    final result = Map<String, dynamic>.from(
      await api.get(
        '/dashboard/properties',
        query: {'search': search, 'page': page},
      ) as Map,
    );
    return (
      items: (result['items'] as List)
          .map(
            (item) => Property.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      hasMore: result['hasMore'] as bool,
    );
  }

  Future<String> dashboardPropertyName(String id) async {
    final result = Map<String, dynamic>.from(
      await api.get('/dashboard/properties/$id') as Map,
    );
    return result['name'] as String;
  }

  Future<Property> createProperty(Map<String, dynamic> body) async =>
      Property.fromJson(
        Map<String, dynamic>.from(await api.post('/properties', body) as Map),
      );
  Future<List<Room>> rooms(
    String propertyId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String? floor,
  }) async => pageData(
    await api.get(
      '/properties/$propertyId/rooms-page',
      query: {
        'page': page,
        'limit': limit,
        if (search.isNotEmpty) 'search': search,
        'floor': ?floor,
      },
    ),
    Room.fromJson,
  );
  Future<Room> room(String id) async => Room.fromJson(
    Map<String, dynamic>.from(await api.get('/rooms/$id') as Map),
  );
  Future<void> createRoom(String propertyId, Map<String, dynamic> body) async =>
      api.post('/properties/$propertyId/rooms', body);
  Future<List<Resident>> residents({
    String? propertyId,
    String? search,
    int page = 1,
  }) async => pageData(
    await api.get(
      '/residents',
      query: {
        'propertyId': ?propertyId,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
      },
    ),
    Resident.fromJson,
  );
  Future<Resident> resident(String id) async => Resident.fromJson(
    Map<String, dynamic>.from(await api.get('/residents/$id') as Map),
  );
  Future<Map<String, dynamic>> residentDetails(String id) async =>
      Map<String, dynamic>.from(await api.get('/residents/$id') as Map);
  Future<Map<String, dynamic>> expense(String id) async =>
      Map<String, dynamic>.from(await api.get('/expenses/$id') as Map);
  Future<Map<String, dynamic>> lead(String id) async =>
      Map<String, dynamic>.from(await api.get('/leads/$id') as Map);
  Future<Map<String, dynamic>> leadStats(String? propertyId) async =>
      Map<String, dynamic>.from(
        await api.get('/leads/stats', query: {'propertyId': ?propertyId})
            as Map,
      );
  Future<Map<String, dynamic>> staff(String id) async =>
      Map<String, dynamic>.from(await api.get('/staff/$id') as Map);
  Future<Map<String, dynamic>> complaint(String id) async =>
      Map<String, dynamic>.from(await api.get('/complaints/$id') as Map);
  Future<Map<String, dynamic>> receipt(String id) async =>
      Map<String, dynamic>.from(await api.get('/payments/$id/receipt') as Map);
  Future<String> report(String type, {String? propertyId}) async =>
      (await api.get(
        '/reports/$type/csv',
        query: {'propertyId': ?propertyId},
      )).toString();
  Future<List<Map<String, dynamic>>> activity(
    String entityType,
    String entityId,
  ) => list(
    '/dashboard/activity',
    query: {'entityType': entityType, 'entityId': entityId, 'limit': 100},
  );
  Future<void> createResident(Map<String, dynamic> body) async =>
      api.post('/residents', body);
  Future<void> updateResident(String id, Map<String, dynamic> body) async =>
      api.patch('/residents/$id', body);
  Future<Map<String, dynamic>> dashboard(
    String? propertyId, {
    int? month,
    int? year,
    bool fy = false,
  }) async => Map<String, dynamic>.from(
    await api.get(
      '/dashboard/metrics',
      query: {
        'propertyId': ?propertyId,
        'month': ?month,
        'year': ?year,
        if (fy) 'fy': 'true',
      },
    ) as Map,
  );
  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) async => pageData(await api.get(path, query: query), (e) => e);
  Future<dynamic> create(String path, Map<String, dynamic> body) async =>
      api.post(path, body);
  Future<String> upload({
    required String filePath,
    required String filename,
    required String purpose,
  }) async {
    final response = await api.upload(
      '/uploads',
      filePath: filePath,
      filename: filename,
      purpose: purpose,
    );
    return (response as Map<String, dynamic>)['url'] as String;
  }

  Future<void> update(String path, Map<String, dynamic> body) async =>
      api.patch(path, body);
  Future<void> delete(String path) async => api.delete(path);
}

final repositoryProvider = Provider(
  (ref) => PgRepository(ref.watch(apiClientProvider)),
);

/// Presentation-facing command/query coordinator.
///
/// Screens depend on this ViewModel instead of reaching into the data-layer
/// repository. Feature-specific notifiers remain responsible for paginated
/// list state; this coordinator owns one-shot form and detail operations.
class PgOperationsViewModel {
  PgOperationsViewModel(this._repository);

  final PgRepository _repository;

  Future<void> switchOrganization(String id) =>
      _repository.switchOrganization(id);
  Future<Property> createProperty(Map<String, dynamic> body) =>
      _repository.createProperty(body);
  Future<void> createRoom(String propertyId, Map<String, dynamic> body) =>
      _repository.createRoom(propertyId, body);
  Future<Resident> resident(String id) => _repository.resident(id);
  Future<Map<String, dynamic>> residentDetails(String id) =>
      _repository.residentDetails(id);
  Future<Map<String, dynamic>> expense(String id) => _repository.expense(id);
  Future<Map<String, dynamic>> lead(String id) => _repository.lead(id);
  Future<Map<String, dynamic>> staff(String id) => _repository.staff(id);
  Future<Map<String, dynamic>> complaint(String id) =>
      _repository.complaint(id);
  Future<Map<String, dynamic>> receipt(String id) => _repository.receipt(id);
  Future<String> report(String type) => _repository.report(type);
  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) => _repository.list(path, query: query);
  Future<dynamic> create(String path, Map<String, dynamic> body) =>
      _repository.create(path, body);
  Future<void> createResident(Map<String, dynamic> body) =>
      _repository.createResident(body);
  Future<void> updateResident(String id, Map<String, dynamic> body) =>
      _repository.updateResident(id, body);
  Future<String> upload({
    required String filePath,
    required String filename,
    required String purpose,
  }) => _repository.upload(
    filePath: filePath,
    filename: filename,
    purpose: purpose,
  );
  Future<void> update(String path, Map<String, dynamic> body) =>
      _repository.update(path, body);
  Future<void> delete(String path) => _repository.delete(path);
}

final operationsViewModelProvider = Provider(
  (ref) => PgOperationsViewModel(ref.watch(repositoryProvider)),
);
final propertiesProvider = FutureProvider<List<Property>>(
  (ref) => ref.watch(repositoryProvider).properties(),
);
final organizationsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).organizations(),
);
final membersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, orgId) =>
          ref.watch(repositoryProvider).list('/organizations/$orgId/members'),
    );
final roomProvider = FutureProvider.family<Room, String>(
  (ref, id) => ref.watch(repositoryProvider).room(id),
);
final residentProvider = FutureProvider.family<Resident, String>(
  (ref, id) => ref.watch(repositoryProvider).resident(id),
);
final complaintProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(repositoryProvider).complaint(id),
);
final receiptProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(repositoryProvider).receipt(id),
);
final reportProvider = FutureProvider.family<String, String>(
  (ref, type) => ref.watch(repositoryProvider).report(type),
);
final optionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, path) => ref.watch(repositoryProvider).list(path),
    );
final activityProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({String entityType, String entityId})
    >(
      (ref, query) => ref
          .watch(repositoryProvider)
          .activity(query.entityType, query.entityId),
    );
final payoutAccountsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).list('/payouts/accounts'),
);
final leadStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final property = ref.watch(selectedPropertyProvider);
  return ref.watch(repositoryProvider).leadStats(property);
});
final roomsProvider = AsyncNotifierProvider<RoomsViewModel, List<Room>>(
  RoomsViewModel.new,
);

class RoomsViewModel extends AsyncNotifier<List<Room>> {
  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;
  @override
  Future<List<Room>> build() async {
    page = 1;
    final propertyId = ref.watch(selectedPropertyProvider);
    final search = ref.watch(roomSearchProvider);
    final floor = ref.watch(roomFloorProvider);
    if (propertyId == null) return [];
    final items = await ref
        .watch(repositoryProvider)
        .rooms(propertyId, search: search, floor: floor);
    hasMore = items.length == 20;
    return items;
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || state.asData == null) return;
    final propertyId = ref.read(selectedPropertyProvider);
    final search = ref.read(roomSearchProvider);
    final floor = ref.read(roomFloorProvider);
    if (propertyId == null) return;
    loadingMore = true;
    try {
      final next = await ref
          .read(repositoryProvider)
          .rooms(propertyId, page: page + 1, search: search, floor: floor);
      if (propertyId != ref.read(selectedPropertyProvider) ||
          search != ref.read(roomSearchProvider) ||
          floor != ref.read(roomFloorProvider)) {
        return;
      }
      page++;
      hasMore = next.length == 20;
      state = AsyncData([...state.asData!.value, ...next]);
    } finally {
      loadingMore = false;
    }
  }
}

final residentsProvider =
    AsyncNotifierProvider<ResidentsViewModel, List<Resident>>(
      ResidentsViewModel.new,
    );

class PagedQuery {
  const PagedQuery({
    required this.path,
    this.propertyId,
    this.search = '',
    this.status,
    this.filterName,
    this.entityType,
    this.filterValue,
  });
  final String path;
  final String? propertyId;
  final String search;
  final String? status;
  final String? filterName;
  final String? entityType;
  final String? filterValue;

  @override
  bool operator ==(Object other) =>
      other is PagedQuery &&
      other.path == path &&
      other.propertyId == propertyId &&
      other.search == search &&
      other.status == status &&
      other.filterName == filterName &&
      other.entityType == entityType &&
      other.filterValue == filterValue;

  @override
  int get hashCode => Object.hash(
    path,
    propertyId,
    search,
    status,
    filterName,
    filterValue,
    entityType,
  );
}

class PagedListViewModel extends AsyncNotifier<List<Map<String, dynamic>>> {
  PagedListViewModel(this.query);
  final PagedQuery query;
  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;
  Object request = Object();

  Map<String, dynamic> params(int requestedPage) => {
    'page': requestedPage,
    'limit': 20,
    'propertyId': ?query.propertyId,
    if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
    'status': ?query.status,
    'entityType': ?query.entityType,
    if (query.filterName != null && query.filterValue != null)
      query.filterName!: query.filterValue,
  };

  @override
  Future<List<Map<String, dynamic>>> build() async {
    final generation = request = Object();
    loadingMore = false;
    page = 1;
    final items = await ref
        .watch(repositoryProvider)
        .list(query.path, query: params(page));
    if (ref.mounted && identical(request, generation)) {
      hasMore = items.length == 20;
    }
    return items;
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || state.asData == null) return;
    loadingMore = true;
    final generation = request;
    try {
      final next = await ref
          .read(repositoryProvider)
          .list(query.path, query: params(page + 1));
      if (!ref.mounted || !identical(request, generation)) return;
      page++;
      hasMore = next.length == 20;
      state = AsyncData([...state.asData!.value, ...next]);
    } finally {
      if (identical(request, generation)) loadingMore = false;
    }
  }
}

final pagedListProvider = AsyncNotifierProvider.autoDispose
    .family<PagedListViewModel, List<Map<String, dynamic>>, PagedQuery>(
      PagedListViewModel.new,
    );

class ResidentsViewModel extends AsyncNotifier<List<Resident>> {
  int page = 1;
  bool hasMore = true;
  bool loadingMore = false;
  @override
  Future<List<Resident>> build() async {
    page = 1;
    final property = ref.watch(selectedPropertyProvider);
    final first = await ref
        .watch(repositoryProvider)
        .residents(propertyId: property, page: 1);
    hasMore = first.length == 20;
    return first;
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore || state.asData == null) return;
    loadingMore = true;
    try {
      final property = ref.read(selectedPropertyProvider);
      final next = await ref
          .read(repositoryProvider)
          .residents(propertyId: property, page: page + 1);
      if (property != ref.read(selectedPropertyProvider)) return;
      page++;
      hasMore = next.length == 20;
      state = AsyncData([...state.asData!.value, ...next]);
    } finally {
      loadingMore = false;
    }
  }
}

final dashboardProvider = FutureProvider<Map<String, dynamic>>(
  (ref) => ref
      .watch(repositoryProvider)
      .dashboard(ref.watch(selectedPropertyProvider)),
);
final dashboardPropertiesProvider =
    FutureProvider.family<
      ({List<Property> items, bool hasMore}),
      ({String search, int page})
    >(
      (ref, query) => ref
          .watch(repositoryProvider)
          .dashboardProperties(query.search, query.page),
    );
final dashboardPropertyNameProvider = FutureProvider.family<String, String>(
  (ref, id) => ref.watch(repositoryProvider).dashboardPropertyName(id),
);
final dashboardPeriodProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String? propertyId, int month, int year, bool fy})
    >(
      (ref, period) => ref
          .watch(repositoryProvider)
          .dashboard(
            period.propertyId,
            month: period.month,
            year: period.year,
            fy: period.fy,
          ),
    );
final globalSearchProvider = FutureProvider.autoDispose
    .family<Map<String, List<Map<String, dynamic>>>, String>((
      ref,
      query,
    ) async {
      final repo = ref.watch(repositoryProvider);
      final property = ref.watch(selectedPropertyProvider);
      final values = await Future.wait([
        repo
            .list(
              '/residents',
              query: {'search': query, 'propertyId': ?property},
            )
            .catchError((_) => <Map<String, dynamic>>[]),
        repo
            .list('/leads', query: {'search': query, 'propertyId': ?property})
            .catchError((_) => <Map<String, dynamic>>[]),
        repo
            .list(
              '/complaints',
              query: {'search': query, 'propertyId': ?property},
            )
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final rooms = property == null ? <Room>[] : await repo.rooms(property);
      return {
        'Tenants': values[0],
        'Leads': values[1],
        'Complaints': values[2],
        'Rooms': rooms
            .where(
              (r) => r.roomNumber.toLowerCase().contains(query.toLowerCase()),
            )
            .map((r) => {'id': r.id, 'name': 'Room ${r.roomNumber}'})
            .toList(),
      };
    });
final tenantLedgerProvider = FutureProvider.autoDispose
    .family<Map<String, List<Map<String, dynamic>>>, String>((
      ref,
      residentId,
    ) async {
      final repo = ref.watch(repositoryProvider);
      Future<List<Map<String, dynamic>>> history(String path) async {
        final all = <Map<String, dynamic>>[];
        for (var page = 1; ; page++) {
          final items = await repo.list(
            path,
            query: {'residentId': residentId, 'page': page, 'limit': 100},
          );
          if (!ref.mounted) return all;
          all.addAll(items);
          if (items.length < 100) return all;
        }
      }

      final result = await Future.wait([
        history('/billing/records'),
        history('/payments'),
      ]);
      return {'dues': result[0], 'payments': result[1]};
    });
