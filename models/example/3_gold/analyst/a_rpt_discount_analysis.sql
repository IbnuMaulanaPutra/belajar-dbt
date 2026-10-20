
with discount_base as (
    select
        p.category,
        pl.platform_name,
        f.price_amount,
        f.original_price_amount,
        case
            when f.original_price_amount > f.price_amount
                then 1
            else 0
        end as is_discounted,
        case
            when f.original_price_amount > 0
                and f.original_price_amount > f.price_amount
            then
                (f.original_price_amount - f.price_amount)
                / f.original_price_amount * 100.0
            else null
        end as discount_pct
    from {{ ref('fct_product_price_daily') }} f
    join {{ ref('dim_product_master') }} p
        on f.product_key = p.product_key
    join {{ ref('dim_platform') }} pl
        on f.platform_key = pl.platform_key
    where f.price_amount > 0
),

discount_summary as (
    select
        category,
        platform_name,
        count(*) as total_price_observations,
        sum(is_discounted) as discounted_observations,
        round(
            100.0 * sum(is_discounted)
            / nullif(count(*), 0),
            2
        ) as discount_frequency_pct,
        round(avg(discount_pct), 2)
            as avg_discount_pct_when_discounted,
        round(max(discount_pct), 2)
            as max_discount_pct
    from discount_base
    group by category, platform_name
)

select *
from discount_summary
order by category, discount_frequency_pct desc
