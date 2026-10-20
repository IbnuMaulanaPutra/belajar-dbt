{% snapshot snap_product_price %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='check',
        check_cols=['price', 'original_price']
    )
}}

select
    id,
    platform,
    store_name,
    product_name,
    price,
    original_price,
    crawl_timestamp
from {{ ref('src_product_crawling') }}

{% endsnapshot %}