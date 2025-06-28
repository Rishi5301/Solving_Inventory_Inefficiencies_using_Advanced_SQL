# QueryRav – Solving Inventory Inefficiencies Using SQL

## 📌 Project Overview

Urban Retail Co., a growing mid-sized retail chain, faces major challenges in inventory management due to reactive planning and underutilized data analytics. This project — **QueryRav** — aims to design a SQL-driven analytics solution to monitor inventory trends, detect inefficiencies, and deliver actionable insights for better stock control, cost management, and demand fulfillment.

---

## 📂 Dataset Summary

* **Time Period**: 730 days (2 years)
* **Granularity**: Daily per store-product-region combination
* **Stores**: 5 stores across 4 regions (North, South, East, West)
* **Products**: 30 products from 5 categories (Clothing, Electronics, Groceries, Toys, Furniture)
* **Data Quality**: Complete, with no missing values

---

## 📊 Key Features of the Data

* **Dynamic Pricing & Promotions**
* **Daily Inventory & Sales Tracking**
* **Weather Conditions per Region**
* **Holiday & Promotion Flags**

---

## 🛠 Schema Design (ERD Overview)

* `date_table`: Seasonal trends and calendar context
* `product`: Product ID and category
* `store`: Store ID and regional info
* `inventory`: Core fact table for sales, stock levels, and forecasts
* `sales_table`: Pricing, discounts, and promotions
* `inventory_calc_para`: Stores calculated metrics like lead time

---

## 📈 Analytical Modules & SQL Logic

### 1. Inventory Gap Detection

**Purpose**: Detect discrepancies between expected and actual inventory
**SQL File**: [`inventory_gap.sql`](SQL_Scripts/inventory_gap.sql)

```sql
SELECT 
    i.product_id, 
    i.store_number, 
    i.date,
    (LAG(i.inventory_level) OVER w - LAG(i.units_sold) OVER w + LAG(i.units_order) OVER w) AS expected_inventory,
    i.inventory_level AS actual_inventory,
    (i.inventory_level - (LAG(i.inventory_level) OVER w - LAG(i.units_sold) OVER w + LAG(i.units_order) OVER w)) AS inventory_gap
FROM inventory i
WINDOW w AS (PARTITION BY i.product_id, i.store_number ORDER BY i.date);
```

### 2. Lead Time Estimation

**SQL File**: [`lead_time_calc.sql`](SQL_Scripts/lead_time_calc.sql)

### 3. Reorder Point and Safety Stock

**SQL File**: [`reorder_point.sql`](SQL_Scripts/reorder_point.sql)

### 4. Lost Revenue Estimation

**SQL File**: [`lost_revenue.sql`](SQL_Scripts/lost_revenue.sql)

---

## 📌 Key Business Insights

* **Promotion Boosts Sales**: Holidays significantly increase units sold.
* **Rain Affects Sales**: Sales dip during rainy days, even for high-demand products.
* **Seasonal Trends**: Clothing sales peak during winter (Dec–Jan).
* **Regional Distribution**: High-performing products are in demand across all regions.

---

## 💡 Recommendations

* **Redistribute Overstocked Items** to reduce waste and meet demand in other locations.
* **Optimize Reorder Points** per store-product combination to reflect localized demand and lead times.
* **Focus on High Lost-Revenue SKUs** to minimize missed sales (₹1.29 Cr lost in 2 years).
* **Regularly Update Safety Stock and Lead Times** based on real-time data.

---

## 🚀 Future Scope

* **AI-based Dynamic Pricing**
* **Unified Multi-Channel Inventory Systems**
* **Training Teams for Advanced Analytics**
* **Partnering with Tech Providers & Academia**

---

## 🧠 Technologies Used

* **SQL** for data extraction and analytics
* **Relational Database Design** (Normalized ERD)
* **Advanced SQL Functions**: `LAG()`, `DATEDIFF()`, `STDDEV()`, etc.

---

## 👨‍💻 Contributors

* **Collaborators**: Ayushi Jain, Rajarshi Verma, Staphy Berwal, Vidhan Agarwal
