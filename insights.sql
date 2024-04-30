

-- Query 1: the distribution of registrations across different fiscal years

SELECT 
    fiscal_year, 
    FORMAT(SUM(registrations), 0) AS total_registrations
FROM 
    Result
GROUP BY 
    fiscal_year
ORDER BY 
    fiscal_year DESC;

-- Query 2: the distribution of registrations, and the approved percentage, across different industries

SELECT 
    i.industry_description, 
    FORMAT(SUM(r.registrations), 0) AS total_registrations,
    CONCAT(ROUND(SUM(CASE WHEN r.approval_status = 1 THEN r.registrations ELSE 0 END) / SUM(r.registrations) * 100, 2), '%') AS approval_rate
FROM 
    Result AS r
LEFT JOIN 
    Employer AS e
ON 
    r.employer_id = e.employer_id
LEFT JOIN 
    IndustryCode AS i
ON 
    e.employer_industry_code = i.industry_code
GROUP BY 
    i.industry_description
ORDER BY 
    SUM(r.registrations) DESC;

-- Query 3: the cities and states had the highest number of petitioners participating in the lottery

SELECT 
    r.fiscal_year, e.employer_state, 
    FORMAT(COUNT(DISTINCT e.employer_name) - 1, 0) AS total_petitioners, 
    FORMAT(SUM(r.registrations), 0) AS total_registrations
FROM 
    Result AS r
LEFT JOIN 
    Employer AS e
ON 
    r.employer_id = e.employer_id
GROUP BY 
    r.fiscal_year, e.employer_state
ORDER BY 
    e.employer_state, r.fiscal_year DESC;

-- Query 4: the distribution of initial round selections vs. continuing rounds for approvals arocross different fiscal years

WITH approval_status AS (
    SELECT 
        fiscal_year, 
        FORMAT(SUM(CASE WHEN initial_round = 1 THEN registrations ELSE 0 END), 0) AS initial_approvals, 
        FORMAT(SUM(CASE WHEN initial_round = 0 THEN registrations ELSE 0 END), 0) AS continuing_approvals,
        FORMAT(SUM(registrations), 0) AS total_approvals
    FROM 
        Result
    WHERE 
        approval_status = 1
    GROUP BY 
        fiscal_year
),
total_registrations AS (
    SELECT
        fiscal_year,
        FORMAT(SUM(CASE WHEN initial_round = 1 THEN registrations ELSE 0 END), 0) AS initial_registrations,
        FORMAT(SUM(CASE WHEN initial_round = 0 THEN registrations ELSE 0 END), 0) AS continuing_registrations,
        FORMAT(SUM(registrations), 0) AS total_registrations
    FROM
        Result
    GROUP BY
        fiscal_year
)
SELECT 
    a.fiscal_year, 
    a.initial_approvals, 
    CONCAT(ROUND(a.initial_approvals / t.initial_registrations * 100, 2), '%') AS initial_approval_ratio, 
    a.continuing_approvals, 
    CONCAT(ROUND(a.continuing_approvals / t.continuing_registrations * 100, 2), '%') AS continuing_approval_ratio, 
    a.total_approvals, 
    CONCAT(ROUND(a.total_approvals / t.total_registrations * 100, 2), '%') AS total_approval_ratio
FROM 
    approval_status AS a
JOIN 
    total_registrations AS t
ON 
    a.fiscal_year = t.fiscal_year
ORDER BY 
    a.fiscal_year DESC;

-- Query 5: the top 10 employers with the highest number of registrations in each fiscal year

WITH RankedEmployers AS (
    SELECT 
        r.fiscal_year,
        e.employer_name,
        FROMAT(r.registrations ,0),
        ROW_NUMBER() OVER (PARTITION BY r.fiscal_year ORDER BY r.registrations DESC) AS `rank`
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
)
SELECT 
    fiscal_year,
    employer_name,
    registrations
FROM 
    RankedEmployers
WHERE 
    `rank` <= 10;

-- Query 6: the top 5 cities with the highest number of registrations, and calculate the percentage of registrations approved in each city

WITH CityRegistrations AS (
    SELECT 
        e.employer_city,
        FORMAT(SUM(r.registrations) ,0) AS total_registrations,
        FORMAT(SUM(CASE WHEN r.approval_status = 1 THEN r.registrations ELSE 0 END) ,0) AS total_approvals
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
    GROUP BY 
        e.employer_city
)
SELECT 
    employer_city,
    total_registrations,
    total_approvals,
    CONCAT(ROUND(total_approvals / total_registrations * 100, 2), '%') AS approval_rate
FROM
    CityRegistrations
ORDER BY
    total_registrations DESC
LIMIT 5;

-- Query 7: the top 10 employers with the highest registrations, and more than 5 years of participation in the lottery

WITH EmployerParticipation AS (
    SELECT 
        e.employer_name,
        COUNT(DISTINCT r.fiscal_year) AS years_participated,
        SUM(r.registrations) AS total_registrations
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
    GROUP BY 
        e.employer_name
    HAVING 
        years_participated > 5
)
SELECT 
    employer_name,
    years_participated,
    total_registrations
FROM
    EmployerParticipation
ORDER BY
    total_registrations DESC
LIMIT 10;

-- Query 8: the top 10 zip codes with the highest number of registrations, and the approval rate for each zip code

WITH ZipCodeRegistrations AS (
    SELECT 
        e.employer_zip_code,
        FORMAT(SUM(r.registrations), 0) AS total_registrations,
        FORMAT(SUM(CASE WHEN r.approval_status = 1 THEN r.registrations ELSE 0 END), 0) AS total_approvals
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
    GROUP BY 
        e.employer_zip_code
)
SELECT 
    employer_zip_code,
    total_registrations,
    total_approvals,
    CONCAT(ROUND(total_approvals / total_registrations * 100, 2), '%') AS approval_rate
FROM
    ZipCodeRegistrations
ORDER BY
    total_registrations DESC
LIMIT 10;

-- Query 9: the percentage of initial round selections that were approved by petitioner state

WITH InitialRoundApprovals AS (
    SELECT 
        e.employer_state,
        FORMAT(SUM(CASE WHEN r.approval_status = 1 AND r.initial_round = 1 THEN r.registrations ELSE 0 END) ,0) AS initial_approvals,
        FORMAT(SUM(CASE WHEN r.initial_round = 1 THEN r.registrations ELSE 0 END) ,0) AS initial_registrations
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
    GROUP BY 
        e.employer_state
)
SELECT 
    employer_state,
    initial_approvals,
    initial_registrations,
    CONCAT(ROUND(initial_approvals / initial_registrations * 100, 2), '%') AS approval_rate
FROM
    InitialRoundApprovals
ORDER BY
    approval_rate DESC;

-- Query 10: the percentage of continuing round selections that were approved by industry

WITH ContinuingRoundApprovals AS (
    SELECT 
        i.industry_description,
        FORMAT(SUM(CASE WHEN r.approval_status = 1 AND r.initial_round = 0 THEN r.registrations ELSE 0 END) ,0) AS continuing_approvals,
        FORMAT(SUM(CASE WHEN r.initial_round = 0 THEN r.registrations ELSE 0 END) ,0) AS continuing_registrations
    FROM 
        Result AS r
        LEFT JOIN Employer AS e
        ON r.employer_id = e.employer_id
        LEFT JOIN IndustryCode AS i
        ON e.employer_industry_code = i.industry_code
    GROUP BY 
        i.industry_description
)
SELECT 
    industry_description,
    continuing_approvals,
    continuing_registrations,
    CONCAT(ROUND(continuing_approvals / continuing_registrations * 100, 2), '%') AS approval_rate
FROM
    ContinuingRoundApprovals
ORDER BY
    approval_rate DESC;