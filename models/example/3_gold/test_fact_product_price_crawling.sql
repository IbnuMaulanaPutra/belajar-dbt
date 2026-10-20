
select
    id as crawl_id,
    product_key,
    platform,
    store_name,
    price,
    original_price,
    discount,
    volume_ml,
    crawl_timestamp,
    source_url
from {{ ref('stg_product_crawling') }}
where price is not null
