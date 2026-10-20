teknologi yang digunakan
- python ini berbeda folder project, jadi saya upload dbt nya
- sql server
- potsgresql
- power bi paralel on progress

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

# lineage dbt
raw.product_crawling
    |
    v
stg_product_crawling
    |
    v
int_product_matching_base
    |
    v
int_product_matching_fuzzy_candidates
    |
    v
int_product_matching_resolved
    |
    +--> dim_product_master
    |
    +--> dim_platform
    |
    +--> dim_date
    |
    v
fct_product_price_daily
    |
    +--> fct_price_recommendation
    |
    +--> a_rpt_price_index_by_platform
    |
    +--> a_rpt_discount_analysis
    |
    +--> a_rpt_price_dispersion
    |
    +--> a_rpt_price_change_patterns
# note AI:
secara general semua tools ini baru saya pakai dan pelajari, seperti pertemuan awal,
secara general project saya sudah memahami end to end nya, dan secara implementasi masih di bantu AI

python script APi, dummy data
konsep atau struktur folder penggunaan dbt.
power BI AI instruktor cara penggunaannya.
penggunaan git,


# untuk kedepannya mungkin ada banyak tambahan dri kondisi saat ini:

untuk analytic yg lebih kompleks ini terbatar dari sumber datanya,
saya juga tidak membuat master brand, agar misalnya bisa lebih kompleks,
ketika ingin membuat sebuah master data yang lebih rapih,
jadi nantinya bisa ada table barang per category per brand dll
bisa per category per platform dan per storname, jadi bisa lihat toko tersebut berjualan di category product apa misalnya.
