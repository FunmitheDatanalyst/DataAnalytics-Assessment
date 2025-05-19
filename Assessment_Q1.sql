Query to identify high-value customers with both savings and investment products
SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    -- Count distinct regular savings plans (using is_regular_savings flag)
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.plan_id END) AS savings_count,
    -- Count distinct investment funds (using is_a_fund flag)
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.plan_id END) AS investment_count,
    -- Calculate total deposits in Naira (convert from kobo by dividing by 100)
    -- Format with comma separators and 2 decimal places
    FORMAT(
        (
            -- Sum of all confirmed savings inflows (in kobo)
            SUM(CASE WHEN p.is_regular_savings = 1 THEN s.confirmed_amount ELSE 0 END) +
            -- Sum of all confirmed investment inflows (in kobo)
            SUM(CASE WHEN p.is_a_fund = 1 THEN s.confirmed_amount ELSE 0 END) -
            -- Subtract any withdrawals (using amount_withdrawn from withdrawals table)
            COALESCE(
                (SELECT SUM(amount_withdrawn) 
                 FROM withdrawals_withdrawal w 
                 WHERE w.owner_id = u.id AND w.transaction_status_id = 2), -- Assuming 2 = successful
                0
            )
        ) / 100, -- Convert from kobo to Naira
        2
    ) AS total_balance_naira
FROM 
    users_customuser u
-- Join with savings accounts to get product relationships
JOIN 
    savings_savingsaccount s ON u.id = s.owner_id
-- Join with plans to get product type information
JOIN 
    plans_plan p ON s.plan_id = p.id
-- Filter for accounts with confirmed deposits
WHERE 
    s.confirmed_amount > 0
GROUP BY 
    u.id, u.first_name, u.last_name
-- Filter for customers who have BOTH product types
HAVING 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.plan_id END) > 0 AND
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.plan_id END) > 0
-- Order by savings_count (DESC), then investment_count (DESC), then total balance (DESC)
ORDER BY 
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN s.plan_id END) DESC,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN s.plan_id END) DESC,
    (
        SUM(CASE WHEN p.is_regular_savings = 1 THEN s.confirmed_amount ELSE 0 END) +
        SUM(CASE WHEN p.is_a_fund = 1 THEN s.confirmed_amount ELSE 0 END) -
        COALESCE(
            (SELECT SUM(amount_withdrawn) 
             FROM withdrawals_withdrawal w 
             WHERE w.owner_id = u.id AND w.transaction_status_id = 2),
            0
        )
    ) DESC;