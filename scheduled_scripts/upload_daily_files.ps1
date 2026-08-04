# Set variables
$SNOWFLAKE_ACCOUNT = "KUORADO-NZ46959"
$SNOWFLAKE_USER    = "SVC_DBT_NORTHERN_RIDGE"
$PRIVATE_KEY_PATH  = "C:/users/LENOVO/rsa_key.p8"
$LOCAL_DATA_DIR    = "D:/Portfolio/Northern-Ridge/northern-ridge-data-platform"

Write-Host "🚀 Starting daily data upload to Snowflake Internal Stage..." -ForegroundColor Cyan

# Execute SnowSQL with forward slashes in file paths
snowsql -a $SNOWFLAKE_ACCOUNT `
        -u $SNOWFLAKE_USER `
        --private-key-path $PRIVATE_KEY_PATH `
        -r NR_DATA_ENGINEER `
        -d NORTHERN_RIDGE_DB `
        -s BRONZE `
        -w NORTHERN_RIDGE_WH `
        -q "PUT file://$LOCAL_DATA_DIR/*.csv @STG_LANDING_ZONE AUTO_COMPRESS=FALSE OVERWRITE=TRUE; PUT file://$LOCAL_DATA_DIR/*.json @STG_LANDING_ZONE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;"

# Check exit status
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ SUCCESS: All CSV and JSON files successfully uploaded to @NORTHERN_RIDGE_DB.BRONZE.STG_LANDING_ZONE!" -ForegroundColor Green
} else {
    Write-Host "`n❌ ERROR: Upload failed with exit code $LASTEXITCODE. Please check the SnowSQL log output above." -ForegroundColor Red
}