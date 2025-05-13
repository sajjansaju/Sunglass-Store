{{ config(
    materialized = 'table'
) }}

with date_range as (

    select 
        sequence(
            date '2018-01-01',
            date '2026-12-31',
            interval '1' day
        ) as date_array

),

flattened as (

    select 
        cast(date_day as date) as date_actual
    from date_range,
    unnest(date_array) as t(date_day)

)

select 
    date_actual,
    extract(year from date_actual) as year,
    extract(month from date_actual) as month,
    extract(day from date_actual) as day,
    extract(quarter from date_actual) as quarter,
    extract(dow from date_actual) as day_of_week,       
    extract(doy from date_actual) as day_of_year,
    format_datetime(date_actual, 'MMMM') as month_name,
    format_datetime(date_actual, 'EEEE') as weekday_name,
    case when extract(dow from date_actual) in (1, 7) then 'Weekend' else 'Weekday' end as day_type

from flattened