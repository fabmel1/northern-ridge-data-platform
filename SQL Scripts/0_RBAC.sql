-- ============================================================================
-- 1. ROLE CREATION (Execute as USERADMIN)
-- ============================================================================
USE ROLE USERADMIN;

-- Create Functional Roles
CREATE ROLE IF NOT EXISTS NR_DATA_ENGINEER
    COMMENT = 'Role for DE team with write access to Bronze, Silver, Gold';

CREATE ROLE IF NOT EXISTS NR_DATA_ANALYST
    COMMENT = 'Role for Analysts with read-only access to Gold dimensional models';

-- Create Service User for dbt / Orchestration
CREATE USER IF NOT EXISTS SVC_DBT_NORTHERN_RIDGE
    PASSWORD = 'NorthernRidgePass123!' -- In production, use RSA Key-Pair Auth
    DEFAULT_ROLE = NR_DATA_ENGINEER
    DEFAULT_WAREHOUSE = NORTHERN_RIDGE_WH
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT = 'Service account for automated dbt pipelines';


-- ============================================================================
-- 2. ROLE HIERARCHY & USER GRANTS (Execute as SECURITYADMIN)
-- ============================================================================
USE ROLE SECURITYADMIN;

-- Assign Service User to the Data Engineer role
GRANT ROLE NR_DATA_ENGINEER TO USER SVC_DBT_NORTHERN_RIDGE;

-- Grant USAGE on Database and Schema
GRANT USAGE ON DATABASE NORTHERN_RIDGE_DB TO ROLE NR_DATA_ENGINEER;
GRANT USAGE ON SCHEMA NORTHERN_RIDGE_DB.BRONZE TO ROLE NR_DATA_ENGINEER;

GRANT READ, WRITE ON STAGE NORTHERN_RIDGE_DB.BRONZE.STG_LANDING_ZONE TO ROLE NR_DATA_ENGINEER;

GRANT USAGE ON WAREHOUSE NORTHERN_RIDGE_WH TO ROLE NR_DATA_ENGINEER;

-- Assign your personal Snowflake user to the DE role (replace 'YOUR_SNOWFLAKE_USERNAME')
SET CURRENT_U = CURRENT_USER();
GRANT ROLE NR_DATA_ENGINEER TO USER IDENTIFIER($CURRENT_U);

-- Connect custom roles to SYSADMIN so system admins retain inherited management rights
GRANT ROLE NR_DATA_ENGINEER TO ROLE SYSADMIN;
GRANT ROLE NR_DATA_ANALYST TO ROLE SYSADMIN;


-- ============================================================================
-- 3. OBJECT PRIVILEGES FOR NR_DATA_ENGINEER
-- ============================================================================
-- Grant Warehouse Usage
GRANT USAGE ON WAREHOUSE NORTHERN_RIDGE_WH TO ROLE NR_DATA_ENGINEER;

-- Grant Database Usage
GRANT USAGE ON DATABASE NORTHERN_RIDGE_DB TO ROLE NR_DATA_ENGINEER;

-- Grant Full Permissions across Schemas for DEs
GRANT ALL PRIVILEGES ON SCHEMA NORTHERN_RIDGE_DB.BRONZE TO ROLE NR_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON SCHEMA NORTHERN_RIDGE_DB.SILVER TO ROLE NR_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON SCHEMA NORTHERN_RIDGE_DB.GOLD TO ROLE NR_DATA_ENGINEER;

-- Grant Future Table/View Privileges
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA NORTHERN_RIDGE_DB.BRONZE TO ROLE NR_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA NORTHERN_RIDGE_DB.SILVER TO ROLE NR_DATA_ENGINEER;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA NORTHERN_RIDGE_DB.GOLD TO ROLE NR_DATA_ENGINEER;


-- ============================================================================
-- 4. OBJECT PRIVILEGES FOR NR_DATA_ANALYST
-- ============================================================================
GRANT USAGE ON WAREHOUSE NORTHERN_RIDGE_WH TO ROLE NR_DATA_ANALYST;
GRANT USAGE ON DATABASE NORTHERN_RIDGE_DB TO ROLE NR_DATA_ANALYST;
GRANT USAGE ON SCHEMA NORTHERN_RIDGE_DB.GOLD TO ROLE NR_DATA_ANALYST;

-- Read-only on Gold tables
GRANT SELECT ON ALL TABLES IN SCHEMA NORTHERN_RIDGE_DB.GOLD TO ROLE NR_DATA_ANALYST;
GRANT SELECT ON FUTURE TABLES IN SCHEMA NORTHERN_RIDGE_DB.GOLD TO ROLE NR_DATA_ANALYST;