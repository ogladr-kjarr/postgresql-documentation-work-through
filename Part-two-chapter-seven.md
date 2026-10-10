# PostgreSQL Walkthrough - Part Two

## PostgreSQL Documentation Chapter Seven: Queries

### 7.2

Select queries create a table expression. First the `FROM` clause is evaluated, then the search condition specified by the `WHERE` clause. Following this the table is subject to grouping with `GROUP BY`, then filtering using the `HAVING` command.

Most of the examples in this section are straightforward and common place, so I have omitted them. My interest is in the grouping commands `GROUPING SETS`, `CUBE`, and `ROLLUP`, as I have never seen or used these before. First I created a view to use for these queries as follows in the ecommerce dataset.


```sql
SELECT CONCAT(u.first_name, ' ', u.last_name) as username,
        p.name,
        oi.line_total
FROM users u 
JOIN orders o on u.user_id = o.user_id
JOIN order_items oi on o.order_id = oi.order_id
JOIN product_variants pv on oi.variant_id = pv.variant_id
JOIN products p on pv.product_id = p.product_id;
```