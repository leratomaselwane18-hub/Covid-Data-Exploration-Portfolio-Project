-- 1. Total Cases vs Total Deaths (Death Percentage in the US)
SELECT
dea.location,
dea.date,
dea.total_cases,
dea.total_deaths,
(CAST(dea.total_deaths AS float) / NULLIF(CAST(vac.population AS float), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..Covidvaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.location LIKE '%states%'
ORDER BY 1, 2;


-- 2. Total Cases vs Population (Infection Percentage)
SELECT
dea.location,
dea.date,
vac.population,
dea.total_cases,
(CAST(dea.total_cases AS float) / NULLIF(CAST(vac.population AS float), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..Covidvaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.location LIKE '%states%'
ORDER BY 1, 2;


-- 3. Table JOIN with Rolling Vaccinations Tally
SELECT
dea.continent,
dea.location,
dea.date,
vac.population,
vac.new_vaccinations,
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..Covidvaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

-- 4. Finding Countries with the highest infection rates compared to their population

SELECT
dea.Location,
MAX(TRY_CAST(vac.population AS float)) AS Population,
MAX(TRY_CAST(dea.total_cases AS float)) AS HighestInfectionCount,
MAX(TRY_CAST(dea.total_cases AS float) / NULLIF(TRY_CAST(vac.population AS float), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..Covidvaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.Location
ORDER BY PercentPopulationInfected DESC;

-- 5. Finding countries with the highest death counts

SELECT
dea.Location,
MAX(TRY_CAST(dea.total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..Covidvaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.Location
ORDER BY TotalDeathCount DESC;

-- 6. Showing continents with the highest death count per population
SELECT
continent,
MAX(TRY_CAST(total_deaths AS float)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 7. Global Covid death percentage by date
SELECT
date,
SUM(TRY_CAST(new_cases AS float)) AS total_cases,
SUM(TRY_CAST(new_deaths AS float)) AS total_deaths,
SUM(TRY_CAST(new_deaths AS float)) / NULLIF(SUM(TRY_CAST(new_cases AS float)), 0) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- 8. Looking at Total Population vs Vaccinations
SELECT
dea.continent,
dea.location,
dea.date,
TRY_CAST(vac.population AS float) AS Population,
TRY_CAST(vac.new_vaccinations AS float) AS New_Vaccinations,
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
PARTITION BY dea.Location
ORDER BY dea.location, dea.date
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;

--9. Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT
dea.continent,
dea.location,
dea.date,
TRY_CAST(vac.population AS float),
TRY_CAST(vac.new_vaccinations AS float),
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
PARTITION BY dea.Location
ORDER BY dea.location, dea.date
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- 10. Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated float
);

INSERT INTO #PercentPopulationVaccinated
SELECT
dea.continent,
dea.location,
dea.date,
TRY_CAST(vac.population AS float),
TRY_CAST(vac.new_vaccinations AS float),
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
PARTITION BY dea.Location
ORDER BY dea.location, dea.date
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- 11. Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT
dea.continent,
dea.location,
dea.date,
TRY_CAST(vac.population AS float) AS Population,
TRY_CAST(vac.new_vaccinations AS float) AS New_Vaccinations,
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
PARTITION BY dea.Location
ORDER BY dea.location, dea.date
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

USE PortfolioProject;
GO

-- Drop it if it accidentally exists here to clear the slate
DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT
dea.continent,
dea.location,
dea.date,
TRY_CAST(vac.population AS float) AS Population,
TRY_CAST(vac.new_vaccinations AS float) AS New_Vaccinations,
SUM(TRY_CAST(vac.new_vaccinations AS float)) OVER (
PARTITION BY dea.Location
ORDER BY dea.location, dea.date
) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations_fixed vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
GO


