# PostgreSQL Walkthrough - Part Two

## PostgreSQL Documentation Chapter Seven: Queries

### 7.2

Select queries create a table expression. First the `FROM` clause is evaluated, then the search condition specified by the `WHERE` clause. Following this the table is subject to grouping with `GROUP BY`, then filtering using the `HAVING` command.

Most of the examples in this section are straightforward and common place, so I have omitted them. My interest is in the grouping commands `GROUPING SETS`, `CUBE`, `ROLLUP`, and the windowing commands, as I have never seen or used these before. First I created a view to use for these queries as follows in the demo air transport database and ecommerce database.

```sql
CREATE MATERIALIZED VIEW airport_airplane_income AS
        SELECT a.airport_name ->>'en' as airport_name,
                r.airplane_code as plane_code,
                f.route_no as route,
                b.total_amount as total_amount
        FROM airports_data a
        JOIN routes r on a.airport_code = r.departure_airport
        JOIN flights f on r.route_no = f.route_no
        JOIN segments s on f.flight_id = s.flight_id
        JOIN tickets t on s.ticket_no = t.ticket_no
        JOIN bookings b on t.book_ref = b.book_ref;
```

#### Grouping Sets

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow', 'Frankfurt am main')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579') 
GROUP BY GROUPING SETS ((airport_name), (plane_code), (route), ()) 
ORDER BY sum(total_amount) DESC;
```

Rollup

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow', 'Frankfurt am main')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579') 
GROUP BY ROLLUP (airport_name, plane_code, route);
```

Cube 

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow', 'Frankfurt am main')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579') 
GROUP BY CUBE (airport_name, plane_code, route);
```

#### Window Functions

```sql

```
SELECT
	product_id,
	product_name,
	group_id,
	price,
	DENSE_RANK () OVER (
		PARTITION BY group_id
		ORDER BY price DESC
	) price_rank
FROM
	products;



SELECT
    product_id,
    product_name,
    group_id,
    price,
    FIRST_VALUE(product_name)
    OVER(
        ORDER BY price
    ) lowest_price
FROM
    products;


SELECT
  year,
  amount,
  LAG(amount, 1) OVER (
    ORDER BY
      year
  ) previous_year_sales
FROM
  sales
WHERE group_id = 1;



```sql
CREATE MATERIALIZED VIEW product_order_total AS
        SELECT CONCAT(u.first_name, ' ', u.last_name) as username,
                p.name,
                oi.line_total
        FROM users u 
        JOIN orders o on u.user_id = o.user_id
        JOIN order_items oi on o.order_id = oi.order_id
        JOIN product_variants pv on oi.variant_id = pv.variant_id
        JOIN products p on pv.product_id = p.product_id;
```