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

-- =======================================================
-- 6. TABEL CHATS (Pesan antara End User & Owner Venue)
-- =======================================================
CREATE TABLE public.chats (
  id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL,
  venue_name text NOT NULL,
  sender text NOT NULL,
  message text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  read_by_user boolean DEFAULT false NOT NULL,
  read_by_owner boolean DEFAULT false NOT NULL
);

-- =======================================================
-- 7. TABEL NOTIFICATIONS (Notifikasi In-App untuk User)
-- =======================================================
CREATE TABLE public.notifications (
  id text NOT NULL PRIMARY KEY,
  username text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  icon_code integer NOT NULL,
  color_value integer NOT NULL,
  is_read boolean DEFAULT false NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
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

## 5. Menerapkan Database Row Level Security (RLS SQL) untuk Chats & Notifications
Agar data percakapan chat dan notifikasi in-app aman dan tidak bisa dibaca/ditulis oleh sembarang orang, kita perlu mengaktifkan Row Level Security (RLS) di PostgreSQL Supabase dan menambahkan kebijakan (policy) hak akses yang sesuai.

1. Buka kembali menu **SQL Editor** di sidebar kiri.
2. Klik **"+ New query"** untuk membuat editor baru.
3. Salin dan tempel skrip SQL policy berikut secara lengkap:

```sql
-- =======================================================
-- ROW LEVEL SECURITY (RLS) UNTUK TABEL CHATS
-- =======================================================
-- 1. Aktifkan RLS pada tabel chats
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

-- 2. Kebijakan SELECT (Membaca chat)
-- Pengguna hanya bisa membaca chat miliknya sendiri, atau chat dari venue miliknya (jika dia Owner)
CREATE POLICY "Allow users to read their own chats"
ON public.chats
FOR SELECT
TO authenticated
USING (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
);

-- 3. Kebijakan INSERT (Mengirim chat)
-- Hanya memperbolehkan pengiriman chat jika dia adalah pengirim yang sah (username-nya cocok dengan profilnya atau dia adalah owner venue)
CREATE POLICY "Allow users to insert their own chats"
ON public.chats
FOR INSERT
TO authenticated
WITH CHECK (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
);

-- 4. Kebijakan UPDATE (Mengupdate status read/unread chat)
CREATE POLICY "Allow users to update their own chats"
ON public.chats
FOR UPDATE
TO authenticated
USING (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
)
WITH CHECK (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
);

-- =======================================================
-- ROW LEVEL SECURITY (RLS) UNTUK TABEL NOTIFICATIONS
-- =======================================================
-- 1. Aktifkan RLS pada tabel notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 2. Kebijakan SELECT (Membaca notifikasi)
-- Pengguna hanya bisa membaca notifikasi yang ditujukan untuk dirinya sendiri, ditujukan ke semua (all), atau ditujukan ke admin (jika dia Admin/Owner)
CREATE POLICY "Allow users to read their own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (
  username = 'all'
  OR username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR (
    username = 'admin'
    AND (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Admin', 'Owner')
  )
);

-- 3. Kebijakan INSERT (Membuat notifikasi)
CREATE POLICY "Allow authenticated users to insert notifications"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 4. Kebijakan UPDATE (Menandai notifikasi telah dibaca)
CREATE POLICY "Allow users to update their own notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR (
    username = 'admin'
    AND (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Admin', 'Owner')
  )
)
WITH CHECK (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR (
    username = 'admin'
    AND (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Admin', 'Owner')
  )
);
```

4. Klik tombol **"Run"** dan tunggu hingga muncul status hijau sukses.

---

## 6. Mengisi Berkas `.env` Lokal
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

## 7. Jalankan Project!
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
