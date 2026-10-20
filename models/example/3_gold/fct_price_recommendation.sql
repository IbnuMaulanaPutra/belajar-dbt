
{{ config(materialized='table') }}

with latest_date as (

    select max(full_date) as recommendation_date
    from {{ ref('dim_date') }}

),

candidates as (

    select
        f.product_key,
        f.platform_key,
        f.date_key,
        d.full_date as recommendation_date,
        f.price_amount as observed_price,

        row_number() over (
            partition by f.product_key
            order by
                f.price_amount asc,
                p.platform_name asc
        ) as recommendation_rank

    from {{ ref('fct_product_price_daily') }} f

    inner join {{ ref('dim_date') }} d
        on f.date_key = d.date_key

    inner join {{ ref('dim_platform') }} p
        on f.platform_key = p.platform_key

    cross join latest_date ld

    where d.full_date = ld.recommendation_date
      and f.price_amount is not null
      and f.price_amount > 0

)

select
    md5(
        product_key
        || '|'
        || recommendation_date::text
    ) as recommendation_key,

    product_key,
    platform_key,
    date_key,
    recommendation_date,
    observed_price as recommended_price,
    'lowest_observed_price' as recommendation_rule

from candidates
where recommendation_rank = 1
