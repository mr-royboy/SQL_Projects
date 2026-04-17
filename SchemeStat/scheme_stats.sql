create database project_2;
use project_2;

select * from merchant_master;
select * from transactions_mena;

-- query to show the success rate for each payment scheme.

with	sp	as	(select		scheme, count(*) as total_transactions,
							sum(case when status = 'Success' then 1 else 0 end) as successful_transaction
				from		transactions_mena
				group by	scheme)
                
select		*, round((successful_transaction * 100 / total_transactions), 2) as success_rate_percentage
from		sp
order by	success_rate_percentage desc;

-- using the iso_response_code find out how many transactions failed due to "Insufficient Funds" (code 51) versus "System Error" (Code 96)

select		scheme,
			sum(case when iso_response_code = 51 then 1 else 0 end) as insufficient_fund,
			sum(case when iso_response_code = 96 then 1 else 0 end) as system_error
from		transactions_mena
group by	scheme;

-- write a query to show the number of Timeouts (code 91) occuring every hour

with	ht	as	(select		date(timestamp) as txn_date,
							hour(timestamp) as txn_hour,
							count(*) as timeout_count
				from		transactions_mena
				where		iso_response_code = 91
				group by	1, 2)
                
select		*,
			lag(timeout_count) over(order by txn_date, txn_hour) as prev_hour_timeout,
			timeout_count - lag(timeout_count) over(order by txn_date, txn_hour) as surge_difference
from		ht
order by	txn_date desc, txn_hour desc;

-- find all merchants who have processed a "System Error" (Code 96) on a transaction greater than 2,000 SAR/AED

select		merchant_id, amount, currency, iso_response_code
from		transactions_mena
where		iso_response_code = 96
and			currency in ('AED', 'SAR')
and			amount > 2000
order by	amount desc;

-- (MERCHANT PERFORMANCE vs SLA) list all merchant_id that has an overall success rate below 90% but have processed at least 50 transactions

select		m.merchant_id, m.country, m.sla_target,
			round(sum(case when status = 'Success' then 1 else 0 end) * 100 / count(t.transaction_id), 2) as success_rate
from		transactions_mena t
join	merchant_master m
on			t.merchant_id = m.merchant_id
group by	1, 2, 3
having		success_rate < m.sla_target
order by	success_rate;

-- for each country, find the most used currency

with	cc	as	(select		m.country, t.currency, count(t.transaction_id) as tot_txn, round(sum(t.amount), 2) as tot_amount
				from		transactions_mena t
				join		merchant_master m
				on			t.merchant_id = m.merchant_id
				group by	1, 2
				order by	tot_amount desc),
                
		cr	as	(select		*, row_number() over(partition by country order by tot_amount desc) as c_rank
				from		cc)
                
select		*
from		cr
where		c_rank = 1;