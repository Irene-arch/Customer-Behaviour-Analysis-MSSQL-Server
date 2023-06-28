CREATE DATABASE projects;

USE projects;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

-- Still works without specifying the column names explicitly
INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

-- 1. What is the total amount each customer spent in the restaurant?

SELECT s.customer_id, SUM(m.price) AS total_spent
FROM dbo.sales s
INNER JOIN dbo.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS days_visited
FROM dbo.sales s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH customer_first_purchase AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM dbo.sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN dbo.sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
INNER JOIN dbo.menu m on m.product_id = s.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name, COUNT(s.product_id) AS total_purchased
FROM sales s
INNER JOIN menu m on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC;

SELECT TOP 1 m.product_name, COUNT(*) AS total_purchased
FROM dbo.sales s
INNER JOIN dbo.menu m on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchased DESC;

-- 5. Which item was the most popular for each customer?

WITH customer_popularity AS (
    SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM sales s
    INNER JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, purchase_count
FROM customer_popularity
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase_after_membership AS (
    SELECT s.customer_id, MIN(s.order_date) as first_purchase_date
    FROM dbo.sales s
    JOIN dbo.members mb ON s.customer_id = mb.customer_id
    WHERE s.order_date >= mb.join_date
    GROUP BY s.customer_id
)
SELECT fpam.customer_id, m.product_name
FROM first_purchase_after_membership fpam
JOIN dbo.sales s ON fpam.customer_id = s.customer_id 
AND fpam.first_purchase_date = s.order_date
JOIN dbo.menu m ON s.product_id = m.product_id;

-- 7. Which item was purchased just before the customer became a member?

WITH last_purchase_before_membership AS (
    SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
    FROM dbo.sales s
    JOIN dbo.members mb ON s.customer_id = mb.customer_id
    WHERE s.order_date < mb.join_date
    GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN dbo.sales s ON lpbm.customer_id = s.customer_id 
AND lpbm.last_purchase_date = s.order_date
JOIN dbo.menu m ON s.product_id = m.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(*) as total_items, SUM(m.price) AS total_spent
FROM dbo.sales s
JOIN dbo.menu m ON s.product_id = m.product_id
JOIN dbo.members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, SUM(
	CASE 
		WHEN m.product_name = 'sushi' THEN m.price*20 
		ELSE m.price*10 END) AS total_points
FROM dbo.sales s
JOIN dbo.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, SUM(
    CASE 
        WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date) THEN m.price*20
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM dbo.sales s
JOIN dbo.menu m ON s.product_id = m.product_id
LEFT JOIN dbo.members mb ON s.customer_id = mb.customer_id
--WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
WHERE s.customer_id = mb.customer_id AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

--11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN s.order_date >= mb.join_date THEN 'Y' 
ELSE 'N' 
END as member
FROM dbo.sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

--12. Rank all the things:

SELECT *, 
CASE WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id ORDER BY order_date) END as ranking
FROM (
    SELECT s.customer_id, s.order_date, m.product_name, m.price, 
    CASE WHEN s.order_date >= mb.join_date THEN 'Y' ELSE 'N' END as member
    FROM dbo.sales s
    JOIN dbo.menu m ON s.product_id = m.product_id
    LEFT JOIN dbo.members mb ON s.customer_id = mb.customer_id
) t
ORDER BY customer_id, order_date;