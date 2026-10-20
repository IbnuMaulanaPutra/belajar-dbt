# Dokumentasi Project Data Warehouse Produk dengan dbt Core

## 1. Deskripsi Project

Project `belajar_dbt` merupakan implementasi data transformation dan data modelling menggunakan **dbt Core dan PostgreSQL** untuk mengolah data hasil crawling produk dari berbagai platform e-commerce menjadi data warehouse yang terstruktur.

Project ini menggunakan arsitektur **Medallion Architecture**, yaitu Raw, Silver, dan Gold. Setiap layer memiliki tanggung jawab berbeda, mulai dari menyimpan data sumber, membersihkan dan menyamakan data produk, hingga menyediakan data analitik untuk perbandingan harga dan rekomendasi harga terbaik.

Project ini juga mengimplementasikan pendekatan product matching untuk mengidentifikasi produk yang sama meskipun memiliki penulisan nama yang berbeda pada platform yang berbeda.

### Tujuan project

- Membangun pipeline transformasi data menggunakan dbt Core.
- Memisahkan data berdasarkan layer Raw, Silver, dan Gold.
- Membersihkan dan menormalisasi data hasil crawling.
- Menyamakan identitas produk lintas platform melalui product matching.
- Membangun dimensional data warehouse menggunakan star schema.
- Menyediakan fact table untuk analisis harga harian dan rekomendasi harga.
- Memvalidasi kualitas, konsistensi, dan hubungan antardata menggunakan dbt tests.
- Menerapkan konsep data lakehouse melalui pemetaan arsitektur Medallion ke teknologi seperti Apache Iceberg dan Delta Lake.

---

## 2. Teknologi yang Digunakan

| Teknologi | Fungsi |
|---|---|
| Python | Bahasa pemrograman untuk lingkungan kerja dan pengembangan |
| dbt Core 1.11.12 | Mengelola transformasi SQL, model, dependensi, dan pengujian data |
| dbt-postgres 1.11.0 | Adapter untuk menghubungkan dbt dengan PostgreSQL |
| PostgreSQL | Database sumber dan penyimpanan hasil transformasi data warehouse |
| SQL | Bahasa utama untuk transformasi dan analisis data |
| dbt-utils 1.4.1 | Paket macro dan utilitas tambahan untuk transformasi serta pengujian |
| YAML | Konfigurasi project, source, dan pengujian dbt |
| CSV seed | Menyimpan pemetaan produk yang telah ditentukan secara manual |

Versi di atas mengacu pada lingkungan pengembangan yang digunakan selama pengerjaan project.

---

## 3. Arsitektur Data

Project menerapkan arsitektur Medallion dengan tiga layer utama.

```text
Data Crawling
     |
     v
+---------------------------+
|       RAW LAYER           |
| Data sumber               |
| product_crawling          |
+---------------------------+
     |
     v
+---------------------------+
|      SILVER LAYER         |
| Data cleansing            |
| Price normalization      |
| Product normalization    |
| Deduplication             |
| Product matching          |
+---------------------------+
     |
     v
+---------------------------+
|       GOLD LAYER          |
| dim_product_master        |
| dim_platform              |
| dim_date                  |
| fct_product_price_daily   |
| fct_price_recommendation  |
+---------------------------+
     |
     v
Analisis Harga dan
Rekomendasi Produk
```

### 3.1 Raw Layer

Raw layer berfungsi sebagai lapisan penyimpanan data sumber sebelum transformasi bisnis dilakukan.

Source yang digunakan adalah tabel `raw.product_crawling` di PostgreSQL.

Karakteristik raw layer:

- Menyimpan data hasil crawling dari berbagai platform.
- Mempertahankan data sumber sebagai acuan proses transformasi.
- Tidak melakukan transformasi bisnis yang kompleks.
- Menjadi titik awal dependensi model dbt.
- Menggunakan konfigurasi source freshness untuk memantau keterbaruan data.

Pembersihan harga, pencocokan produk, dan pembentukan dimensi tidak dilakukan di layer ini.

### 3.2 Silver Layer

Silver layer berfungsi mengubah data mentah menjadi data yang lebih bersih, konsisten, dan siap digunakan oleh model analitik.

Proses utamanya meliputi:

1. Normalisasi format harga.
2. Pembersihan nilai kosong dan data yang tidak valid.
3. Normalisasi nama produk dan atributnya.
4. Ekstraksi informasi ukuran atau volume produk.
5. Identifikasi produk duplikat.
6. Pencocokan produk berdasarkan aturan dan kemiripan nama.
7. Penyelesaian identitas produk berdasarkan hasil pencocokan.

Silver layer menjadi tempat utama untuk memastikan bahwa data dari berbagai platform dapat dibandingkan secara konsisten.

### 3.3 Gold Layer

Gold layer menyediakan model data yang sudah disesuaikan untuk kebutuhan analisis bisnis.

Layer ini menggunakan pendekatan dimensional modelling dengan tabel dimensi dan tabel fakta.

Hasil akhirnya digunakan untuk:

- Membandingkan harga produk lintas platform.
- Menganalisis perubahan harga harian.
- Mengidentifikasi platform dengan harga terendah.
- Menghitung median harga kompetitor.
- Menghasilkan rekomendasi harga berdasarkan data terbaru.

---

## 4. Struktur Project

Lokasi project pada lingkungan pengembangan:

```text
E:\DataEngineer\DBT\belajar_dbt
```

Struktur konseptual project:

```text
belajar_dbt/
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
├── models/
│   └── example/
│       ├── 1_raw/
│       │   └── sources.yml
│       ├── 2_silver/
│       │   ├── stg_product_crawling.sql
│       │   ├── int_product_matching_base.sql
│       │   ├── int_product_matching_fuzzy_candidates.sql
│       │   └── int_product_matching_resolved.sql
│       └── 3_gold/
│           ├── dim_product_master.sql
│           ├── dim_platform.sql
│           ├── dim_date.sql
│           ├── fct_product_price_daily.sql
│           └── fct_price_recommendation.sql
├── seeds/
│   └── product_matching.csv
├── macros/
│   └── generate_schema_name.sql
├── tests/
└── README.md
```

Struktur di atas menggambarkan komponen utama yang dibahas selama pengembangan. Nama dan lokasi beberapa file dapat berbeda dari implementasi aktual. Folder `tests/` juga dapat digunakan untuk pengujian SQL khusus jika diperlukan.

---

## 5. Konfigurasi Project dbt

### 5.1 dbt_project.yml

File `dbt_project.yml` menjadi konfigurasi utama project dbt, termasuk nama project, direktori model, seed, macro, dan pengaturan materialisasi.

Project menggunakan nama:

```yaml
name: belajar_dbt
```

Pengaturan materialisasi model dapat disesuaikan dengan kebutuhan setiap layer, misalnya view untuk staging atau table untuk model analitik yang perlu disimpan secara fisik.

### 5.2 Koneksi PostgreSQL

Konfigurasi koneksi disimpan dalam file `profiles.yml`, yang pada lingkungan pengembangan berada di direktori:

```text
C:\Users\ibnu.putra\.dbt\profiles.yml
```

Profil yang digunakan:

- Profile: `belajar_dbt`
- Target: `dev`
- Adapter: `postgres`
- Database: `postgres`

Contoh struktur konfigurasi profil:

```yaml
belajar_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: postgres
      password: "{{ env_var('DBT_ENV_SECRET_PASSWORD') }}"
      port: 5432
      dbname: postgres
      schema: raw
      threads: 1
```

**Catatan:** Contoh tersebut merupakan template. Host, port, metode penyimpanan kredensial, dan schema harus disesuaikan dengan konfigurasi PostgreSQL aktual. Jangan menyimpan password asli di repository Git.

### 5.3 Pengaturan schema

Project menggunakan macro `generate_schema_name` untuk menentukan schema tujuan model.

Secara konseptual, macro tersebut mempertahankan nama schema yang ditentukan secara eksplisit oleh model, sehingga hasil transformasi dapat ditempatkan di schema masing-masing layer.

Contoh pemetaan:

| Layer | Schema tujuan |
|---|---|
| Raw | `raw` |
| Silver | `silver` |
| Gold | `gold` |

Pemisahan ini mempermudah pengelolaan dependensi, validasi, dan pemeliharaan model data warehouse.

### 5.4 Paket dbt

Project menggunakan `dbt_utils` versi `1.4.1` untuk mendukung fungsi tambahan dalam pengembangan model dan pengujian data.

Paket dikelola melalui `packages.yml` dan diinstal menggunakan:

```bash
dbt deps
```

---

## 6. Source Data dan Source Freshness

Source utama project adalah tabel `product_crawling` di schema `raw`.

Source ini berisi data hasil crawling produk dari beberapa platform.

Atribut yang digunakan dalam proses transformasi mencakup:

- Identitas data sumber.
- Kategori produk.
- Nama produk.
- Harga awal.
- Diskon.
- Harga setelah diskon.
- Detail produk.
- Platform.
- Nama toko.
- Waktu crawling.
- URL sumber.

Daftar kolom tersebut merupakan gambaran atribut source yang digunakan dalam pipeline; kolom yang tersedia harus mengikuti skema tabel aktual.

### Source freshness

Project menggunakan source freshness untuk memantau apakah data crawling masih diperbarui sesuai jadwal yang diharapkan.

Konfigurasi yang telah dibahas menggunakan:

- `loaded_at_field` berbasis `crawl_timestamp`.
- Format timestamp `YYYY-MM-DD HH24:MI`.
- Batas peringatan 24 jam.
- Batas error 48 jam.

Contoh konfigurasi konseptual:

```yaml
version: 2

sources:
  - name: raw
    schema: raw
    tables:
      - name: product_crawling
        loaded_at_field: "to_timestamp(crawl_timestamp, 'YYYY-MM-DD HH24:MI')"
        freshness:
          warn_after:
            count: 24
            period: hour
          error_after:
            count: 48
            period: hour
```

Konfigurasi ini sesuai untuk source dengan `crawl_timestamp` bertipe teks menggunakan format yang telah disepakati.

Pemeriksaan dilakukan dengan:

```bash
dbt source freshness
```

Status freshness yang berhasil menunjukkan bahwa source dapat diperiksa berdasarkan konfigurasi tersebut. Namun, status itu tidak dengan sendirinya menjamin bahwa seluruh data bisnis sudah benar.

---

## 7. Transformasi Silver Layer

### 7.1 Staging product crawling

Model `stg_product_crawling` menjadi tahap awal transformasi source.

Tanggung jawab model ini meliputi:

- Membersihkan format harga.
- Menormalkan atribut produk.
- Mengonversi nilai yang sesuai menjadi tipe data yang tepat.
- Menyiapkan atribut untuk proses pencocokan produk.
- Menyediakan struktur data konsisten untuk model berikutnya.

### 7.2 Normalisasi harga

Data crawling dapat menyimpan harga sebagai teks, misalnya:

```text
Rp. 25.000
Rp 25.000
```

Nilai tersebut perlu dibersihkan sebelum dikonversi menjadi tipe numerik.

Tujuannya adalah agar harga dapat dibandingkan, dihitung median-nya, dan digunakan dalam analisis tanpa terpengaruh format mata uang.

Nilai harga yang tidak valid perlu ditangani secara eksplisit agar tidak menghasilkan angka yang salah.

### 7.3 Normalisasi ukuran produk

Ukuran produk merupakan salah satu atribut penting untuk menentukan apakah dua nama produk merujuk pada produk yang sama.

Contoh variasi penulisan:

```text
produk abc 500 ml
produk abc 0.5 l
```

Kedua penulisan dapat merujuk pada ukuran volume yang sama setelah dikonversi ke satuan standar.

Normalisasi ukuran membantu menghindari pencocokan yang keliru antara produk dengan nama mirip tetapi ukuran berbeda.

### 7.4 Deduplikasi

Deduplikasi digunakan untuk mencegah baris berulang masuk ke model analitik.

Strategi deduplikasi perlu mempertimbangkan grain setiap model. Dua data crawling yang memiliki produk, platform, dan tanggal yang sama belum tentu identik dalam seluruh atribut.

Karena itu, aturan deduplikasi harus ditentukan berdasarkan kebutuhan bisnis dan kunci unik model, bukan hanya berdasarkan kemiripan nama produk.

---

## 8. Product Matching

Product matching merupakan bagian penting dari project karena satu produk dapat memiliki nama berbeda pada platform yang berbeda.

Project menggunakan kombinasi pendekatan berbasis aturan, fuzzy matching, dan pemetaan manual.

### 8.1 Rule-based matching

Pendekatan ini menggunakan aturan untuk menyamakan atribut produk, seperti:

- Nama produk yang telah dinormalisasi.
- Brand atau merek.
- Ukuran atau volume.
- Atribut pembeda lainnya yang tersedia.

Pencocokan berdasarkan aturan dapat memberikan hasil yang lebih konsisten untuk variasi nama yang sudah diketahui.

### 8.2 Fuzzy matching

Fuzzy matching digunakan untuk mencari kandidat produk dengan tingkat kemiripan nama yang tinggi meskipun teksnya tidak identik.

Contohnya, variasi penulisan nama atau singkatan dapat menghasilkan kandidat yang layak diperiksa.

Fuzzy matching tidak otomatis menjamin bahwa dua produk benar-benar sama. Karena itu, hasilnya perlu mempertimbangkan ukuran, merek, dan atribut lain sebelum identitas produk ditetapkan.

### 8.3 Mapping seed

File seed `product_matching.csv` digunakan untuk menyimpan pemetaan produk yang sudah ditentukan.

Seed membantu memastikan bahwa variasi nama produk tertentu secara konsisten diarahkan ke identitas produk kanonis yang sama.

Keuntungan pendekatan ini adalah:

- Pemetaan dapat ditinjau dan diperbarui secara eksplisit.
- Keputusan bisnis tidak sepenuhnya bergantung pada algoritma kemiripan.
- Produk yang sudah dipetakan dapat diproses secara konsisten pada build berikutnya.

### 8.4 Model product matching

Model yang digunakan dalam proses ini mencakup:

| Model | Fungsi |
|---|---|
| `int_product_matching_base` | Menyiapkan data dan atribut dasar untuk pencocokan |
| `int_product_matching_fuzzy_candidates` | Menghasilkan kandidat berdasarkan kemiripan produk |
| `int_product_matching_resolved` | Menentukan hasil pencocokan produk yang telah diselesaikan |

Alur konseptualnya:

```text
Staging Product
      |
      v
Matching Base
      |
      v
Fuzzy Candidates
      |
      v
Mapping dan Aturan
      |
      v
Resolved Product
      |
      v
Gold Product Dimension
```

Hasil akhir yang diharapkan adalah setiap produk yang berhasil dicocokkan memiliki identitas produk kanonis yang konsisten.

Produk yang belum dapat dicocokkan dengan keyakinan memadai sebaiknya ditandai untuk peninjauan, bukan dipaksakan menjadi produk yang sama.

---

## 9. Gold Layer dan Dimensional Modelling

Gold layer dirancang untuk mendukung analisis harga produk dengan pendekatan star schema.

### 9.1 `dim_product_master`

Dimensi produk kanonis.

Informasi yang diharapkan mencakup:

- Identitas produk kanonis.
- Nama produk kanonis.
- Kategori.
- Brand.
- Ukuran atau volume produk.

Dimensi ini menyatukan identitas produk dari berbagai platform sehingga perbandingan harga dilakukan pada produk yang sama.

### 9.2 `dim_platform`

Dimensi platform yang menyimpan identitas platform e-commerce.

Dimensi ini digunakan untuk mengelompokkan dan membandingkan harga berdasarkan platform.

### 9.3 `dim_date`

Dimensi tanggal yang menyediakan identitas tanggal dan atribut kalender untuk analisis harga harian.

Dimensi ini membantu analisis tren harga berdasarkan hari atau periode waktu lain yang didukung oleh atributnya.

### 9.4 `fct_product_price_daily`

Fact table untuk menyimpan informasi harga produk berdasarkan platform dan tanggal.

Grain yang dituju adalah:

**Satu baris untuk setiap kombinasi produk kanonis, platform, dan tanggal.**

Dengan grain tersebut, model dapat digunakan untuk:

- Membandingkan harga antarplatform.
- Menganalisis perubahan harga dari waktu ke waktu.
- Menghitung statistik harga produk.
- Mengidentifikasi harga terendah berdasarkan periode tertentu.

Grain ini perlu dijaga dengan pengujian kombinasi kunci unik.

### 9.5 `fct_price_recommendation`

Fact table untuk menyimpan rekomendasi harga berdasarkan data harga produk terbaru yang tersedia.

Logika bisnis yang telah dibahas mencakup:

- Mengambil data terbaru untuk setiap produk.
- Membandingkan harga lintas platform.
- Menggunakan median harga kompetitor sebagai salah satu metrik.
- Memilih platform dengan harga terendah.
- Menangani kondisi harga yang sama melalui aturan pemilihan yang konsisten, termasuk prioritas nama platform sebagai pemecah seri.

Detail perhitungan, filter, dan pemecah seri harus mengikuti implementasi SQL aktual.

### Relasi star schema

```text
               dim_date
                  |
                  |
dim_product_master -- fct_product_price_daily -- dim_platform
                  |
                  |
          fct_price_recommendation
```

Diagram tersebut menggambarkan konsep dimensi dan fakta, bukan definisi lengkap foreign key. Relasi aktual harus mengikuti kolom kunci yang tersedia dalam model.

---

## 10. Data Quality dan Pengujian

Pengujian data merupakan bagian dari pipeline dbt untuk memastikan hasil transformasi memenuhi aturan yang diharapkan.

Jenis validasi yang digunakan atau dibahas dalam project meliputi:

### 10.1 Source freshness

Memastikan data sumber diperbarui dalam rentang waktu yang diharapkan.

```bash
dbt source freshness
```

### 10.2 Unique test

Memastikan nilai pada kolom kunci tidak berulang.

Contohnya, identitas produk kanonis harus unik dalam dimensi produk.

### 10.3 Not null test

Memastikan kolom penting, seperti kunci produk dan kunci platform, tidak memiliki nilai kosong.

### 10.4 Relationships test

Memastikan nilai foreign key pada fact table memiliki pasangan pada tabel dimensi terkait.

Contohnya, produk yang digunakan pada fact harga harian harus tersedia pada dimensi produk.

### 10.5 Validasi grain fact table

Memastikan tidak terdapat lebih dari satu baris untuk kombinasi produk, platform, dan tanggal yang sama pada fact harga harian.

### 10.6 Validasi rekomendasi harga

Memastikan rekomendasi menggunakan data terbaru sesuai aturan model dan memilih platform berdasarkan logika harga yang ditentukan.

### 10.7 Validasi hasil build

Selama pengembangan, project telah menjalani build selektif untuk model Silver dan Gold serta serangkaian data tests. Sejumlah pengujian dilaporkan berhasil.

Hasil tersebut merupakan catatan perkembangan saat pengujian dilakukan, bukan jaminan bahwa semua pengujian akan selalu lolos setelah perubahan kode atau source.

---

## 11. Cara Menjalankan Project

Jalankan perintah berikut melalui terminal pada direktori project:

```powershell
cd E:\DataEngineer\DBT\belajar_dbt
```

Aktifkan virtual environment apabila belum aktif:

```powershell
.\venv_dbt\Scripts\Activate.ps1
```

Lokasi virtual environment dapat berbeda jika dibuat di luar direktori project.

### 11.1 Memeriksa koneksi

```bash
dbt debug
```

Perintah ini memeriksa konfigurasi project dan koneksi database.

### 11.2 Menginstal dependency

```bash
dbt deps
```

### 11.3 Memeriksa keterbaruan source

```bash
dbt source freshness
```

### 11.4 Menjalankan seluruh model dan pengujian

```bash
dbt build
```

Perintah tersebut menjalankan resource yang termasuk dalam build project, dengan memperhatikan dependensi dan konfigurasi masing-masing resource.

### 11.5 Menjalankan model Silver dan Gold

```bash
dbt build --select path:models/example/2_silver path:models/example/3_gold
```

Perintah ini sesuai untuk menjalankan model dan pengujian pada kedua direktori tersebut.

Jika ingin menjalankan pengujian saja:

```bash
dbt test
```

Jika ingin membuat dokumentasi dbt:

```bash
dbt docs generate
```

Untuk melihat dokumentasi melalui server lokal:

```bash
dbt docs serve
```

Perintah terakhir menjalankan server dokumentasi lokal sesuai konfigurasi dbt.

---

## 12. Full Refresh dan Perubahan Model

Full refresh dapat diperlukan ketika perubahan model mengharuskan data materialisasi dibangun kembali, misalnya setelah mengubah logika product matching atau grain fact table.

Untuk membangun ulang model Silver dan Gold yang terdampak beserta pengujian yang relevan, salah satu perintah yang dapat digunakan adalah:

```bash
dbt build --full-refresh --select path:models/example/2_silver path:models/example/3_gold
```

**Perhatian:** `--full-refresh` terutama memengaruhi model incremental. Model view dan table biasa memiliki perilaku materialisasi masing-masing. Pastikan model yang dipilih memang boleh dibangun ulang dan periksa dampaknya sebelum menjalankan perintah tersebut pada lingkungan yang berisi data penting.

Setelah full refresh, validasi kembali:

1. Jumlah baris model.
2. Keunikan grain fact table.
3. Ketersediaan seluruh foreign key.
4. Konsistensi identitas produk kanonis.
5. Ketepatan tanggal dan harga rekomendasi.
6. Hasil seluruh dbt tests.

---

## 13. Integrasi dengan Konsep Data Lakehouse

Walaupun project saat ini menggunakan PostgreSQL sebagai database, arsitekturnya dapat dipetakan ke konsep data lakehouse.

| Layer | Implementasi saat ini | Pemetaan konseptual lakehouse |
|---|---|---|
| Raw | Tabel source PostgreSQL | Bronze |
| Silver | Model staging dan intermediate dbt | Silver |
| Gold | Dimensi dan fact table dbt | Gold |
| Penyimpanan | PostgreSQL | Dapat menggunakan Apache Iceberg atau Delta Lake pada arsitektur lakehouse |

Pemetaan ini bersifat konseptual. Project saat ini tidak otomatis menggunakan Iceberg atau Delta Lake hanya karena menerapkan arsitektur Medallion.

Apabila nantinya dipindahkan ke lakehouse, penyesuaian dapat mencakup adapter dbt, engine SQL, format tabel, strategi incremental processing, dan mekanisme penyimpanan.

---

## 14. Pengembangan Selanjutnya

Beberapa pengembangan yang relevan untuk project ini:

1. Memperluas pemetaan produk kanonis untuk meningkatkan akurasi product matching.
2. Menentukan ambang kemiripan fuzzy matching berdasarkan evaluasi hasil yang benar dan salah.
3. Menambahkan penanganan eksplisit untuk produk yang belum berhasil dicocokkan.
4. Memperketat pengujian grain dan foreign key pada setiap fact table.
5. Menambahkan dokumentasi kolom dan deskripsi bisnis melalui file YAML dbt.
6. Mengotomatiskan eksekusi pipeline serta pemeriksaan freshness.
7. Mempertimbangkan model incremental jika volume data terus meningkat.
8. Mengembangkan dokumentasi lineage melalui dbt docs.
9. Menyusun strategi penanganan data historis ketika source berubah atau data crawling terlambat masuk.

---

## 15. Kesimpulan

Project `belajar_dbt` membangun fondasi data warehouse produk dengan memisahkan data sumber, transformasi, dan penyajian analitik ke dalam layer Raw, Silver, dan Gold.

Penggunaan dbt Core membantu mengelola dependensi SQL, transformasi data, konfigurasi source, serta pengujian kualitas data. Product matching menjadi komponen penting agar perbandingan harga lintas platform dilakukan terhadap produk yang sama, sementara dimensional modelling menyediakan struktur analitik untuk harga harian dan rekomendasi harga.

Dengan dokumentasi, pengujian, dan pemeliharaan model yang konsisten, project ini dapat dikembangkan menjadi pipeline data yang lebih andal dan menjadi fondasi untuk integrasi lakehouse pada tahap berikutnya.

---

## Catatan Konfigurasi

Sebelum README ini digunakan sebagai dokumentasi final repository, sesuaikan kembali:

- Struktur direktori dengan file project aktual.
- Host, port, dan schema koneksi PostgreSQL.
- Nama kolom serta definisi source yang sebenarnya.
- Definisi grain, kunci, dan relasi dari SQL model terbaru.
- Aturan perhitungan rekomendasi harga.
- Hasil pengujian terakhir setelah perubahan kode.

