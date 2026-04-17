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
      'price': 'IDR 150,000 / Hour',
      'status': 'Active',
      'lat': -6.2297,
      'lng': 106.8295,
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
      'price': 'IDR 80,000 / Hour',
      'status': 'Active',
      'lat': -6.1601,
      'lng': 106.9038,
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
      'price': 'IDR 200,000 / Hour',
      'status': 'Maintenance',
      'lat': -6.2183,
      'lng': 106.8020,
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
      'price': 'IDR 300,000 / Hour',
      'status': 'Active',
      'lat': -6.2446,
      'lng': 106.6961,
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
      'type': 'Tennis',
      'address': 'Jl. PLN Cigereleng No.19, Ciseureuh, Kota Bandung',
      'hours': '06:00 - 22:00',
      'price': 'IDR 125,000 ~ IDR 175,000',
      'status': 'Active',
      'lat': -6.9389,
      'lng': 107.6167,
      'courts': [
        {
          'name': 'BEC Tennis Court Lap.A',
          'size': 'P 23 X L 10',
          'type': 'Tennis',
        },
        {
          'name': 'BEC Tennis Court Lap.B',
          'size': 'P 23 X L 10',
          'type': 'Tennis',
        }
      ]
    },
    {
      'name': 'ASATU ARENA CIKINI',
      'location': 'Jakarta Pusat',
      'type': 'Mini Soccer',
      'price': 'IDR 2,200,000 ~ IDR 2,200,000',
      'status': 'Active',
      'lat': -6.1887,
      'lng': 106.8378,
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
