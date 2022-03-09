/* Covid 19 Data Exploration Using SQL
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Data Sources:  --https://ourworldindata.org/covid-deaths
*/


--Viewing the data of each spreadsheet

SELECT *
FROM PortfolioProject..CovidDeaths
Order by 3,4

--Finding the data that I will use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

--Finding the total cases comparing it to the total deaths in South Africa

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE '%South Africa%'
and location is not NULL
ORDER BY 1,2

--Finding the percentage of population

SELECT location, date, population, total_cases,(total_cases/population)*100 as PositivePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

--Finding countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PositivePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY PositivePercentage desc

--Showing countries with highest death count per population

SELECT location, population, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY TotalDeathCount desc


--Getting global numbers

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2


--Finding the total population vs vaccination
--Shows percentage of population that has received at least one Covid Vaccine

Select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(Cast(v.new_vaccinations as int)) OVER (Partition By d.location Order By d.location, d.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths d
JOIN PortfolioProject..CovidVaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not NULL
order by 2,3

--Use CTE to perform calculation on Partition By in previous query

With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL
)

Select *, (RollingPeopleVaccinated/population)*100
From PopVsVac

-- Temp  Table to perform calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)


Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date


SELECT  *, (RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated



--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *
FROM PercentPopulationVaccinated