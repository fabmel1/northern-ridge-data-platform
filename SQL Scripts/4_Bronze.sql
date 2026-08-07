USE DATABASE NORTHERN_RIDGE_DB;
USE DATABASE NORTHERN_RIDGE_DB;
USE SCHEMA BRONZE;

-- 1. Raw Sales Orders (Structured CSV destination)
CREATE TABLE IF NOT EXISTS RAW_SALES_ORDERS (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    store_id VARCHAR(50),
    city VARCHAR(100),
    province VARCHAR(10),
    product_id VARCHAR(50),
    quantity NUMBER(10, 0),
    unit_price_cad NUMBER(10, 2),
    total_amount_cad NUMBER(10, 2),
    order_status VARCHAR(50),
    transaction_timestamp TIMESTAMP_NTZ,
    _ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name VARCHAR(255)
);

-- 2. Raw Product Catalog (Semi-structured JSON destination)
CREATE TABLE IF NOT EXISTS RAW_PRODUCT_CATALOG (
    raw_payload VARIANT,
    _ingested_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Stored Procedure to load JSON from stage into raw table
CREATE OR REPLACE PROCEDURE NORTHERN_RIDGE_DB.BRONZE.SP_LOAD_RAW_PRODUCT_CATALOG()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
  -- STEP 1: CREATE A TRANSIENT TABLE (Temporary storage)
  CREATE OR REPLACE TRANSIENT TABLE NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG_STAGE LIKE NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG;

  -- STEP 2: LOAD NEW DATA INTO THE TRANSIENT TABLE
  COPY INTO NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG_STAGE (raw_payload, _INGESTED_AT)
  FROM (
    SELECT 
      $1 AS raw_payload,
      CURRENT_TIMESTAMP() AS _INGESTED_AT
    FROM @NORTHERN_RIDGE_DB.BRONZE.STG_LANDING_ZONE
  )
  PATTERN = '.*product_catalog.*\.json.*'
  FILE_FORMAT = (TYPE = 'JSON', STRIP_OUTER_ARRAY = TRUE)
  PURGE = TRUE;

  -- STEP 3: MERGE DATA FROM TRANSIENT TO FINAL BRONZE TABLE
  MERGE INTO NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG AS T
  USING NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG_STAGE AS S
  ON S.raw_payload:product_id::VARCHAR = T.raw_payload:product_id::VARCHAR
  WHEN MATCHED THEN
    UPDATE SET T.raw_payload = S.raw_payload, T._INGESTED_AT = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (raw_payload, _INGESTED_AT) VALUES (S.raw_payload, CURRENT_TIMESTAMP());

  -- STEP 4: CLEAN UP
  DROP TABLE NORTHERN_RIDGE_DB.BRONZE.RAW_PRODUCT_CATALOG_STAGE;

  RETURN 'SUCCESS: Product catalog loaded into BRONZE.RAW_PRODUCT_CATALOG';
END;
$$;

-- 4. Raw Sales Orders (Structured CSV destination)
CREATE OR REPLACE PROCEDURE BRONZE.SP_LOAD_RAW_SALES_ORDERS()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    TRUNCATE TABLE NORTHERN_RIDGE_DB.BRONZE.RAW_SALES_ORDERS;

    COPY INTO BRONZE.RAW_SALES_ORDERS (
        order_id, 
        customer_id, 
        store_id, 
        city, 
        province, 
        product_id, 
        quantity, 
        unit_price_cad, 
        total_amount_cad, 
        order_status,
        transaction_timestamp, 
        _file_name
    )
    FROM (
        SELECT 
            $1::VARCHAR AS order_id, 
            $2::VARCHAR AS customer_id, 
            $3::VARCHAR AS store_id, 
            $4::VARCHAR AS city, 
            $5::VARCHAR AS province, 
            $6::VARCHAR AS product_id, 
            $7::NUMBER  AS quantity, 
            $8::NUMBER  AS unit_price_cad, 
            $9::NUMBER  AS total_amount_cad, 
            
            -- Detect layout by checking if $11 has content
            -- Old file (10 cols): $10 is timestamp, $11 is null/missing -> order_status should be NULL
            -- New file (11 cols): $10 is order_status, $11 is timestamp -> order_status is $10
            CASE 
                WHEN $11 IS NOT NULL AND $11 != '' THEN $10 
                ELSE NULL 
            END AS order_status,
            
            -- Old file (10 cols): timestamp is in $10
            -- New file (11 cols): timestamp is in $11
            CASE 
                WHEN $11 IS NOT NULL AND $11 != '' THEN $11 
                ELSE $10 
            END AS transaction_timestamp,
            
            METADATA$FILENAME AS _file_name
        FROM @BRONZE.STG_LANDING_ZONE
    )
    FILE_FORMAT = (
        FORMAT_NAME = 'BRONZE.FF_CSV_GENERIC',
        -- CRITICAL: Skip header so header strings ('order_status') aren't treated as data
        SKIP_HEADER = 1 
    )
    PATTERN = '.*sales_orders.*\.csv'
    ON_ERROR = 'CONTINUE'
    PURGE = TRUE;

    RETURN 'Successfully loaded raw sales orders.';
END;
$$;

-- 5. Ingest All Landing Zone Data
CREATE OR REPLACE PROCEDURE BRONZE.SP_INGEST_ALL_LANDING_ZONE()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_res_json VARCHAR;
    v_res_csv  VARCHAR;
BEGIN
    CALL BRONZE.SP_LOAD_RAW_PRODUCT_CATALOG() INTO :v_res_json;
    CALL BRONZE.SP_LOAD_RAW_SALES_ORDERS() INTO :v_res_csv;
    
    RETURN v_res_json || ' | ' || v_res_csv;
END;
$$;

-- 6. Create Task for Automated Ingestion
-- Check the timezone here
-- https://data.iana.org/time-zones/tzdb-2025b/zone1970.tab
CREATE OR REPLACE TASK BRONZE.TSK_AUTO_INGEST_BRONZE
    WAREHOUSE = NORTHERN_RIDGE_WH
    SCHEDULE = 'USING CRON 30 7 * * * America/Edmonton'  -- Every day at 07:30 Central Time
AS
    CALL BRONZE.SP_INGEST_ALL_LANDING_ZONE();

-- Tasks are created in SUSPENDED state by default; enable it:
ALTER TASK BRONZE.TSK_AUTO_INGEST_BRONZE RESUME;

/*
-- Manually execute the task immediately
EXECUTE TASK BRONZE.TSK_AUTO_INGEST_BRONZE;

-- Check Bronze table counts
SELECT COUNT(*) FROM BRONZE.RAW_SALES_ORDERS;
SELECT COUNT(*) FROM BRONZE.RAW_PRODUCT_CATALOG;
 */



---Add ons

--Adding order_status column
ALTER TABLE NORTHERN_RIDGE_DB.BRONZE.RAW_SALES_ORDERS 
ADD COLUMN order_status VARCHAR(50);