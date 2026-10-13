{% snapshot scd_cx_ticket_status %}

{{
    config(
        target_schema='odl_snapshots',
        unique_key='ticket_id',
        strategy='timestamp',
        updated_at='last_modified_at',
        invalidate_hard_deletes=True,
        dist='customer_id',
        sort=['ticket_id', 'last_modified_at']
    )
}}

SELECT
    ticket_id,
    customer_id,
    brand,
    channel,
    reason,
    status,
    csat_score,
    created_at,
    resolved_at,
    COALESCE(resolved_at, created_at) AS last_modified_at
FROM {{ ref('stg_cx_tickets') }}

{% endsnapshot %}
