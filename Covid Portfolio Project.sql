select *
from PortfolioProject.dbo.CovidDeaths$
where continent is not null
order by 3, 4;

--select *
--from PortfolioProject.dbo.CovidVaccinations$
--order by 3, 4;

--Select the data that we'll be using
select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
order by 1,2;

--Total cases vs Total deaths
--shows the likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100,2) as DeathPercentage
from PortfolioProject..CovidDeaths$
where location like '%ugan%'
order by 1,2;

--total cases vs population
select Location, date, total_cases, population, round((total_cases/population)*100,2) as PercentagePopulationInfected
from PortfolioProject..CovidDeaths$
where location like '%ugan%'
order by 1,2;

--countries with the highest infection rate compared to population
select Location, population, max(total_cases) as HighestInfectionCount, max(round((total_cases/population)*100,2)) as PercentagePopulationInfected
from PortfolioProject..CovidDeaths$
--where location like '%ugan%'
group by location, population 
order by PercentagePopulationInfected desc;

--countries with the highest death count per population
select Location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by location, population 
order by TotalDeathCount desc;

--BREAKING THINGS DOWN BY CONTINENT
--continents with highest death count
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent 
order by TotalDeathCount desc;

--continents total death count
select continent, sum(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths$
where continent is not null
group by continent 
order by TotalDeathCount desc;


--GLOBAL NUMBERS
--percentage of new deaths to new cases by date
select cast(date as date) as date, 
sum(new_cases) as TotalCases, 
sum(cast(new_deaths as int)) as TotalDeaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null
group by date
order by 1,2;

--overall global total cases and deaths
select sum(new_cases) as TotalCases, 
sum(cast(new_deaths as int)) as TotalDeaths, 
(sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null;


--join coviddeaths and covidvaccinations tables using location and date
select *
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on vac.location = dea.location and vac.date = dea.date
where dea.continent is not null
order by 2,3;

--insert a rolling count of the total number of vaccinations in a given location
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) 
over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on vac.location = dea.location and vac.date = dea.date
where dea.continent is not null
order by 2,3;

--USE A CTE
--enables us to perform calculations on the RollingPeopleVaccinated column
WITH PopvsVac (Continent, Location, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on vac.location = dea.location and vac.date = dea.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/Population)*100 as PercentagePopulationVaccinated
from PopvsVac;

--TEMP TABLE (same as the CTE version)
drop table if exists #PercentagePopulationVaccinated
create table #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) 
over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on vac.location = dea.location and vac.date = dea.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population)*100 as PercentagePopulationVaccinated
from #PercentagePopulationVaccinated;


--creating view to store data for later visualisations
create view PercentPopulationVaccinated
as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) 
over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths$ dea
join PortfolioProject..CovidVaccinations$ vac
on vac.location = dea.location and vac.date = dea.date
where dea.continent is not null;

select * from PercentPopulationVaccinated;