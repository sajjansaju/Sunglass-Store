{{ 
    config(
            materialized = 'incremental',
            on_schema_change = 'fail'
    )
}}
select * from {{ ref('users_cleaned') }}
{% if is_incremental() %}
    where user_id > (select max(user_id) from {{ this }})
{% endif %}    