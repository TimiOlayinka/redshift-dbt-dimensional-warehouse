"""Airflow DAG 02_transform_rdl: Executes dbt source freshness checks, RDL staging views, and staging quality gates."""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

DBT_PROJECT_DIR = "/opt/airflow/dbt/vitality"

default_args = {
    "owner": "vitality-analytics-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=3),
}

with DAG(
    dag_id="02_transform_rdl",
    default_args=default_args,
    description="Validate Redshift RDL source freshness, materialize RDL staging views, and run staging data quality tests",
    schedule="45 1 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "rdl", "staging", "data-quality"],
) as dag:

    dbt_source_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt source freshness --target prod",
    )

    dbt_run_rdl = BashOperator(
        task_id="dbt_run_rdl_staging",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select path:models/rdl --target prod",
    )

    dbt_test_rdl = BashOperator(
        task_id="dbt_test_rdl_staging",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/rdl --target prod",
    )

    trigger_odl_transform = TriggerDagRunOperator(
        task_id="trigger_03_transform_odl",
        trigger_dag_id="03_transform_odl",
        conf={"ingest_date": "{{ ds }}"},
        wait_for_completion=False,
    )

    dbt_source_freshness >> dbt_run_rdl >> dbt_test_rdl >> trigger_odl_transform
