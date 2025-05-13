with interaction_types_cleaned as (
                                    select * from {{source('raw_data','interaction_types')}}
)
select 
		id,
		trim(regexp_replace(interaction_type,'[,._/]',' ')) as interaction_type
from interaction_types_cleaned;