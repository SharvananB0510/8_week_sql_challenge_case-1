-- 1) What is the total amount each customer spent at the restaurant?
SELECT S.customer_id, SUM(M.price) AS total_amount
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
GROUP BY S.customer_id;

-- 2) How many days has each customer visited the restaurant?
SELECT customer_id, count(distinct order_date) AS NO_oF_days
FROM Sales S
GROUP BY S.customer_id;

-- 3) What was the first item from the menu purchased by each customer?
select customer_id, product_name from 
(
select  S.customer_id, M.product_name 
,row_number() over(partition by customer_id order by order_date ) as rnk 
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
) X
where rnk = 1;

-- 4) What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
M.product_name, count(order_date) AS NO_Of_times 
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
group by M.product_name
order by count(order_date) desc
limit 1;

-- 5) Which item was the most popular for each customer?

select customer_id,product_name,nooftimes from 
(
select customer_id,M.product_name, count(order_date) AS nooftimes,
row_number() over( partition by customer_id order by count(order_date) desc) as rnk 
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
group by customer_id,M.product_name
) X
where rnk =1;

-- 6) Which item was purchased first by the customer after they became a member?

with cte1 as(select S.customer_id,order_date,join_date,M.product_name,
rank() over(partition by customer_id order by order_date) as rnk
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
Join members P on S.customer_id = P.customer_id
where order_date >= join_date
)
select customer_id
	 ,product_name
from cte1 
where rnk = 1;

-- 7) Which item was purchased just before the customer became a member?

with cte1 as(
select S.customer_id,order_date,join_date,M.product_name,
rank() over(partition by customer_id order by order_date desc) as rnk
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
Join members P on S.customer_id = P.customer_id
where order_date < join_date
)
select customer_id
	 ,product_name
from cte1 
where rnk = 1;

-- 8) What is the total items and amount spent for each member before they became a member?

select S.customer_id
,count(S.product_id) as Products
,Sum(M.price) as Price
FROM Sales S
JOIN Menu M ON S.product_id = M.product_id
Join members P on S.customer_id = P.customer_id
where order_date < join_date
group by customer_id
order by customer_id ;

-- 9) If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select S.customer_id,
sum(case when product_name = "sushi" then price * 10 * 2
else price * 10 end) as points
from Sales S
JOIN Menu M ON S.product_id = M.product_id
group by customer_id;

-- 10) In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

WITH CTE1 AS (
    SELECT
        S.customer_id,
        S.order_date,
        M.product_name,
        M.price,
        CASE
            WHEN product_name = 'sushi' THEN 2 * M.price 
            WHEN order_date BETWEEN P.join_date AND DATE_ADD(P.join_date, INTERVAL 6 DAY) THEN 2 * M.price
            ELSE M.price
        END AS points
    FROM
        Sales S
        JOIN Menu M ON S.product_id = M.product_id
        JOIN Members P ON S.customer_id = P.customer_id
    WHERE
        DATE_FORMAT(order_date, '%Y-%m-01') = '2021-01-01'
)
SELECT
    customer_id,
    SUM(points) * 10 AS total_points
FROM
    CTE1
GROUP BY
    customer_id
order by customer_id;
-- Bonus 1

SELECT 
    S.customer_id,
    S.order_date,
    M.product_name,
    M.price,
    CASE
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    Sales S
        JOIN
    Menu M ON S.product_id = M.product_id
        LEFT JOIN
    Members P ON S.customer_id = P.customer_id
ORDER BY S.customer_id , S.order_date , M.product_name;
	
-- Bonus 2

with CTE1 as (
SELECT 
    S.customer_id,
    S.order_date,
    M.product_name,
    M.price,
    CASE
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
    END AS Member
FROM
    Sales S
        JOIN
    Menu M ON S.product_id = M.product_id
        LEFT JOIN
    Members P ON S.customer_id = P.customer_id
ORDER BY S.customer_id , S.order_date , M.product_name
)
select * ,
    CASE
    
		WHEN Member = 'N' then NULL 
        else rank() over(PARTITION BY customer_id,Member ORDER BY order_date) end AS RNK
from CTE1;
