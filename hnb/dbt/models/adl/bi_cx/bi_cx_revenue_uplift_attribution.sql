{{
    config(
        materialized='table',
        dist='all',
        sort=['report_month', 'brand', 'nps_category'],
        tags=['adl', 'bi_cx', 'attribution', 'executive']
    )
}}

/*
 * Commercial CX Attribution Mart
 * Links Customer Experience cohorts (Promoter / Passive / Detractor + Support CSAT recovery)
 * with downstream e-commerce repeat purchase velocity, Average Order Value (AOV), and
 * retained LTV across H&B Group brands. Powers the £6.4M ($5.7M) annual revenue uplift attribution model.
 */

WITH customer_nps_cohorts AS (
    SELECT
        customer_id,
        brand,
        CAST(DATE_TRUNC('month', response_date) AS DATE) AS report_month,
        nps_category,
        AVG(CAST(nps_score AS NUMERIC(10, 2))) AS avg_customer_nps
    FROM {{ ref('fact_survey') }}
    WHERE
        survey_type = 'postship'
        AND customer_id IS NOT NULL
    GROUP BY
        customer_id,
        brand,
        CAST(DATE_TRUNC('month', response_date) AS DATE),
        nps_category
),

basket_item_Rollup AS (
    SELECT
        basket_id,
        SUM(quantity) AS total_units,
        COUNT(DISTINCT category_id) AS distinct_categories,
        MAX(department) AS primary_department
    FROM {{ ref('fact_basket_items') }}
    GROUP BY basket_id
),

customer_commerce_spend AS (
    SELECT
        p.customer_id,
        p.brand,
        CAST(DATE_TRUNC('month', p.processed_at) AS DATE) AS purchase_month,
        COUNT(DISTINCT p.basket_id) AS order_count,
        SUM(p.gross_amount) AS gross_revenue_gbp,
        SUM(p.net_settlement_amount) AS net_revenue_gbp,
        AVG(p.gross_amount) AS avg_order_value_gbp,
        SUM(COALESCE(bi.total_units, 1)) AS total_units_purchased
    FROM {{ ref('fact_basket_payments') }} AS p
    LEFT JOIN basket_item_Rollup AS bi
        ON p.basket_id = bi.basket_id
    WHERE p.payment_status = 'Success'
    GROUP BY
        p.customer_id,
        p.brand,
        CAST(DATE_TRUNC('month', p.processed_at) AS DATE)
),

support_intervention AS (
    SELECT
        customer_id,
        brand,
        CAST(DATE_TRUNC('month', created_at) AS DATE) AS ticket_month,
        BOOL_OR(is_first_contact_resolution) AS had_fcr_recovery,
        BOOL_OR(is_sla_breached) AS experienced_sla_breach
    FROM {{ ref('fact_cx_tickets') }}
    GROUP BY
        customer_id,
        brand,
        CAST(DATE_TRUNC('month', created_at) AS DATE)
),

cohort_aggregates AS (
    SELECT
        n.brand,
        n.report_month,
        n.nps_category,
        COALESCE(s.had_fcr_recovery, FALSE) AS had_fcr_recovery,
        COALESCE(s.experienced_sla_breach, FALSE) AS experienced_sla_breach,
        COUNT(DISTINCT n.customer_id) AS cohort_customers,
        SUM(COALESCE(c.order_count, 0)) AS total_orders,
        ROUND(AVG(COALESCE(c.order_count, 0.0)), 2) AS repeat_purchase_frequency,
        ROUND(AVG(COALESCE(c.avg_order_value_gbp, 0.0)), 2) AS avg_order_value_gbp,
        ROUND(SUM(COALESCE(c.gross_revenue_gbp, 0.0)), 2) AS cohort_gross_revenue_gbp,
        ROUND(SUM(COALESCE(c.net_revenue_gbp, 0.0)), 2) AS cohort_net_revenue_gbp,
        ROUND(
            SUM(COALESCE(c.gross_revenue_gbp, 0.0)) / NULLIF(COUNT(DISTINCT n.customer_id), 0),
            2
        ) AS revenue_per_customer_gbp
    FROM customer_nps_cohorts AS n
    LEFT JOIN customer_commerce_spend AS c
        ON n.customer_id = c.customer_id
        AND n.brand = c.brand
        AND n.report_month = c.purchase_month
    LEFT JOIN support_intervention AS s
        ON n.customer_id = s.customer_id
        AND n.brand = s.brand
        AND n.report_month = s.ticket_month
    GROUP BY
        n.brand,
        n.report_month,
        n.nps_category,
        COALESCE(s.had_fcr_recovery, FALSE),
        COALESCE(s.experienced_sla_breach, FALSE)
),

detractor_baseline AS (
    SELECT
        brand,
        report_month,
        AVG(revenue_per_customer_gbp) AS baseline_detractor_rev_per_customer
    FROM cohort_aggregates
    WHERE nps_category = 'Detractor'
    GROUP BY
        brand,
        report_month
)

SELECT
    MD5(
        ca.brand || '|' || CAST(ca.report_month AS VARCHAR) || '|' || ca.nps_category
        || '|' || CAST(ca.had_fcr_recovery AS VARCHAR) || '|' || CAST(ca.experienced_sla_breach AS VARCHAR)
    ) AS attribution_sk,
    ca.brand,
    ca.report_month,
    ca.nps_category,
    ca.had_fcr_recovery,
    ca.experienced_sla_breach,
    ca.cohort_customers,
    ca.total_orders,
    ca.repeat_purchase_frequency,
    ca.avg_order_value_gbp,
    ca.cohort_gross_revenue_gbp,
    ca.cohort_net_revenue_gbp,
    ca.revenue_per_customer_gbp,
    ROUND(
        GREATEST(
            ca.revenue_per_customer_gbp - COALESCE(db.baseline_detractor_rev_per_customer, 0.0),
            0.0
        ) * ca.cohort_customers,
        2
    ) AS incremental_revenue_uplift_gbp,
    CURRENT_TIMESTAMP AS _etl_loaded_at
FROM cohort_aggregates AS ca
LEFT JOIN detractor_baseline AS db
    ON ca.brand = db.brand
    AND ca.report_month = db.report_month
ORDER BY
    ca.report_month DESC,
    ca.brand ASC,
    ca.nps_category ASC
