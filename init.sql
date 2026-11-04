CREATE TABLE IF NOT EXISTS loan_applications (
    id INTEGER PRIMARY KEY,
    borrower_id INTEGER NOT NULL,
    amount_usd INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    monthly_income_usd NUMERIC NOT NULL,
    previous_loans INTEGER NOT NULL,
    late_payments INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    default_probability NUMERIC NOT NULL,
    risk_band VARCHAR(20) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
