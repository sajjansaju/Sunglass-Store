with interactions_cleaned as (
                                select * from {{source('raw_data','interactions')}}
)
select 
		user_id,
		item_id,
		date(interaction_date) as interaction_date,
		interaction_id
from interactions_cleaned;