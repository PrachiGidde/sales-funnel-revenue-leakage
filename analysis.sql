
-- =====================================================
-- Sales Funnel & Revenue Leakage Analysis
-- SQL Analysis File
-- Author: [Prachi Gidde]
-- Dataset: CRM Sales Opportunities (Kaggle)
-- =====================================================

-- =====================================================
-- BASIC SQL QUERIES
-- =====================================================

-- Query 1: Total Deals by Stage
SELECT 
    deal_stage,
    COUNT(opportunity_id) AS total_deals,
    ROUND(COUNT(opportunity_id) * 100.0 / 
          (SELECT COUNT(*) FROM sales_pipeline), 1) AS percentage
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY total_deals DESC;

-- Query 2: Total Revenue by Product
SELECT 
    product,
    COUNT(opportunity_id) AS total_deals,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product
ORDER BY total_revenue DESC;

-- Query 3: Won vs Lost by Region
SELECT 
    st.regional_office,
    COUNT(CASE WHEN sp.deal_stage = 'Won' 
          THEN 1 END) AS won_deals,
    COUNT(CASE WHEN sp.deal_stage = 'Lost' 
          THEN 1 END) AS lost_deals,
    ROUND(COUNT(CASE WHEN sp.deal_stage = 'Won' 
          THEN 1 END) * 100.0 /
          COUNT(opportunity_id), 1) AS win_rate
FROM sales_pipeline sp
JOIN sales_teams st 
    ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage IN ('Won', 'Lost')
GROUP BY st.regional_office
ORDER BY win_rate DESC;

-- Query 4: Top 10 Sales Agents by Revenue
SELECT 
    sales_agent,
    COUNT(opportunity_id) AS deals_won,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 5: Monthly Revenue Trend
SELECT 
    STRFTIME('%Y-%m', close_date) AS month,
    COUNT(opportunity_id) AS deals_won,
    SUM(close_value) AS monthly_revenue,
    ROUND(AVG(close_value), 2) AS avg_deal_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
AND close_date IS NOT NULL
GROUP BY month
ORDER BY month;

-- =====================================================
-- ADVANCED SQL QUERIES
-- =====================================================

-- Query 6: Sales Agent Ranking (Window Function)
SELECT 
    sales_agent,
    regional_office,
    total_revenue,
    deals_won,
    RANK() OVER (ORDER BY total_revenue DESC) 
        AS revenue_rank,
    RANK() OVER (PARTITION BY regional_office 
                 ORDER BY total_revenue DESC) 
        AS regional_rank
FROM (
    SELECT 
        sp.sales_agent,
        st.regional_office,
        SUM(sp.close_value) AS total_revenue,
        COUNT(sp.opportunity_id) AS deals_won
    FROM sales_pipeline sp
    JOIN sales_teams st 
        ON sp.sales_agent = st.sales_agent
    WHERE sp.deal_stage = 'Won'
    GROUP BY sp.sales_agent, st.regional_office
)
ORDER BY revenue_rank
LIMIT 10;

-- Query 7: Funnel Conversion Rate (CTE)
WITH funnel AS (
    SELECT
        COUNT(CASE WHEN deal_stage = 'Prospecting' 
              THEN 1 END) AS prospecting,
        COUNT(CASE WHEN deal_stage = 'Engaging' 
              THEN 1 END) AS engaging,
        COUNT(CASE WHEN deal_stage = 'Won' 
              THEN 1 END) AS won,
        COUNT(CASE WHEN deal_stage = 'Lost' 
              THEN 1 END) AS lost,
        COUNT(*) AS total
    FROM sales_pipeline
)
SELECT
    prospecting, engaging, won, lost, total,
    ROUND(engaging * 100.0 / total, 1) 
        AS prospecting_to_engaging,
    ROUND(won * 100.0 / (won + lost), 1) 
        AS close_to_win_rate,
    ROUND(won * 100.0 / total, 1) 
        AS overall_win_rate
FROM funnel;

-- Query 8: Cumulative Revenue (Running Total)
SELECT 
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY month
    ) AS cumulative_revenue,
    ROUND(monthly_revenue * 100.0 / 
          SUM(monthly_revenue) OVER (), 1) 
        AS pct_of_total
FROM (
    SELECT 
        STRFTIME('%Y-%m', close_date) AS month,
        SUM(close_value) AS monthly_revenue
    FROM sales_pipeline
    WHERE deal_stage = 'Won'
    AND close_date IS NOT NULL
    GROUP BY month
)
ORDER BY month;

-- Query 9: Deal Size Segmentation (CASE WHEN)
SELECT 
    CASE 
        WHEN close_value = 0 THEN 'Zero Value'
        WHEN close_value < 1000 THEN 'Small (< $1K)'
        WHEN close_value BETWEEN 1000 AND 5000 
            THEN 'Medium ($1K-$5K)'
        WHEN close_value > 5000 THEN 'Large (> $5K)'
    END AS deal_segment,
    COUNT(*) AS total_deals,
    SUM(close_value) AS total_revenue,
    ROUND(AVG(close_value), 2) AS avg_value
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY deal_segment
ORDER BY total_revenue DESC;

-- Query 10: Month over Month Growth (LAG Function)
SELECT 
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY month
    ) AS previous_month,
    ROUND((monthly_revenue - LAG(monthly_revenue) 
           OVER (ORDER BY month)) * 100.0 / 
           LAG(monthly_revenue) OVER (
               ORDER BY month
           ), 1) AS growth_pct
FROM (
    SELECT 
        STRFTIME('%Y-%m', close_date) AS month,
        SUM(close_value) AS monthly_revenue
    FROM sales_pipeline
    WHERE deal_stage = 'Won'
    AND close_date IS NOT NULL
    GROUP BY month
)
ORDER BY month;

-- Query 11: Above Average Performing Agents (Subquery)
SELECT 
    sp.sales_agent,
    st.regional_office,
    st.manager,
    SUM(sp.close_value) AS total_revenue,
    COUNT(sp.opportunity_id) AS deals_won,
    ROUND(SUM(sp.close_value) - (
        SELECT AVG(agent_revenue)
        FROM (
            SELECT SUM(close_value) AS agent_revenue
            FROM sales_pipeline
            WHERE deal_stage = 'Won'
            GROUP BY sales_agent
        )
    ), 2) AS above_avg_by
FROM sales_pipeline sp
JOIN sales_teams st 
    ON sp.sales_agent = st.sales_agent
WHERE sp.deal_stage = 'Won'
GROUP BY sp.sales_agent
HAVING total_revenue > (
    SELECT AVG(agent_revenue)
    FROM (
        SELECT SUM(close_value) AS agent_revenue
        FROM sales_pipeline
        WHERE deal_stage = 'Won'
        GROUP BY sales_agent
    )
)
ORDER BY total_revenue DESC;
