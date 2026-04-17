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
      ],
      'services': [
        {'id': 'f1', 'name': 'Sepatu Futsal', 'price': 20000, 'stock': 12, 'unit': 'Pasang'},
        {'id': 'f2', 'name': 'Rompi (1 Set)', 'price': 15000, 'stock': 5, 'unit': 'Set'},
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
      ],
      'services': [
        {'id': 'b1', 'name': 'Raket Badminton', 'price': 15000, 'stock': 20, 'unit': 'Pcs'},
        {'id': 'b2', 'name': 'Sepatu Badminton', 'price': 20000, 'stock': 8, 'unit': 'Pasang'},
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
      ],
      'services': [
        {'id': 't1', 'name': 'Raket Tennis Pro', 'price': 35000, 'stock': 10, 'unit': 'Pcs'},
        {'id': 't2', 'name': 'Bola Tennis (3 pcs)', 'price': 10000, 'stock': 15, 'unit': 'Slop'},
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
      ],
      'services': [
        {'id': 'ms1', 'name': 'Sepatu Mini Soccer', 'price': 25000, 'stock': 10, 'unit': 'Pasang'},
        {'id': 'ms2', 'name': 'Kaos Kaki', 'price': 10000, 'stock': 20, 'unit': 'Pasang'},
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
      ],
      'services': [
        {'id': 'bec1', 'name': 'Raket Tenis BEC', 'price': 30000, 'stock': 6, 'unit': 'Pcs'},
        {'id': 'bec2', 'name': 'Sepatu Tenis BEC', 'price': 25000, 'stock': 4, 'unit': 'Pasang'},
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
      ],
      'services': [
        {'id': 'as1', 'name': 'Sepatu Soccer Pro', 'price': 50000, 'stock': 5, 'unit': 'Pasang'},
      ]
    }
  ];
}
