
with ranked_products as (
    select
        product_key,
        product_name_clean as product_name,
        category,
        volume_ml,
        row_number() over (
            partition by product_key
            order by id desc
        ) as row_num
    from {{ ref('stg_product_crawling') }}
)

select
    product_key,
    product_name,
    category,
    volume_ml
from ranked_products
where row_num = 1
