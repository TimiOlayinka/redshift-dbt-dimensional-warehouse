"""AWS Lambda generator for simulated E-Commerce checkout payment transactions."""

from __future__ import annotations

from datetime import datetime, timezone
import os
from pathlib import Path
import random
import sys
from typing import Any
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from shared.config.core import VITALITY_BRAND_WEIGHTS, VITALITY_BRANDS
from shared.config.ecommerce import (
    DEFAULT_CURRENCY,
    PAYMENT_METHOD_IDS,
    PAYMENT_METHOD_WEIGHTS,
    PAYMENT_STATUS_WEIGHTS,
    PAYMENT_STATUSES,
)
from shared.handler_logic import execute_ingestion_pipeline


def generate_basket_payments(num_records: int = 800) -> list[dict[str, Any]]:
    """Generate realistic e-commerce checkout payment settlements across Vitality Retail Group brands."""
    records: list[dict[str, Any]] = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for _ in range(num_records):
        payment_method_id = random.choices(PAYMENT_METHOD_IDS, weights=PAYMENT_METHOD_WEIGHTS, k=1)[0]
        payment_status = random.choices(PAYMENT_STATUSES, weights=PAYMENT_STATUS_WEIGHTS, k=1)[0]

        records.append(
            {
                "payment_id": str(uuid.uuid4()),
                "basket_id": f"BSK-{random.randint(100000, 199999)}",
                "customer_id": f"CUST-{random.randint(10000, 99999)}",
                "payment_method_id": payment_method_id,
                "amount": round(random.uniform(14.50, 185.00), 2),
                "currency": DEFAULT_CURRENCY,
                "payment_status": payment_status,
                "processed_at": now_iso,
                "brand": random.choices(VITALITY_BRANDS, weights=VITALITY_BRAND_WEIGHTS, k=1)[0],
            }
        )
    return records


def lambda_handler(event: dict[str, Any] | None = None, context: Any = None) -> dict[str, Any]:
    """AWS Lambda entrypoint for `ecommerce_basket_payments`."""
    return execute_ingestion_pipeline(
        domain="ecommerce",
        dataset="basket_payments",
        generator_fn=generate_basket_payments,
        min_records=600,
        max_records=2200,
        event=event,
    )


if __name__ == "__main__":
    os.environ.setdefault("DRY_RUN", "true")
    print(lambda_handler({"num_records": 10}))
