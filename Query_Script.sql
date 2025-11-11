create schema target_sql;

create table target_sql.orders
(
order_id varchar,	
customer_id varchar,
order_status varchar,	
order_purchase_timestamp timestamp,	
order_approved_at timestamp,
order_delivered_carrier_date timestamp,	
order_delivered_customer_date timestamp,	
order_estimated_delivery_date timestamp
);

create table target_sql.products
(
product_id varchar,
product_category varchar,	
product_name_length int,
product_description_length int,
product_photos_qty int,	
product_weight_g int,	
product_length_cm int,	
product_height_cm int,	
product_width_cm int
);

drop table target_sql.products ;

create table target_sql.order_items
(
order_id varchar,	
order_item_id int,	
product_id varchar,
seller_id varchar,	
shipping_limit_date timestamp,
price float,
freight_value float
);

create table target_sql.customers
(
customer_id varchar,
customer_unique_id varchar,
customer_zip_code_prefix int,	
customer_city varchar,	
customer_state varchar
);

create table target_sql.payment
(
order_id varchar,	
payment_sequential int,	
payment_type varchar,	
payment_installments int,	
payment_value float
);

create table target_sql.sellers
(
seller_id varchar,	
seller_zip_code_prefix int,	
seller_city varchar,
seller_state varchar
);

create table target_sql.geolocation
(
geolocation_zip_code_prefix int,
geolocation_lat float,
geolocation_lng float,
geolocation_city varchar,	
geolocation_state varchar
);

create table target_sql.order_review
(
review_id varchar,	
order_id varchar,	
review_score int,		
review_creation_date timestamp,	
review_answer_timestamp timestamp
);

drop table target_sql.order_review ;
--Q.1 Data type of all columns in the "customers" table. 
select
	column_name,
	data_type
from
	information_schema.columns
where
	table_name = 'customers'
;
--Q.2 Get the time range between which the orders were placed. 
select
	max(order_purchase_timestamp) as last_order,
	min(order_purchase_timestamp) as first_order
from
	target_sql.orders
;
--Q.3 Display the details Cities & States of customers who ordered during the given period. 
select
	c.customer_city,
	c.customer_state
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
where
	extract (year
from
	o.order_purchase_timestamp) = 2018
	and 
  	  extract (month
from
	o.order_purchase_timestamp) between 1 and 3
;
--Q.4 Is there a growing trend in the no. of orders placed over the past years? 
select
	extract (year
from
	o.order_purchase_timestamp) as years,
	count(distinct o.order_id) as total_order
from
	target_sql.orders o
group by
	1
order by
	2 desc 
;
--Q.5 Can we see some kind of monthly seasonality in terms of the no. of orders being placed? 
select
	extract(month from order_purchase_timestamp) as order_month,
	count(distinct order_id) as total_order
from
	target_sql.orders
group by
	1
order by
	2 desc
;

/*--Q.6 During what time of the day, do the Brazilian customers mostly place 
their orders? (Dawn, Morning, Afternoon or Night) 
■ 0-6 hrs : Dawn 
■ 7-12 hrs : Mornings 
■ 13-18 hrs : Afternoon 
■ 19-23 hrs : Night */

select
	case
		when extract(hour from o.order_purchase_timestamp) <= 6 then 'Dawn'
		when extract(hour from o.order_purchase_timestamp)between 7 and 12 then 'Morning'
		when extract(hour from o.order_purchase_timestamp)between 13 and 18 then 'Afternoon'
		else 'Night'
	end as Daily_type,
	count(distinct o.order_id) as total_order
from
	target_sql.orders o
group by
	1
order by
	2 desc 
;
--Q.7 Get the month on month no. of orders placed in each state.
select
	c.customer_state,
	date_trunc ('month',
	o.order_purchase_timestamp) as order_month,
	count(o.order_id) as total_order
from
	target_sql.orders o
join 
target_sql.customers c
on
	o.customer_id = c.customer_id
group by
	1 ,
	2
order by
	3 desc 
;
--Q.8 How are the customers distributed across all the states?
select
	c.customer_state,
	count(distinct c.customer_id) as total_customer
from
	target_sql.customers c
group by
	1
order by
	2 desc 
;

/*Q.9 Get the % increase in the cost of orders from year 2017 to 2018 
(include months between Jan to Aug only). 
You can use the "payment_value" column in the payments table to get 
the cost of orders.*/
with yearly_growth as (
select
	extract(year from s.order_purchase_timestamp) as order_year,
	sum(p.payment_value) as total_payment
from
	target_sql.orders s
join 
target_sql.payment p 
on
	p.order_id = s.order_id
where
	extract(year from s.order_purchase_timestamp) in (2017, 2018)
		and 
	  extract(month from s.order_purchase_timestamp)between 1 and 8
	group by
		1 )
select
	order_year,
	--total_payment,
	--py_year_payment ,
((total_payment - py_year_payment)/ py_year_payment)* 100 as increase
from
	(
	select
		order_year,
		total_payment,
		lead(total_payment) over(order by order_year desc) as py_year_payment
	from
		yearly_growth) as ct 
;
-- Q.10 Calculate the Total & Average value of order price for each state.
select
	c.customer_state,
	round(sum(oi.price)::numeric, 2) as total_price,
	round(avg(oi.price)::numeric, 2) as avg_price
from
	target_sql.customers c
join 
target_sql.orders o   
on
	c.customer_id = o.customer_id
join 
target_sql.order_items oi 
on
	o.order_id = oi.order_id
group by
	1
order by
	3 desc 
;
--Q.11 Calculate the Total & Average value of order freight for each state.
select
	c.customer_state ,
	sum(oi.freight_value) as total_freight,
	avg(oi.freight_value) as avg_freight
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
join 
target_sql.order_items oi 
on
	o.order_id = oi.order_id
group by
	1 
;

/*--Q.12 Find the no. of days taken to deliver each order from the order’s 
purchase date as delivery time. 
Also, calculate the difference (in days) between the estimated & actual 
delivery date of an order. 
Do this in a single query. 
You can calculate the delivery time and the difference between the 
estimated & actual delivery date using the given formula: 
■ time_to_deliver = order_delivered_customer_date - 
order_purchase_timestamp 
■ diff_estimated_delivery = order_delivered_customer_date - 
order_estimated_delivery_date*/
select
	*
from
	target_sql.orders;

select
	o.order_id,
	extract (day
from
	age(o.order_delivered_customer_date, o.order_purchase_timestamp)) as days_to_delivery,
	extract (day
from
	age(o.order_delivered_customer_date, o.order_estimated_delivery_date)) as diff_estimated_delivery
from
	target_sql.orders o 
;
--Q.13 Find out the top 5 states with the highest & lowest average freight value
--Highest cost
select
	c.customer_state ,
	round(avg(oi.freight_value)::numeric, 2) as avg_cost
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
join 
target_sql.order_items oi 
on
	o.order_id = oi.order_id
group BY
--Q.1 Data type of all columns in the "customers" table. 
	1
order by
	2 desc
limit 5 
;
--lowest cost
select
	c.customer_state ,
	round(avg(oi.freight_value)::numeric, 2) as avg_cost
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
join 
target_sql.order_items oi 
on
	o.order_id = oi.order_id
group by
	1
order by
	2 asc
limit 5 
;
--Q.14 Find out the top 5 states with the highest & lowest average delivery time.
--Highest avg delivery time
select
	c.customer_state ,
	avg(extract (day from age(o.order_delivered_customer_date, o.order_purchase_timestamp))) as days_to_delivery
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
group by
	1
order by
	2 desc
limit 5 
;
--Lowest avg delivery time
select
	c.customer_state ,
	avg(extract (day from age(o.order_delivered_customer_date, o.order_purchase_timestamp))) as days_to_delivery
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
group by
	1
order by
	2 asc
limit 5 
;

/*--Q.15 Find out the top 5 states where the order delivery is really fast as 
compared to the estimated date of delivery. 
You can use the difference between the averages of actual & estimated 
delivery date to figure out how fast the delivery was for each state*/
select
	c.customer_state,
	avg(extract(day from age(o.order_delivered_customer_date, o.order_estimated_delivery_date))) as diff_estimated_delivery
from
	target_sql.customers c
join 
target_sql.orders o 
on
	c.customer_id = o.customer_id
group by
	1
order by
	2 asc
limit 5 
;
-- Q.16 Find the month on month no. of orders placed using different payment types. 
select
	p.payment_type,
	extract (year
from
	o.order_purchase_timestamp) as order_year,
	extract (month
from
	o.order_purchase_timestamp) as order_month,
	count(distinct o.order_id) as total_order
from
	target_sql.orders o
join 
target_sql.payment p 
on
	p.order_id = o.order_id
group by
	1,
	2,
	3
order by
	4 desc
;
--Q.17 Find the no. of orders placed on the basis of the payment installments that have been paid.
select
	p.payment_installments,
	count(o.order_id) as total_order
from
	target_sql.orders o
left join 
target_sql.payment p 
on
	o.order_id = p. order_id
group by
	1 
;
