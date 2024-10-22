use md_water_services;
SHOW TABLES	;
/*data_dictionary
employee
global_water_access
location
visits
water_quality
water_source
well_pollution*/

/* I will use the location table to check whether the data was imported correctly */

SELECT*
FROM 
	location ;
    
-- and also the visit table

SELECT*
FROM
	visits;
    
--  water_source table to see what a 'source' is. Normally "_id" columns are related to another table.
    
SELECT*
FROM
	water_source ;

--   a SQL query to find all the unique types of water sources

SELECT  DISTINCT
	type_of_water_source
FROM
	water_source;
    
-- Unpack the visits to water sources
/* SQL query that retrieves all records from this table where the time_in_queue is more than  500 min. */

SELECT *
FROM 
		visits
WHERE
	time_in_queue >500
    ;
    
-- a couple of these source_id values from our results.

SELECT *
FROM
	water_source
WHERE
	source_id IN 	('AkRu05234224','HaZa21742224')
    ;
    
-- Assess the quality of water sources

/* a query to find records where the subject_quality_score is 10 -- only looking for home taps -- and where the source
was visited a second time.?*/

SELECT
	water_quality.record_id,
	subjective_quality_score,
    type_of_water_source,
 water_quality.visit_count AS vs
FROM
	water_quality,
    water_source,
    visits as vs
WHERE
	subjective_quality_score = '10'
AND
	type_of_water_source  in ('tap_in_home')
AND 
	vs.visit_count  > 2	
    ;
    
    
SELECT COUNT(*) AS row_count
FROM
	md_water_services.water_quality
WHERE
	subjective_quality_score = '10'
AND 
	visit_count  = 2
;
    
-- Investigate pollution issues
-- Find the right table and print the first few rows to check a few rows.
SELECT *
FROM 
	well_pollution 
LIMIT 5
;

--  a query that checks if the results is Clean but the biological column is > 0.01.

SELECT*
FROM 
	well_pollution	
WHERE 
	biological > '0.01'
AND 
	results = 'clean'   
    ;
    /* To find these descriptions, we will search for the word Clean with additional characters after it.
    As this is what separates incorrect descriptions from the records that should have "Clean".*/
    
SELECT *
FROM 
well_pollution 
WHERE description LIKE  ('clean_%')
;

/*Looking at the results two different descriptions that need to fixed:
1. All records that mistakenly have Clean Bacteria: E. coli should updated to Bacteria: E. coli*/
UPDATE
  well_pollution 
SET
  description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
  well_pollution 
SET
  description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';

-- case c
UPDATE 
 well_pollution 
SET results = 'Contaminated: Biological'
 WHERE
biological > 0.01 AND  results = 'Clean';

CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT
*
FROM
md_water_services.well_pollution
);

SET SQL_SAFE_UPDATES = 0;

UPDATE
well_pollution_copy
SET
description = 'Bacteria
:
E
. coli'
WHERE
description = 'Clean Bacteria
:
E
. coli';
UPDATE
well_pollution_copy
SET
description = 'Bacteria
: Giardia Lamblia'
WHERE
description = 'Clean Bacteria
: Giardia Lamblia';
UPDATE
well_pollution_copy
SET
results = 'Contaminated
: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

SELECT
*
FROM
well_pollution_copy
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);