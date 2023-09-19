# Import San Francisco Employee Compensation Data 

# Import Employee Data
LOAD DATA INFILE "/ProgramData/MySQL/MySQL Server 8.0/Uploads/Employee_EmpComp.csv"
INTO TABLE employee
FIELDS TERMINATED BY ',' -- Change ',' to the actual delimiter used in your CSV file
LINES TERMINATED BY '\n' -- Change '\n' to the line terminator used in your CSV file
IGNORE 1 LINES; -- If your CSV file has a header row, use IGNORE 1 LINES to skip it

# Import Organization Data
LOAD DATA INFILE "/ProgramData/MySQL/MySQL Server 8.0/Uploads/Org_EmpComp.csv"
INTO TABLE organization
FIELDS TERMINATED BY ',' -- Change ',' to the actual delimiter used in your CSV file
OPTIONALLY ENCLOSED BY '"' -- Use double quotes as the enclosure character
LINES TERMINATED BY '\r\n' -- Change '\n' to the line terminator used in your CSV file
IGNORE 1 LINES; -- If your CSV file has a header row, use IGNORE 1 LINES to skip it

# Import Job Data
LOAD DATA INFILE "/ProgramData/MySQL/MySQL Server 8.0/Uploads/Job_EmpComp.csv"
INTO TABLE job
FIELDS TERMINATED BY ',' -- Change ',' to the actual delimiter used in your CSV file
OPTIONALLY ENCLOSED BY '"' -- Use double quotes as the enclosure character
LINES TERMINATED BY '\r\n' -- Change '\n' to the line terminator used in your CSV file
IGNORE 1 LINES; -- If your CSV file has a header row, use IGNORE 1 LINES to skip it

---------------------------------------------------------------------------------------------
# Data Cleaning
---------------------------------------------------------------------------------------------
# Checking for missing values
-- Checks for any NULL values in each column. 
-- Would usually check for NULL values in Python to save time but did so in SQL for the purpose of showcasing the ability to.
SELECT * FROM employee
WHERE EmpID IS NULL OR 
	Retirement IS NULL OR
    Year_Type IS NULL OR
	Year IS NULL OR
    Salaries IS NULL OR
    Overtime IS NULL OR 
    Other_Salaries IS NULL OR 
    Total_Salary IS NULL OR
    Retirement IS NULL OR
    Health_and_Dental IS NULL OR
    Other_Benefits IS NULL OR
    Total_Benefits IS NULL;

-- Did the query for the rest of the columns in the other tables


---------------------------------------------------------------------------------------------
# Data Exploration
---------------------------------------------------------------------------------------------

# Checking the Total Compensation for each Employee 
-- Subqueries from the FROM statement which is calculating total benefits
-- Calculates the SUM of Total Salary and Total Benefits to reach Total Compensation per Employee

CREATE TEMPORARY TABLE Temp_Employee_TC AS
SELECT ID, EmpID, Total_Salary, (Total_Salary + Total_Benefits) AS Total_Compensation
FROM (SELECT ID, EmpID, Total_Salary, (Retirement + Health_and_Dental + Other_Benefits) AS Total_Benefits 
		FROM employee) AS subquery;


# Using Temp Table to Analyze Departments with Highest Compensation

SELECT o.Department, SUM(e.Total_Compensation) AS Total_Compensation
FROM Temp_Employee_TC AS e
INNER JOIN Organization AS o 
	ON e.ID = o.ID
GROUP BY o.Department;


#  Subquery for Departments with Above Average Salary
-- Shows which departments have above average San Francisco salary, 
-- but then poses the question which job in each department have above average salary?
   
SELECT Department, AVG(Total_Salary) As 'Average Salary'
FROM employee AS e
	INNER JOIN organization AS o
		ON e.ID = o.ID
WHERE Total_Salary > (
	SELECT AVG(Total_Salary)
	FROM Employee
    )
GROUP BY Department
ORDER BY 1;  


# Case Statement for Above or Below Average Salary
-- Shows the average salary of each job in each job family and department, and shows whether or not this is above or below the average salary in San Francisco. 

SELECT Department, Job_Family, Job, AVG(Total_Salary) AS 'Average Salary', (Select AVG(Total_Salary) From Employee) AS 'San Francisco Avg Salary',
CASE
	WHEN AVG(Total_Salary) > (Select AVG(Total_Salary) From Employee) THEN 'Above Average'
    ELSE 'Below Average'
END AS 'Salary Comparison'
FROM employee AS e
	INNER JOIN job as j
		ON e.ID = j.ID
			JOIN organization AS o
				ON j.ID = o.ID
GROUP BY Job_Family, Job, Department;


# Analyzing Total Salary over the Past Decade with Window Functions
-- Shows the Percentage Change in Salary each Year

SELECT year, AVG(Total_Salary) AS 'Average Salary',
    (AVG(Total_Salary) - LAG(AVG(Total_Salary)) OVER (ORDER BY year ASC)) / LAG(AVG(Total_Salary)) OVER (ORDER BY year ASC) * 100 AS 'Rate of Change %'
FROM employee
GROUP BY year
ORDER BY year DESC;

