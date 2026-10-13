"""Airflow DAG 04_transform_adl: Builds Executive BI & Revenue Uplift Attribution Marts in Redshift ADL."""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

DBT_PROJECT_DIR = "/opt/airflow/dbt/hnb"

default_args = {
    "owner": "hnb-analytics-engineering",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="04_transform_adl",
    default_args=default_args,
    description="Materialize Executive CX Summary and Revenue Uplift Attribution Marts in Redshift ADL",
    schedule="45 2 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "adl", "executive", "attribution"],
) as dag:

    dbt_run_adl = BashOperator(
        task_id="dbt_run_adl_marts",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt run --select path:models/adl --target prod",
    )

    dbt_test_adl = BashOperator(
        task_id="dbt_test_adl_marts",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/adl --target prod",
    )

    dbt_docs_generate = BashOperator(
        task_id="dbt_docs_generate_catalog",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt docs generate --target prod",
    )

    dbt_run_adl >> dbt_test_adl >> dbt_docs_generate
