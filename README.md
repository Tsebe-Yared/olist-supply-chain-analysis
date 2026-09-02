# 🚚 Olist E-Commerce Supply Chain & Fulfillment Analysis

An end-to-end data analytics project diagnosing supply chain lead times, delivery SLA compliance, and regional fulfillment bottlenecks across 100k+ Brazilian e-commerce orders (2016–2018).

---

## 📌 Executive Summary

* **Overall On-Time Delivery (OTD) Rate:** **92.09%** platform-wide SLA compliance.
* **Lead Time:** Average fulfillment lead time sits at **12.5 days**.
* **Regional Bottlenecks:** Significant delivery SLA breakdown in northeastern Brazilian states—**Maranhão (MA)** at **79.62% OTD** (~20.4% delay rate) and **Piauí (PI)** at **84.51% OTD**.
* **Core Insight:** While high-density regions (e.g., São Paulo) run lean fulfillment schedules, logistics constraints in remote states drag down overall customer satisfaction and fulfillment metrics.

---

## 🛠️ Tech Stack & Pipeline Architecture

1. **Database & Extraction (PostgreSQL / pgAdmin):**
   * Engineered a consolidated relational SQL view (`vw_supply_chain_performance`) joining `orders`, `customers`, and `order_items`.
   * Enforced data integrity, handled `NULL` timestamps, and pre-calculated delivery lead times.

2. **Exploratory Data Analysis (Python / Pandas):**
   * Validated data types, distributions, and outliers in delivery days.
   * Standardized state code values and clean-capitalized operational city names (e.g., `Bauru`, `Rio De Janeiro`).

3. **Business Intelligence & Dashboarding (Power BI Desktop):**
   * Configured an optimized single-table data model (`vw_supply_chain_performance`).
   * Developed custom DAX measures for SLA tracking and lead times.
   * Built interactive Time-Series and Regional Diagnostic visuals.

---

## 📊 Key DAX Measures

```dax
// 1. Total Order Count
Total Orders = COUNTROWS('vw_supply_chain_performance')

// 2. Delayed Orders Count
Delayed Orders = SUM('vw_supply_chain_performance'[is_delayed])

// 3. On-Time Delivery (OTD) Rate %
OTD Rate % = 
DIVIDE(
    [Total Orders] - [Delayed Orders], 
    [Total Orders], 
    0
)

// 4. Average Delivery Lead Time (Days)
Avg Lead Time Days = AVERAGE('vw_supply_chain_performance'[actual_delivery_days])
