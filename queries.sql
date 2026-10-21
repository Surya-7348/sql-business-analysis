-- Business questions answered with SQL (PostgreSQL)
-- Revenue = quantity * unit_price, counted for delivered orders only.


-- 1. Monthly revenue
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS month,
    SUM(oi.quantity * oi.unit_price)        AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY 1
ORDER BY 1;


-- 2. Month-over-month revenue growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE AS month,
        SUM(oi.quantity * oi.unit_price)        AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 1) AS growth_pct
FROM monthly
ORDER BY month;


-- 3. Top 5 customers by total spend
SELECT
    c.customer_id,
    c.name,
    c.city,
    SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'delivered'
GROUP BY c.customer_id, c.name, c.city
ORDER BY total_spend DESC
LIMIT 5;


-- 4. Revenue by category with % share
SELECT
    p.category,
    SUM(oi.quantity * oi.unit_price) AS revenue,
    ROUND(100.0 * SUM(oi.quantity * oi.unit_price)
          / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1) AS share_pct
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.status = 'delivered'
GROUP BY p.category
ORDER BY revenue DESC;


-- 5. Best-selling product in each category
WITH product_sales AS (
    SELECT
        p.category,
        p.name,
        SUM(oi.quantity) AS units_sold,
        RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity) DESC) AS rnk
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.status = 'delivered'
    GROUP BY p.category, p.name
)
SELECT category, name, units_sold
FROM product_sales
WHERE rnk = 1
ORDER BY category;


-- 6. Repeat vs one-time customers
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS orders_placed
    FROM orders
    WHERE status = 'delivered'
    GROUP BY customer_id
)
SELECT
    CASE WHEN orders_placed > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY 1;


-- 7. Customers who signed up but never ordered
SELECT c.customer_id, c.name, c.city, c.signup_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.signup_date;


-- 8. Running total of revenue by day
WITH daily AS (
    SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.order_date
)
SELECT
    order_date,
    revenue,
    SUM(revenue) OVER (ORDER BY order_date) AS running_total
FROM daily
ORDER BY order_date;


-- 9. Average order value by city
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'delivered'
    GROUP BY o.order_id, o.customer_id
)
SELECT
    c.city,
    COUNT(*)                     AS orders,
    ROUND(AVG(ot.order_value), 0) AS avg_order_value
FROM order_totals ot
JOIN customers c ON c.customer_id = ot.customer_id
GROUP BY c.city
ORDER BY avg_order_value DESC;


-- 10. Cancellation rate by month
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    ROUND(100.0 * SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) / COUNT(*), 1) AS cancellation_pct
FROM orders
GROUP BY 1
ORDER BY 1;


-- 11. Days between a customer's first and second order
WITH numbered AS (
    SELECT
        customer_id,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS order_no
    FROM orders
    WHERE status = 'delivered'
)
SELECT
    f.customer_id,
    f.order_date                AS first_order,
    s.order_date                AS second_order,
    s.order_date - f.order_date AS days_to_repeat
FROM numbered f
JOIN numbered s ON s.customer_id = f.customer_id AND s.order_no = 2
WHERE f.order_no = 1
ORDER BY days_to_repeat;
