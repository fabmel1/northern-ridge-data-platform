WITH staged_products AS (
    SELECT * FROM {{ ref('stg_product_catalog') }}
)

SELECT
    -- Primary Key
    product_id,

    -- Attributes
    product_name,
    category,
    subcategory,
    unit_price_cad,
    is_active,

    -- Flattened attributes from extra_attributes_json (if using hybrid pattern)
    extra_attributes_json:color::VARCHAR       AS attribute_color,
    extra_attributes_json:fill::VARCHAR        AS attribute_fill,
    extra_attributes_json:waterproof::BOOLEAN  AS is_waterproof,

    -- Metadata
    ingested_at                                AS updated_at

FROM staged_products