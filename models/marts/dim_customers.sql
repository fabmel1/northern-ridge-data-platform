WITH staged_customers AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
),

ranked_customers AS (
    SELECT
        customer_id,
        city,
        province,
        ingested_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY ingested_at DESC
        ) AS rn
    FROM staged_customers
    WHERE customer_id IS NOT NULL
)

SELECT DISTINCT
    -- Primary Key
    customer_id,

    -- Attributes
    city,
    province,

    -- Metadata
    MIN(ingested_at)                                AS updated_at

FROM ranked_customers
WHERE rn = 1