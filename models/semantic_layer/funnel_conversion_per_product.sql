select i.item_id,
        it.interaction_type,
        count(distinct i.user_id) as user_count
from {{ref('dim_interaction_types')}} it 
join {{ref('fct_interactions')}} i 
on i.interaction_id = it.id 
group by i.item_id, it.interaction_type
order by i.item_id, it.interaction_type
