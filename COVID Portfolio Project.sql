SELECT * FROM Project1..Deaths
ORDER BY 3,4 

--SELECT * FROM Project1..Vaccinations
--ORDER BY 3,4

--Data we are using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project1..Deaths
ORDER BY 1,2

--Total deaths vs Total Cases
--Likelihood of dying if covid positive (in Pakistan)

SELECT location, date, total_cases, population, (total_cases/population)*100 AS DeathPercentage
FROM Project1..Deaths
WHERE location like 'Pakistan' AND continent IS NOT NULL
ORDER BY 1,2

--Total cases vs Population
--Percentage population with covid

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CovidPositivePercentage
FROM Project1..Deaths
WHERE location like 'Pakistan' AND location like 'Pakistan' AND continent IS NOT NULL
ORDER BY 1,2

--Countries with highest infection rates as per the population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS CovidPositivePercentage
FROM Project1..Deaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY CovidPositivePercentage DESC


--Countries with highest death count as per population

SELECT location, population, MAX(cast(total_deaths as BIGINT)) AS TotalDeathCount, MAX((total_deaths/population))*100 AS CovidDeathPercentage
FROM Project1..Deaths
WHERE continent IS NOT NULL
GROUP BY population, location
ORDER BY TotalDeathCount DESC

--CONTINENTS with highest death count

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM Project1..Deaths
WHERE continent IS NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC
--DELETE FROM Deaths WHERE iso_code='OWID_HIC'

--Global Numbers

SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as BIGINT)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPerentage
FROM Project1..Deaths
--WHERE location like 'Pakistan'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 4 DESC

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as BIGINT)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPerentage
FROM Project1..Deaths
--WHERE location like 'Pakistan'
WHERE continent IS NOT NULL
ORDER BY 1,2

--Joining tables

SELECT * 
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date

--Total Population vs Vaccination

SELECT de.continent, de.location, de.date, de.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as RollingSumVaccinatedPeople
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date
WHERE de.continent IS NOT NULL
order by 2,3

--Percentage of above #METHOD 1

SELECT de.continent, de.location, de.date, de.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as RollingSumVaccinatedPeople, 
((SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION BY de.location ORDER BY de.location, de.date))/de.population)*100 AS Percentage
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date
WHERE de.continent IS NOT NULL
order by 2,3

--Percentage of above #METHOD 2 using CTE

WITH popvsvac (Continent, Location ,Date, Population, NewVaccinations, RollingSumVaccinatedPeople)
AS (
SELECT de.continent, de.location, de.date, de.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as RollingSumVaccinatedPeople
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date
WHERE de.continent IS NOT NULL
)
SELECT *, (RollingSumVaccinatedPeople/population)*100 as Percentage
FROM popvsvac

--Percentage of above #METHOD 2 using TEMP TABLE

DROP TABLE IF EXISTS #PercentageofPopulationVaccinated
CREATE TABLE #PercentageofPopulationVaccinated 
( Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_Vaccinations numeric, RollingSumVaccinatedPeople numeric )

INSERT INTO #PercentageofPopulationVaccinated
SELECT de.continent, de.location, de.date, de.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as RollingSumVaccinatedPeople
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date
WHERE de.continent IS NOT NULL

SELECT *, (RollingSumVaccinatedPeople/Population)*100 as Percentage
FROM #PercentageofPopulationVaccinated

--Creating view to store data for later visualizations

USE Project1 
GO
CREATE VIEW PercentageofPopulationVaccinated AS
SELECT de.continent, de.location, de.date, de.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY de.location ORDER BY de.location, de.date) as RollingSumVaccinatedPeople
FROM Project1..Deaths de
JOIN Project1..Vaccinations vac
	ON de.location = vac.location
	AND de.date = vac.date
WHERE de.continent IS NOT NULL

SELECT *
FROM PercentageofPopulationVaccinated