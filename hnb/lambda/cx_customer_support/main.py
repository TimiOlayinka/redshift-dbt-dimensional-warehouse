import json
import boto3
import uuid
import os
import gzip
from datetime import datetime, timedelta
import random

s3 = boto3.client('s3')

def generate_support_tickets(num_records=100):
    records = []
    for _ in range(num_records):
        status = random.choice(["Closed", "Resolved", "Open", "Pending"])
        created_at = datetime.utcnow() - timedelta(days=random.randint(0, 10))
        resolved_at = created_at + timedelta(hours=random.randint(1, 48)) if status in ["Closed", "Resolved"] else None
        
        record = {
            "ticket_id": str(uuid.uuid4()),
            "customer_id": f"CUST-{random.randint(10000, 99999)}",
            "created_at": created_at.isoformat(),
            "resolved_at": resolved_at.isoformat() if resolved_at else None,
            "status": status,
            "channel": random.choice(["Email", "Chat", "Phone", "Social Media"]),
            "reason": random.choice(["Where is my order?", "Returns", "Defective Item", "Account Issue"]),
            "csat_score": random.randint(1, 5) if status in ["Closed", "Resolved"] and random.random() > 0.3 else None,
            "brand": random.choice(["HNB", "PrettyLittleThing", "NastyGal", "Karen Millen", "Coast", "Debenhams"])
        }
        records.append(record)
    return records

def lambda_handler(event, context):
    bucket = os.environ.get('S3_BUCKET', 'hnb-data-lake')
    prefix = 'hnb/cx/customer_support/history/ingest_date=' + datetime.utcnow().strftime('%Y-%m-%d')
    
    records = generate_support_tickets(random.randint(200, 800))
    jsonl = '\n'.join([json.dumps(r) for r in records]).encode('utf-8')
    compressed = gzip.compress(jsonl)
    
    key = f"{prefix}/customer_support.jsonl.gz"
    
    # s3.put_object(Bucket=bucket, Key=key, Body=compressed)
    
    print(f"Generated {len(records)} support ticket records for {key}")
    return {
        "statusCode": 200,
        "body": f"Successfully processed {len(records)} records."
    }
