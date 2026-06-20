# Panduan CI/CD Android Release - GitHub Actions

Dokumen ini menjelaskan workflow GitHub Actions untuk membangun APK Android Flutter secara otomatis pada repository RENSIUS.

Workflow utama berada di:

```text
.github/workflows/android-release.yml
```

## Fungsi Workflow

Workflow **Android Release** akan:

1. Mengambil source code repository.
2. Menyiapkan Java 17 menggunakan Temurin.
3. Menyiapkan Flutter channel stable.
4. Menjalankan `flutter pub get`.
5. Membuat file `.env` sementara di runner GitHub Actions.
6. Menjalankan `flutter clean`.
7. Membangun APK release dengan `flutter build apk --release`.
8. Mengunggah APK sebagai artifact GitHub Actions.
9. Membuat GitHub Release otomatis dan melampirkan APK jika workflow dipicu oleh tag `v*`.

## Trigger Workflow

Workflow berjalan otomatis pada kondisi berikut:

- Ada push ke branch `main`.
- Ada tag baru dengan format `v*`, misalnya `v1.0.0` atau `v1.0.1`.
- Dijalankan manual dari tab **Actions** menggunakan tombol **Run workflow**.

## Artifact APK

Setiap workflow sukses akan menghasilkan artifact bernama:

```text
app-release-apk
```

File APK yang diunggah berasal dari:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Untuk mengunduhnya:

1. Buka repository di GitHub.
2. Masuk ke tab **Actions**.
3. Pilih run workflow **Android Release** yang sukses.
4. Unduh artifact **app-release-apk** pada bagian **Artifacts**.

## GitHub Release Otomatis

GitHub Release hanya dibuat otomatis jika workflow dipicu oleh tag yang diawali huruf `v`.

Contoh membuat release versi `v1.0.0`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Setelah workflow selesai:

- Release baru bernama `v1.0.0` akan dibuat di GitHub.
- APK release akan otomatis dilampirkan ke release tersebut.
- Release notes akan dibuat otomatis oleh GitHub Actions.

## Menjalankan Build Lewat Push ke Main

Untuk menghasilkan artifact APK tanpa membuat GitHub Release:

```bash
git add .github/workflows/android-release.yml GITHUB_ACTIONS_ANDROID_RELEASE.md README.md
git commit -m "Add Android release CI workflow documentation"
git push origin main
```

Push ke `main` akan menjalankan workflow dan menghasilkan artifact APK, tetapi tidak membuat GitHub Release.

## Menjalankan Workflow Manual

Workflow juga bisa dijalankan manual:

1. Buka repository di GitHub.
2. Masuk ke tab **Actions**.
3. Pilih workflow **Android Release**.
4. Klik **Run workflow**.
5. Pilih branch yang ingin dibuild.
6. Klik tombol **Run workflow**.

Manual run akan menghasilkan artifact APK, tetapi tidak membuat GitHub Release kecuali dijalankan dari konteks tag `v*`.

## Konfigurasi Secret ENV_FILE

Project ini menggunakan `.env` sebagai asset pada `pubspec.yaml`, tetapi `.env` tidak di-commit karena berisi konfigurasi sensitif dan sudah masuk `.gitignore`.

Workflow memiliki langkah aman:

- Jika secret `ENV_FILE` tersedia, isi secret akan ditulis ke file `.env` sementara di runner.
- Jika secret `ENV_FILE` tidak tersedia, workflow membuat file `.env` kosong agar build tidak gagal karena asset `.env` hilang.

Untuk mengisi secret `ENV_FILE`:

1. Buka repository di GitHub.
2. Masuk ke **Settings**.
3. Pilih **Secrets and variables**.
4. Pilih **Actions**.
5. Klik **New repository secret**.
6. Isi **Name** dengan:

```text
ENV_FILE
```

7. Isi **Secret** dengan isi file `.env`, contohnya:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key-here
GOOGLE_MAPS_API_KEY=your-google-maps-api-key-here
ANDROID_MAPS_API_KEY=your-android-maps-api-key-here
IOS_MAPS_API_KEY=your-ios-maps-api-key-here
MIDTRANS_MERCHANT_ID=your-midtrans-merchant-id-here
MIDTRANS_CLIENT_KEY=your-midtrans-client-key-here
MIDTRANS_SERVER_KEY=your-midtrans-server-key-here
```

8. Klik **Add secret**.

Jangan memasukkan secret, API key, password, token, atau keystore langsung ke repository.

## Permission Workflow

Workflow menggunakan permission:

```yaml
permissions:
  contents: write
```

Permission ini diperlukan agar `GITHUB_TOKEN` bisa membuat GitHub Release dan mengunggah APK ke release saat tag `v*` dibuat.

## Signing APK

Untuk saat ini workflow membangun APK release default sesuai konfigurasi project.

Project belum menambahkan konfigurasi signing keystore khusus untuk production release. Karena itu, jangan commit file keystore, password keystore, atau konfigurasi signing sensitif ke repository.

Jika suatu saat APK production perlu ditandatangani dengan keystore resmi, simpan data signing di GitHub Secrets dan ubah workflow agar membuat file keystore sementara di runner.

## Troubleshooting

### Build gagal karena `.env` tidak ditemukan

Pastikan workflow memiliki langkah **Prepare environment file**. Langkah ini akan membuat `.env` dari secret `ENV_FILE` atau membuat file kosong jika secret tidak tersedia.

### GitHub Release tidak dibuat

Pastikan workflow dipicu oleh tag dengan format `v*`.

Contoh benar:

```text
v1.0.0
v1.0.1
v2.3.0
```

Contoh yang tidak akan membuat release otomatis:

```text
1.0.0
release-1.0.0
android-v1.0.0
```

### Artifact APK tidak muncul

Pastikan step **Build release APK** sukses dan file berikut tersedia:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Workflow dikonfigurasi dengan `if-no-files-found: error`, sehingga job akan gagal jika APK tidak ditemukan.
