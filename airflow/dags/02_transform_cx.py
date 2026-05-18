from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'hnb-data-engineering',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    '02_transform_cx',
    default_args=default_args,
    description='Run dbt transformations for the CX pipeline (RDL -> ODL -> ADL)',
    schedule_interval='0 2 * * *', # 2:00 AM UTC daily, after S3 to Redshift load
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['cx', 'dbt', 'transformation'],
) as dag:

    # Using BashOperator for a local execution simulation, or KubernetesPodOperator in real environments.
    from airflow.operators.bash import BashOperator

    dbt_run_rdl = BashOperator(
        task_id='dbt_run_rdl',
        bash_command='cd /opt/airflow/dbt/hnb && dbt run --select path:models/rdl',
    )

    dbt_run_odl = BashOperator(
        task_id='dbt_run_odl',
        bash_command='cd /opt/airflow/dbt/hnb && dbt run --select path:models/odl',
    )

    dbt_run_adl = BashOperator(
        task_id='dbt_run_adl',
        bash_command='cd /opt/airflow/dbt/hnb && dbt run --select path:models/adl',
    )

    dbt_test = BashOperator(
        task_id='dbt_test',
        bash_command='cd /opt/airflow/dbt/hnb && dbt test',
    )

    dbt_run_rdl >> dbt_run_odl >> dbt_run_adl >> dbt_test
