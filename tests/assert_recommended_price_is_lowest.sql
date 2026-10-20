
with latest_date as (

    select max(date_key) as date_key
    from {{ ref('fct_product_price_daily') }}

),

expected_prices as (

    select
        f.product_key,
        min(f.price_amount) as lowest_price

    from {{ ref('fct_product_price_daily') }} f

    inner join latest_date ld
        on f.date_key = ld.date_key

    where f.price_amount > 0

    group by f.product_key

)

select
    r.product_key,
    r.recommended_price,
    e.lowest_price

from {{ ref('fct_price_recommendation') }} r

inner join expected_prices e
    on r.product_key = e.product_key

where r.recommended_price <> e.lowest_price
