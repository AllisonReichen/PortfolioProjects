/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Select data that I am using
USE CovidPortfolioProject;

-- Shows new cases each day and total deaths over time
SELECT location, date, new_cases, total_deaths, population
FROM CovidPortfolioProject..covid_deaths
ORDER BY 1,2;


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying from contracting covid-19 in each country over the last 2 years 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM CovidPortfolioProject..covid_deaths
ORDER BY 1,2;


-- Looking at Total Cases vs Population
-- Shows what percentage of populations contracted covid-19 over time
SELECT location, date, total_cases, population, (total_cases/population)*100 AS population_percentage_infected
FROM CovidPortfolioProject..covid_deaths
ORDER BY 1,2;


-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS population_percentage_infected
FROM CovidPortfolioProject..covid_deaths
GROUP BY location, population
ORDER BY population_percentage_infected DESC;


-- Shows countries with highest death count per population
SELECT location, population, MAX(total_deaths) AS total_death_count, MAX((total_deaths/population))*100 AS population_death_rate
FROM CovidPortfolioProject..covid_deaths
Where continent IS NOT NULL
GROUP BY location, population
ORDER BY population_death_rate DESC;


-- Death count and death rate broken down by continent
SELECT location, population, MAX(total_deaths) AS total_death_count, MAX((total_deaths/population))*100 AS population_death_rate
FROM CovidPortfolioProject..covid_deaths
Where continent IS NULL AND ((location = 'North America') OR (location = 'South America') OR (location = 'Europe') OR 
(location = 'Asia') OR (location = 'Africa') OR (location = 'Oceania'))
GROUP BY location, population
ORDER BY population_death_rate DESC;


-- Global Numbers of cases, deaths, and death rate by the day
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths,
SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS global_death_percentage
FROM CovidPortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;


-- Looking at total population vaccination rate over time
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_doses_over_time
FROM CovidPortfolioProject..covid_deaths dea
JOIN CovidPortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- Use CTE
WITH pop_vs_vac (Continent, Location, Date, Population, New_Vaccinations, Vaccination_Doses_Over_Time)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_doses_over_time
FROM CovidPortfolioProject..covid_deaths dea
JOIN CovidPortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (Vaccination_Doses_Over_Time/Population) AS Doses_Given_Per_Population_Rate
FROM pop_vs_vac;


-- Temp Table
DROP TABLE IF EXISTS #RateOfDosesGivenPerPopulation;
CREATE TABLE #RateOfDosesGivenPerPopulation 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Vaccination_Doses_Over_Time numeric
);
INSERT INTO #RateOfDosesGivenPerPopulation
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_doses_over_time
FROM CovidPortfolioProject..covid_deaths dea
JOIN CovidPortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (Vaccination_Doses_Over_Time/Population) AS Doses_Given_Per_Population_Rate
FROM #RateOfDosesGivenPerPopulation;


-- Create View to store data for later visualizations

GO
CREATE VIEW RateOfDosesGivenPerPopulation AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_doses_over_time
FROM CovidPortfolioProject..covid_deaths dea
JOIN CovidPortfolioProject..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

