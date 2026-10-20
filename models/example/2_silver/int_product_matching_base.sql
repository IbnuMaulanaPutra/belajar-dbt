with source_data as (

    select
        id as source_product_id,
        lower(trim(platform)) as platform,
        product_name,
        category,

        lower(
            trim(
                regexp_replace(
                    regexp_replace(
                        product_name,
                        '[^a-zA-Z0-9]+',
                        ' ',
                        'g'
                    ),
                    '[[:space:]]+',
                    ' ',
                    'g'
                )
            )
        ) as normalized_product_name,

        lower(
            trim(
                regexp_replace(
                    regexp_replace(
                        product_name,
                        '[^a-zA-Z0-9]+',
                        ' ',
                        'g'
                    ),
                    '[[:space:]]+',
                    ' ',
                    'g'
                )
            )
        ) as rule_match_key

    from {{ ref('stg_product_crawling') }}

    where product_name is not null

)

select *
from source_data