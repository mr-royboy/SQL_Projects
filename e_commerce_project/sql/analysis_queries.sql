show databases;
create database project_1;

use project_1;

select * from customers;
select * from order_items;
select * from orders;
select * from products;
select * from returns;

-- REVENUE ANALYSIS

	-- monthly revenue

select		month(o.order_date) as month, round(sum(i.quantity * i.unit_price), 2) as revenue
from		order_items i
left join	orders o
on			i.order_id = o.order_id
group by	month(o.order_date)
order by	month;

-- yearly revenue

select		year(o.order_date) as year, round(sum(i.quantity * i.unit_price), 2) as revenue
from		order_items i
left join	orders o
on			i.order_id = o.order_id
group by	year(o.order_date)
order by	year;

	-- sales growth

with	rv	as	(select		year(o.order_date) as year, month(o.order_date) as month, round(sum(i.quantity * i.unit_price), 2) as revenue
				from		order_items i
				left join 	orders o
				on			i.order_id = o.order_id
				group by	year, month
				order by	year, month)
                
select			*,
				lag(revenue) over(order by year, month) as prev_month_rev,
                round((lag(revenue) over(order by year, month) - revenue) * 100 / lag(revenue) over(order by year, month), 2) as sales_growth
from			rv;

-- CUSTOMER ANALYSIS

	-- top spending customers

with	ci	as	(select		o.customer_id, i.quantity, i.unit_price
				from		orders o
				left join	order_items i
				on			o.order_id = i.order_id),
                
		tc	as	(select		concat(c.first_name, ' ', c.last_name) as name, round(sum(ci.quantity * ci.unit_price), 2) as spending
				from		ci
				left join	customers c
				on			ci.customer_id = c.customer_id
				group by	concat(c.first_name, ' ', c.last_name)
				order by	spending desc)
                
select		name, spending
from		tc;

	-- top 5% spending customer

with	ci	as	(select		o.customer_id, i.quantity, i.unit_price
				from		orders o
				left join	order_items i
				on			o.order_id = i.order_id),
                
		tc	as	(select		concat(c.first_name, ' ', c.last_name) as name, round(sum(ci.quantity * ci.unit_price), 2) as spending
				from		ci
				left join	customers c
				on			ci.customer_id = c.customer_id
				group by	concat(c.first_name, ' ', c.last_name)
				order by	spending desc),
                
		op	as	(select		*, ntile(100) over(order by spending desc) as top_one_prct
				from		tc)
                
select		name, spending
from		op
where		top_one_prct <= 5;

	-- orders per customer

select		c.customer_id, concat(c.first_name, ' ', c.last_name) as customer_name, count(c.customer_id) as total_orders
from 		customers c
left join	orders o
on			c.customer_id = o.customer_id
group by	c.customer_id, concat(c.first_name, ' ', c.last_name), o.order_status
having		o.order_status = 'Completed'
order by	total_orders desc;

	-- cities that generates most revenue

select		c.city, round(sum(i.quantity * i.unit_price), 2) as revenue
from		customers c
left join	orders o
on			c.customer_id = o.customer_id
left join	order_items i
on			o.order_id = i.order_id
group by	c.city
order by	revenue desc;

-- PRODUCT PERFORMANCE

	-- best selling products

select		p.product_name, round(sum(i.quantity * i.unit_price), 2) as revenue  
from		order_items i
left join	products p
on			i.product_id = p.product_id
group by	p.product_name
order by	revenue desc;

	-- best selling category

select		p.category, round(sum(i.quantity * i.unit_price), 2) as revenue 
from		products p
left join	order_items i
on			p.product_id = i.product_id
group by	p.category
order by	revenue desc;

-- ORDER ANALYSIS

	-- average order value
    
select		order_id, round(avg(quantity * unit_price), 2) as average
from 		order_items
group by	order_id;

	-- most common payment method

select		payment_method, count(payment_method) as num_of_payments
from		orders
group by	payment_method
order by	num_of_payments desc
limit		1;

	-- cancelled order rate
    
select		round(sum(order_status = 'Cancelled') * 100 / count(*), 2) as cancel_order_rate
from		orders;

-- RETURN ANALYSIS

	-- return rate per product
    
select		p.product_id, p.product_name,
			round(count(distinct r.return_id) * 100 / count(i.order_item_id), 2) as return_rate
from		products p
join		order_items i
on			p.product_id = i.product_id
left join	returns r
on			i.order_item_id = r.order_item_id
group by	p.product_id, p.product_name
order by	return_rate desc;

	-- categories with most returns
    
select		p.category, count(distinct return_id) as return_items
from		products p
join 		order_items i
on			p.product_id = i.product_id
left join	returns r
on			i.order_item_id = r.order_item_id
group by	p.category
order by	return_items desc;

	-- refund amount trends
    
select		month(return_date) as month, year(return_date) as year, count(return_id) as num_of_returns, round(sum(refund_amount), 2) as return_amount
from		returns
group by	month(return_date), year(return_date)
order by	year, month;

-- SOME KPIs

	-- top product per category
with	tp	as	(select		p.category, p.product_name, round(sum(i.quantity * i.unit_price), 2) as revenue
				from		products p
				join		order_items i
				on			p.product_id = i.product_id
				group by	p.category, p.product_name),
                
		rc 	as	(select		*,
							row_number() over(partition by category order by revenue desc) as rank_category
				from		tp)
select		*
from		rc                
where		rank_category = 1;

	-- revenue growth MoM
    
with 	rv	as	(select		year(o.order_date) as year, month(o.order_date) as month, round(sum(i.quantity * i.unit_price), 2) as revenue
				from		order_items i
				join		orders o
				on			i.order_id = o.order_id
				group by	year, month
				order by	year, month)
select		*,
			round(lag(revenue) over(order by year, month), 2) as prev_month_revenue,
			round((revenue - lag(revenue) over(order by year, month)) * 100 / lag(revenue) over(order by year, month), 2) as growth
from		rv;

	-- top customers per city
    
with	tc	as	(select		concat(c.first_name, ' ', c.last_name) as full_name, c.city, round(sum(i.quantity * i.unit_price), 2) as revenue
			from		customers c
			join		orders o
			on			c.customer_id = o.customer_id
			join		order_items i
			on			o.order_id = i.order_id
			group by	c.customer_id, full_name, c.city
            order by	revenue desc),
            
		cr	as	(select		*,
							row_number() over(partition by city order by revenue desc) as customer_rank
				from		tc)
                
select		*
from		cr
where		customer_rank = 1;