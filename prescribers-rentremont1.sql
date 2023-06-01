--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT prescription.npi, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber 
ON prescription.npi = prescriber.npi
GROUP BY prescription.npi
ORDER BY total_claim DESC NULLS LAST;
-- npi 1881634483	CLAIMS 99707

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT prescriber.nppes_provider_first_name AS first, prescriber.nppes_provider_last_org_name AS last, prescriber.specialty_description AS specialty, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber 
ON prescription.npi = prescriber.npi
GROUP BY first, last, specialty
ORDER BY total_claim DESC NULLS LAST;
--BRUCE PENDLEY	"Family Practice"	99707

--2.a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT prescriber.specialty_description AS specialty, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber 
ON prescription.npi = prescriber.npi
GROUP BY specialty
ORDER BY total_claim DESC NULLS LAST;
--"Family Practice"	 WITH 9752347 CLAIMS

--b. Which specialty had the most total number of claims for opioids?
SELECT prescriber.specialty_description AS specialty, SUM(total_claim_count) AS total_claim, prescription.drug_name AS name, drug.opioid_drug_flag AS opioid
FROM prescription
INNER JOIN prescriber 
ON prescription.npi = prescriber.npi
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y' 
GROUP BY specialty, name, opioid
ORDER BY total_claim DESC NULLS LAST;
--"Nurse Practitioner"	351836 OPIOID CLAIMS


--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT prescriber.specialty_description AS specialty, prescription.drug_name AS name, prescription.total_claim_count AS total_claim
FROM prescription
FULL JOIN prescriber 
ON prescription.npi = prescriber.npi
GROUP BY specialty, name, total_claim
ORDER BY total_claim DESC NULLS FIRST;
-- Yes 92 specialties have no prescriptions

----d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH total_opioid AS (SELECT drug_name, npi, specialty_description, 	
					  		SUM(total_claim_count) AS total_opioid
						FROM prescriber
						FULL JOIN prescription
						USING (npi)
						FULL JOIN drug
						USING (drug_name)
						WHERE opioid_drug_flag = 'Y'
						GROUP BY specialty_description, drug_name, npi)
SELECT specialty_description, (total_opioid/SUM(total_claim_count) * 100) AS percentage
FROM prescription
FULL JOIN total_opioid
USING (drug_name)
GROUP BY specialty_description, total_opioid
ORDER BY percentage DESC NULLS LAST
--"Gastroenterology" with 12.82051282051282051300 % and
--"Rheumatology" with 12.61467889908256880700 %


--3. a. Which drug (generic_name) had the highest total drug cost?
SELECT drug.generic_name, SUM(prescription.total_drug_cost::money) AS total_drug
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY total_drug DESC;
--"INSULIN GLARGINE,HUM.REC.ANLOG"	WITH A TOTAL DRUG COST OF $104,264,066.35

--b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT drug.generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2) AS cost_per_day
FROM drug
INNER JOIN prescription
ON drug.drug_name = prescription.drug_name
GROUP BY drug.generic_name
ORDER BY cost_per_day DESC;
--"C1 ESTERASE INHIBITOR"	WITH A COST PER DAY OF $3495.22


--4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_type

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT drug_type, SUM(total_drug_cost::money) AS total
FROM (SELECT drug_name, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug
	ORDER BY drug_type)AS type
INNER JOIN prescription
ON type.drug_name = prescription.drug_name
GROUP BY drug_type
ORDER BY total DESC;
-- More money was spent on opioids than antibiotics with $105,080,626.37 being spent on opioids and $38,435,121.26 being spent on antibiotics.


--5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%'
-- There are 10 CBSAs in TN.

----b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, cbsa, SUM(population) AS total_pop
FROM cbsa
LEFT JOIN population
ON cbsa.fipscounty = population.fipscounty
GROUP BY cbsaname, cbsa
ORDER BY total_pop DESC NULLS LAST
--"Nashville-Davidson--Murfreesboro--Franklin, TN" has the largest combined population of 1830410. "Morristown, TN" has the smallest combined population of 116352.

----c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, population
FROM fips_county
INNER JOIN population
ON fips_county.fipscounty = population.fipscounty
LEFT JOIN cbsa
ON fips_county.fipscounty = cbsa.fipscounty
WHERE cbsa IS NULL
ORDER BY population DESC
-- The largest county not included in a CBSA is Sevier with a population of 95523. 


--6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000

----b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT prescription.drug_name, total_claim_count, drug_type
FROM (SELECT drug_name, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug
	ORDER BY drug_type)AS type
INNER JOIN prescription
USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC


---- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS name
FROM prescriber

SELECT prescription.drug_name, total_claim_count, drug_type, CONCAT(prescriber.nppes_provider_first_name, ' ', prescriber.nppes_provider_last_org_name) AS name 
FROM (SELECT drug_name, 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
	FROM drug
	ORDER BY drug_type)AS type
INNER JOIN prescription
ON type.drug_name = prescription.drug_name
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE total_claim_count >= 3000

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
-----a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name, specialty_description, nppes_provider_city, opioid_drug_flag
FROM prescriber, drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'


---- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi, drug.drug_name, SUM(total_claim_count) AS total_claims
FROM prescriber, drug
FULL JOIN prescription
USING (drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'	
GROUP BY prescriber.npi, drug.drug_name	
	

----c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi, drug.drug_name, COALESCE((SUM(total_claim_count)), 0) AS total_claims
FROM prescriber, drug
FULL JOIN prescription
USING (drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'	
GROUP BY prescriber.npi, drug.drug_name	
