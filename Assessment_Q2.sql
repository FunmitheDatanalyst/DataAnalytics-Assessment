-- Calculate the average number of transactions per customer per month and categorize them
WITH monthly_transactions AS (
    -- Count transactions per customer per month
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS month,
        COUNT(*) AS transaction_count
    FROM 
        users_customuser u
    JOIN 
        savings_savingsaccount s ON u.id = s.owner_id
    WHERE 
        s.transaction_status = 'success'  -- Only count successful transactions
    GROUP BY 
        u.id, u.first_name, u.last_name, DATE_FORMAT(s.transaction_date, '%Y-%m')
),

customer_avg_transactions AS (
    -- Calculate average transactions per month for each customer
    SELECT 
        customer_id,
        customer_name,
        AVG(transaction_count) AS avg_transactions_per_month,
        -- Categorize based on average transactions
        CASE 
            WHEN AVG(transaction_count) >= 10 THEN 'High Frequency'
            WHEN AVG(transaction_count) BETWEEN 3 AND 9 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM 
        monthly_transactions
    GROUP BY 
        customer_id, customer_name
)

-- Final aggregation by frequency category
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM 
    customer_avg_transactions
GROUP BY 
    frequency_category
ORDER BY 
    CASE 
        WHEN frequency_category = 'High Frequency' THEN 1
        WHEN frequency_category = 'Medium Frequency' THEN 2
        ELSE 3
    END;
    