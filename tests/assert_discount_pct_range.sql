with source_data as (
    select
        discount,
        replace(
            regexp_replace(
                discount,
                '[^0-9,.]',
                '',
                'g'
            ),
            ',',
            '.'
        ) as discount_clean
    from {{ ref('src_product_crawling') }}
),

parsed_data as (
    select
        discount,
        case
            when discount_clean ~ '^[0-9]+(\.[0-9]+)?$'
            then discount_clean::numeric
            else null
        end as discount_pct
    from source_data
)

select *
from parsed_data
where discount is not null
  and trim(discount) <> ''
  and (
      discount_pct is null
      or discount_pct < 0
      or discount_pct > 100
  )