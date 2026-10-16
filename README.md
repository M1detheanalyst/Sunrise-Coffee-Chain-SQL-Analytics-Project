# Sunrise Coffee Chain SQL Analytics Project

An end-to-end SQL analytics project built on a star-schema data warehouse to analyse store-level financial performance, product mix, loyalty programme effectiveness, cost vulnerability, and strategic investment priorities across a UK coffee chain.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Database Schema](#database-schema)
- [Data Quality Checks](#data-quality-checks)
- [Analytical Questions Answered](#analytical-questions-answered)
- [Insight Summary](#insight-summary)
- [Key Metrics](#key-metrics)
- [How to Use](#how-to-use)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Potential Extensions](#potential-extensions)
- [Author](#author)

---

## Project Overview

This project models and analyses the operational and financial performance of Sunrise Coffee Chain a UK-based coffee chain with stores across 12 regions using a star schema, the standard data warehousing pattern that separates measurable facts from descriptive dimensions. The SQL file covers:

- **Schema Design**: dimension and fact table creation with appropriate primary and foreign keys, plus performance indexes on every foreign-key column
- **Staging Layer**: a full ETL staging pattern raw data lands in staging tables, passes through quality checks, and is promoted into production tables via clean `INSERT … SELECT` statements
- **Data Quality Checks**: null audits, duplicate-key checks, and range/logic validation across all five tables before any data is loaded
- **Analytical Queries**: 10 purpose-built queries answering real business questions about store profitability, format performance, cost structure, loyalty impact, product mix, seasonal trends, and strategic investment prioritisation

The project is structured around a central business question: **Which stores, formats, products, and programmes are driving Sunrise Coffee's profitability and where does the business need to act?**

---

## Database Schema

The schema follows a **star schema** pattern with two fact tables and three shared dimension tables, covering daily transactional sales and monthly store-level profitability in a single, joined warehouse.

### Dimension Tables

**dim_date** Stores the full UK trading calendar used for time-based aggregations.

```sql
CREATE TABLE dim_date (
    date_id             INTEGER PRIMARY KEY,
    full_date           DATE,
    year                INTEGER,
    month_number        INTEGER,
    month_name          VARCHAR(20),
    quarter             INTEGER,
    week_number         INTEGER,
    day_of_week         VARCHAR(20),
    is_weekend          BOOLEAN,
    is_uk_bank_holiday  BOOLEAN,
    uk_trading_calender VARCHAR(50)
);
```

| Column | Type | Description |
|---|---|---|
| date_id | INTEGER | Primary key |
| full_date | DATE | Calendar date |
| year | INTEGER | Calendar year |
| month_number | INTEGER | Month number (1–12) |
| month_name | VARCHAR | Full month name |
| quarter | INTEGER | Quarter (1–4) |
| week_number | INTEGER | ISO week number |
| day_of_week | VARCHAR | Day name (Monday–Sunday) |
| is_weekend | BOOLEAN | True if Saturday or Sunday |
| is_uk_bank_holiday | BOOLEAN | True if a UK bank holiday |
| uk_trading_calender | VARCHAR | UK trading period label (e.g. Christmas-Period, Standard-Trading-Day) |

---

**dim_product** Holds product-level attributes, pricing, and margin data.

```sql
CREATE TABLE dim_product (
    product_id       INTEGER PRIMARY KEY,
    product_name     VARCHAR(100) NOT NULL UNIQUE,
    category         VARCHAR(50)  NOT NULL,
    unit_price_gbp   NUMERIC(10,2) NOT NULL,
    unit_cost_gbp    NUMERIC(10,2) NOT NULL,
    gross_margin_pct NUMERIC(5,2)  NOT NULL,
    loyalty_eligible BOOLEAN NOT NULL,
    product_status   VARCHAR(20) NOT NULL,
    launch_date      DATE
);
```

| Column | Type | Description |
|---|---|---|
| product_id | INTEGER | Primary key |
| product_name | VARCHAR | Unique product name |
| category | VARCHAR | Product category (Espresso-Drinks, Filter-Coffee, Food, Retail-Beans, Cold-Drinks, Merchandise) |
| unit_price_gbp | NUMERIC | Retail price in GBP |
| unit_cost_gbp | NUMERIC | Cost of goods in GBP |
| gross_margin_pct | NUMERIC | Gross margin as a percentage |
| loyalty_eligible | BOOLEAN | Whether the product earns or redeems loyalty points |
| product_status | VARCHAR | Active or discontinued |
| launch_date | DATE | Product launch date |

---

**dim_store** Describes each store's physical, operational, and financial attributes.

```sql
CREATE TABLE dim_store (
    store_id                  INTEGER PRIMARY KEY,
    store_name                VARCHAR(100) NOT NULL UNIQUE,
    store_format              VARCHAR(50)  NOT NULL,
    location_type             VARCHAR(50)  NOT NULL,
    region                    VARCHAR(100) NOT NULL,
    city                      VARCHAR(100) NOT NULL,
    monthly_rent_gbp          NUMERIC(12,2) NOT NULL,
    staff_headcount           INTEGER NOT NULL,
    monthly_staffing_cost_gbp NUMERIC(10,2) NOT NULL,
    loyalty_adoption_rate     NUMERIC(5,2)  NOT NULL,
    seating_capacity          INTEGER NOT NULL,
    opening_year              INTEGER,
    store_status              VARCHAR(20) NOT NULL
);
```

| Column | Type | Description |
|---|---|---|
| store_id | INTEGER | Primary key |
| store_name | VARCHAR | Unique store name |
| store_format | VARCHAR | High-Street or Transport-Hub |
| location_type | VARCHAR | City-Centre, Shopping-Centre, Suburban-High-Street, Train-Station |
| region | VARCHAR | UK region (12 regions including London, Scotland, Wales, Northern Ireland) |
| city | VARCHAR | City of the store |
| monthly_rent_gbp | NUMERIC | Monthly rent in GBP |
| staff_headcount | INTEGER | Number of staff |
| monthly_staffing_cost_gbp | NUMERIC | Monthly total staffing cost in GBP |
| loyalty_adoption_rate | NUMERIC | Proportion of customers enrolled in the loyalty programme |
| seating_capacity | INTEGER | Number of seats |
| opening_year | INTEGER | Year the store opened |
| store_status | VARCHAR | Active or closed |

---

### Fact Tables

**fact_daily_sales** The daily transactional fact table, recording revenue, product mix, footfall, and loyalty activity at the store × date × product grain.

```sql
CREATE TABLE fact_daily_sales (
    daily_sale_id               INTEGER,
    store_id                    INTEGER REFERENCES dim_store(store_id),
    date_id                     INTEGER REFERENCES dim_date(date_id),
    product_id                  INTEGER REFERENCES dim_product(product_id),
    total_revenue_gbp           NUMERIC(12,2),
    total_transactions          INTEGER,
    avg_transaction_value_gbp   NUMERIC(12,2),
    loyalty_transactions        INTEGER,
    loyalty_redemption_cost_gbp NUMERIC(12,2),
    footfall                    INTEGER,
    espresso_revenue_gbp        NUMERIC(12,2),
    filter_revenue_gbp          NUMERIC(12,2),
    food_revenue_gbp            NUMERIC(12,2),
    retail_beans_revenue_gbp    NUMERIC(12,2),
    daily_gross_profit_gbp      NUMERIC(12,2),
    staff_count                 INTEGER,
    total_staff_hours           NUMERIC(10,2),
    shift_pattern               VARCHAR(50),
    avg_dwell_time_minutes      NUMERIC(10,2)
);
```

| Column | Type | Description |
|---|---|---|
| daily_sale_id | INTEGER | Record identifier |
| store_id | INTEGER | FK → dim_store |
| date_id | INTEGER | FK → dim_date |
| product_id | INTEGER | FK → dim_product |
| total_revenue_gbp | NUMERIC | Total revenue for the day |
| total_transactions | INTEGER | Number of customer transactions |
| avg_transaction_value_gbp | NUMERIC | Average spend per transaction |
| loyalty_transactions | INTEGER | Transactions involving loyalty activity |
| loyalty_redemption_cost_gbp | NUMERIC | Cost of loyalty redemptions on the day |
| footfall | INTEGER | Total footfall through the store |
| espresso_revenue_gbp | NUMERIC | Revenue from espresso-based drinks |
| filter_revenue_gbp | NUMERIC | Revenue from filter coffee |
| food_revenue_gbp | NUMERIC | Revenue from food items |
| retail_beans_revenue_gbp | NUMERIC | Revenue from retail bean sales |
| daily_gross_profit_gbp | NUMERIC | Gross profit after product cost |
| staff_count | INTEGER | Number of staff on shift |
| total_staff_hours | NUMERIC | Total staff hours worked |
| shift_pattern | VARCHAR | Shift pattern label |
| avg_dwell_time_minutes | NUMERIC | Average customer dwell time in minutes |

---

**fact_store_monthly_profitability** The monthly store-level profitability fact table, capturing full P&L elements including rent, staffing, loyalty costs, and net profit at the store × month grain.

```sql
CREATE TABLE fact_store_monthly_profitability (
    monthly_profit_id            INTEGER,
    store_id                     INTEGER REFERENCES dim_store(store_id),
    date_id                      INTEGER REFERENCES dim_date(date_id),
    month_id                     VARCHAR(7),
    total_monthly_revenue_gbp    NUMERIC(12,2),
    total_monthly_cogs_gbp       NUMERIC(12,2),
    monthly_rent_gbp             NUMERIC(12,2),
    monthly_staffing_cost_gbp    NUMERIC(12,2),
    loyalty_redemption_cost_gbp  NUMERIC(12,2),
    net_profit_gbp               NUMERIC(12,2),
    net_profit_margin_pct        NUMERIC(8,2),
    avg_daily_footfall           NUMERIC(10,2),
    loyalty_member_revenue_pct   NUMERIC(8,2),
    loyalty_member_spend_gbp     NUMERIC(12,2),
    non_member_spend_gbp         NUMERIC(12,2),
    revenue_per_sqft_gbp         NUMERIC(12,2),
    peak_hour_transactions       INTEGER,
    dead_hour_transactions       INTEGER,
    avg_dwell_time_minutes       NUMERIC(10,2),
    rent_band                    VARCHAR(30),
    profitability_status         VARCHAR(30),

    UNIQUE (store_id, month_id)
);
```

| Column | Type | Description |
|---|---|---|
| monthly_profit_id | INTEGER | Record identifier |
| store_id | INTEGER | FK → dim_store |
| date_id | INTEGER | FK → dim_date |
| month_id | VARCHAR | Year-month label (e.g. 2023-01) |
| total_monthly_revenue_gbp | NUMERIC | Total revenue for the month |
| total_monthly_cogs_gbp | NUMERIC | Cost of goods sold for the month |
| monthly_rent_gbp | NUMERIC | Rent expense for the month |
| monthly_staffing_cost_gbp | NUMERIC | Total staffing cost for the month |
| loyalty_redemption_cost_gbp | NUMERIC | Loyalty redemption cost for the month |
| net_profit_gbp | NUMERIC | Net profit after all costs |
| net_profit_margin_pct | NUMERIC | Net profit as a percentage of revenue |
| avg_daily_footfall | NUMERIC | Average daily footfall across the month |
| loyalty_member_revenue_pct | NUMERIC | Share of revenue from loyalty members |
| loyalty_member_spend_gbp | NUMERIC | Total spend from loyalty members |
| non_member_spend_gbp | NUMERIC | Total spend from non-members |
| revenue_per_sqft_gbp | NUMERIC | Revenue per square foot |
| peak_hour_transactions | INTEGER | Transactions during peak hours |
| dead_hour_transactions | INTEGER | Transactions during off-peak hours |
| avg_dwell_time_minutes | NUMERIC | Average customer dwell time |
| rent_band | VARCHAR | Rent tier classification |
| profitability_status | VARCHAR | Profitable or Unprofitable |

---

## Data Quality Checks

Before any data is promoted from staging to production, the project runs a systematic three-layer QA process across all five tables:

- **Duplicate key checks**: primary keys (`date_id`, `product_id`, `store_id`, `daily_sale_id`, `monthly_profit_id`) and natural keys (`product_name`, `store_name`, `full_date`) are checked using `GROUP BY … HAVING COUNT(*) > 1`. The composite business grain of each fact table (store × date × product for daily sales; store × month for monthly profitability) is also verified.
- **Null audits**: every column in `dim_date`, `dim_product`, `dim_store`, `fact_daily_sales`, and `fact_store_monthly_profitability` is checked for missing values using `COUNT(*) FILTER (WHERE column IS NULL)`.
- **Range and logic validation**: suspicious values are flagged before load: negative revenues, transaction counts, staff hours, rents, or staffing costs; loyalty transactions exceeding total transactions; product margins outside 0–100%; and monthly net profit margins outside ±100%.

Only records that pass all three layers are inserted from staging into the production tables via clean `INSERT … SELECT` statements with `BTRIM` applied to all text keys.

---

## Analytical Questions Answered

The project addresses 10 core business questions across five analytical themes.

---

### Store & Regional Performance

**Q1: Which stores and regions generate the strongest financial performance?**

```sql
WITH store_performance AS (
    SELECT
        s.store_id,
        s.store_name,
        s.region,
        s.city,
        s.store_format,
        COUNT(*) AS months_recorded,
        SUM(p.total_monthly_revenue_gbp) AS revenue_gbp,
        SUM(p.net_profit_gbp) AS net_profit_gbp
    FROM dim_store AS s
    JOIN fact_store_monthly_profitability AS p
        ON p.store_id = s.store_id
    GROUP BY
        s.store_id,
        s.store_name,
        s.region,
        s.city,
        s.store_format
)
SELECT
    store_id,
    store_name,
    region,
    city,
    store_format,
    months_recorded,
    ROUND(revenue_gbp, 2) AS total_revenue_gbp,
    ROUND(net_profit_gbp, 2) AS total_net_profit_gbp,
    ROUND(
        100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS net_profit_margin_pct,
    ROUND(
        revenue_gbp / NULLIF(months_recorded, 0), 2
    ) AS average_revenue_per_store_month_gbp
FROM store_performance
ORDER BY net_profit_gbp DESC;
```

---

**Q2: Which store formats and location types are most profitable?**

```sql
WITH store_months AS (
    SELECT
        s.store_id,
        s.store_format,
        s.location_type,
        s.region,
        p.month_id,
        p.total_monthly_revenue_gbp AS revenue_gbp,
        p.net_profit_gbp AS net_profit_gbp,
        p.revenue_per_sqft_gbp
    FROM dim_store s
    JOIN fact_store_monthly_profitability p
        ON p.store_id = s.store_id
),
format_performance AS (
    SELECT
        store_format,
        location_type,
        COUNT(DISTINCT store_id) AS store_count,
        COUNT(*) AS store_months,
        SUM(revenue_gbp) AS revenue_gbp,
        SUM(net_profit_gbp) AS net_profit_gbp,
        AVG(revenue_per_sqft_gbp) AS avg_revenue_per_sqft_gbp
    FROM store_months
    GROUP BY store_format, location_type
)
SELECT
    store_format,
    location_type,
    store_count,
    store_months,
    ROUND(revenue_gbp, 2) AS total_revenue_gbp,
    ROUND(net_profit_gbp, 2) AS total_net_profit_gbp,
    ROUND(
        100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS net_profit_margin_pct,
    ROUND(
        revenue_gbp / NULLIF(store_months, 0), 2
    ) AS avg_revenue_per_store_month_gbp,
    ROUND(avg_revenue_per_sqft_gbp, 2) AS avg_revenue_per_sqft_gbp
FROM format_performance
ORDER BY net_profit_margin_pct DESC NULLS LAST;
```

---

### Cost Structure & Vulnerability

**Q3: Which stores are financially vulnerable because of rent and staffing costs?**

```sql
WITH store_cost_metrics AS (
    SELECT
        s.store_id,
        s.store_name,
        s.region,
        s.store_format,
        p.month_id,
        p.total_monthly_revenue_gbp AS revenue_gbp,
        p.monthly_rent_gbp AS rent_gbp,
        p.monthly_staffing_cost_gbp AS staffing_cost_gbp,
        p.net_profit_gbp AS net_profit_gbp
    FROM dim_store s
    JOIN fact_store_monthly_profitability p
        ON p.store_id = s.store_id
),
store_summary AS (
    SELECT
        store_id,
        store_name,
        region,
        store_format,
        COUNT(*) AS months_recorded,
        SUM(revenue_gbp) AS revenue_gbp,
        SUM(rent_gbp) AS rent_gbp,
        SUM(staffing_cost_gbp) AS staffing_cost_gbp,
        SUM(net_profit_gbp) AS net_profit_gbp
    FROM store_cost_metrics
    GROUP BY store_id, store_name, region, store_format
)
SELECT
    store_id,
    store_name,
    region,
    store_format,
    months_recorded,
    ROUND(revenue_gbp, 2) AS total_revenue_gbp,
    ROUND(rent_gbp, 2) AS total_rent_gbp,
    ROUND(staffing_cost_gbp, 2) AS total_staffing_cost_gbp,
    ROUND(
        100.0 * rent_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS rent_to_revenue_pct,
    ROUND(
        100.0 * staffing_cost_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS staffing_cost_to_revenue_pct,
    ROUND(
        100.0 * (rent_gbp + staffing_cost_gbp)
        / NULLIF(revenue_gbp, 0), 2
    ) AS rent_and_staffing_to_revenue_pct,
    ROUND(net_profit_gbp, 2) AS total_net_profit_gbp,
    ROUND(
        100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS net_profit_margin_pct
FROM store_summary
ORDER BY rent_and_staffing_to_revenue_pct DESC NULLS LAST;
```

---

### Loyalty Programme Analysis

**Q4: Is the loyalty programme associated with better financial performance?**

```sql
WITH store_loyalty AS (
    SELECT
        s.store_id,
        s.store_name,
        s.region,
        s.store_format,
        s.loyalty_adoption_rate,
        COUNT(*) AS months_recorded,
        SUM(p.total_monthly_revenue_gbp) AS revenue_gbp,
        SUM(p.net_profit_gbp) AS net_profit_gbp,
        SUM(p.loyalty_redemption_cost_gbp) AS redemption_cost_gbp,
        AVG(p.loyalty_member_revenue_pct)
            AS avg_member_revenue_pct,
        AVG(p.loyalty_member_spend_gbp)
            AS avg_member_spend_gbp,
        AVG(p.non_member_spend_gbp)
            AS avg_non_member_spend_gbp
    FROM dim_store s
    JOIN fact_store_monthly_profitability p
        ON p.store_id = s.store_id
    GROUP BY
        s.store_id,
        s.store_name,
        s.region,
        s.store_format,
        s.loyalty_adoption_rate
)
SELECT
    store_id,
    store_name,
    region,
    store_format,
    loyalty_adoption_rate,
    months_recorded,
    ROUND(revenue_gbp, 2) AS total_revenue_gbp,
    ROUND(avg_member_revenue_pct, 2)
        AS avg_loyalty_member_revenue_pct,
    ROUND(avg_member_spend_gbp, 2)
        AS avg_monthly_loyalty_member_spend_gbp,
    ROUND(avg_non_member_spend_gbp, 2)
        AS avg_monthly_non_member_spend_gbp,
    ROUND(redemption_cost_gbp, 2)
        AS total_loyalty_redemption_cost_gbp,
    ROUND(
        100.0 * redemption_cost_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS redemption_cost_to_revenue_pct,
    ROUND(net_profit_gbp, 2) AS total_net_profit_gbp,
    ROUND(
        100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS net_profit_margin_pct
FROM store_loyalty
ORDER BY loyalty_adoption_rate DESC;
```

---

### Product & Revenue Mix Analysis

**Q5: Which products and categories are the strongest revenue and gross-profit contributors?**

```sql
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.product_status,
        p.unit_price_gbp,
        p.unit_cost_gbp,
        p.gross_margin_pct AS listed_gross_margin_pct,
        SUM(f.total_revenue_gbp) AS revenue_gbp,
        SUM(f.daily_gross_profit_gbp) AS recorded_gross_profit_gbp,
        COUNT(DISTINCT f.date_id) AS dates_recorded
    FROM dim_product p
    JOIN fact_daily_sales f
        ON f.product_id = p.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.product_status,
        p.unit_price_gbp,
        p.unit_cost_gbp,
        p.gross_margin_pct
),
with_revenue_share AS (
    SELECT
        *,
        SUM(revenue_gbp) OVER () AS all_product_revenue_gbp
    FROM product_sales
)
SELECT
    product_id,
    product_name,
    category,
    product_status,
    dates_recorded,
    unit_price_gbp,
    unit_cost_gbp,
    listed_gross_margin_pct,
    ROUND(revenue_gbp, 2) AS recorded_revenue_gbp,
    ROUND(recorded_gross_profit_gbp, 2) AS recorded_gross_profit_gbp,
    ROUND(
        100.0 * revenue_gbp / NULLIF(all_product_revenue_gbp, 0), 2
    ) AS revenue_share_pct,
    ROUND(
        100.0 * recorded_gross_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS calculated_gross_margin_pct
FROM with_revenue_share
ORDER BY recorded_gross_profit_gbp DESC NULLS LAST;
```

---

**Q6: How does the recorded revenue mix across espresso, filter coffee, food, and retail beans change?**

```sql
WITH store_day_category_values AS (
    SELECT
        f.store_id,
        f.date_id,
        MAX(f.espresso_revenue_gbp) AS espresso_revenue_gbp,
        MAX(f.filter_revenue_gbp) AS filter_revenue_gbp,
        MAX(f.food_revenue_gbp) AS food_revenue_gbp,
        MAX(f.retail_beans_revenue_gbp) AS retail_beans_revenue_gbp
    FROM fact_daily_sales f
    GROUP BY f.store_id, f.date_id
),
category_revenue AS (
    SELECT
        category,
        SUM(category_revenue_gbp) AS revenue_gbp
    FROM (
        SELECT 'Espresso' AS category,
               espresso_revenue_gbp AS category_revenue_gbp
        FROM store_day_category_values

        UNION ALL

        SELECT 'Filter coffee',
               filter_revenue_gbp
        FROM store_day_category_values

        UNION ALL

        SELECT 'Food',
               food_revenue_gbp
        FROM store_day_category_values

        UNION ALL

        SELECT 'Retail beans',
               retail_beans_revenue_gbp
        FROM store_day_category_values
    ) category_rows
    GROUP BY category
),
with_total AS (
    SELECT
        *,
        SUM(revenue_gbp) OVER () AS total_category_revenue_gbp
    FROM category_revenue
)
SELECT
    category,
    ROUND(revenue_gbp, 2) AS recorded_category_revenue_gbp,
    ROUND(
        100.0 * revenue_gbp / NULLIF(total_category_revenue_gbp, 0), 2
    ) AS share_of_four_category_revenue_pct
FROM with_total
ORDER BY revenue_gbp DESC NULLS LAST;
```

---

### Seasonal & Day-of-Week Trends

**Q7: How does seasonal demand affect revenue and margins?**

```sql
WITH store_day AS (
    SELECT
        f.store_id,
        d.full_date,
        d.year,
        d.month_number,
        d.month_name,
        d.quarter,
        d.is_weekend,
        d.is_uk_bank_holiday,
        SUM(f.total_revenue_gbp) AS revenue_gbp,
        MAX(f.total_transactions) AS transactions,
        SUM(f.daily_gross_profit_gbp) AS gross_profit_gbp
    FROM fact_daily_sales f
    JOIN dim_date d
        ON d.date_id = f.date_id
    GROUP BY
        f.store_id,
        d.full_date,
        d.year,
        d.month_number,
        d.month_name,
        d.quarter,
        d.is_weekend,
        d.is_uk_bank_holiday
),
monthly_metrics AS (
    SELECT
        year,
        month_number,
        month_name,
        quarter,
        COUNT(*) AS store_days,
        SUM(revenue_gbp) AS revenue_gbp,
        SUM(transactions) AS transactions,
        SUM(gross_profit_gbp) AS gross_profit_gbp
    FROM store_day
    GROUP BY year, month_number, month_name, quarter
)
SELECT
    year,
    month_number,
    month_name,
    quarter,
    store_days,
    ROUND(revenue_gbp, 2) AS revenue_gbp,
    transactions AS recorded_transactions,
    ROUND(gross_profit_gbp, 2) AS gross_profit_gbp,
    ROUND(
        revenue_gbp / NULLIF(store_days, 0), 2
    ) AS revenue_per_store_day_gbp,
    ROUND(
        100.0 * gross_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS calculated_gross_margin_pct
FROM monthly_metrics
ORDER BY year, month_number;
```

---

**Q8: Does loyalty activity differ by day of the week, and what redemption costs are recorded?**

```sql
WITH store_day_loyalty AS (
    SELECT
        f.store_id,
        d.full_date,
        d.year,
        d.month_number,
        d.day_of_week,
        d.is_weekend,
        SUM(f.total_revenue_gbp) AS revenue_gbp,
        MAX(f.total_transactions) AS total_transactions,
        MAX(f.loyalty_transactions) AS loyalty_transactions,
        MAX(f.loyalty_redemption_cost_gbp)
            AS loyalty_redemption_cost_gbp
    FROM fact_daily_sales f
    JOIN dim_date d
        ON d.date_id = f.date_id
    GROUP BY
        f.store_id,
        d.full_date,
        d.year,
        d.month_number,
        d.day_of_week,
        d.is_weekend
),
daypart_metrics AS (
    SELECT
        day_of_week,
        is_weekend,
        COUNT(*) AS store_days,
        SUM(revenue_gbp) AS revenue_gbp,
        SUM(total_transactions) AS total_transactions,
        SUM(loyalty_transactions) AS loyalty_transactions,
        SUM(loyalty_redemption_cost_gbp) AS redemption_cost_gbp
    FROM store_day_loyalty
    GROUP BY day_of_week, is_weekend
)
SELECT
    day_of_week,
    is_weekend,
    store_days,
    ROUND(revenue_gbp, 2) AS revenue_gbp,
    total_transactions,
    loyalty_transactions,
    ROUND(
        100.0 * loyalty_transactions
        / NULLIF(total_transactions, 0), 2
    ) AS loyalty_transaction_share_pct,
    ROUND(redemption_cost_gbp, 2) AS loyalty_redemption_cost_gbp,
    ROUND(
        100.0 * redemption_cost_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS redemption_cost_to_revenue_pct
FROM daypart_metrics
ORDER BY is_weekend, day_of_week;
```

---

### Product Loyalty & Strategic Investment

**Q9: Which products are eligible for loyalty, and how does their recorded performance compare?**

```sql
WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.loyalty_eligible,
        p.gross_margin_pct,
        SUM(f.total_revenue_gbp) AS revenue_gbp,
        COUNT(DISTINCT f.date_id) AS dates_recorded
    FROM dim_product p
    JOIN fact_daily_sales f
        ON f.product_id = p.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category,
        p.loyalty_eligible,
        p.gross_margin_pct
),
with_total AS (
    SELECT
        *,
        SUM(revenue_gbp) OVER () AS all_revenue_gbp
    FROM product_performance
)
SELECT
    product_id,
    product_name,
    category,
    loyalty_eligible,
    dates_recorded,
    ROUND(revenue_gbp, 2) AS recorded_revenue_gbp,
    ROUND(
        100.0 * revenue_gbp / NULLIF(all_revenue_gbp, 0), 2
    ) AS revenue_share_pct,
    ROUND(gross_margin_pct, 2) AS gross_margin_pct
FROM with_total
ORDER BY
    loyalty_eligible DESC,
    revenue_gbp DESC;
```

---

**Q10: Which stores should Sunrise Coffee prioritise for expansion, investment, or turnaround?**

```sql
WITH store_investment_metrics AS (
    SELECT
        s.store_id,
        s.store_name,
        s.region,
        s.city,
        s.store_format,
        s.location_type,
        s.store_status,
        COUNT(*) AS months_recorded,
        SUM(p.total_monthly_revenue_gbp) AS revenue_gbp,
        SUM(p.net_profit_gbp) AS net_profit_gbp,
        AVG(p.revenue_per_sqft_gbp) AS avg_revenue_per_sqft_gbp,
        AVG(p.net_profit_margin_pct) AS avg_recorded_margin_pct,
        COUNT(*) FILTER (
            WHERE p.profitability_status = 'Profitable'
        ) AS profitable_months,
        COUNT(*) FILTER (
            WHERE p.profitability_status = 'Unprofitable'
        ) AS unprofitable_months
    FROM dim_store s
    JOIN fact_store_monthly_profitability p
        ON p.store_id = s.store_id
    GROUP BY
        s.store_id,
        s.store_name,
        s.region,
        s.city,
        s.store_format,
        s.location_type,
        s.store_status
),
scored_stores AS (
    SELECT
        *,
        100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0)
            AS calculated_net_profit_margin_pct,
        revenue_gbp / NULLIF(months_recorded, 0)
            AS avg_monthly_revenue_gbp,
        net_profit_gbp / NULLIF(months_recorded, 0)
            AS avg_monthly_net_profit_gbp
    FROM store_investment_metrics
)
SELECT
    store_id,
    store_name,
    region,
    city,
    store_format,
    location_type,
    store_status,
    months_recorded,
    ROUND(revenue_gbp, 2) AS total_revenue_gbp,
    ROUND(net_profit_gbp, 2) AS total_net_profit_gbp,
    ROUND(avg_monthly_revenue_gbp, 2) AS avg_monthly_revenue_gbp,
    ROUND(avg_monthly_net_profit_gbp, 2) AS avg_monthly_net_profit_gbp,
    ROUND(calculated_net_profit_margin_pct, 2)
        AS calculated_net_profit_margin_pct,
    ROUND(avg_revenue_per_sqft_gbp, 2) AS avg_revenue_per_sqft_gbp,
    profitable_months,
    unprofitable_months
FROM scored_stores
ORDER BY
    calculated_net_profit_margin_pct DESC NULLS LAST,
    avg_monthly_net_profit_gbp DESC NULLS LAST;
```

---

## Insight Summary

Key findings drawn from the analysis:

- **Store performance is highly concentrated:** A small number of stores particularly those in high-footfall Transport-Hub locations are responsible for a disproportionate share of total network revenue, while several suburban high-street units post consistent net losses across the two-year period.

- **Transport-Hub stores outperform High-Street stores on margin:** Transport-Hub format stores benefit from higher transaction volumes and lower relative rent burden, resulting in stronger net profit margins despite similar or lower seating capacity compared to larger high-street cafés.

- **Rent and staffing costs are the primary vulnerability for loss-making stores:** Several stores have combined rent-and-staffing-to-revenue ratios exceeding 70%, making sustained profitability structurally impossible without either a significant revenue uplift or cost renegotiation.

- **Loyalty adoption varies widely across the estate:** Stores with higher loyalty adoption rates tend to show higher average transaction values and a greater share of revenue from members but redemption costs also rise in proportion, compressing margins at the highest-adoption stores if not actively managed.

- **Espresso-based drinks dominate the revenue mix:** Espresso drinks account for the largest share of the four recorded category revenues, with food representing the smallest. Retail bean sales, while modest in total, carry the highest gross margins in the product catalogue.

- **Weekends drive higher footfall but not proportionally more loyalty transactions:** Loyalty transaction share is marginally higher on weekdays, suggesting the loyalty programme may be more heavily used by commuter and regular daily customers rather than casual weekend visitors.

- **Seasonal demand peaks align with standard UK trading patterns:** Q4 (October–December) shows the strongest revenue performance, driven by the Christmas trading period flag in the date dimension. January and February represent the weakest trading months across the two-year dataset.

- **A handful of stores are clear candidates for investment or turnaround:** The Q10 scoring query surfaces a group of stores with strong margin profiles and growing monthly revenue as expansion candidates, alongside a separate group with multiple consecutive unprofitable months and high cost-to-revenue ratios warranting active management intervention.

---

## Key Metrics

The following calculated metrics appear consistently throughout the analysis:

| Metric | Calculation |
|---|---|
| Net Profit Margin % | `100.0 * net_profit_gbp / NULLIF(revenue_gbp, 0)` |
| Average Revenue per Store-Month | `SUM(revenue_gbp) / COUNT(months_recorded)` |
| Rent-to-Revenue % | `100.0 * total_rent_gbp / NULLIF(revenue_gbp, 0)` |
| Staffing-Cost-to-Revenue % | `100.0 * total_staffing_cost_gbp / NULLIF(revenue_gbp, 0)` |
| Combined Cost Burden % | `100.0 * (rent + staffing) / NULLIF(revenue_gbp, 0)` |
| Loyalty Transaction Share % | `100.0 * loyalty_transactions / NULLIF(total_transactions, 0)` |
| Redemption Cost to Revenue % | `100.0 * redemption_cost_gbp / NULLIF(revenue_gbp, 0)` |
| Revenue Share % | `100.0 * product_revenue / NULLIF(all_product_revenue, 0)` |
| Revenue per Store-Day | `SUM(revenue_gbp) / NULLIF(COUNT(store_days), 0)` |
| Gross Margin % (calculated) | `100.0 * gross_profit_gbp / NULLIF(revenue_gbp, 0)` |

---

## How to Use

### Prerequisites

A SQL database compatible with standard SQL syntax. **PostgreSQL is recommended**, as the script uses PostgreSQL-specific syntax including `NUMERIC` types, `BOOLEAN`, `CREATE TABLE … WITH NO DATA`, and `COUNT(*) FILTER (WHERE …)`.

### Steps

1. **Clone the repository**

```bash
git clone https://github.com/M1deTheAnalyst/Sunrise-Coffee-Chain-SQL-Analytics-Project.git
```

2. **Create a new database**

```sql
CREATE DATABASE sunrise_coffee_analytics;
```

3. **Run the SQL script**

```bash
psql -U your_username -d sunrise_coffee_analytics -f "Sunrise_Coffee_Chain_SQL_Script.sql"
```

Or open the file in your preferred SQL client (e.g. DBeaver, pgAdmin, TablePlus) and execute it in full.

4. **Load your data via the staging layer**

Import the CSV files into their corresponding staging tables first (`stg_dim_date`, `stg_dim_product`, `stg_dim_store`, `stg_fact_daily_sales`, `stg_fact_store_monthly_profitability`). The script will validate the data and promote clean records into the production tables in the correct dependency order — dimensions before facts.

5. **Run the analysis queries**

The full SQL for all 10 business questions is included in the [Analytical Questions Answered](#analytical-questions-answered) section above and in `Sunrise_Coffee_Chain_SQL_Script.sql`.

---

## Technologies Used

- **SQL (PostgreSQL)**: schema design, staging ETL, data quality checks, and all analytical logic
- **Star Schema**: data warehousing design pattern with two fact tables and three shared dimension tables
- **Staging Layer**: full ETL staging pattern using `CREATE TABLE … WITH NO DATA` and `INSERT … SELECT`
- **Aggregate Functions**: `SUM`, `AVG`, `COUNT`, `ROUND` for KPI computation
- **Common Table Expressions (CTEs)**: `WITH` clauses used throughout for readable, modular, multi-step analysis
- **Window Functions**: `SUM() OVER ()` used for revenue-share calculations across products and categories
- **Conditional Aggregation**: `COUNT(*) FILTER (WHERE …)` used for profitability month counts
- **NULL Safety**: `NULLIF(…, 0)` applied consistently across all division operations to prevent runtime errors

---

## Project Structure

```
sunrise-coffee-chain-sql-analytics/
│
├── Sunrise_Coffee_Chain_SQL_Script.sql          # Main SQL file (schema + staging + QA + analysis)
├── Sunrise_Coffee_Chain_Analysis.xlsx           # Supporting Excel analysis workbook
│
├── dim_date.csv                                 # Date dimension (730 rows, Jan 2023 – Dec 2024)
├── dim_product.csv                              # Product dimension (40 products, 6 categories)
├── dim_store.csv                                # Store dimension (60 stores, 12 UK regions)
│
├── fact_daily_sales.csv                         # Daily sales fact table (10,000 rows)
├── fact_store_monthly_profitability.csv         # Monthly profitability fact table (1,440 rows)
│
└── README.md                                    # Project documentation
```

---

## Potential Extensions

- Connect to a BI tool (Power BI, Tableau, Metabase) using the analysis queries as data sources to build an interactive store performance dashboard
- Build a stored procedure to automate monthly profitability reporting and flag newly unprofitable stores for management review

---

## Author

**M1deTheAnalyst**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/midetheanalyst/)
[![X](https://img.shields.io/badge/X-Follow-000000?style=for-the-badge&logo=twitter&logoColor=white)](https://x.com/M1detheanalyst)
[![GitHub](https://img.shields.io/badge/GitHub-Profile-181717?style=for-the-badge&logo=github)](https://github.com/M1detheanalyst)

Built as a SQL data analytics project to demonstrate end-to-end data warehouse design, ETL staging, and retail business intelligence querying in a UK coffee chain context.
