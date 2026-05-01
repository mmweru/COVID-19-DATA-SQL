--SELECT * FROM CovidDeaths
--SELECT * FROM CovidVaccinations

--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths
--ORDER BY 1, 2

--Looking At the total Deaths in Kenya from the number of Cases reported to have COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location like 'ke%a'
ORDER BY 1, 2

--Looking At the Total Cases Vs Population
--Shows what percentage of Population got COVID
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (total_cases * 100.0) / population AS PercentageofPopulationInfected
FROM CovidDeaths
WHERE location LIKE 'ke%a'
ORDER BY 1, 2;

--Looking At Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases  * 100.0 /population)) AS MaxPopulationInfected
FROM CovidDeaths
GROUP BY location, population 
ORDER BY MaxPopulationInfected DESC

--Showing Countries with Highest Death Count per Population
SELECT location, population, MAX(total_deaths) as HighestDeaths, MAX((total_deaths  * 100.0 /population)) AS MaxDeathsperPopulation
FROM CovidDeaths
GROUP BY location, population 
ORDER BY MaxDeathsperPopulation DESC, location ASC

--Selecting by continents
SELECT continent, MAX(CAST(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
WHERE continent is not NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Showing continents with the highest death count per population
SELECT continent, population, MAX(Total_deaths * 100.0 / population) as HighestDeathContinentPerPop
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent, population


--Joining the 2 tables (INNER JOIN)
--Looking at Total population vs Vaccinations
SELECT ed.continent, ed.location, ed.population, vac.total_vaccinations, 
(CAST(vac.total_vaccinations AS FLOAT) * 100.0 / NULLIF(CAST(ed.population AS FLOAT), 0)) AS VacinatedinPopulation 
FROM CovidDeaths ed
INNER JOIN CovidVaccinations vac
ON ed.location = vac.location AND ed.date = vac.date
GROUP BY ed.continent, ed.location, ed.population, vac.total_vaccinations

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CONVERT(numeric, dea.population), -- Fix: Match the table's 'numeric' type
    TRY_CONVERT(numeric, vac.new_vaccinations), -- Fix: Match the table's 'numeric' type
    SUM(TRY_CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) 
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date;

-- Check results
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CONVERT(numeric, dea.population) AS Population, 
    TRY_CONVERT(numeric, vac.new_vaccinations) AS New_Vaccinations, 
    SUM(TRY_CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
INNER JOIN CovidVaccinations vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL; -- Added to filter out grouped continent rows

