/* 
Code Basics Resume Project Challenge #4 : Provide Insights to Management 
Domain: Consumer Goods | Function: Executive Management
*/

# Ad-hoc-requests

select distinct customer
from dim_customer;

-- 1. List of markets in which customer "Atliq Exlcusive" operates business in the APAC region

select distinct market
from dim_customer
where region = "APAC" and customer="Atliq Exclusive";


-- 2. The percentage of unique product increase in 2021 vs 2020.
-- The final output contains these fields unique_products_2020, unique_products_2021 and percentage_chg
-- We can get the desired result from fact_gross_price, fact_manufacturing_cost and fact_sales_monthly
-- Always choose a table with less data to parse (performance) 

with 
x as
(
select 
count(distinct product_code) as unique_products_2020
from fact_manufacturing_cost 
where cost_year=2020
),

y as
(
select 
count(distinct product_code) as unique_products_2021
from fact_manufacturing_cost
where cost_year=2021
)

select *,
round((unique_products_2021-unique_products_2020)*100/unique_products_2020,2) as percentage_chg		
from x
cross join y;


-- 3. A report on all unique products for each segment, sorted in descending order. 
-- The final output contains 2 fields - segment and product_count

select 
segment, 
count(distinct product_code) as product_count
from dim_product
group by segment
order by product_count desc;


-- 4. Most increase segment in unique product in 2021 vs 2020.
-- The final output contains these fields - segment, product_count_2020, product_count_2021, difference

with 
x as 
(
select p.segment, fs.fiscal_year,
count(distinct fs.product_code) as product_count
from fact_sales_monthly fs
join dim_product p on fs.product_code = p.product_code
group by p.segment, fs.fiscal_year
)

select 
y.segment,
y.product_count as product_count_2020,
z.product_count as product_count_2021,
z.product_count - y.product_count as difference

from x as y
join x as z 
on y.segment = z.segment
and y.fiscal_year = 2020 
and z.fiscal_year = 2021
order by difference desc limit 1;


-- 5. Products with highest and lowest manufacturing cost.
-- The final output contains these fields - product_code, product, manufacturing_cost

select 
p.product_code, p.product, mc.manufacturing_cost 
from dim_product p
join fact_manufacturing_cost mc
using (product_code)
where 
manufacturing_cost =(select max(manufacturing_cost) from fact_manufacturing_cost ) or 
manufacturing_cost =(select min(manufacturing_cost) from fact_manufacturing_cost )
order by manufacturing_cost desc;


-- 6. A report which contains top 5 customers who received an average high pre_invoice_discount_pct 
-- fiscal_year 2021 and in the Indian market.
-- The final output contains these fields - customer_code, customer, average_discount_percentage

select fd.customer_code, c.customer, 
round(AVG(pre_invoice_discount_pct),4) as average_discount_percentage
from fact_pre_invoice_deductions fd
join dim_customer c on 
fd.customer_code = c.customer_code
where fd.fiscal_year = 2021 and c.sub_zone like '%India%'
group by fd.customer_code,c.customer
order by average_discount_percentage desc limit 5;


-- 7. A complete report of Gross sales amount for the customer "Atliq Exclusive" for each month
-- This analysis helps to get an idea of low and high-performing months and take strategic decisions
--  The final report contains these columns - Month, Year, Gross sales Amount

select 
month(date) as Month,
year(date) as Year,
sum(round((gp.gross_price * sm.sold_quantity),2)) as gross_sales_amount
from fact_sales_monthly as sm
join fact_gross_price as gp
ON sm.product_code = gp.product_code and sm.fiscal_year = gp.fiscal_year
join dim_customer as c
ON sm.customer_code = c.customer_code
WHERE customer like 'Atliq Exclusive'
group by Month, Year
ORDER BY Year, Month asc;


-- Q8. 2020 Quarter with maximum quantities sold.
-- The final output contains these fields - Quarter, total_sold_quantity and sorted by the total_sold_quantity

with 
x as
(
select *,
case
  when month(sm.date) in (9,10,11) then 'Q1'
  when month(sm.date) in (12,1,2) then 'Q2'
  when month(sm.date) in (3,4,5) then 'Q3'
  else 'Q4'
end as Quarter
from fact_sales_monthly sm
where fiscal_year = 2020
)

select 
Quarter, sum(sold_quantity) as total_sold_quantity
from x 
group by Quarter
order by total_sold_quantity desc;


-- 9. Channel with more gross sales in 2021 and percentage contributions.
-- The final output contains these fields - channel, gross_sales_mln, percentage

with 
x as
(
select c.channel,
round(sum(sm.sold_quantity * gp.gross_price)/1000000,2) as gross_sales_mln
from dim_customer c
join fact_sales_monthly sm on c.customer_code = sm.customer_code
join fact_gross_price gp on gp.fiscal_year = sm.fiscal_year and gp.product_code = sm.product_code
group by c.channel
order by gross_sales_mln desc
)

select *,
round ((gross_sales_mln * 100) / (select SUM(gross_sales_mln) from x) , 2) as percentage
from x;


-- 10. Top 3 products  in each division that has high total_sold_quantity for fiscal year 2021
-- The final output contains these fields - division, product_code, product, total_sold_quantity, rank_order

with
x as
(
select p.division, p.product_code, p.product, p.variant,
sum(sold_quantity) as total_sold_quantity
from dim_product p 
join fact_sales_monthly sm on p.product_code = sm.product_code
where sm.fiscal_year =  2021
group by p.division, p.product_code, p.product, p.variant
order by total_sold_quantity desc
),

y as 
(
select *, 
rank() over (partition by division order by total_sold_quantity desc) as rank_order
from x
)

select
division,
product_code,
concat(product," ",variant) product_variant,
total_sold_quantity,
rank_order
from y
where rank_order <= 3;






 



















