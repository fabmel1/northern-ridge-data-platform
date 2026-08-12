WITH staged_stores AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
),

ranked_stores AS (
    SELECT
        store_id,
        city,
        province,
        ingested_at,
        ROW_NUMBER() OVER (
            PARTITION BY store_id 
            ORDER BY ingested_at DESC
        ) AS rn
    FROM staged_stores
    WHERE store_id IS NOT NULL
)

SELECT
    store_id,
    city,
    province,
    ingested_at AS updated_at
FROM ranked_stores
WHERE rn = 1