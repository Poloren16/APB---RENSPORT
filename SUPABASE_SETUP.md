# Supabase Setup Guide for RENSIUS Developer Team

Dokumen ini berisi panduan lengkap langkah-demi-langkah bagi rekan developer untuk melakukan migrasi ke **Supabase** mandiri pada project RENSIUS agar aplikasi bisa dijalankan dan diuji di device masing-masing menggunakan akun Supabase pribadi.

---

## ── Ringkasan Langkah ──
1. **Membuat Akun & Project Baru di Supabase**
2. **Membuat Tabel Database (SQL Editor)**
3. **Membuat Storage Buckets (`profiles` & `documents`)**
4. **Menerapkan Storage Security Policies (RLS SQL)**
5. **Mengisi Berkas `.env` Lokal**
6. **Jalankan Project!**

---

## 1. Membuat Akun & Project Baru di Supabase
1. Buka browser dan daftarkan akun baru di [https://supabase.com](https://supabase.com) (Anda bisa login cepat menggunakan akun GitHub).
2. Klik tombol **"New project"** di dashboard utama Supabase.
3. Isi kolom sebagai berikut:
   * **Name**: `RENSIUS` (atau nama lain bebas).
   * **Database Password**: Buat password yang kuat dan aman (simpan password ini).
   * **Region**: Pilih region terdekat dari lokasi Anda (disarankan **Singapore** untuk kecepatan akses terbaik).
   * **Pricing Plan**: Pilih **Free Plan** (Gratis).
4. Klik **"Create new project"** dan tunggu beberapa menit hingga inisialisasi database Supabase selesai disiapkan.

---

## 2. Membuat Tabel Database (SQL Editor)
Setelah project Supabase Anda aktif, kita perlu membuat 3 tabel utama: `users`, `venues`, dan `verifications`.

1. Di menu sidebar kiri dashboard Supabase, klik **SQL Editor** (ikon berbentuk teks `SQL` atau kertas `>_`).
2. Klik tombol **"+ New query"** (Quickstart -> New Query).
3. Salin (copy) seluruh skrip SQL di bawah ini secara utuh:

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
-- 2. TABEL USERS (Profil Terverifikasi & Sinkronisasi Auth)
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
-- 3. TABEL VENUES (Data Lapangan Aktif Terverifikasi)
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
-- 4. TABEL BOOKINGS (Riwayat Penyewaan & Slot Online)
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
-- 5. TABEL REVIEWS (Ulasan & Rating Lapangan)
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

4. Tempelkan (paste) kode di atas ke editor, lalu klik tombol **"Run"** berwarna hijau di pojok kanan bawah editor (atau tekan `Ctrl + Enter`).
5. Pastikan muncul pesan sukses: **"Success. No rows returned."**

---

## 3. Membuat Storage Buckets (`profiles` & `documents`)
Storage Buckets digunakan untuk menyimpan file gambar unggahan seperti **foto profil user** dan **foto KTP Owner**.

1. Di menu sidebar kiri dashboard Supabase, klik **Storage** (ikon berbentuk gambar ember/box).
2. Klik tombol **"New bucket"** untuk membuat bucket pertama:
   * **Bucket Name**: `profiles`
   * **Public Bucket**: **AKTIFKAN (Toggle ON)** *(Penting agar aplikasi bisa memuat gambar profil via URL Publik)*.
   * Klik **"Save"**.
3. Klik tombol **"New bucket"** sekali lagi untuk membuat bucket kedua:
   * **Bucket Name**: `documents`
   * **Public Bucket**: **AKTIFKAN (Toggle ON)** *(Penting agar admin bisa membaca foto KTP Owner saat verifikasi)*.
   * Klik **"Save"**.

---

## 4. Menerapkan Storage Security Policies (RLS SQL)
Karena bucket storage berada dalam mode aman, kita harus membuat kebijakan (policy) SQL agar aplikasi dapat mengunggah dan mengunduh berkas KTP/Profil tanpa ada pemblokiran izin (*permission errors*).

1. Buka kembali menu **SQL Editor** di sidebar kiri.
2. Klik **"+ New query"** untuk membuat editor baru.
3. Salin dan tempel skrip SQL policy berikut secara lengkap:

```sql
-- =======================================================
-- POLICY UNTUK BUCKET 'profiles' (Foto Profil Avatar)
-- =======================================================
CREATE POLICY "Allow Public Read for profiles" 
ON storage.objects FOR SELECT TO public USING (bucket_id = 'profiles');

CREATE POLICY "Allow Public Insert for profiles" 
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'profiles');

CREATE POLICY "Allow Public Update for profiles" 
ON storage.objects FOR UPDATE TO public USING (bucket_id = 'profiles');

-- =======================================================
-- POLICY UNTUK BUCKET 'documents' (Foto KTP Verifikasi Owner)
-- =======================================================
CREATE POLICY "Allow Public Read for documents" 
ON storage.objects FOR SELECT TO public USING (bucket_id = 'documents');

CREATE POLICY "Allow Public Insert for documents" 
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Allow Public Update for documents" 
ON storage.objects FOR UPDATE TO public USING (bucket_id = 'documents');

-- =======================================================
-- POLICY UNTUK BUCKET 'venues' (Foto Venue & Lapangan)
-- =======================================================
CREATE POLICY "Allow Public Read for venues" 
ON storage.objects FOR SELECT TO public USING (bucket_id = 'venues');

CREATE POLICY "Allow Public Insert for venues" 
ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'venues');

CREATE POLICY "Allow Public Update for venues" 
ON storage.objects FOR UPDATE TO public USING (bucket_id = 'venues');
```

4. Klik tombol **"Run"** dan tunggu hingga muncul status hijau sukses.

---

## 5. Mengisi Berkas `.env` Lokal
Kunci API Supabase Anda harus diintegrasikan ke dalam berkas konfigurasi lokal project agar aplikasi dapat terhubung ke server Anda.

1. Buka kembali dashboard Supabase Anda.
2. Masuk ke menu **Project Settings** (ikon gerigi di sidebar kiri paling bawah).
3. Pilih sub-menu **API**.
4. Di bagian **Project API Keys**, Anda akan menemukan:
   * **Project URL**: Salin URL tersebut.
   * **API Key (anon public)**: Salin string kunci tersebut.
5. Buat file baru bernama **`.env`** di **root directory** (folder utama) project Anda (sejajar dengan file `pubspec.yaml`), lalu salin template berikut dan masukkan kredensial Supabase pribadi Anda:

```env
# =========================================================================
# KREDENSIAL SUPABASE DEVELOPER (ISI DENGAN MILIK ANDA SENDIRI)
# =========================================================================
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here

# =========================================================================
# LISENSI GOOGLE MAPS API & MIDTRANS SANDBOX (ISI DENGAN MILIK ANDA SENDIRI)
# =========================================================================
GOOGLE_MAPS_API_KEY=your-google-maps-api-key-here
ANDROID_MAPS_API_KEY=your-android-maps-api-key-here
IOS_MAPS_API_KEY=your-ios-maps-api-key-here

MIDTRANS_MERCHANT_ID=your-midtrans-merchant-id-here
MIDTRANS_CLIENT_KEY=your-midtrans-client-key-here
MIDTRANS_SERVER_KEY=your-midtrans-server-key-here
```

*(Ganti `https://your-project-id.supabase.co` dan `your-anon-public-key-here` dengan kredensial API Supabase milik Anda).*

---

## 6. Jalankan Project!
Sekarang project Anda sudah siap dijalankan dengan backend Supabase mandiri. Ikuti perintah terminal berikut dari root directory project Anda:

1. **Bersihkan sisa cache build lama**:
   ```bash
   flutter clean
   ```
2. **Muat ulang seluruh paket dependensi**:
   ```bash
   flutter pub get
   ```
3. **Jalankan aplikasi di emulator atau device Android/iOS Anda**:
   ```bash
   flutter run
   ```

Aplikasi Anda kini berjalan secara 100% online, tersinkronisasi, dan aman menggunakan server Supabase pribadi Anda sendiri! Selamat mencoba dan happy coding! 🚀
