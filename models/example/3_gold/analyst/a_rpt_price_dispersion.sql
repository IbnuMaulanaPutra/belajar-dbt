
with ranked_prices as (
    select
        f.product_key,
        f.platform_key,
        f.price_amount,
        f.last_observed_at,
        row_number() over (
            partition by f.product_key, f.platform_key
            order by f.last_observed_at desc, f.date_key desc
        ) as rn
    from {{ ref('fct_product_price_daily') }} f
    where f.price_amount > 0
),

latest_prices as (
    select
        product_key,
        platform_key,
        price_amount
    from ranked_prices
    where rn = 1
),

product_dispersion as (
    select
        p.product_key,
        p.product_name,
        p.category,
        count(distinct f.platform_key) as platform_count,
        min(f.price_amount) as min_price,
        max(f.price_amount) as max_price,
        max(f.price_amount) - min(f.price_amount)
            as price_spread,
        avg(f.price_amount) as avg_price
    from latest_prices f
    join {{ ref('dim_product_master') }} p
        on f.product_key = p.product_key
    group by
        p.product_key,
        p.product_name,
        p.category
    having count(distinct f.platform_key) >= 2
)

select
    product_key,
    product_name,
    category,
    platform_count,
    min_price,
    max_price,
    price_spread,
    round(
        100.0 * price_spread / nullif(avg_price, 0),
        2
    ) as dispersion_pct
from product_dispersion
order by price_spread desc
