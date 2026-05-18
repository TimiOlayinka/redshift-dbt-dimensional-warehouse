import json
import boto3
import uuid
import os
import gzip
from datetime import datetime
import random

s3 = boto3.client('s3')

def generate_basket_items(num_records=100):
    records = []
    for _ in range(num_records):
        quantity = random.randint(1, 4)
        price = round(random.uniform(10.0, 150.0), 2)
        record = {
            "basket_item_id": str(uuid.uuid4()),
            "basket_id": f"BSK-{random.randint(100000, 999999)}",
            "product_id": f"PRD-{random.randint(1000, 5000)}",
            "category_id": random.choice([101, 102, 201, 202]),
            "quantity": quantity,
            "unit_price": price,
            "total_price": round(quantity * price, 2),
            "added_at": datetime.utcnow().isoformat(),
            "brand": random.choice(["HNB", "PrettyLittleThing", "NastyGal", "Karen Millen", "Coast", "Debenhams"])
        }
        records.append(record)
    return records

def lambda_handler(event, context):
    bucket = os.environ.get('S3_BUCKET', 'hnb-data-lake')
    prefix = 'hnb/ecommerce/basket_items/history/ingest_date=' + datetime.utcnow().strftime('%Y-%m-%d')
    
    records = generate_basket_items(random.randint(2000, 8000))
    jsonl = '\n'.join([json.dumps(r) for r in records]).encode('utf-8')
    compressed = gzip.compress(jsonl)
    
    key = f"{prefix}/basket_items.jsonl.gz"
    
    # s3.put_object(Bucket=bucket, Key=key, Body=compressed)
    
    print(f"Generated {len(records)} basket items records for {key}")
    return {
        "statusCode": 200,
        "body": f"Successfully processed {len(records)} records."
    }
