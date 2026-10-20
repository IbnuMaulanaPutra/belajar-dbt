
select distinct
    platform,
    platform as platform_name
from {{ ref('stg_product_crawling') }}
where platform is not null
