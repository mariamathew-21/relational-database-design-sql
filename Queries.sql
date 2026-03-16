-----task d.1------------

WITH VaccineData AS (
    SELECT 
        c.Country_Name AS Country_Name,
        vr.Date AS Observation_Date,
        vr.Total_Vaccinations AS Total_Vaccinations
    FROM 
        Vaccination_Record vr
    JOIN 
        Country c ON vr.Country_ID = c.Country_ID
    WHERE 
        vr.Date IN ('2022-02-22', '2021-04-22', '2023-11-11')
),
PivotedData AS (
    SELECT
        Country_Name,
        MAX(CASE WHEN Observation_Date = '2022-02-22' THEN Observation_Date END) AS Date1,
        MAX(CASE WHEN Observation_Date = '2022-02-22' THEN Total_Vaccinations END) AS VOD1,
        MAX(CASE WHEN Observation_Date = '2021-04-22' THEN Observation_Date END) AS Date2,
        MAX(CASE WHEN Observation_Date = '2021-04-22' THEN Total_Vaccinations END) AS VOD2,
        MAX(CASE WHEN Observation_Date = '2023-11-11' THEN Observation_Date END) AS Date3,
        MAX(CASE WHEN Observation_Date = '2023-11-11' THEN Total_Vaccinations END) AS VOD3
    FROM 
        VaccineData
    GROUP BY 
        Country_Name
)
SELECT 
    Date1 AS "Date 1 (OD1)",
    Country_Name AS "Country Name (CN)",
    VOD1 AS "Vaccine on OD1 (VOD1)",
    Date2 AS "Date 2 (OD2)",
    VOD2 AS "Vaccine on OD2 (VOD2)",
    Date3 AS "Date 3 (OD3)",
    VOD3 AS "Vaccine on OD3 (VOD3)",
    CASE 
        WHEN VOD1 > 0 AND VOD2 > 0 AND VOD3 > 0 THEN 
            ((VOD2 - VOD1) * 1.0 / VOD1) - ((VOD3 - VOD2) * 1.0 / VOD2)
        ELSE 
            NULL 
    END AS "Percentage Change of Totals"
FROM 
    PivotedData
ORDER BY 
    Date1, Country_Name;

------task d.2--------------

WITH MonthlyData AS (
    SELECT 
        c.Country_Name,
        strftime('%Y', vr.Date) AS Year,
        strftime('%m', vr.Date) AS Month,
        SUM(vr.Total_Vaccinations) AS Total_Doses
    FROM 
        Vaccination_Record vr
    JOIN 
        Country c ON vr.Country_ID = c.Country_ID
    GROUP BY 
        c.Country_Name, Year, Month
),

GrowthRates AS (
    SELECT 
        Country_Name,
        Year,
        Month,
        Total_Doses,
        LAG(Total_Doses) OVER (PARTITION BY Country_Name ORDER BY Year, Month) AS Previous_Doses,
        CASE 
            WHEN LAG(Total_Doses) OVER (PARTITION BY Country_Name ORDER BY Year, Month) > 0 THEN 
                (Total_Doses - LAG(Total_Doses) OVER (PARTITION BY Country_Name ORDER BY Year, Month)) * 100.0 / LAG(Total_Doses) OVER (PARTITION BY Country_Name ORDER BY Year, Month)
            ELSE 
                NULL
        END AS Growth_Rate
    FROM 
        MonthlyData
),

GlobalAverageGrowth AS (
    SELECT 
        Year,
        Month,
        AVG(Growth_Rate) AS Avg_Growth_Rate
    FROM 
        GrowthRates
    WHERE 
        Growth_Rate IS NOT NULL
    GROUP BY 
        Year, Month
)

SELECT 
    gr.Country_Name,
    gr.Month,
    gr.Year,
    gr.Growth_Rate AS Growth_Rate,
    (gr.Growth_Rate - avg_gr.Avg_Growth_Rate) AS Difference_From_Global_Avg
FROM 
    GrowthRates gr
JOIN 
    GlobalAverageGrowth avg_gr 
ON 
    gr.Year = avg_gr.Year AND gr.Month = avg_gr.Month
WHERE 
    gr.Growth_Rate > avg_gr.Avg_Growth_Rate
ORDER BY 
    gr.Country_Name, gr.Year, gr.Month;

------task d.3-----------

WITH VaccineShare AS (
    SELECT 
        c.Country_Name,
        v.Vaccine_Name AS Vaccine_Type,
        SUM(vr.Total_Vaccinations) AS Vaccine_Total,
        SUM(SUM(vr.Total_Vaccinations)) OVER (PARTITION BY c.Country_Name) AS Country_Total
    FROM 
        Vaccination_Record vr
    JOIN 
        Country c ON vr.Country_ID = c.Country_ID
    JOIN 
        Vaccine v ON vr.Vaccine_ID = v.Vaccine_ID
    GROUP BY 
        c.Country_Name, v.Vaccine_Name
),

PercentageShare AS (
    SELECT 
        Country_Name,
        Vaccine_Type,
        (Vaccine_Total * 100.0 / Country_Total) AS Percentage_Of_Vaccine
    FROM 
        VaccineShare
),

RankedShare AS (
    SELECT 
        Country_Name,
        Vaccine_Type,
        Percentage_Of_Vaccine,
        ROW_NUMBER() OVER (PARTITION BY Country_Name ORDER BY Percentage_Of_Vaccine DESC) AS Rank
    FROM 
        PercentageShare
)

SELECT 
    Vaccine_Type,
    Country_Name AS Country,
    Percentage_Of_Vaccine AS "Percentage of Vaccine Type"
FROM 
    RankedShare
WHERE 
    Rank <= 5
ORDER BY 
    Country_Name, Percentage_Of_Vaccine DESC;


--------task d.4---------------

WITH MonthlyTotals AS (
    SELECT 
        c.Country_Name,
        strftime('%Y-%m', vr.Date) AS Month,  
        ds.Source_Name || ' (' || ds.Source_URL || ')' AS Source_Name_URL,
        MAX(vr.Total_Vaccinations) AS Total_Administered_Vaccines 
    FROM 
        Vaccination_Record vr
    JOIN 
        Country c ON vr.Country_ID = c.Country_ID
    JOIN 
        Data_Source ds ON c.Country_ID = ds.Country_ID  
    GROUP BY 
        c.Country_Name, Month, ds.Source_Name, ds.Source_URL
)

SELECT 
    Country_Name,
    Month,
    Source_Name_URL AS "Source Name (URL)",
    Total_Administered_Vaccines
FROM 
    MonthlyTotals
ORDER BY 
    Total_Administered_Vaccines DESC;

------------task d.5-------------------------

SELECT 
    vr.Date AS "Dates",
    COALESCE(usa.Vaccination_Increment, 0) AS "United States",
    COALESCE(china.Vaccination_Increment, 0) AS "China",
    COALESCE(ireland.Vaccination_Increment, 0) AS "Ireland",
    COALESCE(india.Vaccination_Increment, 0) AS "India"
FROM 
    (SELECT DISTINCT Date FROM Vaccination_Record WHERE Date BETWEEN '2022-01-01' AND '2023-12-31') vr
LEFT JOIN 
    (
        SELECT 
            Date,
            Total_Vaccinations - LAG(Total_Vaccinations, 1) OVER (ORDER BY Date) AS Vaccination_Increment
        FROM 
            Vaccination_Record
        WHERE 
            Country_ID = (SELECT Country_ID FROM Country WHERE Country_Name = 'United States')
        AND 
            Date BETWEEN '2022-01-01' AND '2023-12-31'
    ) AS usa ON vr.Date = usa.Date
LEFT JOIN 
    (
        SELECT 
            Date,
            Total_Vaccinations - LAG(Total_Vaccinations, 1) OVER (ORDER BY Date) AS Vaccination_Increment
        FROM 
            Vaccination_Record
        WHERE 
            Country_ID = (SELECT Country_ID FROM Country WHERE Country_Name = 'China')
        AND 
            Date BETWEEN '2022-01-01' AND '2023-12-31'
    ) AS china ON vr.Date = china.Date
LEFT JOIN 
    (
        SELECT 
            Date,
            Total_Vaccinations - LAG(Total_Vaccinations, 1) OVER (ORDER BY Date) AS Vaccination_Increment
        FROM 
            Vaccination_Record
        WHERE 
            Country_ID = (SELECT Country_ID FROM Country WHERE Country_Name = 'Ireland')
        AND 
            Date BETWEEN '2022-01-01' AND '2023-12-31'
    ) AS ireland ON vr.Date = ireland.Date
LEFT JOIN 
    (
        SELECT 
            Date,
            Total_Vaccinations - LAG(Total_Vaccinations, 1) OVER (ORDER BY Date) AS Vaccination_Increment
        FROM 
            Vaccination_Record
        WHERE 
            Country_ID = (SELECT Country_ID FROM Country WHERE Country_Name = 'India')
        AND 
            Date BETWEEN '2022-01-01' AND '2023-12-31'
    ) AS india ON vr.Date = india.Date
ORDER BY 
    vr.Date;
