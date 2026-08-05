WITH raw_data AS (
    SELECT 
        raw_payload,
        _ingested_at
    FROM {{ source('bronze', 'RAW_PRODUCT_CATALOG') }}
)

SELECT
    raw_payload:product_id::VARCHAR           AS product_id,
    raw_payload:name::VARCHAR                 AS product_name,
    raw_payload:category::VARCHAR             AS category,
    raw_payload:subcategory::VARCHAR          AS subcategory,
    raw_payload:price_cad::NUMBER(10,2)       AS unit_price_cad,
    raw_payload:is_active::BOOLEAN            AS is_active,
    raw_payload:attributes                    AS extra_attributes_json,
    _ingested_at                              AS ingested_at
FROM raw_data