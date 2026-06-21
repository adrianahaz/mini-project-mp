# System Map - Student Task Manager

## Project Overview

Student Task Manager adalah aplikasi mobile berbasis Flutter yang membantu mahasiswa mengelola tugas kuliah, deadline, dan progres pengerjaan tugas secara terstruktur.

Aplikasi menggunakan:

- Flutter
- Cubit (State Management)
- SQLite (Local Database)

---

# User Role

## Mahasiswa

Mahasiswa dapat:

- Menambahkan tugas
- Mengubah data tugas
- Menghapus tugas
- Melihat daftar tugas
- Mengubah status tugas
- Melihat statistik tugas

---

# Feature Map

## Dashboard

Menampilkan:

- Total tugas
- Tugas selesai
- Tugas belum selesai
- Tugas mendekati deadline

### Actions

- Melihat ringkasan tugas
- Navigasi ke halaman lain

---

## Task Management

### Create Task

Input:

- Nama tugas
- Mata kuliah
- Deskripsi
- Deadline
- Prioritas

Output:

- Data tersimpan ke SQLite

---

### Read Task

Menampilkan:

- Daftar tugas
- Status tugas
- Prioritas
- Deadline

---

### Update Task

Mahasiswa dapat:

- Mengubah informasi tugas
- Mengubah deadline
- Mengubah prioritas

---

### Delete Task

Mahasiswa dapat:

- Menghapus tugas yang tidak diperlukan

---

## Task Status

Status yang tersedia:

- Belum Dimulai
- Sedang Dikerjakan
- Selesai

---

## Statistics

Menampilkan:

- Total tugas
- Persentase tugas selesai
- Persentase tugas belum selesai
- Jumlah tugas berdasarkan prioritas

---

# Database Structure

## Table: tasks

| Field       | Type    |
| ----------- | ------- |
| id          | INTEGER |
| title       | TEXT    |
| course      | TEXT    |
| description | TEXT    |
| priority    | TEXT    |
| status      | TEXT    |
| deadline    | TEXT    |
| created_at  | TEXT    |

---

# Application Architecture

```text
Presentation Layer
│
├── Pages
│   ├── DashboardPage
│   ├── TaskListPage
│   ├── AddTaskPage
│   ├── EditTaskPage
│   └── StatisticsPage
│
Business Logic Layer
│
├── TaskCubit
│
Data Layer
│
├── Models
│   └── TaskModel
│
├── Services
│   └── DatabaseService
│
└── SQLite
```

---

# Folder Structure

```text
lib/
│
├── cubit/
│   ├── task_cubit.dart
│   └── task_state.dart
│
├── models/
│   └── task_model.dart
│
├── services/
│   └── database_service.dart
│
├── pages/
│   ├── dashboard_page.dart
│   ├── task_list_page.dart
│   ├── add_task_page.dart
│   ├── edit_task_page.dart
│   └── statistics_page.dart
│
└── main.dart
```

---

# System Flow

1. Mahasiswa membuka aplikasi.
2. Dashboard menampilkan ringkasan tugas.
3. Mahasiswa menambahkan tugas baru.
4. Data disimpan ke SQLite.
5. TaskCubit memperbarui state aplikasi.
6. Daftar tugas diperbarui secara otomatis.
7. Mahasiswa dapat mengubah status tugas menjadi:
   - Belum Dimulai
   - Sedang Dikerjakan
   - Selesai

8. Statistik diperbarui berdasarkan data terbaru.

---

# Success Criteria

- Data tersimpan secara lokal menggunakan SQLite.
- State management menggunakan Cubit.
- Pengguna dapat melakukan CRUD tugas.
- Dashboard menampilkan ringkasan tugas.
- Statistik tugas ditampilkan dengan benar.
- Struktur project sesuai standar Flutter.
