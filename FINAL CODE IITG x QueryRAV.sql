CREATE DATABASE queryRAV;

USE queryRAV;


CREATE TABLE inventory_combined (
    order_data DATE,
    store_id varchar(255),
    product_id varchar(255),
    categories VARCHAR(255),
    region varchar(255),
    inventory_level int,
    units_sold int,
    units_order int,
    demand_forecast float,
    price float,
    discount int,
    weather_condition VARCHAR(255),
    holiday_promotion boolean, -- Changed from holiday/promotion to holiday_promotion
    competitor_pricing float,
    seasonality varchar(255)
);

DESCRIBE inventory_combined;

SELECT
    *
FROM
    inventory_combined;

SELECT
    COUNT(DISTINCT order_data)
FROM
    inventory_combined;

SELECT DISTINCT
    store_id,
    region
FROM
    inventory_combined
ORDER BY
    store_id;

SELECT DISTINCT
    product_id
FROM
    inventory_combined;

SELECT
    count(DISTINCT product_id) AS Total_product,
    store_id,
    region
FROM
    inventory_combined
GROUP BY
    store_id,
    region
ORDER BY
    store_id,
    region;

SELECT DISTINCT
    categories
FROM
    inventory_combined;

SELECT
    COUNT(DISTINCT product_id) AS total_products,
    categories
FROM
    inventory_combined
GROUP BY
    categories;

SELECT
    *
FROM
    inventory_combined
WHERE
    order_data = '2022-01-01'
    and store_id = 'S001'
    and region = 'West';

SELECT
    SUM(
        CASE
            WHEN weather_condition IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_weather,
    SUM(
        CASE
            WHEN competitor_pricing IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_comp_price,
    SUM(
        CASE
            WHEN seasonality IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_season
FROM
    inventory_combined;

SELECT
    store_id,
    region,
    (COUNT(*))
FROM
    inventory_combined
GROUP BY
    store_id,
    region;

DELETE FROM inventory_combined
WHERE
    inventory_level < 0
    OR units_sold < 0;

-- no rows with negative values found
SELECT
    COUNT(DISTINCT order_data)
FROM
    inventory_combined
WHERE
    holiday_promotion;

SELECT
    SUM(units_sold),
    SUM(units_order)
FROM
    inventory_combined
WHERE
    store_id = 'S001'
    AND product_id = 'P0096'
    AND region = 'West';

SELECT
    *
FROM
    inventory_combined;


-- Creating the store table
CREATE TABLE store (
    store_number VARCHAR PRIMARY KEY,
    store_id VARCHAR(255),
    region VARCHAR(255)
);

INSERT INTO
    store (store_number, store_id, region)
SELECT
    (CAST(SUBSTRING(store_id, 2, 3) AS SIGNED) * 1000) + -- Changed INT to SIGNED
    CASE
        WHEN LOWER(region) = 'west' THEN 1
        WHEN LOWER(region) = 'east' THEN 2
        WHEN LOWER(region) = 'north' THEN 3
        WHEN LOWER(region) = 'south' THEN 4
    END AS store_number,
    store_id,
    region
FROM
    (
        SELECT DISTINCT
            store_id,
            region
        FROM
            inventory_combined
    ) AS unique_stores;

SELECT
    *
FROM
    store;


-- creating product table
CREATE TABLE product (
    product_id VARCHAR(255) PRIMARY KEY,
    categories VARCHAR(255)
);

INSERT INTO
    product (product_id, categories)
SELECT
    product_id,
    categories
FROM
    (
        SELECT DISTINCT
            product_id,
            categories
        FROM
            inventory_combined
    ) AS unique_products;

SELECT
    *
FROM
    product;

CREATE TABLE date_table (date_ date PRIMARY KEY, seasonality VARCHAR(255));

INSERT INTO
    date_table (date_, seasonality)
SELECT
    order_data,
    seasonality
FROM
    (
        SELECT DISTINCT
            order_data,
            seasonality
        FROM
            inventory_combined
    ) AS unique_dates;

SELECT
    *
FROM
    date_table;


CREATE TABLE inventory (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    date_ DATE,
    product_id VARCHAR(255),
    store_number INT,
    unit_sold INT,
    inventory_level INT,
    unit_order INT,
    demand_forecast FLOAT,
    FOREIGN KEY (date_) REFERENCES date_table (date_),
    FOREIGN KEY (product_id) REFERENCES product (product_id),
    FOREIGN KEY (store_number) REFERENCES store (store_number)
);

ALTER TABLE inventory AUTO_INCREMENT = 100000;

ALTER TABLE inventory
RENAME COLUMN unit_sold TO units_sold,
RENAME COLUMN unit_order TO units_order;


INSERT INTO
    inventory (
        date_,
        product_id,
        store_number,
        units_sold,
        inventory_level,
        units_order,
        demand_forecast
    )
SELECT
    ic.order_data,
    ic.product_id,
    s.store_number,
    ic.units_sold,
    ic.inventory_level,
    ic.units_order,
    ic.demand_forecast
FROM inventory_combined ic
JOIN store s
ON ic.store_id = s.store_id AND ic.region = s.region;

SELECT * FROM inventory;

CREATE TABLE sales_table(
    order_id INT PRIMARY KEY,
    price FLOAT,
    discount FLOAT,
    weather_condition VARCHAR(255),
    competitor_pricing FLOAT,
    holiday_promotion INT,
    FOREIGN KEY (order_id) REFERENCES inventory (order_id)
);

INSERT INTO sales_table
SELECT 
    i.order_id,
    ic.price,
    ic.discount,
    ic.weather_condition,
    ic.competitor_pricing,
    ic.holiday_promotion
FROM inventory_combined ic
JOIN store s
  ON ic.store_id = s.store_id AND ic.region = s.region
JOIN inventory i
  ON i.date_ = ic.order_data
     AND i.store_number = s.store_number
     AND i.product_id = ic.product_id;
);

CREATE TABLE analysis_variable(
    store_number INT,
    product_id VARCHAR(255),
    stock_level_calculation FLOAT,
    inventory_turnover_analysis FLOAT,
    dsi FLOAT,
    avg_lead_time FLOAT,
    reroder_point INT,
    PRIMARY KEY (store_number, product_id)
);

ALTER TABLE analysis_variable
ADD CONSTRAINT fk_store FOREIGN KEY (store_number) REFERENCES store (store_number),
ADD CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES product (product_id);

SELECT * FROM analysis_variable;


DROP TABLE inventory_calc_para;



-- Vidhan ka code
CREATE TABLE inventory_calc_para(
    store_number INT,
    product_id varchar(255),
    avg_lead_time_days FLOAT,
    PRIMARY KEY (store_number, product_id),
    FOREIGN KEY (store_number) REFERENCES store(store_number),
    FOREIGN KEY (product_id) REFERENCES product(product_id)
);
    
select * from inventory_calc_para;


-- calulating lead time and putting in table 
INSERT INTO inventory_calc_para (product_id, store_number, avg_lead_time_days)
WITH ordered_days AS (
  SELECT 
    date_,
    store_number,
    product_id,
    units_order
  FROM inventory
  WHERE units_order > 0
),
future_inventory AS (
  SELECT 
    o.date_ AS order_date,
    o.store_number,
    o.product_id,
    o.units_order,
    d.date_ AS delivery_date,
    d.inventory_level - LAG(d.inventory_level) OVER (
      PARTITION BY d.store_number, d.product_id 
      ORDER BY d.date_
    ) AS inventory_change
  FROM ordered_days o
  JOIN inventory d
    ON o.store_number = d.store_number
   AND o.product_id = d.product_id
   AND d.date_ BETWEEN o.date_ AND DATE_ADD(o.date_, INTERVAL 7 DAY)
)
SELECT 
  product_id,
  store_number,
  ROUND(AVG(DATEDIFF(delivery_date, order_date)), 2) AS avg_lead_time_days
FROM future_inventory
WHERE inventory_change >= units_order * 0.8 -- assuming 80% delivery and constant lead time of 7 days 
GROUP BY product_id, store_number;




-- top selling product 
SELECT 
    i.product_id,
    SUM(i.units_sold * (s.price - (s.price * s.discount / 100))) AS total_price
FROM inventory i
JOIN sales_table s
ON i.order_id = s.order_id
GROUP BY product_id
ORDER BY total_price DESC;


-- safety stock ( assuming 95% service level , Z  = 1.65)
SELECT 
    i.product_id,
    i.store_number,
    p.avg_lead_time_days ,
    STDDEV(i.units_sold) AS demand_std,
    ROUND(1.65 * STDDEV(i.units_sold) * SQRT(p.avg_lead_time_days), 2) AS safety_stock 
FROM inventory as i
INNER JOIN inventory_calc_para as p
ON i.product_id = p.product_id AND i.store_number = p.store_number
GROUP BY i.product_id , i.store_number, p.avg_lead_time_days;



ALTER TABLE inventory_calc_para
ADD COLUMN reorder_point FLOAT;
-- Reorder Point Calucation 
-- ROP = Safety Stock + Avg Units Sold ×Lead Time
WITH reorder_point_calc AS (
  SELECT 
    i.product_id,
    i.store_number,
    ROUND(
        AVG(i.units_sold) * p.avg_lead_time_days +
        1.65 * STDDEV(i.units_sold) * SQRT(p.avg_lead_time_days), 
        2
    ) AS reorder_point
  FROM inventory AS i
  JOIN inventory_calc_para AS p
    ON i.product_id = p.product_id AND i.store_number = p.store_number
  GROUP BY i.product_id, i.store_number, p.avg_lead_time_days
)
UPDATE inventory_calc_para p
JOIN reorder_point_calc r
  ON p.product_id = r.product_id AND p.store_number = r.store_number
SET p.reorder_point = r.reorder_point;




-- Low inventory detection based on reorder point 

SELECT 
    i.product_id,
    i.store_number,
     ROUND(AVG(i.inventory_level), 2) AS avg_inventory_level,

    -- Demand and Std Dev
    ROUND(AVG(i.units_sold), 2) AS avg_daily_demand,

    -- Safety Stock
    ROUND(1.65 * STDDEV(i.units_sold) * SQRT(p.avg_lead_time_days), 2) AS safety_stock,

    -- Reorder Point
    ROUND(
        AVG(i.units_sold) * p.avg_lead_time_days +
        1.65 * STDDEV(i.units_sold) * SQRT(p.avg_lead_time_days), 
        2
    ) AS reorder_point,

    CASE 
    WHEN avg(i.inventory_level) < ROUND(
        AVG(i.units_sold) * p.avg_lead_time_days +
        1.65 * STDDEV(i.units_sold) * SQRT(p.avg_lead_time_days), 
        2) 
        THEN 'REORDER NOW'
        ELSE "SUFFICIENT STOCK"
         END AS stock_status  

FROM inventory AS i
JOIN inventory_calc_para AS p
  ON i.product_id = p.product_id AND i.store_number = p.store_number
  GROUP BY i.product_id, i.store_number, p.avg_lead_time_days;





ALTER TABLE inventory_calc_para
ADD COLUMN inventory_turnover_ratio FLOAT,
ADD COLUMN day_of_inventory FLOAT;



-- Inventory Turnover Ratio  ( FORMULA  - ITR = TOTAL UNITS SOLD / AVG INVENTORY LEVEL
-- days of inventory = 365/ INVENTORY TURN OVER RATIO )
WITH inventory_metrics AS (
  SELECT 
    product_id,
    store_number,
    ROUND(SUM(units_sold) / NULLIF(AVG(inventory_level), 0), 2) AS inventory_turnover_ratio,
    ROUND(365 / NULLIF(SUM(units_sold) / AVG(inventory_level), 0), 1) AS days_of_inventory
  FROM inventory
  GROUP BY product_id, store_number
)
UPDATE inventory_calc_para p
JOIN inventory_metrics m
  ON p.product_id = m.product_id AND p.store_number = m.store_number
SET 
  p.inventory_turnover_ratio = m.inventory_turnover_ratio,
  p.day_of_inventory = m.days_of_inventory;




-- WEEKLY SALES AND MONTHLY SALES 
SELECT 
    product_id,
    store_number,
    YEAR(date_) AS year,
    WEEK(date_, 1) AS week_number,  -- Mode 1: weeks start on Monday
    SUM(units_sold) AS weekly_sales
FROM inventory
GROUP BY product_id, store_number, YEAR(date_), WEEK(date_, 1)
ORDER BY year, week_number, product_id, store_number;

-- Monthly sales
SELECT 
    product_id, 
    store_number,
    YEAR(date_) AS year,
    MONTH(date_) AS MONTH,  -- Mode 1: weeks start on Monday
    SUM(units_sold) AS monthly_sales
FROM inventory
GROUP BY product_id, store_number, YEAR(date_), month(date_)
ORDER BY year, month , product_id, store_number;


-- STOCK OUT RATE AND LOST REVNEUE 

SELECT 
    product_id,
    store_number,

    -- Total forecasted demand days
    COUNT(CASE WHEN demand_forecast > 0 THEN 1 END) AS forecasted_demand_days,

    -- Days when stock was  less and forecasted demand existed
    COUNT(CASE WHEN inventory_level < demand_forecast  THEN 1 END) AS stockout_days,

    -- Stockout Rate
    ROUND(
        COUNT(CASE WHEN inventory_level < demand_forecast THEN 1 END) * 100.0 /
        NULLIF(COUNT(CASE WHEN demand_forecast > 0 THEN 1 END), 0), 2
    ) AS stockout_rate_percent

FROM inventory
GROUP BY product_id, store_number
ORDER BY stockout_rate_percent DESC;

-- LOST REVENUE
SELECT 
    i.product_id,
    i.store_number,

    -- Sum of lost units where stock was unavailable and demand existed
    SUM(CASE 
        WHEN i.inventory_level < i.demand_forecast 
        THEN i.demand_forecast - i.inventory_level
        ELSE 0 
    END) AS lost_units,

    -- Total potential revenue lost
    ROUND(SUM(CASE 
        WHEN i.inventory_level < i.demand_forecast  
        THEN (i.demand_forecast - i.inventory_level)* s.price
        ELSE 0 
    END), 2) AS lost_revenue

FROM inventory i
JOIN sales_table s ON i.order_id= s.order_id
GROUP BY i.product_id, i.store_number
ORDER BY lost_revenue DESC;



-- age of inventory ( AOI = AVERAGE INVENTORY LEVEL / TOAL UNITS SOLD DAILY )
SELECT 
  product_id,
  store_number,
  ROUND(AVG(inventory_level), 2) AS avg_inventory,
  ROUND(AVG(units_sold), 2) AS avg_daily_sold,
  ROUND(AVG(inventory_level) / NULLIF(AVG(units_sold), 0), 2) AS inventory_age_days
FROM inventory
GROUP BY product_id, store_number;


ALTER TABLE inventory_calc_para
ADD COLUMN stock_level_calculation FLOAT;

WITH last_known_inventory AS (
  SELECT 
    store_number,
    product_id,
    MAX(date_) AS last_date
  FROM inventory
  WHERE date_ <= '2024-12-30'
  GROUP BY store_number, product_id
),
inventory_730_base AS (
  SELECT i.*
  FROM inventory i
  JOIN last_known_inventory l
    ON i.store_number = l.store_number 
   AND i.product_id = l.product_id
   AND i.date_ = l.last_date
),
sales_730 AS (
  SELECT store_number, product_id, units_sold
  FROM inventory
  WHERE date_ = '2024-12-30'
),
expected_deliveries_731 AS (
  SELECT 
    i.store_number,
    i.product_id,
    ROUND(SUM(i.units_order * 0.8), 0) AS expected_delivery
  FROM inventory i
  JOIN inventory_calc_para p
    ON i.store_number = p.store_number AND i.product_id = p.product_id
  WHERE DATE_ADD(i.date_, INTERVAL p.avg_lead_time_days DAY) = '2024-12-31'
  GROUP BY i.store_number, i.product_id
),
final_731_inventory AS (
  SELECT 
    b.store_number,
    b.product_id,
    b.inventory_level
      - COALESCE(s.units_sold, 0)
      + COALESCE(e.expected_delivery, 0) AS inventory_731
  FROM inventory_730_base b
  LEFT JOIN sales_730 s
    ON b.store_number = s.store_number AND b.product_id = s.product_id
  LEFT JOIN expected_deliveries_731 e
    ON b.store_number = e.store_number AND b.product_id = e.product_id
)
UPDATE inventory_calc_para p
JOIN final_731_inventory f
  ON p.store_number = f.store_number AND p.product_id = f.product_id
SET p.stock_level_calculation = f.inventory_731;



SELECT * FROM inventory_calc_para;


-- detecting low inventory by comparing the reorder_point with stock_level_calculation
ALTER TABLE inventory_calc_para
ADD COLUMN stock_status BOOLEAN;

UPDATE inventory_calc_para
SET stock_status = 
    CASE 
        WHEN reorder_point >= stock_level_calculation THEN 1
        ELSE 0
    END;

WITH base AS (
    SELECT product_id, store_number, inventory_turnover_ratio
    FROM inventory_calc_para
    ORDER BY inventory_turnover_ratio DESC
    LIMIT 10
)
SELECT AVG(inventory_turnover_ratio) FROM base;


SELECT * FROM inventory_combined;