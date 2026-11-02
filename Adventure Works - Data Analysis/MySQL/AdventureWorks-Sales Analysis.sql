CREATE DATABASE myproject;
use myproject;

SELECT * FROM factinternetsales1;
SELECT * FROM DIMDATE1;
SELECT * FROM FACTINTERNETSALES1;
SELECT * FROM FACT_INTERNET_SALES_NEW1 LIMIT 10;
SELECT * FROM DIMPRODUCT1 LIMIT 10;
SELECT * FROM DIMSALESTERRITORY1;
SELECT * FROM DIMPRODUCTSUBCATEGORY1;
SELECT * FROM DIMPRODUCTCATEGORY1;
SELECT * FROM DIMCUSTOMER1 LIMIT 10;

-- Union of Fact Tables
CREATE OR REPLACE VIEW CombinedSales AS
SELECT * FROM FactInternetSales1
UNION ALL
SELECT * FROM Fact_Internet_Sales_New1; 

SELECT * FROM CombinedSales; 

-- Lookup Product name from Product Sheet

SELECT 
    p.EnglishProductName AS ProductName,
    SUM(s.OrderQuantity * s.UnitPrice * (1 - s.UnitPriceDiscountPct)) AS TotalSales
FROM CombinedSales s
LEFT JOIN DimProduct1 p ON s.ProductKey = p.ProductKey
GROUP BY p.EnglishProductName
ORDER BY TotalSales DESC;

-- Lookup Customer Full name and unit price

SELECT DISTINCT
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    p.`Unit price` AS UnitPrice
FROM CombinedSales s
LEFT JOIN DimCustomer1 c ON s.CustomerKey = c.CustomerKey
LEFT JOIN DimProduct1 p ON s.ProductKey = p.ProductKey;

-- Date Fields From OrderDateKey

SELECT 
    DateKey AS OrderDateKey,
    FullDateAlternateKey AS OrderDate,
    CalendarYear AS Year,
    MonthNumberOfYear AS MonthNo,
    EnglishMonthName AS MonthFullName,
    CONCAT('Q', CalendarQuarter) AS Quarter,
    DATE_FORMAT(FullDateAlternateKey, '%Y-%b') AS YearMonth,
    DayNumberOfWeek AS WeekdayNo,
    EnglishDayNameOfWeek AS WeekdayName,
    
    -- Financial Month (April 1st Fiscal Start)
    CASE 
        WHEN MonthNumberOfYear >= 4 THEN MonthNumberOfYear - 3 
        ELSE MonthNumberOfYear + 9 
    END AS FinancialMonth,
    
    -- Financial Quarter
    CONCAT('FQ', CEILING((
        CASE 
            WHEN MonthNumberOfYear >= 4 THEN MonthNumberOfYear - 3 
            ELSE MonthNumberOfYear + 9 
        END) / 3)) AS FinancialQuarter
FROM DimDate1;

-- Calculating Sales Aount

SELECT 
    SalesOrderNumber,
    OrderQuantity,
    UnitPrice,
    UnitPriceDiscountPct,
    (OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS SalesAmount
FROM CombinedSales;

-- Calculating Production Cost

SELECT 
    SalesOrderNumber,
    OrderQuantity,
    ProductStandardCost,
    (ProductStandardCost * OrderQuantity) AS ProductionCost
FROM CombinedSales;

-- Calculating Profit

SELECT 
    SalesOrderNumber,
    (OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS SalesAmount,
    (ProductStandardCost * OrderQuantity) AS ProductionCost,
    ((OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) - 
     (ProductStandardCost * OrderQuantity)) AS Profit
FROM CombinedSales;

--  Pivot table for month & sales

SELECT 
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthFullName,
    SUM(
        s.OrderQuantity * 
        s.UnitPrice * 
        (1 - s.UnitPriceDiscountPct)
    ) AS TotalSales
FROM CombinedSales s
LEFT JOIN DimDate1 d 
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY 
    d.MonthNumberOfYear;
    
-- Year-wise Sales

SELECT 
    d.CalendarYear AS Year,
    SUM(
        s.OrderQuantity * 
        s.UnitPrice * 
        (1 - s.UnitPriceDiscountPct)
    ) AS TotalSales
FROM CombinedSales s
LEFT JOIN DimDate1 d 
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarYear
ORDER BY 
    d.CalendarYear;
    
-- Month-wise Sales

SELECT 
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthFullName,
    SUM(
        s.OrderQuantity * 
        s.UnitPrice * 
        (1 - s.UnitPriceDiscountPct)
    ) AS TotalSales
FROM CombinedSales s
LEFT JOIN DimDate1 d 
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.MonthNumberOfYear,
    d.EnglishMonthName
ORDER BY 
    d.MonthNumberOfYear;
    
-- Quarter-wise Sales

SELECT 
    CONCAT('Q', d.CalendarQuarter) AS Quarter,
    SUM(
        s.OrderQuantity * 
        s.UnitPrice * 
        (1 - s.UnitPriceDiscountPct)
    ) AS TotalSales
FROM CombinedSales s
LEFT JOIN DimDate1 d 
    ON s.OrderDateKey = d.DateKey
GROUP BY 
    d.CalendarQuarter
ORDER BY 
    d.CalendarQuarter;
    
-- Year, Month wise Sales & Production cost

SELECT 
    d.CalendarYear AS Year,
    d.MonthNumberOfYear AS MonthNo,
    d.EnglishMonthName AS MonthFullName,
    DATE_FORMAT(d.FullDateAlternateKey, '%Y-%m') AS YearMonth,

    SUM(
        s.OrderQuantity * 
        s.UnitPrice * 
        (1 - s.UnitPriceDiscountPct)
    ) AS SalesAmount,

    SUM(
        s.ProductStandardCost * 
        s.OrderQuantity
    ) AS ProductionCost

FROM CombinedSales s

LEFT JOIN DimDate1 d 
    ON s.OrderDateKey = d.DateKey

GROUP BY 
    d.CalendarYear,
    d.MonthNumberOfYear,
    d.EnglishMonthName,
    DATE_FORMAT(d.FullDateAlternateKey, '%Y-%m')

ORDER BY 
    d.CalendarYear,
    d.MonthNumberOfYear;
    
-- Total Sales

SELECT 
    SUM(
        OrderQuantity * 
        UnitPrice * 
        (1 - UnitPriceDiscountPct)
    ) AS TotalSales
FROM CombinedSales;

-- Total Production Cost

SELECT 
    SUM(
        ProductStandardCost * OrderQuantity
    ) AS TotalProductionCost
FROM CombinedSales;

-- Total Profit

SELECT 
    SUM(
        (OrderQuantity * UnitPrice * 
        (1 - UnitPriceDiscountPct))
        -
        (ProductStandardCost * OrderQuantity)
    ) AS TotalProfit
FROM CombinedSales;

-- Total Orders

SELECT 
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders
FROM CombinedSales;

-- Total Number of Customers

SELECT 
    COUNT(DISTINCT CustomerKey) AS NumberOfCustomers
FROM CombinedSales;

-- Total Number of Products

SELECT 
    COUNT(DISTINCT ProductKey) AS NumberOfProducts
FROM CombinedSales;