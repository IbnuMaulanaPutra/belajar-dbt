
{{ config(materialized='table') }}

select
    md5(lower(trim(platform))) as platform_key,
    lower(trim(platform)) as platform_name
from {{ ref('stg_product_crawling') }}
where platform is not null
group by lower(trim(platform))
