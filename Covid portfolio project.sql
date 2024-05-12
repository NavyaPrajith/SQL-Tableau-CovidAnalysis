-- Query to retrieve data from coviddeath table, sorted by date and location.
select * from project01..coviddeath order by 3,5;

--select * from project01..covidvaccinations order by 3;

select location,date,total_cases,new_cases,total_deaths,population from project01..coviddeath order by 1,2;

--Looking at Total Cases vs Total Deaths
--shows likelihood of dying if you contract covid in your country
select 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    (CONVERT(float, total_deaths) / CONVERT(float, total_cases)) * 100 as DeathPercentage
from 
    project01..coviddeath 
where 
    location like '%states%'
order by 
    location, date;

--looking at total cases vs population
--shows what percentage of population got covid
select location,date,total_cases,population,(total_cases/population)*100 as PercentPopulationInfected
from project01..coviddeath 
where location like'%states%'
order by 1,2

--looking at countries with highest infection rate compared to population
select location,population,MAX(total_cases) as HighestInfectionCount,MAX(total_cases/population)*100 as PercentPopulationInfected
from project01..coviddeath 
group by location,population
order by PercentPopulationInfected desc

--showing countries with highest death count per population
select location,MAX(total_deaths) as TotalDeathCount
from project01..coviddeath 
where continent is not null
group by location
order by TotalDeathCount desc;

--let's break things down by continent
--Showing continents with the highest death count per population
select continent,MAX(total_deaths) as TotalDeathCount
from project01..coviddeath 
where continent is not null
group by continent
order by TotalDeathCount desc;

-- Query to calculate total new cases, total new deaths, and new death percentage.
-- This provides a summary of COVID statistics.
ALTER TABLE project01..coviddeath
ALTER COLUMN new_cases FLOAT;

ALTER TABLE project01..coviddeath
ALTER COLUMN new_deaths FLOAT;

select SUM(new_cases) AS TotalNewCases,SUM(new_deaths) AS TotalNewDeaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE SUM(new_deaths) / SUM(new_cases) * 100
    END AS NewDeathPercentage
from project01..coviddeath 
where continent is not null
--group by date
order by 1,2

Select location, SUM(new_deaths) as TotalDeathCount
from project01..coviddeath
where continent is null
and location not in ('World', 'European Union', 'International')
group by location
order by TotalDeathCount

-- Query using CTE to calculate the rolling sum of new vaccinations per location.
-- This query enhances readability and manageability by breaking down the calculation into smaller units.
--They are especially useful when you need to reference the same subquery multiple times within a larger query.
With PopvsVac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated) as
(select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER(Partition by dea.location order by dea.location,dea.date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from project01..coviddeath dea
join project01..covidvaccination vac
    on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null)
--order by 2,3
select * ,(RollingPeopleVaccinated/population)*100 from PopvsVac

-- Creating a temporary table to store data for later use.
--DROP TABLE if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER(Partition by dea.location order by dea.location,dea.date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from project01..coviddeath dea
join project01..covidvaccination vac
    on dea.location=vac.location and dea.date=vac.date
--where dea.continent is not null
select * ,(RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated


--Creating view to store data for later visualizations
Create view PercentPopulationVaccinated as 
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
,SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER(Partition by dea.location order by dea.location,dea.date ROWS UNBOUNDED PRECEDING) AS RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from project01..coviddeath dea
join project01..covidvaccination vac
    on dea.location=vac.location and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select * from PercentPopulationVaccinated
