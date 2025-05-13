with orders_cleaned as (
                        select * from {{source('raw_data','orders')}}
)
select 
		user_id,
		item_id,
		date(purchase_date) as purchase_date,
		order_id,
		trim(regexp_replace(payment_type,'[.,\/_-]',' ')) as payment_type
from orders_cleaned;
