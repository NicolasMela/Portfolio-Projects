# Import Covid Death Data into MySQL

LOAD DATA INFILE '/ProgramData/MySQL/MySQL Server 8.0/Uploads/CovidDeaths NA.csv'
INTO TABLE coviddeaths_na
FIELDS TERMINATED BY ',' -- Change ',' to the actual delimiter used in your CSV file
LINES TERMINATED BY '\n' -- Change '\n' to the line terminator used in your CSV file
IGNORE 1 LINES; -- If your CSV file has a header row, use IGNORE 1 LINES to skip it

# Import Covid Vaccinations North America Data into MySQL

LOAD DATA INFILE '/ProgramData/MySQL/MySQL Server 8.0/Uploads/CovidVaccinations NA.csv'
INTO TABLE covidvaccinations_na
FIELDS TERMINATED BY ',' -- Change ',' to the actual delimiter used in your CSV file
LINES TERMINATED BY '\n' -- Change '\n' to the line terminator used in your CSV file
IGNORE 1 LINES; -- If your CSV file has a header row, use IGNORE 1 LINES to skip it

# Update all blank rows to NULL values
-- Did the following for each table and columns within each
UPDATE coviddeaths_na
SET total_cases = NULL
WHERE total_cases = '' AND ID > 0;

----------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
Skills used: Joins, CTE's, Aggregate Functions, Creating Views, Data Cleaning
*/

-- First looking at Countries with Highest Cases, Deaths, and Vaccinations
-- Looking at vaccinations that aren't boosters
SELECT cd.location, MAX(population) as Population, MAX(total_cases) AS TotalCases, MAX(total_deaths) AS TotalDeaths, (MAX(total_vaccinations) - MAX(total_boosters)) AS TotalVaccinations
FROM coviddeaths_na AS cd
	INNER JOIN covidvaccinations_na AS cv
		ON cd.ID = cv.ID
GROUP BY cd.location
ORDER BY 1;        


-- Looking at Total Cases vs. Total Deaths
-- Shows us the current death percentage of all the cases in each country
SELECT location, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths, (MAX(total_deaths) * 100 / MAX(total_cases))  AS Death_Percentage
FROM coviddeaths_na 
GROUP BY location
ORDER BY location;


-- Now look at Total Cases vs. Total Deaths Over Time
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100  AS death_percentage
FROM coviddeaths_na 
ORDER BY location;


-- Looking at Total Cases vs. Population Over Time
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS case_per_population
FROM coviddeaths_na
ORDER BY location, date;


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, Population, MAX(total_cases) AS max_infection_count, MAX((total_cases/population))*100 AS population_infection_percentage
FROM coviddeaths_na
GROUP BY Location, population
ORDER BY population_infection_percentage DESC;


-- Looking at Countries with Highest Death Count per Population
SELECT location, population, MAX(total_deaths) AS total_death_count, MAX((total_deaths/population))*100 AS population_death_percentage
FROM coviddeaths_na
GROUP BY location, population
ORDER BY total_death_count DESC;


-- Looking at Total Population vs. Vaccinations using CTE
-- Shows the percentage of population that has been vaccinated at least once
WITH PopVac (location, date, population, new_vaccinations, total_vaccinations)  
AS
(
SELECT cd.location, cd.date, population, new_vaccinations, SUM(new_vaccinations) OVER (partition by cd.location ORDER BY cd.location, cd.date) AS total_vaccinations
FROM coviddeaths_na as cd
	INNER JOIN covidvaccinations_na as cv
		ON cd.ID = cv.ID
)
SELECT *, (total_vaccinations/population)*100 AS population_vaccination_percentage
FROM PopVac;
      



----------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Creating views to store data for later visualizations

CREATE VIEW PopulationVaccinatedPercentage AS
      WITH PopVac (location, date, population, new_vaccinations, total_vaccinations)  
AS
(
SELECT cd.location, cd.date, population, new_vaccinations, SUM(new_vaccinations) OVER (partition by cd.location ORDER BY cd.location, cd.date) AS total_vaccinations
FROM coviddeaths_na as cd
	INNER JOIN covidvaccinations_na as cv
		ON cd.ID = cv.ID
)
SELECT *, (total_vaccinations/population)*100 AS population_vaccination_percentage
FROM PopVac;

CREATE VIEW DeathPercentage AS
SELECT location, MAX(total_cases) as TotalCases, MAX(total_deaths) as TotalDeaths, (MAX(total_deaths) * 100 / MAX(total_cases))  AS Death_Percentage
FROM coviddeaths_na 
GROUP BY location
ORDER BY location;