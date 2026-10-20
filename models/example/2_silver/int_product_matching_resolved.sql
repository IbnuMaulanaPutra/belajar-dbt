
with products as (

    select *
    from {{ ref('int_product_matching_base') }}

),

seed_normalized as (

    select
        lower(trim(platform)) as platform,

        lower(
            trim(
                regexp_replace(
                    regexp_replace(
                        source_product_name,
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

        canonical_product_id,
        canonical_product_name

    from {{ ref('product_matching') }}

),

rule_based_products as (

    select
        rule_match_key,
        'exact_' || md5(rule_match_key) as canonical_product_id,
        min(product_name) as canonical_product_name,
        count(distinct platform) as platform_count

    from products
    where rule_match_key is not null
      and rule_match_key <> ''

    group by rule_match_key

),

matched as (

    select
        p.*,

        coalesce(
            s.canonical_product_id,
            r.canonical_product_id
        ) as canonical_product_id,

        coalesce(
            s.canonical_product_name,
            r.canonical_product_name,
            p.product_name
        ) as canonical_product_name,

        case
            when s.canonical_product_id is not null
                then 'mapping_seed'

            when r.platform_count >= 2
                then 'exact_normalized'

            when r.canonical_product_id is not null
                then 'single_platform'

            else 'unmatched'
        end as matching_method

    from products p

    left join seed_normalized s
        on p.platform = s.platform
       and p.normalized_product_name = s.normalized_product_name

    left join rule_based_products r
        on p.rule_match_key = r.rule_match_key

)

select *
from matched
