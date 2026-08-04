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
CREATE OR REPLACE PROCEDURE SP_LOAD_RAW_PRODUCT_CATALOG()
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    COPY INTO BRONZE.RAW_PRODUCT_CATALOG (raw_payload)
    FROM @BRONZE.STG_LANDING_ZONE/product_catalog.json
    FILE_FORMAT = (FORMAT_NAME = 'BRONZE.FF_JSON_GENERIC')
    ON_ERROR = 'CONTINUE';
    
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
        transaction_timestamp, 
        _file_name
    )
    FROM (
        SELECT 
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, METADATA$FILENAME
        FROM @BRONZE.STG_LANDING_ZONE
    )
    FILE_FORMAT = (FORMAT_NAME = 'BRONZE.FF_CSV_GENERIC')
    PATTERN = '.*sales_orders.*\.csv'
    ON_ERROR = 'CONTINUE';
    
    RETURN 'SUCCESS: Sales orders loaded into BRONZE.RAW_SALES_ORDERS';
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