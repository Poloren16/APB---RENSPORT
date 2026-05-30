# Firebase Setup RENSIUS

Dokumen ini menjelaskan integrasi Firebase yang sudah dilakukan pada project RENSIUS dan langkah yang perlu dilakukan rekan developer untuk menjalankan project serta mengakses Firebase.

## Integrasi Yang Sudah Dilakukan

Project sudah dihubungkan ke Firebase project:

- Project ID: `rensius`
- Android App ID: `1:786242129327:android:dda1af1c10ca68c9a4335a`
- Web App ID: `1:786242129327:web:abec7ce7f2ef4786a4335a`

Layanan Firebase yang sudah disiapkan di kode:

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Analytics

Firebase Storage tidak dipakai karena layanan tersebut membutuhkan billing/upgrade. Upload gambar untuk sementara tetap menggunakan path lokal atau URL manual, bukan upload ke Firebase Storage.

## File Firebase Yang Sudah Ditambahkan

File penting yang terkait Firebase:

- `lib/firebase_options.dart`
- `lib/services/firebase_service.dart`
- `lib/services/firebase_auth_service.dart`
- `android/app/google-services.json`
- `firebase.json`

Perubahan konfigurasi Android:

- `android/settings.gradle.kts` menambahkan plugin Google Services.
- `android/app/build.gradle.kts` menerapkan plugin `com.google.gms.google-services`.
- `android/app/src/main/AndroidManifest.xml` menambahkan permission notifikasi.

Perubahan konfigurasi iOS:

- `ios/Runner/Info.plist` menambahkan background mode untuk remote notification.

## Dependency Firebase

Dependency Firebase yang digunakan:

```yaml
firebase_core
firebase_auth
cloud_firestore
firebase_messaging
firebase_analytics
```

Dependency `firebase_storage` sudah dilepas karena Storage tidak digunakan.

## Alur Firebase Saat Ini

Saat aplikasi mulai, `main.dart` memanggil:

```dart
await FirebaseService.initialize();
```

Service tersebut melakukan:

- Inisialisasi Firebase Core
- Setup Firebase Cloud Messaging
- Setup Firebase Analytics
- Fallback agar Auth/Firestore tetap bisa jalan walaupun Messaging/Analytics belum lengkap

Pada halaman register, data user mulai diarahkan ke:

- Firebase Authentication untuk membuat akun email/password
- Cloud Firestore collection `users` untuk menyimpan profil user

Data lokal lama masih dipertahankan agar halaman app yang masih bergantung pada mock/local data tetap berjalan.

## Cara Menjalankan Project

Pastikan Flutter sudah terpasang.

1. Clone project.

2. Masuk ke folder project:

```bash
cd APB---RENSPORT
```

3. Ambil dependency:

```bash
flutter pub get
```

4. Jalankan di Chrome:

```bash
flutter run -d chrome
```

5. Jalankan di Android emulator/device:

```bash
flutter run
```

Setelah ada perubahan file Firebase, lakukan stop aplikasi total lalu run ulang. Hot reload saja tidak cukup untuk beberapa perubahan konfigurasi Firebase.

## Akses Firebase Console

Untuk mengakses Firebase Console, rekan developer harus diundang ke project Firebase `rensius`.

Langkah untuk owner/admin Firebase:

1. Buka Firebase Console.
2. Pilih project `rensius`.
3. Buka Project settings.
4. Pilih Users and permissions.
5. Tambahkan email rekan developer.
6. Berikan role yang sesuai.

Role yang disarankan:

- Viewer: hanya melihat konfigurasi dan data.
- Editor: bisa mengubah Authentication, Firestore, dan konfigurasi app.
- Owner: hanya untuk orang yang benar-benar mengelola project dan billing.

## Layanan Yang Harus Aktif Di Firebase Console

Authentication:

- Buka Authentication.
- Masuk ke Sign-in method.
- Aktifkan Email/Password.

Cloud Firestore:

- Buka Firestore Database.
- Buat database jika belum ada.
- Untuk development, gunakan rules sementara yang aman sesuai kebutuhan tim.

Cloud Messaging:

- Android bisa menggunakan `google-services.json`.
- Web biasanya membutuhkan konfigurasi tambahan seperti VAPID key dan service worker jika push notification web ingin benar-benar dipakai.

Analytics:

- Sudah dipanggil dari kode melalui `firebase_analytics`.

Storage:

- Tidak digunakan.
- Jangan aktifkan dependency Storage kecuali billing sudah siap.

## Catatan Untuk Web/Chrome

`lib/firebase_options.dart` sudah memiliki konfigurasi web agar Firebase aktif saat dijalankan di Chrome.

Jika register di Chrome masih gagal, cek hal berikut:

- Email/Password provider sudah enabled di Firebase Authentication.
- Browser memiliki koneksi internet.
- Console browser tidak menampilkan error Firebase API key atau project config.
- Firestore rules mengizinkan penulisan dokumen user sesuai strategi development.

## IDE Setup & Mengatasi "Unresolved class 'MainActivity'"

Jika IDE menampilkan error "Unresolved class 'MainActivity'", berikut langkah untuk memperbaikinya:

### Pada Android Studio / IntelliJ IDEA:

1. **Sinkronisasi Gradle Project:**
   - Main Menu → Gradle → Projects panel (kanan) → Tap refresh icon
   - Atau: File → Sync Now

2. **Bersihkan Build Cache:**
   ```bash
   cd android
   ./gradlew clean
   ```
   Atau dari root project:
   ```bash
   flutter clean
   ```

3. **Invalidate Caches:**
   - File → Invalidate Caches... → Invalidate and Restart

4. **Rebuild Project:**
   - Build → Clean Project
   - Build → Rebuild Project

5. **Verifikasi MainActivity:**
   - File tree: `android/app/src/main/kotlin/com/example/rensius/MainActivity.kt`
   - Pastikan file ada dan memiliki konten:
   ```kotlin
   package com.example.rensius
   
   import io.flutter.embedding.android.FlutterActivity
   
   class MainActivity : FlutterActivity()
   ```

### Pada VS Code:

1. **Install Extensions:**
   - Flutter extension (resmi dari Google)
   - Dart extension

2. **Bersihkan Project:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Rebuild Android:**
   ```bash
   flutter run
   ```

3. **Verify di Terminal:**
   ```bash
   flutter analyze
   ```

### Issue Umum dan Solusi:

**Gradle Plugin Belum Disinkronkan:**
- Build kembali dengan `flutter clean` dan `flutter pub get`
- Pastikan `.gradlebuild/com.google.gms.google-services:google-services:4.3.15` ter-download

**JAVA_HOME Tidak Terset:**
- Install Android Studio atau JDK
- Set JAVA_HOME environment variable
- Atau biarkan Flutter menangani ini dengan menjalankan `flutter run`

**Manifest Package Mismatch:**
- Pastikan package name di `AndroidManifest.xml`: `com.example.rensius`
- Cocok dengan folder struktur: `android/app/src/main/kotlin/com/example/rensius/`

## Troubleshooting Firebase

Jika muncul pesan:

```text
Firebase belum aktif
```

Kemungkinan penyebab:

- App belum di-restart penuh setelah konfigurasi Firebase berubah.
- Menjalankan di platform yang belum ada config-nya.
- `lib/firebase_options.dart` tidak berisi konfigurasi platform tersebut.
- Firebase gagal init karena error Messaging/Analytics.

Jika register berhasil di aplikasi tetapi tidak muncul di Firebase Authentication:

- Pastikan halaman register memanggil `FirebaseAuthService.registerEndUser`.
- Pastikan `FirebaseService.isInitialized` bernilai true.
- Pastikan Email/Password provider aktif.
- Cek Debug Console atau browser console untuk error `FirebaseAuthException`.

Jika akun muncul di Authentication tetapi profil tidak muncul di Firestore:

- Cek rules Firestore.
- Cek collection `users`.
- Cek apakah write ditolak karena permission.

## Batasan Saat Ini

- Tidak menggunakan Firebase Storage.
- Notifikasi web membutuhkan setup lanjutan jika ingin push notification berjalan penuh.

## Rekomendasi Langkah Berikutnya

1. Finalisasi register agar semua user baru masuk Firebase Authentication dan Firestore.
2. Migrasikan login agar memakai Firebase Authentication.
3. Migrasikan data venue dan booking dari mock/local data ke Cloud Firestore.
4. Tambahkan rules Firestore yang sesuai role user.
5. Tambahkan setup FCM web jika push notification di Chrome diperlukan.
