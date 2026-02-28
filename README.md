# Nanti Juga Kelar ✅

**Nanti Juga Kelar** adalah aplikasi pengelola tugas (To-Do List) modern berbasis Flutter yang dirancang untuk membantu produktivitas Anda. Dengan antarmuka (UI) minimalis yang elegan, fitur kategorisasi yang cerdas, dan integrasi notifikasi lokal, aplikasi ini memastikan tidak ada tenggat waktu atau tugas yang terlewat.

---

## ✨ Fitur Utama

1. **Atur Tugas dengan Cerdas** 📅
   Terdapat 3 tipe fleksibilitas tanggal:
   - _Catatan Biasa:_ Simpan ide atau to-do list harian tanpa beban notifikasi / alarm.
   - _Acara Masa Depan (Event)_: Tetapkan 1 tanggal untuk acara penting. Mendukung pengingat alarm H-7 sebelum hari H.
   - _Kejar Target (Deadline)_: Tentukan rentang waktu. Tugas akan hilang otomatis saat telah melampaui masa _deadline_.

2. **Kategori Berwarna & Sub-Tugas** 🏷️
   Bebas memberikan kategori prioritas (`🔴 Urgent`, `🔵 Kuliah`, `🟢 Pribadi`, `⚪ Lain-lain`) dan menyematkan catatan tambahan/detail dalam sebuah tugas.

3. **Status & Statistik Mingguan** 📊
   Fitur pemantauan tugas yang sudah selesai, tugas yang belum, serta grafis garis kemajuan (Progress Bar) dan pencapaian tugas mingguan (_Weekly Completed_).

4. **Notifikasi Alarm Otomatis (Local Notification)** 🔔
   Didukung oleh `flutter_local_notifications`. Alarm bekerja dengan presisi untuk mengingatkan deadline atau jadwal, langsung ke _Notification Tray_ HP Anda.

5. **Pencarian & Filter Instan** 🔍
   Cari nama tugas secara langsung, atau filter berdasarkan status (_Semua, Selesai, Belum Selesai_). Anda juga dapat mengurutkan tugas (Sort) berdasarkan Alfabet (A-Z, Z-A) atau rentang Waktu.

6. **Abstraksi Clean Code** 🧱
   Aplikasi dibagi dengan metode arsitektur _Atomic Design_ (`Atoms`, `Molecules`, `Organisms`, `Pages`) sehingga struktur kode sangat modular, _reusable_, dan mudah dipelihara (Clean Architecture).

---

## 📂 Struktur Direktori UI (Atomic Design)

Aplikasi dibangun menggunakan pola partisi komponen **Atomic Design**:

```
lib/
├── models/             # Model data utama (Task)
├── services/           # Service Background (Notifikasi, Widget, dsb)
└── ui/
    ├── atoms/          # Komponen UI terkecil (Custom TextField, Switch, Button, StatPill)
    ├── molecules/      # Gabungan atom yang memiliki fungsi kecil (Task Label, Filter Dropdown)
    ├── organisms/      # Komponen kompleks yang bisa berdiri sendiri (Header, List Item, Form)
    │   └── dialogs/    # Semua modular Popup dan Dialog konfirmasi
    └── pages/          # Layar/Halaman utama penuh (Home Page, Splash Screen)
```

---

## 🛠️ Tech Stack & Library

- **Flutter SDK**: ^3.24.0 (Atau yang terbaru)
- **Penyimpanan Luring**: `shared_preferences`
- **Notifikasi**: `flutter_local_notifications` & `timezone`
- **Manipulasi Waktu**: `intl` (Untuk format tanggal interaktif)

---

## 🚀 Panduan Instalasi & Menjalankan (Run)

1. **Pastikan lingkungan (environment) siap**
   Pastikan Anda sudah menginstall Flutter dan Dart SDK, serta memiliki Emulator / Device fisik yang terkoneksi.
2. **Clone / Buka Proyek**
   Buka terminal, dan masuklah ke _root directory_ `nantijugakelar`.
3. **Download semua package yang dibutuhkan**
   ```bash
   flutter pub get
   ```
4. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 👨‍💻 Kontribusi

Projek ini dibuat untuk mempermudah produktivitas mahasiswa dan masyarakat umum. Silakan ajukan **Pull Request** atau lapor **Issue** bila menemukan _bug_ atau ingin menambah fitur baru.

Dibuat dengan ❤️ agar tugasmu **_Nanti Juga Kelar!_**
