EXPLAIN ANALYZE
SELECT
    p.product_id,
    p.product_name,
    p.product_category,
    COUNT(o.order_id) AS orders_count,
    COUNT(DISTINCT c.id) AS active_clients_count
FROM opt_orders AS o
JOIN opt_products AS p
    ON o.product_id = p.product_id
JOIN opt_clients AS c
    ON o.client_id = c.id
WHERE o.order_date >= DATE '2024-01-01'
  AND c.status = 'active'
  AND p.product_category IN ('Category1', 'Category2')
GROUP BY
    p.product_id,
    p.product_name,
    p.product_category
HAVING COUNT(o.order_id) > (
    SELECT AVG(product_orders)
    FROM (
        SELECT
            p2.product_id,
            COUNT(o2.order_id) AS product_orders
        FROM opt_orders AS o2
        JOIN opt_products AS p2
            ON o2.product_id = p2.product_id
        JOIN opt_clients AS c2
            ON o2.client_id = c2.id
        WHERE o2.order_date >= DATE '2024-01-01'
          AND c2.status = 'active'
          AND p2.product_category IN ('Category1', 'Category2')
        GROUP BY p2.product_id
    ) AS repeated_stats
)
ORDER BY
    orders_count DESC,
    active_clients_count DESC,
    p.product_id ASC
LIMIT 10;


CREATE INDEX IF NOT EXISTS idx_my_orders_date_product_client
    ON opt_orders(order_date, product_id, client_id);

CREATE INDEX IF NOT EXISTS idx_my_orders_client_id
    ON opt_orders(client_id);

CREATE INDEX IF NOT EXISTS idx_my_clients_status_id
    ON opt_clients(status, id);

CREATE INDEX IF NOT EXISTS idx_my_products_category_id
    ON opt_products(product_category, product_id);

ANALYZE;


EXPLAIN ANALYZE
WITH filtered_orders AS (
    SELECT
        o.order_id,
        o.order_date,
        p.product_id,
        p.product_name,
        p.product_category,
        c.id AS client_id
    FROM opt_orders AS o
    JOIN opt_products AS p
        ON o.product_id = p.product_id
    JOIN opt_clients AS c
        ON o.client_id = c.id
    WHERE o.order_date >= DATE '2024-01-01'
      AND c.status = 'active'
      AND p.product_category IN ('Category1', 'Category2')
),
product_stats AS (
    SELECT
        product_id,
        product_name,
        product_category,
        COUNT(order_id) AS orders_count,
        COUNT(DISTINCT client_id) AS active_clients_count
    FROM filtered_orders
    GROUP BY
        product_id,
        product_name,
        product_category
),
average_stats AS (
    SELECT
        AVG(orders_count) AS avg_orders_count
    FROM product_stats
)
SELECT
    ps.product_id,
    ps.product_name,
    ps.product_category,
    ps.orders_count,
    ps.active_clients_count
FROM product_stats AS ps
CROSS JOIN average_stats AS av
WHERE ps.orders_count > av.avg_orders_count
ORDER BY
    ps.orders_count DESC,
    ps.active_clients_count DESC,
    ps.product_id ASC
LIMIT 10;



SET enable_seqscan = OFF;

EXPLAIN ANALYZE
WITH filtered_orders AS (
    SELECT
        o.order_id,
        o.order_date,
        p.product_id,
        p.product_name,
        p.product_category,
        c.id AS client_id
    FROM opt_orders AS o
    JOIN opt_products AS p
        ON o.product_id = p.product_id
    JOIN opt_clients AS c
        ON o.client_id = c.id
    WHERE o.order_date >= DATE '2024-01-01'
      AND c.status = 'active'
      AND p.product_category IN ('Category1', 'Category2')
),
product_stats AS (
    SELECT
        product_id,
        product_name,
        product_category,
        COUNT(order_id) AS orders_count,
        COUNT(DISTINCT client_id) AS active_clients_count
    FROM filtered_orders
    GROUP BY
        product_id,
        product_name,
        product_category
),
average_stats AS (
    SELECT
        AVG(orders_count) AS avg_orders_count
    FROM product_stats
)
SELECT
    ps.product_id,
    ps.product_name,
    ps.product_category,
    ps.orders_count,
    ps.active_clients_count
FROM product_stats AS ps
CROSS JOIN average_stats AS av
WHERE ps.orders_count > av.avg_orders_count
ORDER BY
    ps.orders_count DESC,
    ps.active_clients_count DESC,
    ps.product_id ASC
LIMIT 10;

RESET enable_seqscan;
