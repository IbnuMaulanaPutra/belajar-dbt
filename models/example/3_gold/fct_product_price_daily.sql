
{{ config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['product_key', 'platform_key', 'date_key']
) }}

with source_data as (

    select
        s.id,
        m.canonical_product_id,
        s.product_name,
        s.platform,
        s.crawl_timestamp::timestamp as crawled_at,

        nullif(
            regexp_replace(s.price::text, '[^0-9]', '', 'g'),
            ''
        )::numeric as price_amount,

        nullif(
            regexp_replace(s.original_price::text, '[^0-9]', '', 'g'),
            ''
        )::numeric as original_price_amount,

        s.source_url,
        s.store_name

    from {{ ref('stg_product_crawling') }} s

    inner join {{ ref('int_product_matching_resolved') }} m
        on s.id = m.source_product_id

    where s.product_name is not null
      and s.platform is not null
      and s.crawl_timestamp is not null
      and m.canonical_product_id is not null

      {% if is_incremental() %}
      and s.crawl_timestamp::timestamp >= (
          select
              coalesce(max(last_observed_at)::date, date '1900-01-01') - 3
          from {{ this }}
      )
      {% endif %}

),

keyed as (

    select
        md5(canonical_product_id) as product_key,
        md5(lower(trim(platform))) as platform_key,
        to_char(crawled_at::date, 'yyyymmdd')::integer as date_key,

        id,
        crawled_at,
        price_amount,
        original_price_amount,
        source_url,
        store_name

    from source_data

),

ranked as (

    select
        *,
        row_number() over (
            partition by product_key, platform_key, date_key
            order by crawled_at desc, id desc
        ) as row_num

    from keyed

)

select
    product_key,
    platform_key,
    date_key,
    price_amount,
    original_price_amount,
    crawled_at as last_observed_at,
    store_name,
    source_url

from ranked

where row_num = 1
