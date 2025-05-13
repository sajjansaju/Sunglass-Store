with products_cleaned as (
                            select * from {{source('raw_data','products')}}
)
select 
		item_id,
		trim(regexp_replace(brand,'[.,_-]',' ')) as brand,
		product_name,
		eye_size,
		trim(regexp_replace(lens_color,'[.,_-]',' ')) as lens_color,
		price,
		polarized_glasses,
		prescribed_glasses,
		is_active,
		cast(list_date as date) as list_date,
		cast(discontinued_date as date) as discontinued_date
from products_cleaned;

