-- DATA CLEANING 




SELECT *
FROM layoffs;


-- 1. Remove Duplicates
-- 2. Standardize the Data (spelling checks and other stuffs)
-- 3. Deal with Null Values or Blank Values
-- 4. Remove any columns that are not necessary


CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;


SELECT *
FROM layoffs_staging;



-- STARTING THE DATA CLEANING PROCESS:



--  REMOVING DUPLICATES  (STEP - 1)


-- Since we don't have a unique id so we have to assign a row number/value to our dataset.
-- This will assign row_numbers 

SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, industry, total_laid_off, percentage_laid_off, 'date') as row_num
FROM layoffs_staging;


-- Here we're selecting everything that has row_num that is greater than 1 i.e. may be duplicate
-- We'll get all the values that might be potentially a duplicate value 
-- Based on that particular result we'll filter the data

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- From the list of values that had row_num greater than 2
-- We're choosing a company name just to make sure if it's correct or not
-- The company 'Casper' has 3 values and two of them are duplicate (checked after running the code)
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';



-- Now we have to create new table with similar attributes of old table and insert row_num as a new column there

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Checking if the new table is created or not
SELECT *
FROM layoffs_staging2;


-- Inserting everything from old table and also assigning row_num and inserting them too in new table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER( 
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;


-- Recheck if everything is inserted or not
SELECT *
FROM layoffs_staging2;


-- select everything with row_value greater than 1 (duplicates)
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- deleting the duplicates make sure to select greater than 1 so that one of the duplicates gets deleted not all
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;

-- checking if the duplicates still exists or not
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;



-- STANDARDIZING THE DATA   (STEP - 2)



SELECT *
FROM layoffs_staging2;

-- Removing Whitespaces

-- company column
SELECT company, TRIM(company)
FROM layoffs_staging2;  

-- Updating the table and removing whitespaces from company column
UPDATE layoffs_staging2
SET company = TRIM(company);

-- industry column

-- checking errors in industry column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;   -- we'll see some industry being common but named abit differently 

-- We found there's some spelling errors and naming errors in crpto industry

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Updating the naming mistake
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- location column
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;  -- it looks like there's no error in location column


-- country column
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) -- trailing means go to last occurung character
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- date column
SELECT date
FROM layoffs_staging2;

SELECT date,
str_to_date(date, '%m/%d/%Y') -- setting it to 2020-12-28 format
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = str_to_date(date, '%m/%d/%Y');  -- updating the format

ALTER table layoffs_staging2
MODIFY COLUMN date DATE;  -- atering the data type from text to DATE





-- DEALING WITH NULL VALUES AND BLANK VALUES (STEP - 3)



SELECT *
FROM layoffs_staging2;

-- selecting everything that has total_laid_off & percentage_laid_off NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL;   -- we'll most likely remove this rows in next step i.e. step 4


-- checking if there's blank value in industry column
SELECT DISTINCT industry
FROM layoffs_staging2;


-- We need to populate or fill the data if we can
-- So we're selecting everything that has industry NULL
-- We can populate some of them
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL   
OR industry = '';

-- We can set the value NULL to blank values so it's easy to update later on
UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

-- There's blank value or now null value in Airbnb's industry column
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';


-- We're joining the same table to itself so we can see what data can be filled in 
-- Based on other data of Airbnb, we can see it belongs in Travel industry
-- Basically we're saying, select one column which has NULL values or blank values in TABLE 1 
-- and select one column which has filled value in TABLE 2 of join
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;


-- Now we're updating the table and inserting values to rows with NULL value
-- we're selecting t1.industry where values are NULL
-- and setting it's value i.e t2.industry where values are NOT NULL

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- We can check now blank values are updated in Industry column 
-- We'll deal with the NULL values in next step
SELECT DISTINCT industry
FROM layoffs_staging2;





-- REMOVING UNNECESSARY COLUMNS (STEP - 4)

SELECT *
FROM layoffs_staging2;



-- selecting everything that has total_laid_off & percentage_laid_off NULL
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL; 


-- deleting everything that has total_laid_off & percentage_laid_off NULL
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND 
percentage_laid_off IS NULL; 


SELECT *
FROM layoffs_staging2;


-- DROPPPING DOWN row_num because we won't need them anymore

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

