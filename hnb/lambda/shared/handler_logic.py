"""Standardized execution harness for all H&B synthetic ingestion Lambda handlers."""

from __future__ import annotations

import json
import os
import random
import time
from typing import Any, Callable

from shared.config.core import DEFAULT_S3_BUCKET
from shared.utils import (
    build_s3_partition_key,
    serialize_and_compress_jsonl,
    setup_logger,
    upload_to_s3_with_backoff,
)


def execute_ingestion_pipeline(
    domain: str,
    dataset: str,
    generator_fn: Callable[[int], list[dict[str, Any]]],
    min_records: int,
    max_records: int,
    event: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Orchestrate synthetic batch generation, GZIP compression, and S3 partition upload."""
    start_time = time.perf_counter()
    event_payload = event or {}
    logger = setup_logger(f"hnb.lambda.{domain}.{dataset}")

    bucket = event_payload.get("bucket") or os.environ.get("S3_BUCKET", DEFAULT_S3_BUCKET)
    ingest_date = event_payload.get("ingest_date")
    num_records = int(event_payload.get("num_records") or random.randint(min_records, max_records))
    dry_run_env = os.environ.get("DRY_RUN", "true").lower() in ("1", "true", "yes")
    dry_run = bool(event_payload.get("dry_run", dry_run_env))

    records = generator_fn(num_records)
    compressed_bytes = serialize_and_compress_jsonl(records)
    s3_key = build_s3_partition_key(domain=domain, dataset=dataset, ingest_date=ingest_date)

    upload_to_s3_with_backoff(
        bucket=bucket,
        key=s3_key,
        payload_bytes=compressed_bytes,
        dry_run=dry_run,
    )

    elapsed_ms = round((time.perf_counter() - start_time) * 1000.0, 2)
    logger.info(
        "Completed %s.%s ingestion: records=%d, compressed_bytes=%d, s3_uri=s3://%s/%s, elapsed_ms=%.2f",
        domain,
        dataset,
        len(records),
        len(compressed_bytes),
        bucket,
        s3_key,
        elapsed_ms,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "domain": domain,
                "dataset": dataset,
                "records_generated": len(records),
                "compressed_bytes": len(compressed_bytes),
                "s3_uri": f"s3://{bucket}/{s3_key}",
                "dry_run": dry_run,
                "execution_time_ms": elapsed_ms,
            }
        ),
    }
