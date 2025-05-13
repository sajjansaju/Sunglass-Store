with users_cleaned as (
                        select * from {{source('raw_data','users')}}
)
select 
		user_id,
		upper(substring(first_name,1 ,1))|| lower(substring(first_name from 2)) as first_name,
		upper(substring(last_name,1 ,1))|| lower(substring(last_name from 2)) as last_name,
		lower(email) as email,
		age,
		upper(substring(gender from 1 for 1))as gender,
		post_code,
		upper(substring(country,1 ,1))|| lower(substring(country from 2)) as country,
		cast(join_date as date) as join_date,
		trim(REGEXP_REPLACE(from_platform, '[, . \ - _ ?]', ' ')) as from_platform
from users_cleaned;
