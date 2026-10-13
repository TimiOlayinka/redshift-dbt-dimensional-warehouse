"""Airflow DAG 03_transform_odl: Executes Kimball SCD2 snapshots, ODL dimensions, incremental ODL facts, and quality tests."""

from __future__ import annotations

from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.task_group import TaskGroup

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
    dag_id="03_transform_odl",
    default_args=default_args,
    description="Build Kimball SCD Type 2 snapshots, ODL conformed dimensions, and incremental Redshift fact tables",
    schedule="15 2 * * *",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "odl", "kimball", "incremental"],
) as dag:

    dbt_snapshot_scd2 = BashOperator(
        task_id="dbt_snapshot_scd2",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt snapshot --target prod",
    )

    with TaskGroup(group_id="odl_kimball_layer") as odl_layer:
        dbt_run_odl_dims = BashOperator(
            task_id="dbt_run_odl_dimensions",
            bash_command=(
                f"cd {DBT_PROJECT_DIR} && "
                "dbt run --select path:models/odl/dim_cx dim_product_category map_payment_methods --target prod"
            ),
        )

        dbt_run_odl_facts = BashOperator(
            task_id="dbt_run_odl_incremental_facts",
            bash_command=(
                f"cd {DBT_PROJECT_DIR} && "
                "dbt run --select path:models/odl/fact_cx fact_basket_items fact_basket_payments --target prod"
            ),
        )

        dbt_run_odl_dims >> dbt_run_odl_facts

    dbt_test_odl = BashOperator(
        task_id="dbt_test_odl_contracts",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --select path:models/odl --target prod",
    )

    trigger_adl_transform = TriggerDagRunOperator(
        task_id="trigger_04_transform_adl",
        trigger_dag_id="04_transform_adl",
        conf={"ingest_date": "{{ ds }}"},
        wait_for_completion=False,
    )

    dbt_snapshot_scd2 >> odl_layer >> dbt_test_odl >> trigger_adl_transform
