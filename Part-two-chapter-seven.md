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
                b.total_amount as total_amount,
                EXTRACT (DOY FROM f.scheduled_departure) AS day_of_year
        FROM airports_data a
        JOIN routes r on a.airport_code = r.departure_airport
        JOIN flights f on r.route_no = f.route_no
        JOIN segments s on f.flight_id = s.flight_id
        JOIN tickets t on s.ticket_no = t.ticket_no
        JOIN bookings b on t.book_ref = b.book_ref;
```

#### Grouping Sets

Grouping sets group below group by the attributes in brackets. As they are individual, the grouping are individual, so we get the sum of the total amount by airport, by plane, by route, and by the whole dataset.

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579') 
GROUP BY GROUPING SETS ((airport_name), (plane_code), (route), ()) 
ORDER BY sum(total_amount) DESC;
```

Rollup takes the attributes and works left to right, so first the sum of the total amount by everything, then airport, then airport and plane code, then aiport, plane code and route.

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579') 
GROUP BY ROLLUP (airport_name, plane_code, route);
```

Cube creates every permutation of the attributes in the cube function.

```sql
SELECT airport_name, plane_code, route, SUM(total_amount) 
FROM airport_airplane_income 
WHERE airport_name IN ('Gatwick', 'Heathrow')
AND route IN ('PG0120', 'PG0664', 'PG0387', 'PG0579')
GROUP BY CUBE (airport_name, plane_code, route);
```

#### Window Functions

The below view is used for the window functions, we will be interested in comparing rows based on the route_income attribute.

```sql 
CREATE MATERIALIZED VIEW airport_route_income AS
        SELECT airport_name, route, sum(total_amount) as route_income
        FROM airport_airplane_income
        WHERE airport_name in ('Gatwick','Heathrow', 'Bergamo', 'Kazan')
        GROUP BY airport_name, route;
```

Here we partition by airport name and order by route_income descending. So for every airport, the routes are numbered in ascending order based on their rank or route_income, e.g. the highest income is rank 1, second income rank 2 and so on.

```sql
SELECT airport_name, route, route_income,
        DENSE_RANK () OVER (PARTITION BY airport_name ORDER BY route_income DESC) income_rank
FROM airport_route_income;
```

The sub-query is needed as when trying to filter using the `WHERE` clause it isn't found if included just as an attribute in the main query. However if we didn't want to filter based on it, we wouldn't need the subquery. here we select the top two income routes per airport. 

```sql
SELECT airport_name, route, route_income
FROM 
        (SELECT airport_name, route, route_income, ROW_NUMBER() OVER (PARTITION BY airport_name ORDER BY route_income DESC) as position
        FROM airport_route_income) as sub_query
WHERE position < 3;
```

The following looks to see which airport has the worst performing route in terms of income, and shows that as the last column in the query output.

```sql
SELECT airport_name, route, route_income, FIRST_VALUE(airport_name) OVER (ORDER BY route_income) worst_performance
FROM airport_route_income;
```

### 7.8 

Taking the example in the previous section of using a sub-query, we now use a with expression to achieve the same thing.

```sql
WITH row_numbers_added AS (
        SELECT airport_name, route, route_income, ROW_NUMBER() OVER (PARTITION BY airport_name ORDER BY route_income DESC) as position
        FROM airport_route_income
)
SELECT airport_name, route, route_income 
FROM row_numbers_added 
WHERE position < 3;
```

For recursive queries many examples use a staff/manager hieararchy tree, so I asked Claude to create a .sql file that has 100 users and many managers, with some managers managing other managers. It provided the following example query.

```sql
WITH RECURSIVE org AS (
    SELECT staff_id, first_name, second_name, manager_id, 0 AS depth,
           ARRAY[staff_id] AS chain
    FROM staff WHERE manager_id IS NULL
  UNION ALL
    SELECT s.staff_id, s.first_name, s.second_name, s.manager_id,
           o.depth + 1, o.chain || s.staff_id
    FROM staff s JOIN org o ON s.manager_id = o.staff_id
)
SELECT * FROM org ORDER BY chain;
```

Using an array to record the hierarchy for display is a nice addtion. It is also used for ordering, as above, and note that the depth integer could also be used for ordering. Both of which can be achieved by using an explicit command either `DEPTH FIRST` or `BREADTH FIRST`. The below is as if ordered by the array, the second below if ordered by the depth value.

```sql
WITH RECURSIVE org AS (
        SELECT staff_id, first_name, second_name, manager_id
        FROM staff WHERE manager_id IS NULL
   UNION ALL
        SELECT s.staff_id, s.first_name, s.second_name, s.manager_id
        FROM staff s, org o
        WHERE s.manager_id = o.staff_id
) SEARCH DEPTH FIRST BY staff_id SET ordercol
SELECT * FROM org order by ordercol
```

```sql
WITH RECURSIVE org AS (
        SELECT staff_id, first_name, second_name, manager_id
        FROM staff WHERE manager_id IS NULL
   UNION ALL
        SELECT s.staff_id, s.first_name, s.second_name, s.manager_id
        FROM staff s, org o
        WHERE s.manager_id = o.staff_id
) SEARCH BREADTH FIRST BY staff_id SET ordercol
SELECT * FROM org order by ordercol
```

There are a number of examples of how to manually track for cycles in the graph hierarchy, and then an example of the way to make the DBMS do the work for you.

```sql
WITH RECURSIVE org AS (
    SELECT staff_id, first_name, second_name, manager_id, 0 AS depth,
           ARRAY[staff_id] AS chain
    FROM staff WHERE manager_id IS NULL
  UNION ALL
    SELECT s.staff_id, s.first_name, s.second_name, s.manager_id,
           o.depth + 1, o.chain || s.staff_id
    FROM staff s JOIN org o ON s.manager_id = o.staff_id
) CYCLE staff_id SET is_cycle USING path
SELECT * FROM org ORDER BY chain;
```

This adds the is_cycle and path attributes to the output query. First we tell the `CYCLE` command that staff_id is the value that may cycle, we say is_cycle is the attribute that will either be true or false depending on if the same staff_id is seen more than once, and chain is the array that shows the path each recursive call took.