WITH staged_customers AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
)

SELECT DISTINCT
    -- Primary Key
    customer_id,

    -- Attributes
    city,
    province,

    -- Metadata
    MIN(ingested_at)                                AS updated_at

FROM staged_customers
WHERE customer_id IS NOT NULL
GROUP BY customer_id, city, province