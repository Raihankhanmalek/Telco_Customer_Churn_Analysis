select * from capstone;

-- Total Customers
select count(*) as total_customers from capstone;

-- Total churned customers
select count(*) as churned_customers
from capstone
where churn = 'yes';

-- Churn Rate
select round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate_percentage
from capstone;

-- churn by gender
select gender,
		count(*) as Total_customers,
        sum(case when churn = 'yes' then 1 else 0 end) as churned_customers,
        round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by gender;

-- churn by senior citizen
select (case when seniorcitizen = 1 then 'Yes' else 'No' end) as seniorcitizen,
		count(*) as total_customers,
        sum(case when churn = 'Yes' then 1 else 0 end) as churned_customers,
        round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by seniorcitizen;
        
-- churn by partner & dependents
select partner, dependents,
		count(*) as total_customers,
        sum(case when churn = 'yes' then 1 else 0 end) as churned_customers,
        round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by partner, dependents
order by churn_rate desc;

-- churn by contract type
select contract,
		count(*) as total_customers,
        sum(case when churn = 'yes' then 1 else 0 end) as churned_customers,
        round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by contract;

-- churn by internet service
SELECT InternetService,
       COUNT(*) AS total_customers,
       SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
       ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate
FROM capstone
GROUP BY InternetService
ORDER BY churn_rate DESC;

-- Average charges & Tenure by churn
select churn,
		round(avg(monthlycharges), 2) as avg_monthly_charges,
        round(avg(totalcharges), 2) as avg_total_charges,
        round(avg(tenure), 2) as avg_tenure
from capstone
group by churn
order by churn desc;

-- churn by tenure groups
select
	case
		when tenure between 0 and 12 then '0-12 months'
        when tenure between 13 and 24 then '13-24 months'
        when tenure between 25 and 48 then '25-48 months'
        else '49+ months'
	end as tenure_group,
    count(*) as total_customers,
    sum(case when churn = 'Yes' then 1  else 0 end) as churned_customers,
    round(100.0 * sum(case when churn ='yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by tenure_group
order by churn_rate desc;

-- High-Risk segment (Combination of factors)
select contract, InternetService, PaymentMethod,
		count(*) as total_customers,
        sum(case when churn = 'Yes' then 1 else 0 end) as churned_customers,
        round(100.0 * sum(case when churn = 'yes' then 1 else 0 end) / count(*), 2) as churn_rate
from capstone
group by contract, internetservice, paymentmethod
order by churn_rate desc;

-- Trusted Customers
select
	count(customerid) as TotalTrustedCustomers
from capstone
where tenure > (
	select avg(tenure) from capstone
    );

-- PhoneService
select
	PhoneService,
    count(customerID) as TotalCustomers,
    sum(case when churn = 'Yes' then 1 else 0 end) as ChurnedCustomers,
    concat(
		round(
			(sum(case when churn='yes' then 1 else 0 end)*100) / count(customerid), 2),
            '%'
			)as ChurnRate
from capstone
group by PhoneService
order by PhoneService desc;

-- Contract and Churn
select
	Contract,
    count(customerID) as TotalCustomers,
    sum(case when churn = 'Yes' then 1 else 0 end) as ChurnedCustomers,
    concat(
		round(
			(sum(case when churn='yes' then 1 else 0 end)*100) / count(customerid), 2),
            '%'
			)as ChurnRate
from capstone
group by contract;

-- Avg Monthly Charges of Contract
select
	Contract,
    round(avg(monthlycharges), 2) as AvgMonthlyCharge
from capstone
group by contract;

-- Contract More than Avg Monthly Charges
select
	Contract,
    count(CustomerID)
from capstone
where MonthlyCharges > (
		select avg(MonthlyCharges) from capstone
        )
group by contract;

-- Total Churned customers with contract which have monthly charges more than Avg Monthly Charges
select
    Contract,
    count(customerid) as TotalCustomers,
    sum(case when churn = 'Yes' and MonthlyCharges > (select avg(MonthlyCharges) from capstone) then 1 else 0 end) as ChurnedCustomers,
    concat(
        round(
            (sum(case when churn = 'Yes' and MonthlyCharges > (select avg(MonthlyCharges) from capstone) then 1 else 0 end) * 100.0) / count(customerid),
            2
        ),
        '%'
    ) as ChurnRate
from capstone
group by Contract;

-- Adding Extra charge field in table
set sql_safe_updates = 0;

ALTER TABLE capstone
ADD COLUMN ExtraCharges DECIMAL(10,2);

UPDATE capstone
SET ExtraCharges = totalcharges - (tenure * monthlycharges);
select extracharges from capstone;

set sql_safe_updates = 0;

SELECT 
    CASE 
        WHEN ExtraCharges < 0 THEN 'Negative'
        WHEN ExtraCharges = 0 THEN 'Zero'
        ELSE 'Positive'
    END AS ExtraChargeType,
    COUNT(*) AS CustomerCount
FROM capstone
GROUP BY ExtraChargeType;

-- Modifying ExtraCharge column
ALTER TABLE capstone
MODIFY COLUMN ExtraCharges VARCHAR(20);

UPDATE capstone
SET ExtraCharges = CASE
    WHEN (totalcharges - (tenure * monthlycharges)) < 0 THEN 'Discount'
    WHEN (totalcharges - (tenure * monthlycharges)) = 0 THEN 'Zero'
    ELSE 'Penalty'
END;

-- Zero (614) → These customers’ TotalCharges match exactly Tenure × MonthlyCharges → clean, consistent records.

-- Negative (3,214) → TotalCharges is less than expected → means discounts, free/partial months, or data entry issues (very common in churn datasets like Telco Customer Churn).

-- Positive (3,204) → TotalCharges is more than expected → means extra fees, add-ons, one-time charges, or late payment penalties.

-- So, roughly half of customers show extra costs (positive) and the other half show discounts or undercharges (negative).



-- churn analysis of customers by extra charge
SELECT 
    ExtraCharges AS ExtraChargeType,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS ChurnedCustomers,
    CONCAT(
        ROUND(
            (SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*),
            2
        ),
        '%'
    ) AS ChurnRate
FROM capstone
GROUP BY ExtraCharges;
