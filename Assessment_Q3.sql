-- Account Inactivity Alert
WITH last_transactions AS (
    -- Get the most recent transaction date for each plan
    SELECT 
        s.plan_id,
        s.owner_id,
        MAX(s.transaction_date) AS last_transaction_date,
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE 'Other'
        END AS account_type
    FROM 
        savings_savingsaccount s
    JOIN 
        plans_plan p ON s.plan_id = p.id
    WHERE 
        s.confirmed_amount > 0  -- Only consider funded transactions
    GROUP BY 
        s.plan_id, s.owner_id, p.is_regular_savings, p.is_a_fund
)

-- Select accounts with no transactions in the last 365 days
SELECT 
    lt.plan_id,
    lt.owner_id,
    lt.account_type AS type,
    lt.last_transaction_date,
    DATEDIFF(CURRENT_DATE, lt.last_transaction_date) AS inactivity_days
FROM 
    last_transactions lt
WHERE 
    -- No transactions in the last 365 days
    lt.last_transaction_date < DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY)
    -- Only include active accounts (not deleted/archived)
    AND EXISTS (
        SELECT 1 FROM plans_plan p 
        WHERE p.id = lt.plan_id 
        AND p.is_deleted = 0 
        AND p.is_archived = 0
    )
ORDER BY 
    inactivity_days DESC;