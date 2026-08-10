WITH silver_orders AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
)

SELECT
    order_id,
    customer_id,
    store_id,
    product_id,
    CAST(transaction_at AS DATE) AS date_key,
    order_status,
    quantity,
    unit_price_cad,
    total_amount_cad,
    transaction_at
FROM silver_orders