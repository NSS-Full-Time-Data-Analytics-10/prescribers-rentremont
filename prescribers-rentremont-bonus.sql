--1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT npi)
FROM prescriber;
--25050

SELECT COUNT(DISTINCT npi)
FROM prescription;
--20592
----25050 - 20592 = 4458 numbers that appear in the prescriber table but not in the prescritpion table
--ALSO
SELECT COUNT(DISTINCT prescriber.npi) - COUNT(DISTINCT prescription.npi)
FROM prescriber
LEFT JOIN prescription
USING (npi)
--4458 

--2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

WITH drugs AS (SELECT generic_name, COUNT(*) AS drugs
				FROM drug
				GROUP BY generic_name)
SELECT specialty_description, generic_name, drugs
FROM prescriber, drug
FULL JOIN drugs
USING (generic_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name, specialty_description, drugs
ORDER BY drugs DESC
LIMIT 5
--The top 5 drugs prescribed by Family Practice prescribers is "PEN NEEDLE, DIABETIC", "SYRINGE AND NEEDLE,INSULIN,1ML", "SYRINGE-NEEDLE,INSULIN,0.5 ML", "SYRING-NEEDL,DISP,INSUL,0.3 ML", and "LEVONORGESTREL-ETHIN ESTRADIOL"

----b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

WITH drugs AS (SELECT generic_name, COUNT(*) AS drugs
				FROM drug
				GROUP BY generic_name)
SELECT specialty_description, generic_name, drugs
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
INNER JOIN drugs
USING (generic_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name, specialty_description, drugs
ORDER BY drugs DESC
LIMIT 5;
--The top 5 drugs prescribed by Cardiology are "PEN NEEDLE, DIABETIC", "SYRINGE AND NEEDLE,INSULIN,1ML", "SYRINGE-NEEDLE,INSULIN,0.5 ML", "SYRING-NEEDL,DISP,INSUL,0.3 ML", and "ALCOHOL ANTISEPTIC PADS"

----c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
WITH drugs AS (SELECT generic_name, COUNT(*) AS drugs
				FROM drug
				GROUP BY generic_name)
SELECT specialty_description, generic_name, drugs
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
INNER JOIN drugs
USING (generic_name)
WHERE specialty_description = 'Cardiology' 
	OR specialty_description = 'Family Practice'
GROUP BY generic_name, specialty_description, drugs
ORDER BY drugs DESC
LIMIT 10;
--The drugs that are in the top five prescribed by Family Practice prescribers and Cardiologists are "PEN NEEDLE, DIABETIC", "SYRINGE AND NEEDLE,INSULIN,1ML", "SYRINGE-NEEDLE,INSULIN,0.5 ML", and "SYRING-NEEDL,DISP,INSUL,0.3 ML".


--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
----a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5;

----b. Now, report the same for Memphis.
SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5;

----c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'KNOXVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_num_claims, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY total_num_claims DESC
LIMIT 5)
ORDER BY total_num_claims DESC

--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
(SELECT AVG(overdose_deaths) AS avg_overdose
FROM overdose_deaths) 
-- Average is 12.6052631578947368

SELECT county, overdose_deaths
FROM fips_county
INNER JOIN overdose_deaths
ON fips_county.fipscounty::integer = overdose_deaths.fipscounty
WHERE overdose_deaths > (SELECT AVG(overdose_deaths) AS avg_overdose
						FROM overdose_deaths) 
GROUP BY county, overdose_deaths.overdose_deaths
-- 81 counties over the average overdose death

--5.a. Write a query that finds the total population of Tennessee.
SELECT SUM(population) AS total_tn_pop
FROM population
-- Total TN population is 6597381

----b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
WITH total_tn_pop AS (SELECT SUM(population) AS total_tn_pop
						FROM population)
						
SELECT county, population, ((population/(SELECT SUM(population) AS total_tn_pop
											FROM population)) * 100) AS percentage
FROM population
INNER JOIN fips_county
USING (fipscounty)
GROUP BY county, population.population
ORDER BY percentage DESC




