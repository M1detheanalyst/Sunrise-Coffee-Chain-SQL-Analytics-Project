-- =====================================================
-- SUNRISE COFFEE DATABASE SCHEMA
-- =====================================================

-- 1. DATE DIMENSION
CREATE TABLE dim_date (
    date_id INTEGER PRIMARY KEY,
    full_date DATE,
    year INTEGER,
    month_number INTEGER,
    month_name VARCHAR(20),
	quarter INTEGER,
    week_number INTEGER,
    day_of_week VARCHAR (20),
    is_weekend BOOLEAN,
    is_uk_bank_holiday BOOLEAN,
    uk_trading_calender VARCHAR(50)
);


-- 2. PRODUCT DIMENSION
CREATE TABLE dim_product (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL,
    unit_price_gbp NUMERIC(10,2) NOT NULL,
    unit_cost_gbp NUMERIC(10,2) NOT NULL,
    gross_margin_pct NUMERIC(5,2) NOT NULL,
    loyalty_eligible BOOLEAN NOT NULL,
    product_status VARCHAR(20) NOT NULL,
    launch_date DATE
);


-- 3. STORE DIMENSION
CREATE TABLE dim_store (
    store_id INTEGER PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL UNIQUE,
    store_format VARCHAR(50) NOT NULL,
    location_type VARCHAR(50) NOT NULL,
    region VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    monthly_rent_gbp NUMERIC(12,2) NOT NULL,
	staff_headcount INTEGER NOT NULL,
    monthly_staffing_cost_gbp NUMERIC(10,2) NOT NULL,
    loyalty_adoption_rate NUMERIC(5,2) NOT NULL,
    seating_capacity INTEGER NOT NULL,
    opening_year INTEGER,
    store_status VARCHAR(20) NOT NULL
);


-- 4. DAILY SALES FACT TABLE
CREATE TABLE fact_daily_sales (
    daily_sale_id INTEGER,
    store_id INTEGER REFERENCES dim_store(store_id),
    date_id INTEGER REFERENCES dim_date(date_id),
    product_id INTEGER REFERENCES dim_product(product_id),
    total_revenue_gbp NUMERIC(12,2),
    total_transactions INTEGER,
    avg_transaction_value_gbp NUMERIC(12,2),
    loyalty_transactions INTEGER,
    loyalty_redemption_cost_gbp NUMERIC(12,2),
    footfall INTEGER,
    espresso_revenue_gbp NUMERIC(12,2),
    filter_revenue_gbp NUMERIC(12,2),
    food_revenue_gbp NUMERIC(12,2),
    retail_beans_revenue_gbp NUMERIC(12,2),
    daily_gross_profit_gbp NUMERIC(12,2),
    staff_count INTEGER,
    total_staff_hours NUMERIC(10,2),
    shift_pattern VARCHAR(50),
    avg_dwell_time_minutes NUMERIC(10,2)
);


-- 5. MONTHLY STORE PROFITABILITY FACT TABLE
CREATE TABLE fact_store_monthly_profitability (
    monthly_profit_id INTEGER,
    store_id INTEGER REFERENCES dim_store(store_id),
    date_id INTEGER REFERENCES dim_date(date_id),
    month_id VARCHAR(7),
    total_monthly_revenue_gbp NUMERIC(12,2),
    total_monthly_cogs_gbp NUMERIC(12,2),
    monthly_rent_gbp NUMERIC(12,2),
    monthly_staffing_cost_gbp NUMERIC(12,2),
    loyalty_redemption_cost_gbp NUMERIC(12,2),
    net_profit_gbp NUMERIC(12,2),
    net_profit_margin_pct NUMERIC(8,2),
    avg_daily_footfall NUMERIC(10,2),
    loyalty_member_revenue_pct NUMERIC(8,2),
    loyalty_member_spend_gbp NUMERIC(12,2),
    non_member_spend_gbp NUMERIC(12,2),
    revenue_per_sqft_gbp NUMERIC(12,2),
    peak_hour_transactions INTEGER,
    dead_hour_transactions INTEGER,
    avg_dwell_time_minutes NUMERIC(10,2),
    rent_band VARCHAR(30),
    profitability_status VARCHAR(30),

    UNIQUE (store_id, month_id)
);


-- =====================================================
-- INDEXES FOR FOREIGN-KEY LOOKUPS AND ANALYSIS
-- =====================================================

CREATE INDEX idx_daily_sales_store
    ON fact_daily_sales(store_id);

CREATE INDEX idx_daily_sales_date
    ON fact_daily_sales(date_id);

CREATE INDEX idx_daily_sales_product
    ON fact_daily_sales(product_id);

CREATE INDEX idx_monthly_profit_store
    ON fact_store_monthly_profitability(store_id);

CREATE INDEX idx_monthly_profit_date
    ON fact_store_monthly_profitability(date_id);

CREATE INDEX idx_monthly_profit_month
    ON fact_store_monthly_profitability(month_id);


-- =====================================================
-- STEP 1: STAGING TABLES
-- =====================================================

DROP TABLE IF EXISTS stg_fact_store_monthly_profitability;
DROP TABLE IF EXISTS stg_fact_daily_sales;
DROP TABLE IF EXISTS stg_dim_product;
DROP TABLE IF EXISTS stg_dim_store;
DROP TABLE IF EXISTS stg_dim_date;

CREATE TABLE stg_dim_date AS
SELECT * FROM dim_date WITH NO DATA;

CREATE TABLE stg_dim_product AS
SELECT * FROM dim_product WITH NO DATA;

CREATE TABLE stg_dim_store AS
SELECT * FROM dim_store WITH NO DATA;

CREATE TABLE stg_fact_daily_sales AS
SELECT * FROM fact_daily_sales WITH NO DATA;

CREATE TABLE stg_fact_store_monthly_profitability AS
SELECT * FROM fact_store_monthly_profitability WITH NO DATA;

-- Duplicate date IDs
SELECT date_id, COUNT(*) AS occurrences
FROM stg_dim_date
GROUP BY date_id
HAVING COUNT(*) > 1;

-- Duplicate calendar dates
SELECT full_date, COUNT(*) AS occurrences
FROM stg_dim_date
GROUP BY full_date
HAVING COUNT(*) > 1;

-- Duplicate product IDs
SELECT product_id, COUNT(*) AS occurrences
FROM stg_dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Duplicate product names
SELECT LOWER(BTRIM(product_name)) AS normalized_product_name,
       COUNT(*) AS occurrences
FROM stg_dim_product
GROUP BY LOWER(BTRIM(product_name))
HAVING COUNT(*) > 1;

-- Duplicate store IDs
SELECT store_id, COUNT(*) AS occurrences
FROM stg_dim_store
GROUP BY store_id
HAVING COUNT(*) > 1;

-- Duplicate store names
SELECT LOWER(BTRIM(store_name)) AS normalized_store_name,
       COUNT(*) AS occurrences
FROM stg_dim_store
GROUP BY LOWER(BTRIM(store_name))
HAVING COUNT(*) > 1;

-- Duplicate daily sale IDs
SELECT daily_sale_id, COUNT(*) AS occurrences
FROM stg_fact_daily_sales
GROUP BY daily_sale_id
HAVING COUNT(*) > 1;

-- Duplicate daily business grain:
-- one row per store, date and product is the intended grain
SELECT store_id, date_id, product_id, COUNT(*) AS occurrences
FROM stg_fact_daily_sales
GROUP BY store_id, date_id, product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- Duplicate monthly profit IDs
SELECT monthly_profit_id, COUNT(*) AS occurrences
FROM stg_fact_store_monthly_profitability
GROUP BY monthly_profit_id
HAVING COUNT(*) > 1;

-- Duplicate store-month records
SELECT store_id, BTRIM(month_id) AS month_id,
       COUNT(*) AS occurrences
FROM stg_fact_store_monthly_profitability
GROUP BY store_id, BTRIM(month_id)
HAVING COUNT(*) > 1;

-- =====================================================
-- A. MISSING DIMENSION VALUES
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE date_id IS NULL) AS missing_date_id,
    COUNT(*) FILTER (WHERE full_date IS NULL) AS missing_full_date,
    COUNT(*) FILTER (WHERE year IS NULL) AS missing_year,
    COUNT(*) FILTER (WHERE month_number IS NULL) 
FROM stg_dim_date;

SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE product_name IS NULL
                      OR BTRIM(product_name) = '') AS missing_product_name,
    COUNT(*) FILTER (WHERE category IS NULL
                      OR BTRIM(category) = '') AS missing_category,
    COUNT(*) FILTER (WHERE unit_price_gbp IS NULL) AS missing_price,
    COUNT(*) FILTER (WHERE unit_cost_gbp IS NULL) AS missing_cost
FROM stg_dim_product;

SELECT
    COUNT(*) FILTER (WHERE store_id IS NULL) AS missing_store_id,
    COUNT(*) FILTER (WHERE store_name IS NULL
                      OR BTRIM(store_name) = '') AS missing_store_name,
    COUNT(*) FILTER (WHERE city IS NULL
                      OR BTRIM(city) = '') AS missing_city,
    COUNT(*) FILTER (WHERE region IS NULL
                      OR BTRIM(region) = '') AS missing_region
FROM stg_dim_store;


-- =====================================================
-- B. MISSING DAILY FACT VALUES
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE daily_sale_id IS NULL) AS missing_sale_id,
    COUNT(*) FILTER (WHERE store_id IS NULL) AS missing_store_id,
    COUNT(*) FILTER (WHERE date_id IS NULL) AS missing_date_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE total_revenue_gbp IS NULL) AS missing_revenue,
    COUNT(*) FILTER (WHERE total_transactions IS NULL) AS missing_transactions,
    COUNT(*) FILTER (WHERE avg_transaction_value_gbp IS NULL) AS missing_atv
FROM stg_fact_daily_sales;


-- =====================================================
-- C. MISSING MONTHLY FACT VALUES
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE monthly_profit_id IS NULL) AS missing_profit_id,
    COUNT(*) FILTER (WHERE store_id IS NULL) AS missing_store_id,
    COUNT(*) FILTER (WHERE date_id IS NULL) AS missing_date_id,
    COUNT(*) FILTER (WHERE month_id IS NULL
                      OR BTRIM(month_id) = '') AS missing_month_id,
    COUNT(*) FILTER (WHERE total_monthly_revenue_gbp IS NULL) AS missing_revenue,
    COUNT(*) FILTER (WHERE net_profit_gbp IS NULL) AS missing_net_profit
FROM stg_fact_store_monthly_profitability;

-- Negative or suspicious daily values
SELECT *
FROM stg_fact_daily_sales
WHERE total_revenue_gbp < 0
   OR total_transactions < 0
   OR loyalty_transactions < 0
   OR footfall < 0
   OR total_staff_hours < 0
   OR loyalty_redemption_cost_gbp < 0;

-- Transaction counts exceeding total transactions
SELECT *
FROM stg_fact_daily_sales
WHERE loyalty_transactions > total_transactions;

-- Implausible product prices or costs
SELECT *
FROM stg_dim_product
WHERE unit_price_gbp < 0
   OR unit_cost_gbp < 0
   OR gross_margin_pct < 0
   OR gross_margin_pct > 100;

-- Invalid store values
SELECT *
FROM stg_dim_store
WHERE monthly_rent_gbp < 0
   OR monthly_staffing_cost_gbp < 0
   OR staff_headcount < 0
   OR seating_capacity < 0
   OR loyalty_adoption_rate < 0
   OR loyalty_adoption_rate > 100;

-- Invalid monthly financial values
SELECT *
FROM stg_fact_store_monthly_profitability
WHERE total_monthly_revenue_gbp < 0
   OR total_monthly_cogs_gbp < 0
   OR monthly_rent_gbp < 0
   OR monthly_staffing_cost_gbp < 0
   OR net_profit_margin_pct < -100
   OR net_profit_margin_pct > 100;

-- 1. Insert date dimension
INSERT INTO dim_date (
    date_id,
    full_date,
    year,
    month_number,
    month_name,
    quarter,
    week_number,
    day_of_week,
    is_weekend,
    is_uk_bank_holiday,
    uk_trading_calender
)
SELECT
    date_id,
    full_date,
    year,
    month_number,
    month_name,
    quarter,
    week_number,
    day_of_week,
    is_weekend,
    is_uk_bank_holiday,
    uk_trading_calender
FROM stg_dim_date;

-- 2. Insert product dimension
INSERT INTO dim_product (
    product_id,
    product_name,
    category,
    unit_price_gbp,
    unit_cost_gbp,
    gross_margin_pct,
    loyalty_eligible,
    product_status,
    launch_date
)
SELECT
    product_id,
    BTRIM(product_name),
    BTRIM(category),
    unit_price_gbp,
    unit_cost_gbp,
    gross_margin_pct,
    loyalty_eligible,
    product_status,
    launch_date
FROM stg_dim_product;

-- 3. Insert store dimension
INSERT INTO dim_store (
    store_id,
    store_name,
    store_format,
    location_type,
    region,
    city,
    monthly_rent_gbp,
    staff_headcount,
    monthly_staffing_cost_gbp,
    loyalty_adoption_rate,
    seating_capacity,
    opening_year,
    store_status
)
SELECT
    store_id,
    BTRIM(store_name),
    store_format,
    location_type,
    region,
    city,
    monthly_rent_gbp,
    staff_headcount,
    monthly_staffing_cost_gbp,
    loyalty_adoption_rate,
    seating_capacity,
    opening_year,
    store_status
FROM stg_dim_store;

-- 4. Insert daily sales fact table
INSERT INTO fact_daily_sales (
    daily_sale_id,
    store_id,
    date_id,
    product_id,
    total_revenue_gbp,
    total_transactions,
    avg_transaction_value_gbp,
    loyalty_transactions,
    loyalty_redemption_cost_gbp,
    footfall,
    espresso_revenue_gbp,
    filter_revenue_gbp,
    food_revenue_gbp,
    retail_beans_revenue_gbp,
    daily_gross_profit_gbp,
    staff_count,
    total_staff_hours,
    shift_pattern,
    avg_dwell_time_minutes
)
SELECT
    daily_sale_id,
    store_id,
    date_id,
    product_id,
    total_revenue_gbp,
    total_transactions,
    avg_transaction_value_gbp,
    loyalty_transactions,
    loyalty_redemption_cost_gbp,
    footfall,
    espresso_revenue_gbp,
    filter_revenue_gbp,
    food_revenue_gbp,
    retail_beans_revenue_gbp,
    daily_gross_profit_gbp,
    staff_count,
    total_staff_hours,
    shift_pattern,
    avg_dwell_time_minutes
FROM stg_fact_daily_sales;

-- 5. Insert monthly store profitability fact table
INSERT INTO fact_store_monthly_profitability (
    monthly_profit_id,
    store_id,
    date_id,
    month_id,
    total_monthly_revenue_gbp,
    total_monthly_cogs_gbp,
    monthly_rent_gbp,
    monthly_staffing_cost_gbp,
    loyalty_redemption_cost_gbp,
    net_profit_gbp,
    net_profit_margin_pct,
    avg_daily_footfall,
    loyalty_member_revenue_pct,
    loyalty_member_spend_gbp,
    non_member_spend_gbp,
    revenue_per_sqft_gbp,
    peak_hour_transactions,
    dead_hour_transactions,
    avg_dwell_time_minutes,
    rent_band,
    profitability_status
)
SELECT
    monthly_profit_id,
    store_id,
    date_id,
    BTRIM(month_id),
    total_monthly_revenue_gbp,
    total_monthly_cogs_gbp,
    monthly_rent_gbp,
    monthly_staffing_cost_gbp,
    loyalty_redemption_cost_gbp,
    net_profit_gbp,
    net_profit_margin_pct,
    avg_daily_footfall,
    loyalty_member_revenue_pct,
    loyalty_member_spend_gbp,
    non_member_spend_gbp,
    revenue_per_sqft_gbp,
    peak_hour_transactions,
    dead_hour_transactions,
    avg_dwell_time_minutes,
    rent_band,
    profitability_status
FROM stg_fact_store_monthly_profitability;

-- =====================================================
-- Sunrise Coffee Chain Business Analysis 
-- =====================================================

--- Business question 1: Which stores and regions generate the strongest financial performance?

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

--- Business question 2: Which store formats and location types are most profitable?

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
    ROUND(avg_revenue_per_sqft_gbp, 2)
        AS avg_revenue_per_sqft_gbp
FROM format_performance
ORDER BY net_profit_margin_pct DESC NULLS LAST;

--- Business Question 3: Which stores are financially vulnerable because of rent and staffing costs?

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

--- Business Question 4: Is the loyalty programme associated with better financial performance?

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

--- Business Question 5:  Which products and categories are the strongest revenue and gross-profit

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
    ROUND(recorded_gross_profit_gbp, 2)
        AS recorded_gross_profit_gbp,
    ROUND(
        100.0 * revenue_gbp / NULLIF(all_product_revenue_gbp, 0), 2
    ) AS revenue_share_pct,
    ROUND(
        100.0 * recorded_gross_profit_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS calculated_gross_margin_pct
FROM with_revenue_share
ORDER BY recorded_gross_profit_gbp DESC NULLS LAST;

--- Business Question 6: How does the recorded revenue mix across espresso, filter coffee, food, and retail beans change?

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

--- Business Question 7: How does seasonal demand affect revenue and margins?

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

--- Business Question 8: Does loyalty activity differ by day, and what redemption costs are recorded?

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
    ROUND(redemption_cost_gbp, 2)
        AS loyalty_redemption_cost_gbp,
    ROUND(
        100.0 * redemption_cost_gbp / NULLIF(revenue_gbp, 0), 2
    ) AS redemption_cost_to_revenue_pct
FROM daypart_metrics
ORDER BY is_weekend, day_of_week;

--- Business Question 9: Which products are eligible for loyalty, and how does their recorded performance compare?

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
        100.0 * revenue_gbp / NULLIF(all_revenue_gbp, 0),
        2
    ) AS revenue_share_pct,
    ROUND(gross_margin_pct, 2) AS gross_margin_pct
FROM with_total
ORDER BY
    loyalty_eligible DESC,
    revenue_gbp DESC;

--- Business Question 10: Which stores should Sunrise Coffee prioritise for expansion, investment, or turnaround?

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
    ROUND(avg_monthly_revenue_gbp, 2)
        AS avg_monthly_revenue_gbp,
    ROUND(avg_monthly_net_profit_gbp, 2)
        AS avg_monthly_net_profit_gbp,
    ROUND(calculated_net_profit_margin_pct, 2)
        AS calculated_net_profit_margin_pct,
    ROUND(avg_revenue_per_sqft_gbp, 2)
        AS avg_revenue_per_sqft_gbp,
    profitable_months,
    unprofitable_months
FROM scored_stores
ORDER BY
    calculated_net_profit_margin_pct DESC NULLS LAST,
    avg_monthly_net_profit_gbp DESC NULLS LAST;