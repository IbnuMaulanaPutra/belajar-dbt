
select
    product_key,
    count(*) as total_recommendations

from {{ ref('fct_price_recommendation') }}

group by product_key

having count(*) > 1
