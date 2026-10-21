# SQL Business Analysis

Eleven real-world business questions answered with SQL, written against a small sample database for an online office-supplies store. The queries cover the patterns used in day-to-day reporting: joins, aggregation, CTEs, CASE logic and window functions.

Written for **PostgreSQL**. Every query has been tested against the sample data.

## Files

| File | What it contains |
|---|---|
| `schema.sql` | The four tables: `customers`, `products`, `orders`, `order_items` |
| `seed.sql` | Sample data: 20 customers, 10 products, 70 orders (all dummy data) |
| `queries.sql` | The 11 queries below, in order |

## Data model

```
customers 1 ──< orders 1 ──< order_items >── 1 products
```

Revenue is calculated as `quantity * unit_price`, and only **delivered** orders are counted as revenue.

## Questions and the logic behind each query

1. **Monthly revenue**: joins orders to their items, keeps delivered orders, rounds each date down to its month with `DATE_TRUNC`, and totals the revenue per month.
2. **Month-over-month growth**: calculates monthly revenue in a CTE, then uses `LAG()` to fetch the previous month's revenue on the same row and computes the % change.
3. **Top 5 customers by spend**: totals delivered revenue per customer, sorts from highest to lowest, and keeps the top 5.
4. **Revenue by category with % share**: totals revenue per category, then divides by the grand total. The grand total comes from `SUM(...) OVER ()`, a window over all rows.
5. **Best-selling product in each category**: ranks products by units sold within each category using `RANK() OVER (PARTITION BY category ...)` and keeps rank 1. `RANK` keeps ties, so two products with equal sales both appear.
6. **Repeat vs one-time customers**: counts each customer's delivered orders, labels them "Repeat" (more than 1) or "One-time" with `CASE`, then counts the customers in each group.
7. **Customers who never ordered**: a `LEFT JOIN` from customers to orders keeps every customer, and `WHERE order_id IS NULL` leaves only those with no matching order.
8. **Running total of revenue**: totals revenue per day, then `SUM(...) OVER (ORDER BY order_date)` adds each day to all the days before it.
9. **Average order value by city**: calculates each order's value in a CTE, joins to customers for the city, and averages the order values per city.
10. **Cancellation rate by month**: counts all orders and cancelled orders per month (`CASE` turns each cancelled order into a 1), then divides the two.
11. **Days to second order**: numbers each customer's orders by date with `ROW_NUMBER()`, joins order 1 to order 2 for the same customer, and subtracts the dates.

## How to run

```bash
createdb store_demo
psql -d store_demo -f schema.sql
psql -d store_demo -f seed.sql
psql -d store_demo -f queries.sql
```

Or paste the three files into any online PostgreSQL playground, such as DB Fiddle.

## Skills shown

SQL · PostgreSQL · JOINs · GROUP BY · CTEs · CASE · window functions (`LAG`, `RANK`, `ROW_NUMBER`, running totals) · business reporting
