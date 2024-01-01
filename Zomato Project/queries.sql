-- 1. Total amount spent by each customer on Zomato
select s.userid, sum(p.price) as total_spent
from sales s 
	 join product p on s.product_id = p.product_id
group by s.userid
order by s.userid;
-- 2. How many days each customer has visited Zomato?
select userid, count(distinct created_date) as dist_days -- using distinct if a customer orders >1 product on same day
from sales
group by userid;
-- CONCLUSION: We may offer better discount coupons to customers with less no. of visits.

-- 3. First product purchased by each customer
select * from sales
where (userid, created_date) in
(
	select userid, min(created_date)
	from sales
	group by userid
)
order by userid;
-- CONCLUSION: Each new customer is attracted to a particular product.

-- 4. Most purchased item on menu and no. of times it was purchased by all customers.
select product_id
from sales
group by product_id
order by count(product_id) desc
limit 1;
-- CONCLUSION: Though product 1 is first ordered item, but product 2 is most loved overall.

-- 5. Favourite item of each customer
select userid, product_id
from
(
	select *, row_number() over(partition by userid order by no_of_purchase desc) as rnum
	from
	(
		select userid, product_id, count(product_id) as no_of_purchase
		from sales
		group by userid, product_id
		order by userid
	) d1
) d2
where d2.rnum = 1;
-- CONCLUSION: We can offer some add-on with their favourite meal to increase sales.

-- 6. First item purchased by a customer after becoming gold member
select userid, product_id 
from sales 
where (userid, created_date) in
(
	select s.userid, min(s.created_date)
	from sales s 
		join goldusers_signup gs on s.userid = gs.gold_userid and s.created_date >= gs.gold_signup_date
	group by s.userid
);

-- 7. Last item purchased by a customer before becoming gold member
select userid, product_id 
from sales 
where (userid, created_date) in
(	
	select s.userid, max(s.created_date)
	from sales s 
		join goldusers_signup gs on s.userid = gs.gold_userid and s.created_date < gs.gold_signup_date
	group by s.userid
);

-- 8. Total orders and amount spent by each customer before becoming member
select s.userid, count(s.product_id) as no_of_items, sum(p.price) as total_spent
from sales s 
	join goldusers_signup gs on s.userid = gs.gold_userid and s.created_date < gs.gold_signup_date
    join product p on s.product_id = p.product_id
group by s.userid;

-- 9. Each product has different reward points: 
-- 					for p1 1point/5Rs. *** for p2 5points/10Rs. *** for p3 1point/5Rs.
-- For 2 reward points, customer earns Rs.5 cashback
-- Calculate points collected by each customer and product for which most points have been given till now.
-- *** Part 1 ***
select userid, sum(reward_points) as total_reward_points, sum(reward_points) * 2.5 as cashback
from 
(
	select s.userid, 
		   case 
			   when p.product_name = 'p1' then round(p.price/5)
			   when p.product_name = 'p2' then round(p.price/2)
			   when p.product_name = 'p3' then round(p.price/5)
		   end as reward_points
	from sales s 
		join product p on s.product_id = p.product_id
) d
group by userid
order by userid;
-- *** Part 2 ***
select p.product_id,
	sum(case 
		when p.product_name = 'p1' then round(p.price/5)
		when p.product_name = 'p2' then round(p.price/2)
		when p.product_name = 'p3' then round(p.price/5)
	end) as reward_points
from sales s 
join product p on s.product_id = p.product_id
group by p.product_id
order by reward_points desc; 

-- 10. In the first year after joining gold membership, customer earns 5points/10Rs. on any purchase.
-- What is the cashback in the first year after gold membership?
select s.userid, sum(p.price) as total_spent, sum(p.price) * .5 as cashback
from sales s 
	join goldusers_signup gs on s.userid = gs.gold_userid and s.created_date > gs.gold_signup_date
    join product p on s.product_id = p.product_id
where datediff(s.created_date, gs.gold_signup_date) <= 365
group by s.userid;

-- 11. Rank all the transactions by the customers
select *, rank() over(order by created_date) as rnk
from sales;

-- 12. Rank the gold membership transactions. For non-gold membership transactions mark 'NA'
select s.*, 
	case
		when s.userid in (select gold_userid from goldusers_signup)
			 and s.created_date > gs.gold_signup_date
			then rank() over(partition by s.userid order by created_date desc)
		else 'NA'
	end as rnk
from sales s 
	left join goldusers_signup gs on s.userid = gs.gold_userid;