with source_data as (
    select
        price,
        original_price,
        regexp_replace(price, '[^0-9]', '', 'g') as price_clean,
        regexp_replace(
            original_price,
            '[^0-9]',
            '',
            'g'
        ) as original_price_clean
    from {{ ref('src_product_crawling') }}
),

parsed_data as (
    select
        price,
        original_price,
        case
            when price_clean <> ''
            then price_clean::numeric
            else null
        end as price_amount,
        case
            when original_price_clean <> ''
            then original_price_clean::numeric
            else null
        end as original_price_amount
    from source_data
)

select *
from parsed_data
where price_amount is not null
  and original_price_amount is not null
  and price_amount > original_price_amount