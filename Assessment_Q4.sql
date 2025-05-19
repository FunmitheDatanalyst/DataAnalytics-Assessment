-- Customer Lifetime Value (CLV) Estimation
WITH customer_stats AS (
    SELECT
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        -- Calculate tenure in months
        TIMESTAMPDIFF(MONTH, u.date_joined, CURRENT_DATE) AS tenure_months,
        -- Count all transactions
        COUNT(s.id) AS total_transactions,
        -- Calculate average transaction amount (in kobo)
        AVG(s.confirmed_amount) AS avg_transaction_amount_kobo
    FROM
        users_customuser u
    LEFT JOIN
        savings_savingsaccount s ON u.id = s.owner_id
    WHERE
        s.confirmed_amount > 0  -- Only count funded transactions
        AND s.transaction_status = 'success'  -- Only successful transactions
    GROUP BY
        u.id, u.first_name, u.last_name, u.date_joined
)

SELECT
    customer_id,
    name,
    tenure_months,
    total_transactions,
    -- CLV calculation: (transactions/month) * 12 months * (0.1% of avg transaction)
    -- Convert from kobo to Naira by dividing by 100
    FORMAT(
        (total_transactions / NULLIF(tenure_months, 0)) * 12 * 
        (avg_transaction_amount_kobo * 0.001 / 100),
        2
    ) AS estimated_clv
FROM customer_stats
WHERE tenure_months > 0  -- Exclude customers who joined this month
ORDER BY estimated_clv DESC;