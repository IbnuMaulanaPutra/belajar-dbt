Teknologi yang digunakan dalam project ini

- python ini di project yg berbeda, jadi saya upload folder dbt saja
- sql server
- postgresql
- dbt
- power bi
- airflow untuk orkestrasi on progress

secara general project.
# python
1. mengambil data dari berbagai sumber kemudian di simpan ke table

# sql server
2. di table tersebut datanya akan append terus, jadi kita lakukan skema datalake ke staging datalake
dimana datalake asli akan terus append, kemudian saya gunakan procedure sql server untuk melakukan validasi dan merge data ke staging datalake agar tidak ada duplikat di staging data lake nya

# python
3. ambil data dari staging data lake sql server, lalu melakukan insert data ke postgresql raw.product_crawling, berdasarkan source_id, agar data yang sudah ada tidak perlu di insert/duplikat nantinya

# dbt skema raw-silver-gold
4. saya bikin 2 raw, yaitu berupa table dan view, tetapi saya gunakan view untuk seterusnya
5. untuk di skema silver, tidak terlalu banyak tranformasi, karena data nya sudah melalui proses
verifikasi dari sql server,dan python
6. jadi mostly akan lebih banyak di gold nya, di gold sendiri ada beberapa table yang saya buat
yaitu 
7. dim_date untuk grouping, detail, sama melihat tanggal berapa saja yang ada di transkasi product crawling itu.
8. dim platform isinya untuk meilhat dari platform apa saja data tersebut di ambil
9. fct product price daily, ini untuk melihat harga harian dari masing-masing product
10. fct price rekommendasi, ini untuk melihat harga yang kita sarankan di bawah haraga pasaran
11. untuk product matching based untuk melihat perbandingan harga barang yg sama tiap platform
12. untuk snapshot, untuk history perubahan saja

# dashboard power BI, paralel on progress

# untuk bathcing sudah run by scheduler task windows

# untuk API sudah

# orkestrasi pralel on progress