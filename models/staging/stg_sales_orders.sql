WITH raw_orders AS (
    SELECT 
        order_id::VARCHAR                     AS order_id,
        customer_id::VARCHAR                  AS customer_id,
        store_id::VARCHAR                     AS store_id,
        city::VARCHAR                         AS city,
        province::VARCHAR                     AS province,
        product_id::VARCHAR                   AS product_id,
        quantity::INT                         AS quantity,
        unit_price_cad::NUMBER(10,2)          AS unit_price_cad,
        total_amount_cad::NUMBER(10,2)        AS total_amount_cad,
        order_status::VARCHAR                 AS order_status,
        TO_TIMESTAMP_NTZ(transaction_timestamp) AS transaction_at,
        _file_name,
        _ingested_at                          AS ingested_at
    FROM {{ source('bronze', 'RAW_SALES_ORDERS') }}
)

SELECT * FROM raw_orders