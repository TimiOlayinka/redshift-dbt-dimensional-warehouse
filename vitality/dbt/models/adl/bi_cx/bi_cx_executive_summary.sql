{{
    config(
        materialized='table',
        dist='all',
        sort=['report_month', 'brand'],
        tags=['adl', 'bi_cx', 'executive']
    )
}}

WITH nps_monthly AS (
    SELECT
        brand,
        CAST(DATE_TRUNC('month', response_date) AS DATE) AS report_month,
        COUNT(*) AS total_nps_responses,
        SUM(CASE WHEN survey_type = 'postship' THEN 1 ELSE 0 END) AS postship_responses,
        SUM(CASE WHEN survey_type = 'visitview' THEN 1 ELSE 0 END) AS visitview_responses,
        SUM(CASE WHEN nps_category = 'Promoter' THEN 1 ELSE 0 END) AS promoters,
        SUM(CASE WHEN nps_category = 'Passive' THEN 1 ELSE 0 END) AS passives,
        SUM(CASE WHEN nps_category = 'Detractor' THEN 1 ELSE 0 END) AS detractors,
        {{ calculate_net_nps_score('nps_category') }} AS nps_score,
        ROUND(
            (
                SUM(CASE WHEN survey_type = 'postship' AND nps_category = 'Promoter' THEN 1.0 ELSE 0.0 END)
                - SUM(CASE WHEN survey_type = 'postship' AND nps_category = 'Detractor' THEN 1.0 ELSE 0.0 END)
            ) * 100.0 / NULLIF(SUM(CASE WHEN survey_type = 'postship' THEN 1 ELSE 0 END), 0),
            2
        ) AS postship_nps_score,
        ROUND(
            (
                SUM(CASE WHEN survey_type = 'visitview' AND nps_category = 'Promoter' THEN 1.0 ELSE 0.0 END)
                - SUM(CASE WHEN survey_type = 'visitview' AND nps_category = 'Detractor' THEN 1.0 ELSE 0.0 END)
            ) * 100.0 / NULLIF(SUM(CASE WHEN survey_type = 'visitview' THEN 1 ELSE 0 END), 0),
            2
        ) AS visitview_nps_score
    FROM {{ ref('fact_survey') }}
    GROUP BY
        brand,
        CAST(DATE_TRUNC('month', response_date) AS DATE)
),

csat_monthly AS (
    SELECT
        brand,
        CAST(DATE_TRUNC('month', created_at) AS DATE) AS report_month,
        COUNT(ticket_id) AS total_tickets,
        ROUND(AVG(CAST(csat_score AS NUMERIC(10, 2))), 2) AS avg_csat_score,
        ROUND(
            SUM(CASE WHEN is_positive_csat = TRUE THEN 1.0 ELSE 0.0 END) * 100.0
            / NULLIF(COUNT(csat_score), 0),
            2
        ) AS positive_csat_pct,
        ROUND(AVG(resolution_time_hours), 2) AS avg_resolution_time_hours,
        ROUND(
            SUM(CASE WHEN is_first_contact_resolution = TRUE THEN 1.0 ELSE 0.0 END) * 100.0
            / NULLIF(COUNT(ticket_id), 0),
            2
        ) AS first_contact_resolution_pct,
        ROUND(
            SUM(CASE WHEN is_sla_breached = TRUE THEN 1.0 ELSE 0.0 END) * 100.0
            / NULLIF(COUNT(ticket_id), 0),
            2
        ) AS sla_breach_rate_pct
    FROM {{ ref('fact_cx_tickets') }}
    GROUP BY
        brand,
        CAST(DATE_TRUNC('month', created_at) AS DATE)
)

SELECT
    MD5(COALESCE(n.brand, c.brand) || '|' || CAST(COALESCE(n.report_month, c.report_month) AS VARCHAR)) AS summary_sk,
    COALESCE(n.brand, c.brand) AS brand,
    COALESCE(n.report_month, c.report_month) AS report_month,
    COALESCE(n.total_nps_responses, 0) AS total_nps_responses,
    COALESCE(n.postship_responses, 0) AS postship_responses,
    COALESCE(n.visitview_responses, 0) AS visitview_responses,
    COALESCE(n.promoters, 0) AS promoters,
    COALESCE(n.passives, 0) AS passives,
    COALESCE(n.detractors, 0) AS detractors,
    n.nps_score,
    n.postship_nps_score,
    n.visitview_nps_score,
    COALESCE(c.total_tickets, 0) AS total_tickets,
    c.avg_csat_score,
    c.positive_csat_pct,
    c.avg_resolution_time_hours,
    c.first_contact_resolution_pct,
    c.sla_breach_rate_pct,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM nps_monthly AS n
FULL OUTER JOIN csat_monthly AS c
    ON n.brand = c.brand
    AND n.report_month = c.report_month
ORDER BY
    report_month DESC,
    brand ASC
