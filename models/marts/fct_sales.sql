WITH staged_orders AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
),

staged_products AS (
    SELECT product_id, unit_price_cad FROM {{ ref('stg_product_catalog') }}
)

SELECT
    -- Primary Key / Unique Line Item ID
    o.order_id,
    
    -- Foreign Keys
    o.product_id,
    o.customer_id,
    
    -- Dates & Timestamps
    CAST(o.transaction_at AS DATE)           AS order_date,
    o.transaction_at as order_timestamp,

    -- Measures & Metrics
    o.quantity,
    p.unit_price_cad,
    (o.quantity * p.unit_price_cad)::NUMBER(10,2) AS total_amount_cad,

    -- Status Flags
    o.order_status,
    
    -- Lineage
    o.ingested_at

FROM staged_orders o
LEFT JOIN staged_products p 
    ON o.product_id = p.product_id