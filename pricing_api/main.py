
import hmac
import os
import shutil
import subprocess
from pathlib import Path
from typing import Annotated
from datetime import date

import psycopg
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Header, HTTPException, Query
from psycopg.rows import dict_row


BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

DBT_PROJECT_DIR = Path(os.environ["DBT_PROJECT_DIR"])

app = FastAPI(
    title="Product Pricing API",
    description=(
        "API untuk membaca data produk, harga, dan rekomendasi "
        "dari gold layer PostgreSQL."
    ),
    version="1.0.0",
)


def get_connection():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5444")),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        row_factory=dict_row,
        connect_timeout=10,
    )


def get_role(
    x_api_key: Annotated[str | None, Header()] = None,
) -> str:
    analyst_key = os.environ["ANALYST_API_KEY"]
    admin_key = os.environ["ADMIN_API_KEY"]

    if not x_api_key:
        raise HTTPException(
            status_code=401,
            detail="API key wajib diisi pada header X-API-Key.",
        )

    if hmac.compare_digest(x_api_key, admin_key):
        return "admin"

    if hmac.compare_digest(x_api_key, analyst_key):
        return "analyst"

    raise HTTPException(
        status_code=401,
        detail="API key tidak valid.",
    )


def require_analyst(role: Annotated[str, Depends(get_role)]) -> str:
    if role not in ("analyst", "admin"):
        raise HTTPException(status_code=403, detail="Akses ditolak.")
    return role


def require_admin(role: Annotated[str, Depends(get_role)]) -> str:
    if role != "admin":
        raise HTTPException(
            status_code=403,
            detail="Endpoint ini hanya untuk admin.",
        )
    return role


def fetch_page(
    count_sql: str,
    data_sql: str,
    params: list,
    page: int,
    page_size: int,
):
    offset = (page - 1) * page_size

    with get_connection() as conn:
        total = conn.execute(count_sql, params).fetchone()["total"]

        rows = conn.execute(
            data_sql,
            [*params, page_size, offset],
        ).fetchall()

    return {
        "page": page,
        "page_size": page_size,
        "total": total,
        "total_pages": (total + page_size - 1) // page_size,
        "data": rows,
    }


@app.get("/")
def home():
    return {
        "message": "Product Pricing API is running",
        "docs": "/docs",
    }


@app.get("/products")
def get_products(
    role: Annotated[str, Depends(require_analyst)],
    search: Annotated[str | None, Query(max_length=100)] = None,
    category: Annotated[str | None, Query(max_length=100)] = None,
    brand: Annotated[str | None, Query(max_length=100)] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    conditions = []
    params = []

    if search:
        conditions.append("product_name ILIKE %s")
        params.append(f"%{search}%")

    if category:
        conditions.append("category = %s")
        params.append(category)

    if brand:
        conditions.append("brand = %s")
        params.append(brand)

    where_sql = (
        "WHERE " + " AND ".join(conditions)
        if conditions
        else ""
    )

    base_sql = f"""
        FROM gold.dim_product_master
        {where_sql}
    """

    return fetch_page(
        "SELECT COUNT(*) AS total " + base_sql,
        """
        SELECT
            product_key,
            canonical_product_id,
            product_name,
            category,
            brand,
            pack_size
        """ + base_sql + """
        ORDER BY product_name
        LIMIT %s OFFSET %s
        """,
        params,
        page,
        page_size,
    )


@app.get("/prices")
def get_prices(
    role: Annotated[str, Depends(require_analyst)],
    product_key: Annotated[str | None, Query(max_length=100)] = None,
    platform: Annotated[str | None, Query(max_length=100)] = None,
    date_from: date | None = None,
    date_to: date | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    conditions = []
    params = []

    if product_key:
        conditions.append("f.product_key = %s")
        params.append(product_key)

    if platform:
        conditions.append("pl.platform_name = %s")
        params.append(platform)

    if date_from:
        conditions.append("d.full_date >= %s")
        params.append(date_from)

    if date_to:
        conditions.append("d.full_date <= %s")
        params.append(date_to)

    where_sql = (
        "WHERE " + " AND ".join(conditions)
        if conditions
        else ""
    )

    base_sql = f"""
        FROM gold.fct_product_price_daily f
        JOIN gold.dim_product_master pm
            ON pm.product_key = f.product_key
        JOIN gold.dim_platform pl
            ON pl.platform_key = f.platform_key
        JOIN gold.dim_date d
            ON d.date_key = f.date_key
        {where_sql}
    """

    return fetch_page(
        "SELECT COUNT(*) AS total " + base_sql,
        """
        SELECT
            f.product_key,
            pm.product_name,
            pl.platform_name,
            d.full_date AS price_date,
            f.price_amount,
            f.original_price_amount,
            f.last_observed_at,
            f.store_name,
            f.source_url
        """ + base_sql + """
        ORDER BY d.full_date DESC, pm.product_name
        LIMIT %s OFFSET %s
        """,
        params,
        page,
        page_size,
    )


@app.get("/recommendations")
def get_recommendations(
    role: Annotated[str, Depends(require_analyst)],
    product_key: Annotated[str | None, Query(max_length=100)] = None,
    date_from: date | None = None,
    date_to: date | None = None,
    page: Annotated[int, Query(ge=1)] = 1,
    page_size: Annotated[int, Query(ge=1, le=100)] = 20,
):
    conditions = []
    params = []

    if product_key:
        conditions.append("r.product_key = %s")
        params.append(product_key)

    if date_from:
        conditions.append("r.recommendation_date >= %s")
        params.append(date_from)

    if date_to:
        conditions.append("r.recommendation_date <= %s")
        params.append(date_to)

    where_sql = (
        "WHERE " + " AND ".join(conditions)
        if conditions
        else ""
    )

    base_sql = f"""
        FROM gold."2_fct_price_recommendation" r
        JOIN gold.dim_product_master pm
            ON pm.product_key = r.product_key
        JOIN gold.dim_platform pl
            ON pl.platform_key = r.platform_key
        {where_sql}
    """

    return fetch_page(
        "SELECT COUNT(*) AS total " + base_sql,
        """
        SELECT
            r.recommendation_key,
            r.product_key,
            pm.product_name,
            pl.platform_name,
            r.recommendation_date,
            r.competitor_median_price,
            r.lowest_observed_price,
            r.recommended_price,
            r.recommendation_rule,
            r.model_version,
            r.run_timestamp
        """ + base_sql + """
        ORDER BY r.recommendation_date DESC, pm.product_name
        LIMIT %s OFFSET %s
        """,
        params,
        page,
        page_size,
    )


@app.post("/admin/recommendations/run")
def run_recommendations(
    role: Annotated[str, Depends(require_admin)],
):
    dbt_executable = shutil.which("dbt")

    if not dbt_executable:
        raise HTTPException(
            status_code=500,
            detail="dbt tidak ditemukan. Jalankan API dari venv yang berisi dbt.",
        )

    if not (DBT_PROJECT_DIR / "dbt_project.yml").is_file():
        raise HTTPException(
            status_code=500,
            detail="DBT_PROJECT_DIR tidak menunjuk ke project dbt yang valid.",
        )

    try:
        result = subprocess.run(
            [
                dbt_executable,
                "run",
                "--select",
                "2_fct_price_recommendation",
            ],
            cwd=str(DBT_PROJECT_DIR),
            capture_output=True,
            text=True,
            timeout=600,
            check=False,
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=504,
            detail="Eksekusi dbt melewati batas waktu 600 detik.",
        )

    if result.returncode != 0:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Eksekusi dbt gagal.",
                "stderr": result.stderr[-4000:],
                "stdout": result.stdout[-4000:],
            },
        )

    return {
        "status": "success",
        "message": "Pricing recommendation berhasil dijalankan.",
        "model": "2_fct_price_recommendation",
        "stdout": result.stdout[-4000:],
    }
