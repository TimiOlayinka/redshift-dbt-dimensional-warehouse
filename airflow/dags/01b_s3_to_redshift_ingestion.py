"""Airflow DAG 01b_s3_to_redshift_ingestion: Standardized idempotent S3-to-Redshift COPY loader."""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.utils.task_group import TaskGroup

default_args = {
    "owner": "hnb-analytics-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
    "retry_exponential_backoff": True,
}

DATASETS = [
    {"domain": "cx", "dataset": "nps_postship", "schema": "rdl", "table": "rdl_smg_nps_postship"},
    {"domain": "cx", "dataset": "nps_visitview", "schema": "rdl", "table": "rdl_smg_nps_visitview"},
    {"domain": "cx", "dataset": "customer_support", "schema": "rdl", "table": "rdl_cx_tickets"},
    {"domain": "ecommerce", "dataset": "basket_items", "schema": "rdl", "table": "rdl_basket_items"},
    {"domain": "ecommerce", "dataset": "basket_payments", "schema": "rdl", "table": "rdl_basket_payments"},
]

with DAG(
    dag_id="01b_s3_to_redshift_ingestion",
    default_args=default_args,
    description="Idempotent COPY ingestion from S3 Hive partitions into Redshift Serverless RDL tables",
    schedule="30 1 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["ingestion", "redshift", "s3", "rdl"],
) as dag:

    s3_bucket = "{{ var.value.get('hnb_s3_bucket', 'hnb-data-lake') }}"
    redshift_iam_role = "{{ var.value.get('redshift_copy_iam_role', 'arn:aws:iam::123456789012:role/hnb-cx-dwh-prod-redshift-s3-role') }}"
    ingest_date = "{{ ds }}"

    with TaskGroup(group_id="copy_s3_to_redshift_rdl") as copy_group:
        for cfg in DATASETS:
            domain = cfg["domain"]
            dataset = cfg["dataset"]
            schema = cfg["schema"]
            table = cfg["table"]

            s3_key = f"hnb/{domain}/{dataset}/history/ingest_date={ingest_date}/{dataset}.jsonl.gz"

            copy_sql = f"""
                CREATE SCHEMA IF NOT EXISTS {schema};
                CREATE TABLE IF NOT EXISTS {schema}.{table} (
                    raw_data SUPER,
                    _ingested_at TIMESTAMP DEFAULT SYSDATE
                );
                COPY {schema}.{table} (raw_data)
                FROM 's3://{s3_bucket}/{s3_key}'
                IAM_ROLE '{redshift_iam_role}'
                FORMAT AS JSON 'noshred'
                GZIP
                TIMEFORMAT 'auto'
                 STATUPDATE ON;
            """

            SQLExecuteQueryOperator(
                task_id=f"copy_{dataset}_to_redshift",
                conn_id="redshift_default",
                sql=copy_sql,
            )

    trigger_rdl_transform = TriggerDagRunOperator(
        task_id="trigger_02_transform_rdl",
        trigger_dag_id="02_transform_rdl",
        conf={"ingest_date": "{{ ds }}"},
        wait_for_completion=False,
    )

    copy_group >> trigger_rdl_transform
