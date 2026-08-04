import pandas as pd
import numpy as np
import json
import random
from datetime import datetime, timedelta

# Configuración de reproducibilidad
np.random.seed(42)

# 1. Configuración de parámetros canadienses
ALBERTA_CITIES = ['Calgary', 'Edmonton', 'Red Deer', 'Lethbridge', 'Medicine Hat']
STORES = [f"NR-STORE-{i:03d}" for i in range(101, 108)]

# 2. Generar Catálogo de Productos (Semiestructurado - JSON)
catalog = [
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
    }
]

with open('product_catalog.json', 'w') as f:
    json.dump(catalog, f, indent=4)

print("✅ 'product_catalog.json' generado con éxito.")

# 3. Generar Transacciones de Ventas (CSV Tabular)
n_rows = 1000
start_date = datetime(2026, 1, 1)

orders = []
for i in range(1, n_rows + 1):
    order_date = start_date + timedelta(days=random.randint(0, 180), minutes=random.randint(0, 1440))
    product = random.choice(catalog)
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
        "transaction_timestamp": order_date.strftime("%Y-%m-%d %H:%M:%S")
    })

df_orders = pd.DataFrame(orders)
df_orders.to_csv('sales_orders.csv', index=False)

print("✅ 'sales_orders.csv' generado con éxito (1,000 transacciones).")