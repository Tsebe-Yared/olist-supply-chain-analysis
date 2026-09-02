-- 1. Customers Table
CREATE TABLE olist_customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- 2. Geolocation Table
CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC(10,8),
    geolocation_lng NUMERIC(11,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- 3. Orders Table
CREATE TABLE olist_orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) REFERENCES olist_customers(customer_id),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 4. Order Items Table
CREATE TABLE olist_order_items (
    order_id VARCHAR(32) REFERENCES olist_orders(order_id),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10,2),
    freight_value NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 5. Order Payments Table
CREATE TABLE olist_order_payments (
    order_id VARCHAR(32) REFERENCES olist_orders(order_id),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC(10,2)
);

-- 6. Order Reviews Table
CREATE TABLE olist_order_reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32) REFERENCES olist_orders(order_id),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- 7. Products Table
CREATE TABLE olist_products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 8. Sellers Table
CREATE TABLE olist_sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- 9. Product Category Translation Table
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);
	

-- Check if it worked
SELECT 'olist_customers' AS table_name, COUNT(*) AS total_rows FROM olist_customers
UNION ALL
SELECT 'olist_orders', COUNT(*) FROM olist_orders
UNION ALL
SELECT 'olist_order_items', COUNT(*) FROM olist_order_items
UNION ALL
SELECT 'olist_order_payments', COUNT(*) FROM olist_order_payments
UNION ALL
SELECT 'olist_order_reviews', COUNT(*) FROM olist_order_reviews
UNION ALL
SELECT 'olist_products', COUNT(*) FROM olist_products
UNION ALL
SELECT 'olist_sellers', COUNT(*) FROM olist_sellers
UNION ALL
SELECT 'olist_geolocation', COUNT(*) FROM olist_geolocation
UNION ALL
SELECT 'product_category_name_translation', COUNT(*) FROM product_category_name_translation;

-- Check total count and delivery status distributions
	SELECT 
	    order_status, 
	    COUNT(*) AS total_orders,
	    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
	FROM olist_orders
	GROUP BY order_status
	ORDER BY total_orders DESC;
	
-- CREATE VIEW vw_supply_chain_performance AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_state,
    c.customer_city,
    i.seller_id,
    s.seller_state,
    s.seller_city,
    i.product_id,
    p.product_category_name,
    t.product_category_name_english,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    i.price,
    i.freight_value,
    -- Lead Time Calculations (in days)
    ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400, 2) AS actual_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400, 2) AS estimated_delivery_days,
    -- Delay Indicator (1 = Delayed, 0 = On-Time)
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 
        ELSE 0 
    END AS is_delayed
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_sellers s ON i.seller_id = s.seller_id
JOIN olist_products p ON i.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;

SELECT * FROM vw_supply_chain_performance LIMIT 10;
	
        WITH seller_metrics AS (
	    SELECT 
	        seller_id,
	        seller_state,
	        COUNT(DISTINCT order_id) AS total_orders,
	        SUM(price) AS total_revenue,
	        ROUND(AVG(actual_delivery_days), 1) AS avg_delivery_days,
	        SUM(is_delayed) AS total_delayed_orders,
	        ROUND(SUM(is_delayed)::DECIMAL / COUNT(DISTINCT order_id) * 100, 2) AS delay_rate_pct
	    FROM vw_supply_chain_performance
	    GROUP BY seller_id, seller_state
	    HAVING COUNT(DISTINCT order_id) >= 10 -- Focus on active sellers with at least 10 orders
	)
	SELECT 
	    seller_id,
	    seller_state,
	    total_orders,
	    total_revenue,
	    avg_delivery_days,
	    total_delayed_orders,
	    delay_rate_pct,
	    -- Rank sellers by highest delay rate among high-volume accounts
	    DENSE_RANK() OVER (ORDER BY delay_rate_pct DESC) AS delay_rank
	FROM seller_metrics
	ORDER BY delay_rate_pct DESC
	LIMIT 20;
	
