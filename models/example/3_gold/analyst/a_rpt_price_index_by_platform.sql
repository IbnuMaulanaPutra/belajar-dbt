
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

comparable_prices as (
    select
        p.product_key,
        pl.platform_name,
        p.price_amount,
        avg(p.price_amount) over (
            partition by p.product_key
        ) as product_average_price
    from latest_prices p
    join {{ ref('dim_platform') }} pl
        on p.platform_key = pl.platform_key
),

platform_index as (
    select
        platform_name,
        count(*) as comparable_product_count,
        round(avg(price_amount), 2) as average_price,
        round(
            avg(price_amount / nullif(product_average_price, 0) * 100),
            2
        ) as price_index
    from comparable_prices
    group by platform_name
)

select
    platform_name,
    comparable_product_count,
    average_price,
    price_index,
    rank() over (order by price_index) as price_rank
from platform_index
