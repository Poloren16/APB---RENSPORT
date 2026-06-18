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
  favorites jsonb DEFAULT '[]'::jsonb NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
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
  payment_deadline timestamp with time zone,
  redirect_url text,
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

-- =======================================================
-- POLICY UNTUK STORAGE BUCKETS
-- =======================================================
-- profiles (Foto Profil Avatar)
CREATE POLICY "Allow Public Read for profiles" ON storage.objects FOR SELECT TO public USING (bucket_id = 'profiles');
CREATE POLICY "Allow Public Insert for profiles" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'profiles');
CREATE POLICY "Allow Public Update for profiles" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'profiles');

-- documents (Foto KTP Verifikasi Owner)
CREATE POLICY "Allow Public Read for documents" ON storage.objects FOR SELECT TO public USING (bucket_id = 'documents');
CREATE POLICY "Allow Public Insert for documents" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'documents');
CREATE POLICY "Allow Public Update for documents" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'documents');

-- venues (Foto Venue & Lapangan)
CREATE POLICY "Allow Public Read for venues" ON storage.objects FOR SELECT TO public USING (bucket_id = 'venues');
CREATE POLICY "Allow Public Insert for venues" ON storage.objects FOR INSERT TO public WITH CHECK (bucket_id = 'venues');
CREATE POLICY "Allow Public Update for venues" ON storage.objects FOR UPDATE TO public USING (bucket_id = 'venues');

-- =======================================================
-- ROW LEVEL SECURITY (RLS) UNTUK TABEL CHATS
-- =======================================================
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their own chats"
ON public.chats FOR SELECT TO authenticated
USING (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
);

CREATE POLICY "Allow users to insert their own chats"
ON public.chats FOR INSERT TO authenticated
WITH CHECK (
  username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR venue_name IN (
    SELECT name FROM public.venues
    WHERE owner_username = (SELECT username FROM public.users WHERE id = auth.uid())
  )
);

CREATE POLICY "Allow users to update their own chats"
ON public.chats FOR UPDATE TO authenticated
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
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to read their own notifications"
ON public.notifications FOR SELECT TO authenticated
USING (
  username = 'all'
  OR username = (SELECT username FROM public.users WHERE id = auth.uid())
  OR (
    username = 'admin'
    AND (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Admin', 'Owner')
  )
);

CREATE POLICY "Allow authenticated users to insert notifications"
ON public.notifications FOR INSERT TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow users to update their own notifications"
ON public.notifications FOR UPDATE TO authenticated
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

-- =======================================================
-- POLICIES UNTUK TABEL UTAMA LAINNYA
-- =======================================================
-- users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for users" ON public.users FOR SELECT TO public USING (true);
CREATE POLICY "Allow insert for self or admin" ON public.users FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow update for self or admin" ON public.users FOR UPDATE TO public 
USING (auth.uid() = id OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin')
WITH CHECK (auth.uid() = id OR (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin');

-- verifications
ALTER TABLE public.verifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for verifications" ON public.verifications FOR SELECT TO public USING (true);
CREATE POLICY "Allow public insert for verifications" ON public.verifications FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow update/delete for verifications" ON public.verifications FOR ALL TO public USING (true) WITH CHECK (true);

-- venues
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for venues" ON public.venues FOR SELECT TO public USING (true);
CREATE POLICY "Allow insert for owner or admin" ON public.venues FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow update/delete for owner or admin" ON public.venues FOR ALL TO public USING (true) WITH CHECK (true);

-- bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for bookings" ON public.bookings FOR SELECT TO public USING (true);
CREATE POLICY "Allow insert for bookings" ON public.bookings FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow update for bookings" ON public.bookings FOR UPDATE TO public USING (true) WITH CHECK (true);

-- reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for reviews" ON public.reviews FOR SELECT TO public USING (true);
CREATE POLICY "Allow all for authenticated users on reviews" ON public.reviews FOR ALL TO public 
USING (username = (SELECT username FROM public.users WHERE id = auth.uid()))
WITH CHECK (username = (SELECT username FROM public.users WHERE id = auth.uid()));
