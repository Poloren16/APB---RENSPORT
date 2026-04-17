class GlobalVenueData {
  static List<Map<String, dynamic>> favorites = [];

  static void toggleFavorite(Map<String, dynamic> venue) {
    final exists = favorites.any((v) => v['name'] == venue['name']);
    if (exists) {
      favorites.removeWhere((v) => v['name'] == venue['name']);
    } else {
      favorites.add(venue);
    }
  }

  static bool isFavorite(String venueName) {
    return favorites.any((v) => v['name'] == venueName);
  }

  static List<Map<String, dynamic>> venues = [
    {
      'name': 'Rensius Arena',
      'location': 'Jakarta Selatan',
      'type': 'Futsal',
      'price': 'Rp 150.000 / Jam',
      'status': 'Active',
      'courts': [
        {
          'name': 'Lapangan Futsal A',
          'size': 'P 25 X L 15',
          'schedules': [
            {'time': '14:00', 'isAvailable': true},
            {'time': '16:00', 'isAvailable': false},
            {'time': '18:00', 'isAvailable': true},
          ]
        }
      ]
    },
    {
      'name': 'Gading Sport Center',
      'location': 'Kelapa Gading',
      'type': 'Badminton',
      'price': 'Rp 80.000 / Jam',
      'status': 'Active',
      'courts': [
        {
          'name': 'Lapangan Badminton 1',
          'size': 'P 13 X L 6',
          'schedules': [
            {'time': '10:00', 'isAvailable': true},
            {'time': '12:00', 'isAvailable': true},
          ]
        }
      ]
    },
    {
      'name': 'Senayan Tennis Court',
      'location': 'Senayan',
      'type': 'Tennis',
      'price': 'Rp 200.000 / Jam',
      'status': 'Maintenance',
      'courts': [
        {
          'name': 'Lapangan Tenis Outdoor',
          'size': 'P 23 X L 10',
          'schedules': [
            {'time': '08:00', 'isAvailable': false},
            {'time': '10:00', 'isAvailable': false},
          ]
        }
      ]
    },
    {
      'name': 'Bintaro Mini Soccer',
      'location': 'Bintaro',
      'type': 'Mini Soccer',
      'price': 'Rp 300.000 / Jam',
      'status': 'Active',
      'courts': [
        {
          'name': 'Mini Soccer Field',
          'size': 'P 40 X L 32',
          'schedules': [
            {'time': '16:00', 'isAvailable': true},
            {'time': '19:00', 'isAvailable': false},
            {'time': '21:00', 'isAvailable': true},
          ]
        }
      ]
    },
    {
      'name': 'Bandung Elektrik Cigereleng Tennis Court',
      'location': 'Bandung',
      'type': 'Tenis',
      'address': 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
      'hours': '06:00 - 22:00',
      'price': 'Rp 125.000 ~ Rp 175.000',
      'status': 'Active',
      'courts': [
        {
          'name': 'BEC Tennis Court Lap.A',
          'size': 'P 23 X L 10',
          'type': 'Tenis',
        },
        {
          'name': 'BEC Tennis Court Lap.B',
          'size': 'P 23 X L 10',
          'type': 'Tenis',
        }
      ]
    },
    {
      'name': 'ASATU ARENA CIKINI',
      'location': 'Jakarta Pusat',
      'type': 'Mini Soccer',
      'price': 'Rp 2.200.000 ~ Rp 2.200.000',
      'status': 'Active',
      'courts': [
        {
          'name': 'ASATU Mini Soccer',
          'size': 'P 40 X L 32',
          'type': 'Mini Soccer',
        }
      ]
    }
  ];
}
