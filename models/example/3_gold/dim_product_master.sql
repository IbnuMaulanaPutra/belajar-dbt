
{{ config(materialized='table') }}

with source_data as (

    select
        canonical_product_id,
        canonical_product_name,
        trim(category) as category,

        nullif(
            (
                regexp_match(
                    lower(canonical_product_name),
                    '([0-9]+([.][0-9]+)?[[:space:]]*(ml|kg|mg|g|l|pcs|pack|tablet))'
                )
            )[1],
            ''
        ) as pack_size

    from {{ ref('int_product_matching_resolved') }}

    where canonical_product_id is not null

),

deduplicated as (

    select
        canonical_product_id,
        min(canonical_product_name) as product_name,
        min(category) as category,
        min(pack_size) as pack_size

    from source_data

    group by canonical_product_id

),

final as (

    select
        md5(canonical_product_id) as product_key,
        canonical_product_id,
        product_name,
        category,
        split_part(product_name, ' ', 1) as brand,
        pack_size,
        lower(trim(product_name)) as normalized_product_name

    from deduplicated

)

select *
from final
