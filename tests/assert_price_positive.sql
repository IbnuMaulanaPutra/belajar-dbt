select *
from {{ ref('fct_product_price_daily') }}
where price_amount is not null
  and price_amount <= 0