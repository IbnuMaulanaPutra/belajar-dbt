{{ config(materialized='view') }}

select
    id,
    nullif(trim(category), '') as category,
    nullif(trim(product_name), '') as product_name,
    original_price,
    discount,
    price,
    detail,
    nullif(trim(platform), '') as platform,
    store_name,
    to_timestamp(crawl_timestamp, 'YYYY-MM-DD HH24:MI') as crawl_timestamp,
    crawled_by,
    nullif(trim(source_url), '') as source_url,
    crawler_version,
    source_id

from {{ source('raw', 'product_crawling') }}