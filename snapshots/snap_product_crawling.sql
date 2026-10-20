{% snapshot snap_product_crawling %}

{{
    config(
        target_schema='snapshots',
        unique_key='id',
        strategy='check',
        check_cols=[
            'product_name',
            'category',
            'original_price'
        ]
    )
}}

select
    id,
    product_name,
    category,
    original_price,
    platform,
    store_name
from {{ ref('src_product_crawling') }}

{% endsnapshot %}