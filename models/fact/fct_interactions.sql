{{
    config(
        materialized = 'incremental',
        on_schema_change = 'fail'
    )
}}
select * from {{ref('interactions_cleaned')}}
{% if is_incremental() %}
    where interaction_id > (select max(interaction_id) from {{this}}) 
{% endif %}