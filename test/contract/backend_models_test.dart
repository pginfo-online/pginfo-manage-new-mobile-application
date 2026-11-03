import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/shared/models/models.dart';

void main() {
  test('room contract maps inventory beds and paise', () {
    final room = Room.fromJson({
      'id': 'room-id',
      'roomNumber': '101',
      'sharingType': 'DOUBLE',
      'rentAmount': 1200000,
      'status': 'PARTIALLY_OCCUPIED',
      'beds': [
        {'id': 'bed-id', 'bedNumber': 'A', 'status': 'OCCUPIED'},
      ],
      'images': <String>[],
    });
    expect(room.beds.single.status, 'OCCUPIED');
    expect(rupees(room.rentAmount), '₹12000');
  });
  test('paginated resident response maps backend data wrapper', () {
    final residents = pageData({
      'data': [
        {
          'id': 'resident-id',
          'firstName': 'Asha',
          'mobile': '9876543210',
          'monthlyRent': 500000,
          'dues': 10000,
        },
      ],
      'meta': {'total': 1},
    }, Resident.fromJson);
    expect(residents.single.dues, 10000);
  });
}
