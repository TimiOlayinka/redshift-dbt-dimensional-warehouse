from airflow import DAG
from airflow.providers.amazon.aws.operators.lambda_function import LambdaInvokeFunctionOperator
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
    '01_cx_ingestion',
    default_args=default_args,
    description='Invoke Lambda functions to generate simulated CX data and push to S3',
    schedule_interval='0 1 * * *', # 1 AM UTC daily
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['cx', 'ingestion', 'lambda'],
) as dag:

    invoke_nps_postship = LambdaInvokeFunctionOperator(
        task_id='invoke_nps_postship',
        function_name='cx_nps_postship',
        aws_conn_id='aws_default',
    )

    invoke_nps_visitview = LambdaInvokeFunctionOperator(
        task_id='invoke_nps_visitview',
        function_name='cx_nps_visitview',
        aws_conn_id='aws_default',
    )

    invoke_customer_support = LambdaInvokeFunctionOperator(
        task_id='invoke_customer_support',
        function_name='cx_customer_support',
        aws_conn_id='aws_default',
    )

    [invoke_nps_postship, invoke_nps_visitview, invoke_customer_support]
