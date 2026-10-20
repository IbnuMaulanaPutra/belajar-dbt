
{{ config(materialized='table') }}

with latest_date as (

    select max(d.full_date) as recommendation_date
    from {{ ref('fct_product_price_daily') }} f
    inner join {{ ref('dim_date') }} d
        on f.date_key = d.date_key
    where f.price_amount > 0

),

latest_prices as (

    select
        f.product_key,
        f.platform_key,
        f.date_key,
        d.full_date as recommendation_date,
        f.price_amount::numeric as observed_price,

        row_number() over (
            partition by f.product_key
            order by
                f.price_amount asc,
                p.platform_name asc
        ) as price_rank

    from {{ ref('fct_product_price_daily') }} f

    inner join {{ ref('dim_date') }} d
        on f.date_key = d.date_key

    inner join {{ ref('dim_platform') }} p
        on f.platform_key = p.platform_key

    cross join latest_date ld

    where d.full_date = ld.recommendation_date
      and f.price_amount > 0

),

product_stats as (

    select
        product_key,
        recommendation_date,

        percentile_cont(0.5)
            within group (order by observed_price)
            as competitor_median_price,

        min(observed_price) as lowest_observed_price

    from latest_prices

    group by
        product_key,
        recommendation_date

),

recommendations as (

    select
        s.product_key,
        lp.platform_key,
        lp.date_key,
        s.recommendation_date,
        s.competitor_median_price,
        s.lowest_observed_price,

        greatest(
            s.competitor_median_price * 0.95,
            s.lowest_observed_price * 0.95
        ) as recommended_price

    from product_stats s

    inner join latest_prices lp
        on s.product_key = lp.product_key
       and s.recommendation_date = lp.recommendation_date
       and lp.price_rank = 1

)

select
    md5(
        product_key::text
        || '|'
        || recommendation_date::text
    ) as recommendation_key,

    product_key,
    platform_key,
    date_key,
    recommendation_date,

    round(competitor_median_price::numeric, 2)
        as competitor_median_price,

    round(lowest_observed_price::numeric, 2)
        as lowest_observed_price,

    round(recommended_price::numeric, 2)
        as recommended_price,

    case
        when competitor_median_price * 0.95
             < lowest_observed_price * 0.95
            then 'median_minus_5pct_limited_by_price_floor'
        else 'competitor_median_minus_5pct'
    end as recommendation_rule,

    'pricing_v1' as model_version,

    current_timestamp as run_timestamp

from recommendations
