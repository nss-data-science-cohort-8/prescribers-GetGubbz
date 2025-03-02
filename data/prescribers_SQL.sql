-- 1. 
   -- a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. */
SELECT npi, SUM(total_claim_count) AS highest_claim
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi
ORDER by highest_claim DESC
LIMIT 1;

   -- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims. */
SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS highest_claim
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER by highest_claim DESC
LIMIT 1;

-- 2. 
    -- Which specialty had the most total number of claims (totaled over all drugs)? */
SELECT npi, specialty_description, SUM(total_claim_count) AS highest_claim
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY npi, specialty_description
ORDER by highest_claim DESC
LIMIT 1;

   -- b. Which specialty had the most total number of claims for opioids? */
SELECT specialty_description, SUM(total_claim_count) AS highest_claim
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
ON prescription.drug_name = drug.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY highest_claim DESC
LIMIT 1;

   -- c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table? */
SELECT prescriber.specialty_description, COUNT(prescription.*) AS prescription_count  
FROM drug
LEFT JOIN prescription ON drug.drug_name = prescription.drug_name 
FULL JOIN prescriber ON prescriber.npi = prescription.npi
WHERE prescriber.specialty_description IS NOT NULL
GROUP BY prescriber.specialty_description
HAVING COUNT(prescription.*) = 0
ORDER BY prescription_count;

   -- d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT specialty_description,
	(SELECT COUNT(drug_name)
	FROM drug
	WHERE opioid_drug_flag = 'Y')/SUM(total_claim_count)*100 AS percentage_opioid
FROM prescriber AS pr
INNER JOIN prescription AS pn
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
GROUP BY specialty_description
ORDER BY percentage_opioid DESC;

SELECT specialty_description, SUM(is_opioid)/SUM(total_claim_count)*100 AS percentage_opioid
FROM prescriber AS pr
INNER JOIN prescription AS pn
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
INNER JOIN (SELECT drug_name, CASE
			WHEN opioid_drug_flag = 'Y' THEN 1
			ELSE 0
			END AS is_opioid
			FROM drug)
USING(drug_name)
GROUP BY specialty_description
ORDER BY percentage_opioid DESC;


-- 3. 
    --a. Which drug (generic_name) had the highest total drug cost? */
SELECT d.generic_name, MAX(p.total_drug_cost) AS max_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY generic_name
ORDER BY max_cost DESC;


    --b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.** */
SELECT d.generic_name, MAX(p.total_drug_cost/p.total_day_supply) AS max_cost_per_day
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY generic_name
ORDER BY max_cost_per_day DESC;

--4. 
   -- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
CASE 
	WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug;

   -- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT CAST(SUM(p.total_drug_cost) AS MONEY) AS money,
CASE 
	WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	ELSE 'neither'
END AS drug_type
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY drug_type
ORDER BY money DESC;

--5. 
   -- a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN' OR cbsaname LIKE '%,TN%'
GROUP BY cbsaname;

   -- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
(SELECT cbsaname, SUM(population) AS population, 'largest' AS new_column
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY population DESC
LIMIT 1)

UNION

(SELECT cbsaname, SUM(population) AS population, 'smallest' AS new_column
FROM cbsa
INNER JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY population
LIMIT 1);

   -- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT *
FROM cbsa
RIGHT JOIN population
USING(fipscounty)
RIGHT JOIN fips_county
USING(fipscounty)
WHERE cbsa IS NULL AND population IS NOT NULL
ORDER BY population DESC
LIMIT 1;

--6. 
   -- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

   -- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, p.total_claim_count,
CASE
	WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'N/A'
END AS is_opioid
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
WHERE p.total_claim_count >= 3000;

   -- c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT pre.nppes_provider_first_name || ' ' || pre.nppes_provider_last_org_name, drug_name, p.total_claim_count,
CASE
	WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
	ELSE 'N/A'
END AS is_opioid
FROM prescription AS p
INNER JOIN drug AS d
USING(drug_name)
RIGHT JOIN prescriber AS pre
USING(npi)
WHERE p.total_claim_count >= 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

   -- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

   -- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
   -- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT pn.npi, pn.drug_name, pn.total_claim_count, SUM(pn.total_claim_count) AS total_claims_per_drug_per_prescriber
FROM prescription AS pn
INNER JOIN drug AS d ON d.drug_name = pn.drug_name
INNER JOIN prescriber AS pb ON pb.npi = pn.npi 
WHERE nppes_provider_city = 'NASHVILLE' 
	AND specialty_description = 'Pain Management'
	AND (opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y')  
GROUP BY pn.npi, pn.drug_name, pn.total_claim_count
ORDER BY total_claims_per_drug_per_prescriber DESC
;

