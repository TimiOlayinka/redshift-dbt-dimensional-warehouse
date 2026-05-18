{{ config(materialized='table') }}

WITH nps_overall AS (
    SELECT 
        brand,
        DATE_TRUNC('month', response_date) AS report_month,
        COUNT(*) AS total_nps_responses,
        SUM(CASE WHEN nps_category = 'Promoter' THEN 1 ELSE 0 END) AS promoters,
        SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) AS detractors,
        ROUND(
            (SUM(CASE WHEN nps_category = 'Promoter' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) - 
            (SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 
        2) AS nps_score
    FROM {{ ref('fact_survey') }}
    GROUP BY brand, DATE_TRUNC('month', response_date)
),
csat_overall AS (
    SELECT
        brand,
        DATE_TRUNC('month', created_at) AS report_month,
        COUNT(ticket_id) AS total_tickets,
        AVG(csat_score) AS avg_csat_score,
        AVG(resolution_time_hours) AS avg_resolution_time_hours
    FROM {{ ref('fact_cx_tickets') }}
    GROUP BY brand, DATE_TRUNC('month', created_at)
)

SELECT 
    COALESCE(n.brand, c.brand) AS brand,
    COALESCE(n.report_month, c.report_month) AS report_month,
    n.total_nps_responses,
    n.nps_score,
    c.total_tickets,
    c.avg_csat_score,
    c.avg_resolution_time_hours
FROM nps_overall n
FULL OUTER JOIN csat_overall c 
    ON n.brand = c.brand AND n.report_month = c.report_month
ORDER BY report_month DESC, brand
