teknologi yang digunakan
- python ini berbeda folder project, jadi saya upload dbt nya
- sql server
- potsgresql
- power bi

general end to end project

1. data raw from data dummy python script, karena crawling data nya kena proteksi
2. setelah dapat data dummy nya, simapn di sql server, di sql server saya gunakan datalake dan staging lake, staging lake ini isinya adalah data yang tdak duplikat, karena data dummy atau crawling bisa terjadi duplikat, saya gunakan procedure untuk validasi data tersebut ke staging
3. setelah dari staging, gunakan python untuk memindahkan data ke pgsql, ada validasi juga di script python, agar data yang sama tidak masuk lagi
4. di dbt menggunakan skema raw,silver,gold
5. karena raw sudah ada di pgsql, jdi tdk crate lgi,
6. silver ini digunakan untuk parsing , cleanse,deduplicate, tetapi karena sudah di bantu dri validasi sp jadi lebih dimudahkan pembuatan stg silver ini
7. gold, ini ada pembuatan master dari data -data tersebut.
8. hasil table gold digunakan sebagai source dashboard power bi
9. gold, digunakan juga sebagai bahan untuk API python