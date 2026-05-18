from airflow import DAG
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
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
    '01b_s3_to_redshift_ingestion',
    default_args=default_args,
    description='Standardized COPY ingestion from S3 to Redshift Serverless for all domains',
    schedule_interval='30 1 * * *',
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=['ingestion', 'redshift', 'standardized'],
) as dag:

    s3_bucket = 'hnb-data-lake'
    ingest_date = '{{ ds }}'

    # Configuration registry for all S3 to Redshift ingestions
    datasets = [
        {'domain': 'cx', 'dataset': 'nps_postship', 'schema': 'rdl', 'table': 'rdl_smg_nps_postship'},
        {'domain': 'cx', 'dataset': 'nps_visitview', 'schema': 'rdl', 'table': 'rdl_smg_nps_visitview'},
        {'domain': 'cx', 'dataset': 'customer_support', 'schema': 'rdl', 'table': 'rdl_cx_tickets'},
        {'domain': 'ecommerce', 'dataset': 'basket_items', 'schema': 'rdl', 'table': 'rdl_basket_items'},
        {'domain': 'ecommerce', 'dataset': 'basket_payments', 'schema': 'rdl', 'table': 'rdl_basket_payments'}
    ]

    for config in datasets:
        domain = config['domain']
        dataset = config['dataset']
        schema = config['schema']
        table = config['table']
        
        s3_key = f"hnb/{domain}/{dataset}/history/ingest_date={ingest_date}/{dataset}.jsonl.gz"
        
        copy_sql = f"""
            COPY {schema}.{table}
            FROM 's3://{s3_bucket}/{s3_key}'
            IAM_ROLE 'arn:aws:iam::ACCOUNT:role/RedshiftS3Access'
            FORMAT AS JSON 'noshred'
            GZIP;
        """

        SQLExecuteQueryOperator(
            task_id=f"copy_{dataset}_to_redshift",
            conn_id='redshift_default',
            sql=copy_sql,
        )
