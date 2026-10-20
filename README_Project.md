# Product Crawling Analytics with dbt

## 1. Project Overview

This project uses **dbt Core and PostgreSQL** to transform e-commerce product crawling data into analytics-ready datasets.

The project follows a layered data architecture:

- **Raw:** Original crawling data.
- **Silver:** Cleaned, standardized, and matched product data.
- **Gold:** Analytical dimensions, price facts, and price recommendations.

### Objectives

- Clean and standardize product crawling data.
- Match equivalent products across e-commerce platforms.
- Build dimensional models and daily price facts.
- Recommend the platform with the lowest observed price.
- Validate data quality through automated dbt tests.

## 2. Technology Stack

| Component | Technology |
|---|---|
| Transformation framework | dbt Core 1.11.12 |
| Database adapter | dbt-postgres 1.11.0 |
| Database | PostgreSQL |
| dbt package | dbt_utils 1.4.1 |
| Development environment | Python virtual environment |
| Data source | E-commerce product crawling data |

## 3. Data Architecture

```text
E-commerce Crawling Data
          |
          v
         RAW
          |
          v
        SILVER
          |
          +-- stg_product_crawling
          +-- int_product_matching_base
          +-- int_product_matching_fuzzy_candidates
          +-- int_product_matching_resolved
          |
          v
         GOLD
          |
          +-- dim_product_master
          +-- dim_platform
          +-- dim_date
          +-- fct_product_price_daily
          +-- fct_price_recommendation
```

### Raw Layer

Stores the original crawling data as the source for downstream transformations. Business logic and analytical calculations are applied in subsequent layers.

### Silver Layer

Prepares data for analytics through cleaning, normalization, and product matching.

| Model | Purpose |
|---|---|
| `stg_product_crawling` | Stages and standardizes source data |
| `int_product_matching_base` | Normalizes product names and prepares matching keys |
| `int_product_matching_fuzzy_candidates` | Identifies potentially similar product names |
| `int_product_matching_resolved` | Combines explicit mappings and rule-based matching |

### Gold Layer

Provides analytical models for product and price analysis.

| Model | Purpose |
|---|---|
| `dim_product_master` | Canonical product dimension |
| `dim_platform` | E-commerce platform dimension |
| `dim_date` | Date dimension |
| `fct_product_price_daily` | Daily product prices by platform |
| `fct_price_recommendation` | Lowest observed price recommendation |

Legacy models ending in `_crawling` are retained for learning and comparison.

## 4. Product Matching Strategy

Products can have different names across platforms even when they refer to the same item. This project uses three matching approaches.

### 4.1 Seed-based mapping

The `seeds/product_matching.csv` file defines explicit mappings between source product names and canonical product identities.

Expected columns:

| Column | Description |
|---|---|
| `platform` | Source e-commerce platform |
| `source_product_name` | Product name on the source platform |
| `canonical_product_id` | Shared identity for the same product |
| `canonical_product_name` | Standardized product name |

Example:

```csv
platform,source_product_name,canonical_product_id,canonical_product_name
shopee,sunlight jeruk nipis 755ml,sunlight_jeruk_nipis_755ml,Sunlight Jeruk Nipis 755 ml
tokopedia,sunlight dishwashing liquid 755 ml,sunlight_jeruk_nipis_755ml,Sunlight Jeruk Nipis 755 ml
```

The example is illustrative. Replace it with verified mappings from the actual source data.

### 4.2 Rule-based matching

Product names are converted to lowercase, punctuation is normalized, and whitespace is standardized.

The current matching methods are:

- `mapping_seed`: matched through an explicit seed mapping.
- `exact_normalized`: normalized product names match across multiple platforms.
- `single_platform`: the normalized key appears on only one platform.
- `unmatched`: no valid matching key is available.

**Important:** Identical normalized names do not guarantee identical products. Size, flavor, package quantity, and product variants must also be checked.

### 4.3 Fuzzy matching

The `int_product_matching_fuzzy_candidates` model identifies potentially similar names using PostgreSQL's `pg_trgm` extension.

Enable the extension if it is not already available:

```sql
create extension if not exists pg_trgm;
```

Fuzzy matching produces candidates for manual review. It does not automatically merge products into the resolved mapping.

Verified matches can subsequently be added to the seed file.

## 5. Gold Data Models

### `dim_product_master`

Contains the canonical product dimension.

Key columns:

- `product_key`
- `canonical_product_id`
- `product_name`
- `category`
- `brand`
- `pack_size`
- `normalized_product_name`

The product key is derived from the canonical product identity, allowing matched source products to share the same dimension key.

The current brand extraction uses the first word of the product name as a simple heuristic. This may need improvement for multiword brand names.

### `dim_platform`

Contains platform identifiers and names used to connect price facts to e-commerce platforms.

### `dim_date`

Provides date keys and calendar attributes for analytical queries.

### `fct_product_price_daily`

Stores daily product price observations by canonical product and platform.

The model selects the latest available observation for each product-platform-date combination. It also parses the source price fields into numeric values.

Price parsing should be reviewed if the source contains decimal separators, currency conversions, or more complex price formats.

### `fct_price_recommendation`

Selects the lowest positive observed price for each product on the latest available date.

When prices are tied, the platform name provides a deterministic tie-breaker.

The recommendation currently considers observed product prices only. It does not include shipping costs, vouchers, service fees, stock availability, or seller reputation.

## 6. Data Quality and Testing

The project uses dbt tests to validate data quality and model relationships.

Current test coverage includes:

- `not_null` checks on required columns.
- `unique` checks on keys.
- `relationships` checks between fact and dimension models.
- Unique combinations of `product_key`, `platform_key`, and `date_key`.
- `assert_one_recommendation_per_product`: checks that each product has no more than one recommendation.
- `assert_recommended_price_is_lowest`: checks that the recommended price equals the lowest eligible observed price on the latest available date.

### Latest Build Results

The latest recorded build completed successfully:

| Metric | Result |
|---|---:|
| Total operations | 39 |
| Passed operations | 39 |
| Data tests passed | 27 |
| Warnings | 0 |
| Errors | 0 |

These results confirm that the configured models and tests ran successfully against the data available at that time. They do not independently prove that every cross-platform product match is correct from a business perspective.

## 7. How to Run the Project

Run the following commands from the project root:

`E:\DataEngineer\DBT\belajar_dbt`

### Step 1: Activate the virtual environment

In PowerShell:

```powershell
.\venv_dbt\Scripts\Activate.ps1
```

Skip this step if the environment is already active.

### Step 2: Validate the dbt configuration

```powershell
dbt debug
```

Verify that the configured PostgreSQL connection is correct. Keep passwords and other credentials out of this README and source control.

### Step 3: Install dependencies

```powershell
dbt deps
```

### Step 4: Load the product mapping seed

Run this when the seed is new or its contents have changed:

```powershell
dbt seed --select product_matching
```

### Step 5: Build the Silver and Gold layers

```powershell
dbt build --select path:models\example/2_silver path:models\example/3_gold
```

This command builds the selected models and runs the applicable tests according to dbt's dependency graph.

### Step 6: Run Gold tests separately

```powershell
dbt test --select path:models\example/3_gold
```

To run the two recommendation tests individually:

```powershell
dbt test --select assert_recommended_price_is_lowest assert_one_recommendation_per_product
```

### Step 7: Query the recommendations

The following example returns the recommended price and platform for each product:

```sql
select
    r.recommendation_date,
    d.product_name,
    p.platform_name,
    r.recommended_price,
    r.recommendation_rule
from gold.fct_price_recommendation r
inner join gold.dim_product_master d
    on r.product_key = d.product_key
inner join gold.dim_platform p
    on r.platform_key = p.platform_key
order by d.product_name;
```

The example assumes the configured target schemas are `gold` and `silver`. If the dbt profile or schema naming configuration changes, adjust the query accordingly.

## 8. Project Structure

The relevant project structure is expected to resemble:

```text
belajar_dbt/
├── dbt_project.yml
├── packages.yml
├── README.md
├── seeds/
│   └── product_matching.csv
├── models/
│   └── example/
│       ├── 1_raw/
│       ├── 2_silver/
│       │   ├── stg_product_crawling.sql
│       │   ├── int_product_matching_base.sql
│       │   ├── int_product_matching_fuzzy_candidates.sql
│       │   └── int_product_matching_resolved.sql
│       └── 3_gold/
│           ├── dim_product_master.sql
│           ├── dim_platform.sql
│           ├── dim_date.sql
│           ├── fct_product_price_daily.sql
│           ├── fct_price_recommendation.sql
│           └── schema.yml
└── tests/
    ├── assert_one_recommendation_per_product.sql
    └── assert_recommended_price_is_lowest.sql
```

This is a logical overview; retain any additional models, configuration files, and legacy models already present in the actual project.

## 9. Known Limitations

1. **Product identity:** Rule-based matching can produce false positives when product names are similar.
2. **Seed maintenance:** New products and changed product names may require additional mappings.
3. **Fuzzy matching:** Similarity thresholds need evaluation against real product pairs.
4. **Brand extraction:** Taking the first word is not sufficient for every brand.
5. **Price parsing:** Currency and decimal formats may require more robust parsing.
6. **Recommendation logic:** Shipping, promotions, inventory, and seller quality are not yet considered.
7. **Source freshness:** Freshness monitoring should be configured according to the ingestion schedule and source requirements.

## 10. Recommended Next Steps

- Review fuzzy matching candidates and add verified mappings to the seed.
- Improve product identity rules for size, flavor, and package quantity.
- Strengthen price parsing and data validation.
- Add source freshness checks where appropriate.
- Incorporate shipping costs and promotions into a more realistic recommendation model.
- Expand model descriptions and documentation for easier maintenance.

---

**Project status:** The latest recorded Silver and Gold build passed all configured operations and tests. Product matching and price recommendation logic should continue to be validated against actual business requirements.
