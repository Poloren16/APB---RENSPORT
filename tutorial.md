# Panduan Lengkap Setup Supabase - RENSIUS

Dokumen ini berisi panduan lengkap langkah-demi-langkah bagi developer untuk melakukan setup, integrasi, hingga aplikasi siap diuji dari nol menggunakan akun Supabase pribadi.

---

## ── Ringkasan Langkah ──
1. **Kloning Repositori**
2. **Membuat Akun & Project Baru di Supabase**
3. **Membuat Tabel Database (SQL Editor)**
4. **Membuat Storage Buckets (`profiles`, `documents`, & `venues`)**
5. **Menerapkan Storage Security Policies (RLS SQL)**
6. **Mengisi Berkas `.env` Lokal**
7. **Jalankan Aplikasi!**

---

## 1. Kloning Repositori dari GitHub
Buka terminal/CMD di folder kerja Anda, lalu jalankan perintah:
```bash
git clone https://github.com/Poloren16/APB---RENSPORT.git
cd APB---RENSPORT
```

---

## 2. Membuat Akun & Project Baru di Supabase
1. Buka browser dan kunjungi [https://supabase.com](https://supabase.com) (Anda bisa login menggunakan akun GitHub).
2. Di halaman dashboard, klik **"New project"** dan pilih organisasi Anda.
3. Isi kolom pembuatan project baru:
   * **Project Name**: `RENSIUS` (atau nama bebas lainnya).
   * **Database Password**: Buat password yang kuat (dan catat baik-baik).
   * **Region**: Pilih **Singapore** (agar latency/kecepatan akses dari Indonesia sangat cepat).
   * **Pricing Plan**: Pilih **Free** (Gratis).
4. Klik **"Create new project"** dan tunggu beberapa menit hingga inisialisasi server selesai.

---

## 3. Inisialisasi Database (SQL Editor)
Setelah status project Supabase berubah menjadi aktif, kita buat seluruh struktur tabel:
1. Di menu sidebar kiri dashboard Supabase, pilih **SQL Editor** (ikon kertas bernotasi `>_` atau `SQL`).
2. Klik tombol **"+ New query"** (atau New Query kosong).
3. Salin seluruh skrip pembuatan tabel database berikut, tempelkan ke editor, lalu klik **"Run"** (atau tekan `Ctrl + Enter`):

```sql
-- =======================================================
-- 1. TABEL VERIFICATIONS (Pendaftaran Owner & Detail KTP)
-- =======================================================
CREATE TABLE public.verifications (
  id text NOT NULL PRIMARY KEY,
  applicant_name text NOT NULL,
  email text NOT NULL,
  username text NOT NULL,
  phone_number text NOT NULL,
  nik text NOT NULL,
  npwp text NOT NULL,
  document_url text NOT NULL,
  type text NOT NULL,
  status text NOT NULL DEFAULT 'Pending',
  submitted_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  venue_name text,
  venue_address text,
  venue_provinsi text,
  venue_kota text,
  venue_lat double precision,
  venue_lng double precision,
  venue_data jsonb,
  rejection_reason text,
  password text
);

-- =======================================================
-- 2. TABEL USERS (Profil User & Hubungan Auth)
-- =======================================================
CREATE TABLE public.users (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text NOT NULL UNIQUE,
  applicant_name text NOT NULL,
  email text NOT NULL,
  phone_number text NOT NULL,
  role text NOT NULL,
  bio text,
  sports_interests jsonb,
  instagram text,
  twitter text,
  facebook text,
  profile_image_path text,
  ktp_image_path text,
  gender text,
  date_of_birth text,
  points integer NOT NULL DEFAULT 0,
  cart jsonb DEFAULT '[]'::jsonb NOT NULL,
  favorites jsonb DEFAULT '[]'::jsonb NOT NULL
);

-- =======================================================
-- 3. TABEL VENUES (Daftar Arena & Lapangan Aktif)
-- =======================================================
CREATE TABLE public.venues (
  name text NOT NULL PRIMARY KEY,
  location text NOT NULL,
  address text NOT NULL,
  provinsi text NOT NULL,
  dll text,
  type text NOT NULL,
  price integer NOT NULL,
  status text NOT NULL DEFAULT 'Aktif',
  hours text NOT NULL DEFAULT '06:00 - 22:00',
  courts jsonb DEFAULT '[]'::jsonb NOT NULL,
  images jsonb DEFAULT '[]'::jsonb NOT NULL,
  image_paths jsonb DEFAULT '[]'::jsonb NOT NULL,
  image text NOT NULL,
  owner_username text NOT NULL,
  lat double precision DEFAULT 0.0 NOT NULL,
  lng double precision DEFAULT 0.0 NOT NULL
);

-- =======================================================
-- 4. TABEL BOOKINGS (Riwayat Pemesanan Slot Lapangan)
-- =======================================================
CREATE TABLE public.bookings (
  id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id text NOT NULL UNIQUE,
  username text NOT NULL,
  venue_name text NOT NULL,
  court_name text NOT NULL,
  date text NOT NULL,
  time text NOT NULL,
  price integer NOT NULL,
  payment_method text NOT NULL,
  status text NOT NULL,
  services text,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =======================================================
-- 5. TABEL REVIEWS (Rating dan Ulasan Lapangan)
-- =======================================================
CREATE TABLE public.reviews (
  id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL,
  venue_name text NOT NULL,
  rating double precision NOT NULL,
  comment text NOT NULL,
  date timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (username, venue_name)
);
```

---

## 4. Membuat Storage Buckets di Supabase
1. Di sidebar kiri dashboard Supabase, klik menu **Storage** (ikon berbentuk ember/box).
2. Buat tiga bucket baru dengan mengeklik **"New bucket"**. Pastikan untuk mengaktifkan pilihan **"Public Bucket" (Toggle ON)** pada ketiganya agar foto bisa diakses lewat URL publik:
   - Nama Bucket 1: `profiles`
   - Nama Bucket 2: `documents`
   - Nama Bucket 3: `venues`

---

## 5. Terapkan Kebijakan Keamanan Storage (SQL Editor)
Agar aplikasi diperbolehkan untuk mengunggah (*Insert*), melihat (*Select*), dan memperbarui (*Update*) gambar tanpa terblokir sistem keamanan Supabase, jalankan script kebijakan (*RLS Policies*) berikut di **SQL Editor**:

```sql
-- POLICY UNTUK BUCKET 'profiles'
CREATE POLICY "Allow Public Read for profiles" ON storage.objects FOR SELECT TO public USING (bucket_id = 'profiles');
CREATE POLICY "Allow Public Insert for profiles" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'profiles');
CREATE POLICY "Allow Public Update for profiles" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'profiles');

-- POLICY UNTUK BUCKET 'documents'
CREATE POLICY "Allow Public Read for documents" ON storage.objects FOR SELECT TO public USING (bucket_id = 'documents');
CREATE POLICY "Allow Public Insert for documents" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'documents');
CREATE POLICY "Allow Public Update for documents" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'documents');

-- POLICY UNTUK BUCKET 'venues'
CREATE POLICY "Allow Public Read for venues" ON storage.objects FOR SELECT TO public USING (bucket_id = 'venues');
CREATE POLICY "Allow Public Insert for venues" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'venues');
CREATE POLICY "Allow Public Update for venues" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'venues');
```

---

## 6. Membuat Berkas `.env` Lokal
1. Di folder utama proyek Flutter Anda (sejajar dengan file `pubspec.yaml`), buat sebuah file baru bernama **`.env`**.
2. Salin template berikut ke dalam file `.env`:
   ```env
   # =========================================================================
   # KREDENSIAL SUPABASE
   # =========================================================================
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-public-key-here

   # =========================================================================
   # LISENSI GOOGLE MAPS API & MIDTRANS SANDBOX
   # =========================================================================
   GOOGLE_MAPS_API_KEY=your-google-maps-api-key-here
   ANDROID_MAPS_API_KEY=your-android-maps-api-key-here
   IOS_MAPS_API_KEY=your-ios-maps-api-key-here

   MIDTRANS_MERCHANT_ID=your-midtrans-merchant-id-here
   MIDTRANS_CLIENT_KEY=your-midtrans-client-key-here
   MIDTRANS_SERVER_KEY=your-midtrans-server-key-here
   ```
3. Buka dashboard Supabase Anda -> **Project Settings** (ikon roda gigi) -> sub-menu **API**.
4. Salin **Project URL** dan **API Key (anon public)** Anda, lalu masukkan ke dalam nilai `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di file `.env`.

---

## 7. Menjalankan Aplikasi
Buka terminal Anda di folder utama proyek, lalu jalankan perintah berikut secara berurutan:
```bash
# 1. Bersihkan cache lama
flutter clean

# 2. Ambil ulang seluruh dependensi paket
flutter pub get

# 3. Jalankan aplikasi di emulator atau device Anda
flutter run
```
