import pandas as pd
import numpy as np
import json
import random
from datetime import datetime, timedelta

# Set seed for reproducibility
np.random.seed(42)

# 1. Canadian Configuration Parameters
ALBERTA_CITIES = ['Calgary', 'Edmonton', 'Red Deer', 'Lethbridge', 'Medicine Hat']
STORES = [f"NR-STORE-{i:03d}" for i in range(101, 108)]
ORDER_STATUSES = ['in_progress', 'shipped', 'delivered', 'returned', 'cancelled']

# 2. Generate Product Catalog (Semi-structured - JSON)
catalog = [
    # --- Existing Products ---
    {
        "product_id": "PRD-1001",
        "name": "Banff Thermal Winter Parka",
        "category": "Apparel",
        "price_cad": 299.99,
        "attributes": {"color": "Midnight Blue", "waterproof": True, "fill": "Down 700"}
    },
    {
        "product_id": "PRD-1002",
        "name": "Jasper 4-Person All-Weather Tent",
        "category": "Outdoor Gear",
        "price_cad": 450.00,
        "attributes": {"capacity": 4, "season": "4-season", "weight_kg": 4.2}
    },
    {
        "product_id": "PRD-1003",
        "name": "Bow Valley Leather Recliner",
        "category": "Home & Furniture",
        "price_cad": 899.50,
        "attributes": {"material": "Genuine Leather", "recline_type": "Power"}
    },
    {
        "product_id": "PRD-1004",
        "name": "Rocky Mountain Hiking Boots",
        "category": "Footwear",
        "price_cad": 189.99,
        "attributes": {"size_range": [7, 13], "goretex": True}
    },
    # --- 5 New Products Added ---
    {
        "product_id": "PRD-1005",
        "name": "Canmore Carbon Trekking Poles",
        "category": "Outdoor Gear",
        "price_cad": 129.99,
        "attributes": {"material": "Carbon Fiber", "adjustable": True}
    },
    {
        "product_id": "PRD-1006",
        "name": "Kananaskis Hydration Pack 15L",
        "category": "Outdoor Gear",
        "price_cad": 85.00,
        "attributes": {"capacity_liters": 15, "reservoir_included": True}
    },
    {
        "product_id": "PRD-1007",
        "name": "Lake Louise Wool Knit Sweater",
        "category": "Apparel",
        "price_cad": 149.50,
        "attributes": {"material": "Merino Wool", "gender": "Unisex"}
    },
    {
        "product_id": "PRD-1008",
        "name": "Calgary Trail Headlamp 800 Lumens",
        "category": "Electronics",
        "price_cad": 64.99,
        "attributes": {"lumens": 800, "rechargeable": True}
    },
    {
        "product_id": "PRD-1009",
        "name": "Edmonton Cast Iron Camp Dutch Oven",
        "category": "Cookware",
        "price_cad": 110.00,
        "attributes": {"volume_quarts": 6, "pre_seasoned": True}
    }
]

# Save updated product catalog
with open('product_catalog.json', 'w') as f:
    json.dump(catalog, f, indent=4)

print("✅ 'product_catalog.json' generated successfully (9 products total).")

# 3. Generate Sales Transactions (Tabular CSV)
# Starting parameters: 200 orders starting from August 8, 2026
n_rows = 200
start_order_id = 1006  # Adjust based on where your previous IDs left off
start_date = datetime(2026, 8, 8)

orders = []
for i in range(start_order_id, start_order_id + n_rows):
    # Generates random timestamps over 14 days starting from Aug 8, 2026
    order_date = start_date + timedelta(days=random.randint(0, 14), minutes=random.randint(0, 1440))
    product = random.choice(catalog)  # Randomly picks from all 9 products (old and new)
    qty = random.randint(1, 3)
    
    orders.append({
        "order_id": f"ORD-2026-{i:05d}",
        "customer_id": f"CUST-{random.randint(5000, 5200)}",
        "store_id": random.choice(STORES),
        "city": random.choice(ALBERTA_CITIES),
        "province": "AB",
        "product_id": product["product_id"],
        "quantity": qty,
        "unit_price_cad": product["price_cad"],
        "total_amount_cad": round(qty * product["price_cad"], 2),
        "order_status": random.choice(ORDER_STATUSES),
        "transaction_timestamp": order_date.strftime("%Y-%m-%d %H:%M:%S")
    })

# Export new batch to CSV
df_orders = pd.DataFrame(orders)
file_name = 'sales_orders_08082026.csv'
df_orders.to_csv(file_name, index=False)

print(f"✅ '{file_name}' generated successfully ({n_rows} transactions starting from 2026-08-08).")