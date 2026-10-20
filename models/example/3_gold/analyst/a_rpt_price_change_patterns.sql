
with price_history as (
    select
        f.product_key,
        f.platform_key,
        f.price_amount,
        f.last_observed_at,
        lag(f.price_amount) over (
            partition by f.product_key, f.platform_key
            order by f.last_observed_at, f.date_key
        ) as previous_price
    from {{ ref('fct_product_price_daily') }} f
    where f.price_amount > 0
),

price_changes as (
    select
        product_key,
        platform_key,
        last_observed_at,
        price_amount,
        previous_price,
        case
            when previous_price is not null
                and price_amount <> previous_price
            then 1
            else 0
        end as price_changed,
        case
            when previous_price > 0
                and price_amount <> previous_price
            then
                100.0 * (price_amount - previous_price)
                / previous_price
            else null
        end as price_change_pct
    from price_history
    where previous_price is not null
),

weekday_summary as (
    select
        extract(isodow from last_observed_at)::int
            as weekday_number,
        trim(to_char(last_observed_at, 'Day'))
            as weekday_name,
        count(*) as price_comparisons,
        sum(price_changed) as price_change_count,
        round(
            100.0 * sum(price_changed) / nullif(count(*), 0),
            2
        ) as price_change_frequency_pct,
        round(avg(price_change_pct), 2)
            as avg_signed_change_pct,
        round(avg(abs(price_change_pct)), 2)
            as avg_absolute_change_pct
    from price_changes
    group by
        extract(isodow from last_observed_at)::int,
        trim(to_char(last_observed_at, 'Day'))
)

select *
from weekday_summary
order by weekday_number
