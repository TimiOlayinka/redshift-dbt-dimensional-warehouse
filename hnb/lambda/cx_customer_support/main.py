"""AWS Lambda generator for simulated Zendesk Customer Care support tickets."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import random
import sys
from typing import Any
import uuid

# Allow local execution outside packaged zip by adding parent directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from shared.config.core import HNB_BRAND_WEIGHTS, HNB_BRANDS
from shared.config.marketing import (
    SUPPORT_CHANNEL_WEIGHTS,
    SUPPORT_CHANNELS,
    SUPPORT_CONTACT_REASONS,
    SUPPORT_TICKET_STATUS_WEIGHTS,
    SUPPORT_TICKET_STATUSES,
)
from shared.handler_logic import execute_ingestion_pipeline


def generate_support_tickets(num_records: int = 250) -> list[dict[str, Any]]:
    """Generate realistic omnichannel customer support ticket payloads for H&B Group brands."""
    records: list[dict[str, Any]] = []
    now_utc = datetime.now(timezone.utc)

    for _ in range(num_records):
        status = random.choices(SUPPORT_TICKET_STATUSES, weights=SUPPORT_TICKET_STATUS_WEIGHTS, k=1)[0]
        created_at = now_utc - timedelta(days=random.randint(0, 7), hours=random.randint(0, 23))
        is_completed = status in ("Closed", "Resolved")

        # Simulate realistic resolution distribution (most within 1-18h, tail up to 48h)
        resolution_hours = (
            random.choices([random.randint(1, 4), random.randint(5, 20), random.randint(25, 48)], weights=[0.45, 0.40, 0.15], k=1)[0]
            if is_completed
            else None
        )
        resolved_at = created_at + timedelta(hours=resolution_hours) if resolution_hours is not None else None

        # Higher CSAT when resolved within First-Contact Resolution (<= 4 hours)
        csat_score: int | None = None
        if is_completed and random.random() > 0.25:
            if resolution_hours and resolution_hours <= 4:
                csat_score = random.choices([5, 4, 3], weights=[0.70, 0.22, 0.08], k=1)[0]
            elif resolution_hours and resolution_hours <= 24:
                csat_score = random.choices([5, 4, 3, 2], weights=[0.40, 0.35, 0.15, 0.10], k=1)[0]
            else:
                csat_score = random.choices([4, 3, 2, 1], weights=[0.10, 0.25, 0.35, 0.30], k=1)[0]

        records.append(
            {
                "ticket_id": str(uuid.uuid4()),
                "customer_id": f"CUST-{random.randint(10000, 99999)}",
                "created_at": created_at.isoformat(),
                "resolved_at": resolved_at.isoformat() if resolved_at else None,
                "status": status,
                "channel": random.choices(SUPPORT_CHANNELS, weights=SUPPORT_CHANNEL_WEIGHTS, k=1)[0],
                "reason": random.choice(SUPPORT_CONTACT_REASONS),
                "csat_score": csat_score,
                "brand": random.choices(HNB_BRANDS, weights=HNB_BRAND_WEIGHTS, k=1)[0],
            }
        )
    return records


def lambda_handler(event: dict[str, Any] | None = None, context: Any = None) -> dict[str, Any]:
    """AWS Lambda entrypoint for `cx_customer_support`."""
    return execute_ingestion_pipeline(
        domain="cx",
        dataset="customer_support",
        generator_fn=generate_support_tickets,
        min_records=250,
        max_records=800,
        event=event,
    )


if __name__ == "__main__":
    os.environ.setdefault("DRY_RUN", "true")
    print(lambda_handler({"num_records": 10}))
