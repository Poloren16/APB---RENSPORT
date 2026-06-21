# Dokumentasi API RENSIUS

Dokumen ini menjelaskan kontrak API yang digunakan aplikasi RENSIUS. Backend utama memakai Supabase sebagai Auth, PostgreSQL via PostgREST, dan Storage. Pembayaran memakai Midtrans Sandbox.

## Ringkasan

| Layanan | Base URL | Keterangan |
| --- | --- | --- |
| Supabase Auth | `{{SUPABASE_URL}}/auth/v1` | Register, login, reset password, update password |
| Supabase REST | `{{SUPABASE_URL}}/rest/v1` | CRUD tabel PostgreSQL |
| Supabase Storage | `{{SUPABASE_URL}}/storage/v1` | Upload dan akses file bucket |
| Midtrans Snap | `https://app.sandbox.midtrans.com/snap/v1` | Membuat transaksi pembayaran |
| Midtrans Status | `https://api.sandbox.midtrans.com/v2` | Cek status transaksi |

## Environment

Buat file `.env` di root project.

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here

MIDTRANS_MERCHANT_ID=your-midtrans-merchant-id-here
MIDTRANS_CLIENT_KEY=your-midtrans-client-key-here
MIDTRANS_SERVER_KEY=your-midtrans-server-key-here
```

## Header Supabase

Untuk request REST Supabase, gunakan header berikut.

```http
apikey: {{SUPABASE_ANON_KEY}}
Authorization: Bearer {{SUPABASE_ANON_KEY_OR_ACCESS_TOKEN}}
Content-Type: application/json
Prefer: return=representation
```

Catatan:

- `SUPABASE_ANON_KEY` bisa digunakan untuk data publik sesuai RLS policy.
- Setelah login, gunakan `access_token` user pada header `Authorization` agar policy berbasis `auth.uid()` berjalan.
- Aplikasi Flutter memakai `supabase_flutter`, sehingga header ini dibentuk otomatis oleh SDK.

## Autentikasi

### Register User

Mendaftarkan akun baru ke Supabase Auth, lalu aplikasi menyimpan profil ke tabel `users`.

```http
POST {{SUPABASE_URL}}/auth/v1/signup
```

Body:

```json
{
  "email": "user@example.com",
  "password": "password123",
  "data": {
    "username": "budi",
    "applicant_name": "Budi Santoso",
    "role": "End User"
  }
}
```

Setelah Auth berhasil, lakukan upsert profil:

```http
POST {{SUPABASE_URL}}/rest/v1/users
```

Body:

```json
{
  "id": "uuid-dari-auth-users",
  "username": "budi",
  "applicant_name": "Budi Santoso",
  "email": "user@example.com",
  "phone_number": "081234567890",
  "role": "End User",
  "bio": "",
  "sports_interests": ["Futsal", "Badminton"],
  "instagram": "",
  "twitter": "",
  "facebook": "",
  "profile_image_path": null,
  "ktp_image_path": null,
  "gender": "Not Set",
  "date_of_birth": null,
  "points": 0,
  "cart": [],
  "favorites": [],
  "updated_at": "2026-06-21T00:00:00.000Z"
}
```

### Login

```http
POST {{SUPABASE_URL}}/auth/v1/token?grant_type=password
```

Body:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response penting:

```json
{
  "access_token": "jwt-access-token",
  "refresh_token": "refresh-token",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com"
  }
}
```

### Reset Password

```http
POST {{SUPABASE_URL}}/auth/v1/recover
```

Body:

```json
{
  "email": "user@example.com"
}
```

### Update Password

```http
PUT {{SUPABASE_URL}}/auth/v1/user
Authorization: Bearer {{USER_ACCESS_TOKEN}}
```

Body:

```json
{
  "password": "newPassword123"
}
```

## Users

Tabel: `public.users`

### Ambil Semua User

Dipakai untuk sinkronisasi cache akun lokal.

```http
GET {{SUPABASE_URL}}/rest/v1/users?select=*
```

### Ambil Profil Berdasarkan ID

```http
GET {{SUPABASE_URL}}/rest/v1/users?select=*&id=eq.{{USER_ID}}
```

### Ambil Cart User

```http
GET {{SUPABASE_URL}}/rest/v1/users?select=cart&username=eq.{{USERNAME}}
```

### Ambil Favorites User

```http
GET {{SUPABASE_URL}}/rest/v1/users?select=favorites&username=eq.{{USERNAME}}
```

### Update Profil, Cart, Favorites, atau Points

```http
PATCH {{SUPABASE_URL}}/rest/v1/users?username=eq.{{USERNAME}}
```

Body contoh:

```json
{
  "bio": "Suka olahraga pagi",
  "sports_interests": ["Badminton"],
  "cart": [
    {
      "venueName": "Arena Futsal Rensius",
      "courtName": "Court A",
      "date": "2026-06-21",
      "time": "08:00 - 09:00",
      "price": 100000
    }
  ],
  "favorites": []
}
```

### Hapus User

```http
DELETE {{SUPABASE_URL}}/rest/v1/users?username=eq.{{USERNAME}}
```

## Verifications

Tabel: `public.verifications`

Digunakan untuk pengajuan owner dan verifikasi dokumen.

### Ambil Semua Pengajuan

```http
GET {{SUPABASE_URL}}/rest/v1/verifications?select=*&order=submitted_at.desc
```

### Buat Pengajuan Owner

```http
POST {{SUPABASE_URL}}/rest/v1/verifications
```

Body:

```json
{
  "id": "VER-1718950000000",
  "applicant_name": "Owner Venue",
  "email": "owner@example.com",
  "username": "owner1",
  "phone_number": "081234567890",
  "nik": "317xxxxxxxxxxxxx",
  "npwp": "12.345.678.9-012.000",
  "document_url": "https://project.supabase.co/storage/v1/object/public/documents/ktp_owner1.jpg",
  "type": "Owner",
  "status": "Pending",
  "submitted_at": "2026-06-21T00:00:00.000Z",
  "venue_name": "Arena Futsal Rensius",
  "venue_address": "Jl. Contoh No. 1",
  "venue_provinsi": "DKI Jakarta",
  "venue_kota": "Jakarta Selatan",
  "venue_lat": -6.2,
  "venue_lng": 106.8,
  "venue_data": {},
  "rejection_reason": null,
  "password": "password-owner"
}
```

### Update Status Pengajuan

```http
PATCH {{SUPABASE_URL}}/rest/v1/verifications?id=eq.{{VERIFICATION_ID}}
```

Body approve:

```json
{
  "status": "Approved",
  "rejection_reason": null
}
```

Body reject:

```json
{
  "status": "Rejected",
  "rejection_reason": "Dokumen tidak jelas"
}
```

## Venues

Tabel: `public.venues`

### Ambil Semua Venue

```http
GET {{SUPABASE_URL}}/rest/v1/venues?select=*
```

### Tambah Venue

```http
POST {{SUPABASE_URL}}/rest/v1/venues
```

Body:

```json
{
  "name": "Arena Futsal Rensius",
  "location": "Jakarta Selatan",
  "address": "Jl. Contoh No. 1",
  "provinsi": "DKI Jakarta",
  "dll": "Parkir luas, mushola",
  "type": "Futsal",
  "price": 100000,
  "status": "Aktif",
  "hours": "06:00 - 22:00",
  "courts": [
    {
      "name": "Court A",
      "type": "Vinyl",
      "price": 100000
    }
  ],
  "images": [
    "https://project.supabase.co/storage/v1/object/public/venues/arena-1.jpg"
  ],
  "image_paths": ["arena-1.jpg"],
  "image": "https://project.supabase.co/storage/v1/object/public/venues/arena-1.jpg",
  "owner_username": "owner1",
  "lat": -6.2,
  "lng": 106.8
}
```

### Update Venue

```http
PATCH {{SUPABASE_URL}}/rest/v1/venues?name=eq.{{VENUE_NAME}}
```

Body contoh:

```json
{
  "price": 120000,
  "status": "Aktif",
  "hours": "07:00 - 23:00"
}
```

### Hapus Venue

```http
DELETE {{SUPABASE_URL}}/rest/v1/venues?name=eq.{{VENUE_NAME}}
```

### Hapus Venue Berdasarkan Owner

```http
DELETE {{SUPABASE_URL}}/rest/v1/venues?owner_username=eq.{{OWNER_USERNAME}}
```

## Bookings

Tabel: `public.bookings`

Status yang umum dipakai:

- `Menunggu Pembayaran`
- `Menunggu Jadwal`
- `Selesai`
- `Dibatalkan`
- `Expired`
- `Refunded`

### Ambil Semua Booking

```http
GET {{SUPABASE_URL}}/rest/v1/bookings?select=*&order=created_at.desc
```

Aplikasi melakukan filter role di client:

- `Admin`: melihat semua booking.
- `Owner`: melihat semua booking pada implementasi saat ini.
- `End User`: hanya booking dengan `username` miliknya.

### Buat atau Update Booking

```http
POST {{SUPABASE_URL}}/rest/v1/bookings
Prefer: resolution=merge-duplicates,return=representation
```

Body:

```json
{
  "order_id": "ORDER-1718950000000",
  "username": "budi",
  "venue_name": "Arena Futsal Rensius",
  "court_name": "Court A",
  "date": "2026-06-21",
  "time": "08:00 - 09:00",
  "price": 100000,
  "payment_method": "Midtrans",
  "status": "Menunggu Pembayaran",
  "services": "Sewa raket",
  "payment_deadline": "2026-06-21T01:00:00.000Z",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/token",
  "used_points": 0
}
```

### Update Status Booking

```http
PATCH {{SUPABASE_URL}}/rest/v1/bookings?order_id=eq.{{ORDER_ID}}
```

Body:

```json
{
  "status": "Selesai"
}
```

### Tandai Booking Sudah Dibayar

Hanya mengubah booking yang masih berstatus `Menunggu Pembayaran`.

```http
PATCH {{SUPABASE_URL}}/rest/v1/bookings?order_id=eq.{{ORDER_ID}}&status=eq.Menunggu%20Pembayaran
```

Body:

```json
{
  "status": "Menunggu Jadwal",
  "payment_deadline": null,
  "redirect_url": null
}
```

### Batalkan Booking Pending

```http
PATCH {{SUPABASE_URL}}/rest/v1/bookings?order_id=eq.{{ORDER_ID}}
```

Body:

```json
{
  "status": "Dibatalkan",
  "payment_deadline": null,
  "redirect_url": null
}
```

### Hapus Booking

```http
DELETE {{SUPABASE_URL}}/rest/v1/bookings?order_id=eq.{{ORDER_ID}}
```

## Reviews

Tabel: `public.reviews`

### Ambil Semua Review

```http
GET {{SUPABASE_URL}}/rest/v1/reviews?select=*&order=date.desc
```

### Buat atau Update Review

Review memakai unique constraint `username, venue_name`.

```http
POST {{SUPABASE_URL}}/rest/v1/reviews
Prefer: resolution=merge-duplicates,return=representation
```

Body:

```json
{
  "username": "budi",
  "venue_name": "Arena Futsal Rensius",
  "rating": 4.5,
  "comment": "Lapangan bersih dan nyaman.",
  "date": "2026-06-21T00:00:00.000Z"
}
```

### Hapus Review

```http
DELETE {{SUPABASE_URL}}/rest/v1/reviews?username=eq.{{USERNAME}}&venue_name=eq.{{VENUE_NAME}}
```

## Chats

Tabel: `public.chats`

### Ambil Semua Thread Chat

```http
GET {{SUPABASE_URL}}/rest/v1/chats?select=*&order=created_at.asc
```

### Ambil Chat User

```http
GET {{SUPABASE_URL}}/rest/v1/chats?select=*&username=eq.{{USERNAME}}&order=created_at.asc
```

### Ambil Chat User dan Venue

```http
GET {{SUPABASE_URL}}/rest/v1/chats?select=*&username=eq.{{USERNAME}}&venue_name=eq.{{VENUE_NAME}}&order=created_at.asc
```

### Kirim Pesan

```http
POST {{SUPABASE_URL}}/rest/v1/chats
```

Body dari user:

```json
{
  "username": "budi",
  "venue_name": "Arena Futsal Rensius",
  "sender": "budi",
  "message": "Apakah slot jam 8 masih tersedia?",
  "read_by_user": true,
  "read_by_owner": false
}
```

Body dari owner:

```json
{
  "username": "budi",
  "venue_name": "Arena Futsal Rensius",
  "sender": "owner1",
  "message": "Masih tersedia.",
  "read_by_user": false,
  "read_by_owner": true
}
```

### Tandai Chat Sudah Dibaca

Untuk owner:

```http
PATCH {{SUPABASE_URL}}/rest/v1/chats?username=eq.{{USERNAME}}&venue_name=eq.{{VENUE_NAME}}
```

Body:

```json
{
  "read_by_owner": true
}
```

Untuk user:

```json
{
  "read_by_user": true
}
```

## Notifications

Tabel: `public.notifications`

Username target:

- `all`: notifikasi untuk semua user.
- `admin`: notifikasi untuk Admin dan Owner.
- username spesifik: notifikasi untuk user tertentu.

### Ambil Notifikasi User

```http
GET {{SUPABASE_URL}}/rest/v1/notifications?select=*&or=(username.eq.{{USERNAME}},username.eq.all)&order=created_at.desc
```

Untuk Admin atau Owner:

```http
GET {{SUPABASE_URL}}/rest/v1/notifications?select=*&or=(username.eq.admin,username.eq.all)&order=created_at.desc
```

### Buat atau Update Notifikasi

```http
POST {{SUPABASE_URL}}/rest/v1/notifications
Prefer: resolution=merge-duplicates,return=representation
```

Body:

```json
{
  "id": "NOTIF-1718950000000",
  "username": "all",
  "title": "Venue Baru",
  "message": "Arena Futsal Rensius sudah tersedia.",
  "icon_code": 59477,
  "color_value": -16776961,
  "is_read": false,
  "created_at": "2026-06-21T00:00:00.000Z"
}
```

### Tandai Semua Notifikasi Sudah Dibaca

```http
PATCH {{SUPABASE_URL}}/rest/v1/notifications?or=(username.eq.{{USERNAME}},username.eq.all)
```

Body:

```json
{
  "is_read": true
}
```

## Storage

Bucket yang digunakan:

| Bucket | Fungsi | Public |
| --- | --- | --- |
| `profiles` | Foto profil user | Ya |
| `documents` | Foto KTP/berkas owner | Ya |
| `venues` | Foto venue/lapangan | Ya |

### Upload File

```http
POST {{SUPABASE_URL}}/storage/v1/object/{{BUCKET_NAME}}/{{DESTINATION_PATH}}
Authorization: Bearer {{USER_ACCESS_TOKEN_OR_ANON_KEY}}
Content-Type: multipart/form-data
```

Contoh path yang dibuat aplikasi:

- KTP: `ktp_{{username}}_{{timestamp}}.jpg`
- Avatar: `avatar_{{username}}_{{timestamp}}.jpg`
- Venue: path disimpan pada kolom `image_paths`

### Ambil Public URL

```http
GET {{SUPABASE_URL}}/storage/v1/object/public/{{BUCKET_NAME}}/{{DESTINATION_PATH}}
```

Contoh:

```text
{{SUPABASE_URL}}/storage/v1/object/public/profiles/avatar_budi_1718950000000.jpg
```

## Midtrans

Integrasi Midtrans pada aplikasi memakai Sandbox dan `MIDTRANS_SERVER_KEY`. Header Authorization menggunakan Basic Auth dari format `base64("{{MIDTRANS_SERVER_KEY}}:")`.

```http
Authorization: Basic {{BASE64_SERVER_KEY_COLON}}
Content-Type: application/json
Accept: application/json
```

### Buat Transaksi Snap

```http
POST https://app.sandbox.midtrans.com/snap/v1/transactions
```

Body:

```json
{
  "transaction_details": {
    "order_id": "ORDER-1718950000000",
    "gross_amount": 100000
  },
  "enabled_payments": ["gopay", "bank_transfer"],
  "credit_card": {
    "secure": true
  },
  "customer_details": {
    "first_name": "budi",
    "email": "user@example.com",
    "phone": "081234567890"
  },
  "item_details": [
    {
      "id": "ORDER-1718950000000",
      "price": 100000,
      "quantity": 1,
      "name": "Court A - Arena Futsal Rensius"
    }
  ]
}
```

Response sukses:

```json
{
  "token": "snap-token",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/redirection/snap-token"
}
```

### Cek Status Transaksi

```http
GET https://api.sandbox.midtrans.com/v2/{{ORDER_ID}}/status
```

Response contoh:

```json
{
  "order_id": "ORDER-1718950000000",
  "transaction_status": "settlement",
  "payment_type": "bank_transfer",
  "gross_amount": "100000.00"
}
```

Status Midtrans yang dipakai aplikasi:

- `settlement`
- `capture`
- `pending`
- `cancel`
- `deny`
- `expire`

## Skema Tabel Ringkas

### `users`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | uuid | PK, referensi `auth.users.id` |
| `username` | text | Unique username |
| `applicant_name` | text | Nama lengkap |
| `email` | text | Email user |
| `phone_number` | text | Nomor telepon |
| `role` | text | `Admin`, `Owner`, atau `End User` |
| `sports_interests` | jsonb | Minat olahraga |
| `cart` | jsonb | Keranjang user |
| `favorites` | jsonb | Venue favorit |
| `points` | integer | Poin loyalitas |

### `venues`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `name` | text | PK nama venue |
| `location` | text | Lokasi ringkas |
| `address` | text | Alamat lengkap |
| `type` | text | Jenis olahraga |
| `price` | integer | Harga dasar |
| `status` | text | Status venue |
| `courts` | jsonb | Daftar lapangan |
| `images` | jsonb | URL gambar |
| `owner_username` | text | Pemilik venue |
| `lat`, `lng` | double precision | Koordinat venue |

### `bookings`

| Kolom | Tipe | Keterangan |
| --- | --- | --- |
| `id` | uuid | PK otomatis |
| `order_id` | text | Unique order ID |
| `username` | text | Pemesan |
| `venue_name` | text | Nama venue |
| `court_name` | text | Nama lapangan |
| `date` | text | Tanggal booking |
| `time` | text | Jam booking |
| `price` | integer | Total harga |
| `payment_method` | text | Metode pembayaran |
| `status` | text | Status booking |
| `payment_deadline` | timestamptz | Batas pembayaran |
| `redirect_url` | text | URL Snap Midtrans |
| `used_points` | integer | Poin yang dipakai |

## Error Umum

| Kondisi | Penyebab Umum | Solusi |
| --- | --- | --- |
| `401 Unauthorized` | Header `Authorization` salah atau token expired | Login ulang dan gunakan access token baru |
| `403 Forbidden` | RLS policy menolak operasi | Cek policy di `schema.sql` dan role user |
| `PGRST204` | Kolom/tabel belum tersedia di Supabase | Jalankan ulang `schema.sql` |
| Upload storage gagal | Bucket belum dibuat atau policy storage belum ada | Buat bucket `profiles`, `documents`, `venues` dan policy public |
| Midtrans gagal membuat transaksi | `MIDTRANS_SERVER_KEY` salah atau kosong | Isi `.env` dengan server key sandbox yang benar |

## File Implementasi Terkait

- `lib/services/supabase_service.dart`: inisialisasi Supabase dan upload storage.
- `lib/services/supabase_auth_service.dart`: register, login, reset password, update profil.
- `lib/services/booking_service.dart`: CRUD booking dan update status pembayaran.
- `lib/services/review_service.dart`: CRUD review.
- `lib/services/midtrans_service.dart`: Snap transaction dan cek status transaksi.
- `lib/data/venue_data.dart`: CRUD venue, cart, favorites.
- `lib/data/verification_data.dart`: pengajuan dan status verifikasi owner.
- `lib/data/chat_data.dart`: chat user dan owner.
- `lib/data/notification_data.dart`: notifikasi in-app.
- `schema.sql`: definisi tabel, RLS policy, dan storage policy.
