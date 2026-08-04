WITH raw_data AS (
    SELECT 
        raw_payload,
        _loaded_at
    FROM {{ source('bronze', 'RAW_PRODUCT_CATALOG') }}
)

SELECT
    raw_payload:product_id::VARCHAR           AS product_id,
    raw_payload:product_name::VARCHAR         AS product_name,
    raw_payload:category::VARCHAR             AS category,
    raw_payload:subcategory::VARCHAR          AS subcategory,
    raw_payload:unit_price_cad::NUMBER(10,2)  AS unit_price_cad,
    raw_payload:is_active::BOOLEAN            AS is_active,
    _loaded_at                                AS ingested_at
FROM raw_data