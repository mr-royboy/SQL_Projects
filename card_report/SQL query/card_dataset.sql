create database card_project;
use card_project;

select	*	from	users;
select	*	from	merchants;
select	*	from	transactions;
select	*	from	chargebacks;
select	*	from	fraud_flags;

-- CORE TRANSACTION METRICS

-- 1. Calculate Total Transaction Volume and Total Transaction Value per day

select		day(transaction_time) as day, count(*) as transaction_count, round(sum(amount), 2) as transaction_value
from		transactions
group by	day(transaction_time)
order by	day;

-- 2. Calculate Approval Rate

select		sum(case when status = 'approved' then 1 else 0 end) as approved,
			sum(case when status = 'declined' then 1 else 0 end) as declined,
            round((sum(case when status = 'approved' then 1 else 0 end) / count(*)) * 100, 2) as approval_rate
from		transactions;

-- 3. Find Top 10 Merchants by Transaction Value.

select		merchant_id, round(sum(amount), 2) as total_transaction
from		transactions
group by	merchant_id
order by	total_transaction desc
limit		10;

-- 4. Calculate average Transaction Value per Merchant category

select		m.category, round(avg(t.amount), 2) as avg_value
from		merchants m
join		transactions t
on			m.merchant_id = t.merchant_id
group by	m.category
order by	avg_value desc;

-- 5. Find the Daily Transaction Count trend for the last 30 days

select		date(transaction_time) as day, count(*) as num_of_transactions
from		transactions
group by	date(transaction_time)
order by	day desc
limit		30;

-- CUSTOMER BEHAVIOUR ANALYSIS

-- 6. find Top 20 users by transaction amount

select		user_id, round(sum(amount), 2) as total_amount
from		transactions
group by	user_id
order by	total_amount desc
limit		20;

-- 7. calculate the average Transaction Value per user per month

select		user_id, month(transaction_time) as month, round(avg(amount), 2) as avg_value
from		transactions
group by	user_id, month(transaction_time)
order by	user_id, month asc;

-- 8. Find Users who made Transactions in more than 5 different merchant categories

select		t.user_id, count(distinct m.category) as categories
from		transactions t
join		merchants m
on			t.merchant_id = m.merchant_id
group by	t.user_id
having		categories > 5;

-- 9. find new Users who made their first transaction within first 7 days of sign up

select		u.user_id, u.signup_date, min(t.transaction_time) as transaction_date,
			datediff(min(t.transaction_time), u.signup_date) as days_to_transaction
from		users u
join		transactions t
on			u.user_id = t.user_id
where		t.transaction_time >= u.signup_date
group by	u.user_id, u.signup_date
having		days_to_transaction <= 7;

-- 10. Calculate Fraud Rate

select		count(f.fraud_flag) * 100 / count(*) as fraud_rate
from		transactions t
left join	fraud_flags f
on 			t.transaction_id = f.transaction_id;

-- 11. Find top merchants with highest fraud transaction count

select		m.merchant_id, m.merchant_name, count(fraud_flag) as fraud_count
from		merchants m
left join	transactions t
on 			m.merchant_id = t.merchant_id
left join	fraud_flags f
on			f.transaction_id = t.transaction_id
group by	m.merchant_id, m.merchant_name
order by	fraud_count desc;

-- 12. Calculate fraud transaction value by merchant category

select		m.category, round(sum(t.amount), 2) as fraud_amount
from		merchants m
left join	transactions t
on			m.merchant_id = t.merchant_id
left join	fraud_flags f
on			f.transaction_id = t.transaction_id
where		f.fraud_flag is not null
group by	m.category
order by	fraud_amount desc;

-- 13. Detect users with more than 3 fraud transactions

select		u.user_id, count(f.fraud_flag) as fraud_count
from 		users u
join 		transactions t
on 			u.user_id = t.user_id
join		fraud_flags f
on			t.transaction_id = f.transaction_id
group by	u.user_id
having		fraud_count >= 3;

-- 14. Calculate Chargeback Rate

select		(count(c.transaction_id) * 100 / count(case when t.status = 'approved' then 1 end)) as chargeback_rate
from		chargebacks c
left join	transactions t
on			c.transaction_id = t.transaction_id;

-- 15. Find top merchants by chargeback amount

select		m.merchant_name, round(sum(c.chargeback_amount), 2) as total_chargeback
from		chargebacks c
join		transactions t
on			c.transaction_id = t.transaction_id
join		merchants m
on			t.merchant_id = m.merchant_id
group by	m.merchant_id, m.merchant_name
order by	total_chargeback desc;

-- 16. Calculate chargeback rate per merchant category

with	cr	as	(select		m.category, round(sum(c.chargeback_amount), 2) as total_chargeback
				from		chargebacks c
				join		transactions t
				on			c.transaction_id = t.transaction_id
				join		merchants m
				on			t.merchant_id = m.merchant_id
				group by	m.category)
                
select		category, round(total_chargeback * 100 / sum(total_chargeback) over(), 2) as chargeback_rate
from		cr
order by	total_chargeback desc;

-- 17. Calculate Monthly Active Users (MAU)

select		year(transaction_time) as year, month(transaction_time) as month,
			count(distinct user_id) as active_users
from		transactions
group by	year, month
order by	year, month;

-- 18. Calculate User Retention (users transacting in consecutive months)

with	ma	as	(select		distinct user_id, month(transaction_time) as month, year(transaction_time) as year
				from		transactions)
select		count(distinct a.user_id) as retained_users, a.month, a.year
from		ma a
join		ma b
on			a.user_id = b.user_id
and			((a.year = b.year and b.month = a.month + 1) or (a.month = 12 and b.month = 1 and b.year = a.year + 1))
group by	a.year, a.month
order by	a.year, a.month;

-- option 2

WITH ma AS (
    SELECT DISTINCT
        user_id,
        DATE_FORMAT(transaction_time,'%Y-%m-01') AS month
    FROM transactions
)

SELECT
    COUNT(DISTINCT a.user_id) AS retained_users,
    a.month
FROM ma a
JOIN ma b
    ON a.user_id = b.user_id
    AND b.month = DATE_ADD(a.month, INTERVAL 1 MONTH)
GROUP BY a.month
ORDER BY a.month;

-- 19. Detect users whose transaction amount increased >200% compared to previous month

with	ts	as	(select		user_id, round(sum(amount), 2) as total_transaction, 
				year(transaction_time) as year, month(transaction_time) as month
				from		transactions
				group by	user_id, year(transaction_time), month(transaction_time)),

		nm	as	(select		user_id, year, month, total_transaction,
							lead(total_transaction) over(partition by user_id order by year, month) as next_month_spend
				from		ts),

		pc	as	(select		*, round((next_month_spend - total_transaction) * 100 / total_transaction, 2) as percentage_increase
				from		nm
				group by	user_id, year, month)
                
select		*
from		pc
where		percentage_increase > 200;

-- 20. Create merchant category contribution % to total revenue

select		m.category, round(sum(t.amount), 2) as revenue,
			round(sum(t.amount) * 100 / sum(sum(t.amount)) over(), 2) as category_contribution
from		merchants m
join		transactions t
on			m.merchant_id = t.merchant_id
group by	m.category;