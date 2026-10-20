
with source_data as (
    select
        id,
        category,
        product_name,
        original_price,
        discount,
        price,
        detail,
        platform,
        store_name,
        crawl_timestamp,
        crawled_by,
        source_url,
        crawler_version,
        source_id
    from {{ ref('src_product_crawling') }}
),

cleaned as (
    select
        *,
        lower(trim(product_name)) as product_name_clean,

        regexp_replace(
            lower(trim(product_name)),
            '[^a-z0-9]',
            '',
            'g'
        ) as product_key,

        nullif(
            regexp_replace(original_price, '[^0-9]', '', 'g'),
            ''
        )::numeric as original_price_num,

        nullif(
            regexp_replace(price, '[^0-9]', '', 'g'),
            ''
        )::numeric as price_num,

        nullif(
            regexp_replace(discount, '[^0-9]', '', 'g'),
            ''
        )::numeric as discount_pct,

        regexp_match(
            lower(coalesce(detail, '') || ' ' || product_name),
            '([0-9]+([.,][0-9]+)?)\s*(ml|l)'
        ) as unit_match

    from source_data
),

normalized as (
    select
        *,
        case
            when unit_match is null then null
            when unit_match[3] = 'l'
                then replace(unit_match[1], ',', '.')::numeric * 1000
            else replace(unit_match[1], ',', '.')::numeric
        end as volume_ml
    from cleaned
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by
                platform,
                store_name,
                product_key,
                crawl_timestamp
            order by id desc
        ) as row_num
    from normalized
)

select
    id,
    category,
    product_name,
    product_name_clean,
    product_key,
    original_price_num as original_price,
    discount_pct as discount,
    price_num as price,
    detail,
    volume_ml,
    platform,
    store_name,
    crawl_timestamp,
    crawled_by,
    source_url,
    crawler_version,
    source_id
from deduplicated
where row_num = 1
