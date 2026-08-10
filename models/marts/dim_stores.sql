WITH staged_stores AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
)

SELECT DISTINCT
    -- Primary Key
    store_id,

    -- Attributes
    city,
    province,

    -- Metadata
    MIN(ingested_at)                                AS updated_at

FROM staged_stores
WHERE store_id IS NOT NULL
GROUP BY store_id, city, province