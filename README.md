# Data-Cleaning-in-MYSQL
Here I have cleaned world layoff dataset using MYSQL

Here's the dataset used in this project : -- https://www.kaggle.com/datasets/swaptr/layoffs-2022

# Data Cleaning Project

## Overview

This project involves cleaning a dataset of company layoffs. The main objectives are to:

1. Remove duplicate records.
2. Standardize the data.
3. Handle null and blank values.
4. Eliminate unnecessary columns.

The cleaned data will be more reliable and useful for further analysis.

## Steps Involved in the Data Cleaning Process

### Step 1: Removing Duplicates

#### Create a Staging Table

We start by creating a staging table `layoffs_staging` which is a copy of the original `layoffs` table.

```sql
CREATE TABLE layoffs_staging LIKE layoffs;
INSERT layoffs_staging SELECT * FROM layoffs;
```

#### Assign Row Numbers

Since the table does not have a unique identifier, we assign row numbers to identify duplicates. The `ROW_NUMBER()` function is used for this purpose.

```sql
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;
```

#### Identify Duplicates

We use a common table expression (CTE) to identify duplicates where the row number is greater than 1.

```sql
WITH duplicate_cte AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;
```

#### Create a New Table for Cleaned Data

We create a new table `layoffs_staging2` to store the data without duplicates and include the row number for reference.

```sql
CREATE TABLE layoffs_staging2 (
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
```

#### Insert Data with Row Numbers

Insert data from the staging table into the new table while assigning row numbers.

```sql
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;
```

#### Remove Duplicates

Delete records where the row number is greater than 1 to remove duplicates.

```sql
DELETE FROM layoffs_staging2 WHERE row_num > 1;
```

### Step 2: Standardizing the Data

#### Remove Whitespaces

Trim whitespaces from relevant columns such as `company`.

```sql
UPDATE layoffs_staging2 SET company = TRIM(company);
```

#### Correct Spelling Errors

Standardize the `industry` column to correct spelling errors and inconsistencies.

```sql
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';
```

#### Standardize Country Names

Remove trailing periods and correct country names.

```sql
UPDATE layoffs_staging2 SET country = TRIM(TRAILING '.' FROM country) WHERE country LIKE 'United States%';
```

#### Format Dates

Convert the `date` column to a standard date format and change its data type to `DATE`.

```sql
UPDATE layoffs_staging2 SET date = STR_TO_DATE(date, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN date DATE;
```

### Step 3: Dealing with Null and Blank Values

#### Identify and Handle Null Values

Select rows with null values in critical columns and decide on actions such as deletion or imputation.

```sql
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```

#### Update Null Values

For columns where data can be populated based on existing information, perform updates.

```sql
UPDATE layoffs_staging2 SET industry = NULL WHERE industry = '';
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
```

### Step 4: Removing Unnecessary Columns

#### Delete Records with Critical Null Values

Remove rows where critical columns like `total_laid_off` and `percentage_laid_off` are null.

```sql
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```

#### Drop Temporary Columns

Remove the `row_num` column used for duplicate identification.

```sql
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;
```

## Final Check

Perform final checks to ensure data integrity and correctness.

```sql
SELECT * FROM layoffs_staging2;
```

## Conclusion

This data cleaning process involves creating a staging environment, identifying and removing duplicates, standardizing the dataset, handling null values, and finally removing unnecessary columns. The resulting dataset is clean and ready for further analysis.

By following these steps, the quality of the data is significantly improved, making it more reliable for any analytical or reporting purposes.
