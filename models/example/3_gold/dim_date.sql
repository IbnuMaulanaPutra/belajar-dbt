
{{ config(materialized='table') }}

with date_range as (

    select
        min(crawl_timestamp::timestamp::date) as min_date,
        max(crawl_timestamp::timestamp::date) as max_date
    from {{ ref('stg_product_crawling') }}
    where crawl_timestamp is not null

),

calendar as (

    select
        generate_series(
            min_date,
            max_date,
            interval '1 day'
        )::date as full_date
    from date_range
    where min_date is not null

)

select
    to_char(full_date, 'yyyymmdd')::integer as date_key,
    full_date,
    extract(day from full_date)::integer as day_number,
    extract(month from full_date)::integer as month_number,
    extract(quarter from full_date)::integer as quarter_number,
    extract(year from full_date)::integer as year_number,
    to_char(full_date, 'day') as day_name,
    to_char(full_date, 'month') as month_name,
    extract(isodow from full_date)::integer as day_of_week
from calendar
