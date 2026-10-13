"""Build deterministic AWS Lambda deployment ZIP artifacts bundling function handlers + `shared/`."""

from __future__ import annotations

from pathlib import Path
import zipfile

LAMBDA_FUNCTIONS: list[str] = [
    "cx_customer_support",
    "cx_nps_postship",
    "cx_nps_visitview",
    "ecommerce_basket_items",
    "ecommerce_basket_payments",
]


def build_lambda_archives(vitality_root: Path | None = None) -> list[Path]:
    """Package each Lambda function directory and the `shared/` library into `vitality/dist/<fn>.zip`."""
    base_dir = vitality_root or Path(__file__).resolve().parents[1]
    lambda_root = base_dir / "lambda"
    shared_dir = lambda_root / "shared"
    dist_dir = base_dir / "dist"
    dist_dir.mkdir(parents=True, exist_ok=True)

    built_archives: list[Path] = []

    for fn_name in LAMBDA_FUNCTIONS:
        fn_dir = lambda_root / fn_name
        main_py = fn_dir / "main.py"
        if not main_py.exists():
            raise FileNotFoundError(f"Missing Lambda entrypoint: {main_py}")

        zip_path = dist_dir / f"{fn_name}.zip"
        with zipfile.ZipFile(zip_path, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
            # 1. Add main.py at the root of the archive
            zf.write(main_py, arcname="main.py")

            # 2. Bundle all Python modules from `lambda/shared/`
            for py_file in sorted(shared_dir.rglob("*.py")):
                rel_path = py_file.relative_to(lambda_root)
                zf.write(py_file, arcname=str(rel_path).replace("\\", "/"))

        built_archives.append(zip_path)
        print(f"[build_zips] Packaged {zip_path.name} ({zip_path.stat().st_size:,} bytes)")

    return built_archives


if __name__ == "__main__":
    build_lambda_archives()
