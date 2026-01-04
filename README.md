# Blue Mart Promotions: Measuring Sales Lift (STATA)

This project measures how supermarket promotions affect daily sales volume for **Blue Mart (UAE)**, and checks whether sales drop (or rise) right before/after a promotion ends.

We take transaction-level sales data, aggregate it to the **day level**, and estimate log-linear OLS models with seasonality controls.

## Key findings (high level)
- Promotions are associated with a **large increase in daily units sold** during the promo period.
- No statistically meaningful **pre-promotion** or **post-promotion** dip is detected in the short window tested (±5 days).

## Data
Input data is a CSV with transaction-level records (one row per sale line). Typical fields include:
- `date`, `store_id`, `sku_id`, `customer_id`
- `quantity`, `unit_price`, `total_value`
- `channel`, `discount_pct`
- (optionally) promotion identifiers and dates

> Note: If your dataset is proprietary or too large, don’t commit it. Put it in `/data` and add that folder to `.gitignore`.

## Method (what the code actually does)
### 1) Build daily dataset
- Import the raw CSV
- Convert `date` to a Stata daily date
- Create a row-level promo flag: `promo_line = (discount_pct > 0)`
- Collapse to daily totals:
  - `qty_total = sum(quantity)`
  - `promo_active = max(promo_line)` (a day is “promo” if any discounted transaction exists)
- Add seasonality controls:
  - `dow` (day-of-week)
  - `month`

### 2) Model 1: Promotion on/off effect
Log-linear regression:
- `log(qty_total + 1) ~ promo_active + dow + month`

### 3) Model 2: Dynamic promo phases (±5 days)
Create a `phase` variable:
- `baseline`
- `pre` (up to 5 days before promo start)
- `promo`
- `post` (up to 5 days after promo end)

Log-linear regression:
- `log(qty_total + 1) ~ phase + dow + month`

## Repo structure (suggested)
```text
.
├── stata/
│   └── 30420_Project2_code_Group1.do
├── report/
│   └── 30420_Project2_report_Group1.pdf
├── data/                      # not committed (recommended)
├── outputs/                   # generated datasets/results
└── README.md
