with products as (

    select distinct
        platform,
        product_name,
        category,
        normalized_product_name,
        rule_match_key

    from {{ ref('int_product_matching_base') }}

),

candidate_pairs as (

    select
        a.platform as platform_a,
        a.product_name as product_name_a,
        b.platform as platform_b,
        b.product_name as product_name_b,

        a.normalized_product_name as normalized_name_a,
        b.normalized_product_name as normalized_name_b,

        similarity(
            a.normalized_product_name,
            b.normalized_product_name
        ) as similarity_score

    from products a

    join products b
        on a.platform < b.platform
       and a.category = b.category
       and a.normalized_product_name
           <> b.normalized_product_name

)

select *
from candidate_pairs
where similarity_score >= 0.35
order by similarity_score desc