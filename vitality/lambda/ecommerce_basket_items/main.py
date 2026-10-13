"""AWS Lambda generator for simulated E-Commerce shopping basket line items."""

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
from shared.config.ecommerce import LEAF_CATEGORY_IDS, PRODUCT_CATEGORY_PRICE_RANGES
from shared.handler_logic import execute_ingestion_pipeline


def generate_basket_items(num_records: int = 2000) -> list[dict[str, Any]]:
    """Generate realistic e-commerce basket line items across Vitality Health & Wellness categories."""
    records: list[dict[str, Any]] = []
    now_iso = datetime.now(timezone.utc).isoformat()

    for _ in range(num_records):
        category_id = random.choice(LEAF_CATEGORY_IDS)
        min_price, max_price = PRODUCT_CATEGORY_PRICE_RANGES[category_id]
        quantity = random.choices([1, 2, 3, 4], weights=[0.55, 0.28, 0.12, 0.05], k=1)[0]
        unit_price = round(random.uniform(min_price, max_price), 2)

        records.append(
            {
                "basket_item_id": str(uuid.uuid4()),
                "basket_id": f"BSK-{random.randint(100000, 199999)}",
                "product_id": f"SKU-VIT-{category_id}-{random.randint(100, 999)}",
                "category_id": category_id,
                "quantity": quantity,
                "unit_price": unit_price,
                "total_price": round(quantity * unit_price, 2),
                "added_at": now_iso,
                "brand": random.choices(VITALITY_BRANDS, weights=VITALITY_BRAND_WEIGHTS, k=1)[0],
            }
        )
    return records


def lambda_handler(event: dict[str, Any] | None = None, context: Any = None) -> dict[str, Any]:
    """AWS Lambda entrypoint for `ecommerce_basket_items`."""
    return execute_ingestion_pipeline(
        domain="ecommerce",
        dataset="basket_items",
        generator_fn=generate_basket_items,
        min_records=2000,
        max_records=7500,
        event=event,
    )


if __name__ == "__main__":
    os.environ.setdefault("DRY_RUN", "true")
    print(lambda_handler({"num_records": 10}))
