WITH staged_orders AS (
    SELECT * FROM {{ ref('stg_sales_orders') }}
)

SELECT DISTINCT
    CAST(transaction_at AS DATE)          AS date_key,
    YEAR(transaction_at)                  AS year,
    MONTH(transaction_at)                 AS month,
    MONTHNAME(transaction_at)             AS month_name,
    DAY(transaction_at)                   AS day_of_month,
    DAYNAME(transaction_at)               AS day_of_week,
    WEEKOFYEAR(transaction_at)            AS week_of_year,
    QUARTER(transaction_at)               AS quarter
FROM staged_orders
WHERE transaction_at IS NOT NULL