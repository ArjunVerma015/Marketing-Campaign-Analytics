/* 
=============================================================================
Marketing Campaign Performance Analytics
Focus: 50,000+ Engagement Metrics, ROI, CTR, and Cohort Analysis across 25+ Channels
=============================================================================
*/

-- 1. Core Performance Metrics by Marketing Channel
-- Evaluates CTR, Conversion Rate, and ROI to deliver data-backed insights for ad spend.
SELECT 
    channel,
    COUNT(DISTINCT campaign_id) AS total_campaigns,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions,
    SUM(revenue) AS total_revenue,
    
    -- Performance Metrics Calculations
    ROUND((SUM(clicks) * 100.0) / NULLIF(SUM(impressions), 0), 2) AS click_through_rate_pct,
    ROUND((SUM(conversions) * 100.0) / NULLIF(SUM(clicks), 0), 2) AS conversion_rate_pct,
    ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS return_on_investment_pct

FROM cleaned_campaign_metrics
GROUP BY channel
ORDER BY return_on_investment_pct DESC;


-- 2. Underperforming Ad Groups Identification
-- Isolates channels/campaigns with high spend but negative ROI for budget reallocation.
SELECT 
    channel,
    campaign_name,
    spend,
    revenue,
    ROUND(((revenue - spend) / NULLIF(spend, 0)) * 100, 2) AS roi_pct,
    ROUND((conversions * 100.0) / NULLIF(clicks, 0), 2) AS conversion_rate_pct
FROM cleaned_campaign_metrics
WHERE spend > 1000 -- Assuming a minimum spend threshold for evaluation
  AND revenue < spend
ORDER BY spend DESC, roi_pct ASC;


-- 3. Monthly Acquisition Cohort Analysis
-- Tracks long-term campaign effectiveness by analyzing how different monthly cohorts perform.
WITH CohortSetup AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(campaign_date)) AS cohort_month,
        channel AS acquisition_channel
    FROM cleaned_campaign_metrics
    WHERE conversions > 0
    GROUP BY customer_id, channel
),
CohortPerformance AS (
    SELECT 
        c.cohort_month,
        c.acquisition_channel,
        COUNT(DISTINCT c.customer_id) AS total_acquired_customers,
        SUM(m.revenue) AS cumulative_cohort_revenue
    FROM CohortSetup c
    JOIN cleaned_campaign_metrics m ON c.customer_id = m.customer_id
    GROUP BY c.cohort_month, c.acquisition_channel
)
SELECT 
    cohort_month,
    acquisition_channel,
    total_acquired_customers,
    cumulative_cohort_revenue,
    ROUND(cumulative_cohort_revenue / NULLIF(total_acquired_customers, 0), 2) AS avg_revenue_per_acquired_user
FROM CohortPerformance
ORDER BY cohort_month ASC, total_acquired_customers DESC;
