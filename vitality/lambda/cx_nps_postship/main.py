"""AWS Lambda generator for simulated SMG Post-Ship Net Promoter Score (NPS) surveys."""

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
from shared.config.marketing import (
    POSTSHIP_COMMENTS_BY_BAND,
    SURVEY_PLATFORM_WEIGHTS,
    SURVEY_PLATFORMS,
)
from shared.handler_logic import execute_ingestion_pipeline


def generate_postship_nps(num_records: int = 500) -> list[dict[str, Any]]:
    """Generate realistic post-delivery NPS survey responses across Vitality Retail Group brands."""
    records: list[dict[str, Any]] = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for _ in range(num_records):
        band = random.choices(["Promoter", "Passive", "Detractor"], weights=[0.62, 0.23, 0.15], k=1)[0]
        if band == "Promoter":
            score = random.randint(9, 10)
        elif band == "Passive":
            score = random.randint(7, 8)
        else:
            score = random.randint(0, 6)

        records.append(
            {
                "survey_id": str(uuid.uuid4()),
                "customer_id": f"CUST-{random.randint(10000, 99999)}",
                "order_id": f"ORD-{random.randint(100000, 999999)}",
                "response_date": now_iso,
                "nps_score": score,
                "comment": random.choice(POSTSHIP_COMMENTS_BY_BAND[band]),
                "platform": random.choices(SURVEY_PLATFORMS, weights=SURVEY_PLATFORM_WEIGHTS, k=1)[0],
                "brand": random.choices(VITALITY_BRANDS, weights=VITALITY_BRAND_WEIGHTS, k=1)[0],
            }
        )
    return records


def lambda_handler(event: dict[str, Any] | None = None, context: Any = None) -> dict[str, Any]:
    """AWS Lambda entrypoint for `cx_nps_postship`."""
    return execute_ingestion_pipeline(
        domain="cx",
        dataset="nps_postship",
        generator_fn=generate_postship_nps,
        min_records=500,
        max_records=2000,
        event=event,
    )


if __name__ == "__main__":
    os.environ.setdefault("DRY_RUN", "true")
    print(lambda_handler({"num_records": 10}))
