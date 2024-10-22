use md_water_services ;

-- joining location to visits
select lo.province_name ,lo.town_name, 
       vi.visit_count ,vi.location_id
from location  as lo inner join visits as vi 
      on lo.location_id=vi.location_id;

-- join the water_source table
select lo.province_name ,lo.town_name, 
       vi.visit_count ,vi.location_id, 
       ws.type_of_water_source , ws.number_of_people_served
from location  as lo inner join visits as vi 
      on lo.location_id=vi.location_id
       inner join water_source as ws  on vi.source_id = ws.source_id ;
       
-- Remove WHERE visits.location_id = 'AkHa00103' and add the visits.visit_count = 1 as a filter.
select lo.province_name ,lo.town_name, 
       vi.visit_count ,vi.location_id, 
       ws.type_of_water_source , ws.number_of_people_served
from location  as lo inner join visits as vi 
      on lo.location_id=vi.location_id
       inner join water_source as ws  on vi.source_id = ws.source_id 
where vi.location_id = 'AkHa00103' ;

-- To fix this, we can just select rows where visits.visit_count = 1.
select lo.province_name ,lo.town_name, 
       vi.visit_count ,vi.location_id, 
       ws.type_of_water_source , ws.number_of_people_served
from location  as lo inner join visits as vi 
      on lo.location_id=vi.location_id
       inner join water_source as ws  on vi.source_id = ws.source_id 
where vi.visit_count=1;

 -- Since we have confirmed the joins work correctly
 -- we can remove the location_id and visit_count columns and 
 -- Add the location_type column from location and time_in_queue from visits to our results set.
 select lo.province_name ,lo.town_name, 
       ws.type_of_water_source , lo.location_type ,
       ws.number_of_people_served,vi.time_in_queue 
from location  as lo inner join visits as vi 
      on lo.location_id=vi.location_id
       inner join water_source as ws  on vi.source_id = ws.source_id 
where vi.visit_count=1;

-- Now we need to grab the results from the well_pollution table.
SELECT
ws.type_of_water_source,
lo.town_name,
lo.province_name,
lo.location_type,
ws.number_of_people_served,
vi.time_in_queue,
wp.results
from visits as vi 
     left join well_pollution as wp  on vi.source_id = wp.source_id 
     join  location as lo  on  vi.location_id=lo.location_id
     join water_source as ws on vi.source_id =ws.source_id
where vi.visit_count=1;

-- Let create  a View for this Table 
create view combined_analysis_table as 
SELECT
ws.type_of_water_source,
lo.town_name,
lo.province_name,
lo.location_type,
ws.number_of_people_served,
vi.time_in_queue,
wp.results
from visits as vi 
     left join well_pollution as wp  on vi.source_id = wp.source_id 
     join  location as lo  on  vi.location_id=lo.location_id
     join water_source as ws on vi.source_id =ws.source_id
where vi.visit_count=1;

 -- THE LAST ANALYSIS
 --  Create pivot table! This time, we want to break down our data into provinces and source types. 
 with province_total as(
     select province_name , sum(number_of_people_served) as total_ppl_serv
     from combined_analysis_table
     group by  province_name)
     
select pt.province_name, 
       round(sum(case when ct.type_of_water_source='river'
        then number_of_people_served else 0 end)*100/total_ppl_serv,0) as River ,
        round(sum(case when ct.type_of_water_source='well'
        then number_of_people_served else 0 end)*100/total_ppl_serv,0) as Well ,
        round(sum(case when ct.type_of_water_source='tap_in_home'
        then number_of_people_served else 0 end)*100/total_ppl_serv,0) as Tap_in_home ,
        round(sum(case when ct.type_of_water_source='tap_in_home_broken'
        then number_of_people_served else 0 end)*100/total_ppl_serv,0) as Tap_in_home_broken ,
        round(sum(case when ct.type_of_water_source='shared_tap'
        then number_of_people_served else 0 end)*100/total_ppl_serv,0) as Shared_tap 
      
from combined_analysis_table as ct join province_total as pt 
    on ct.province_name=pt.province_name
group by ct.province_name
order by ct.province_name;

 --  Create pivot table! This time, we want to break down our data into town  and source types. 
 WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN 
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- Let's store it as a temporary table first, so it is quicker to access
create temporary table  town_aggregated_water_source
 WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
ct.province_name,
ct.town_name,
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN 
town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
ct.province_name,
ct.town_name
ORDER BY
ct.town_name;

-- Show the table result
select province_name , town_name ,
       tap_in_home,tap_in_home_broken,
	   shared_tap, well, river
from town_aggregated_water_source
 order by  province_name;
 
 -- which town has the highest ratio of people who have taps, but have no running water?
SELECT province_name,
		town_name,
		ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *100,0) AS Pct_broken_taps
FROM town_aggregated_water_source;

-- CREATE A PROGRESS TABLE 
CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
Date_of_completion DATE,
Comments TEXT
);

-- Complete the table
INSERT INTO project_progress (
    `source_id`,
    `Address`,
    `Town`,
    `Province`,
    `Source_type`,
    `Improvement`
)
SELECT
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN well_pollution.results = "Contaminated: Chemical" THEN "Install RO filter"
        WHEN well_pollution.results = "Contaminated: Biological" THEN "Install UV and RO filter"
        WHEN water_source.type_of_water_source = "river" THEN "Drill well"
        WHEN water_source.type_of_water_source = "shared_tap" AND visits.time_in_queue >= 30
            THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby"
                            -- " tap", IF(FLOOR(visits.time_in_queue / 30) > 1, "s", ""), " nearby" -- comment line above and then uncomment this if you want: 1 tap, 2 taps, 3 taps...
                        )
        WHEN water_source.type_of_water_source = "tap_in_home_broken" THEN "Diagnose local infrastructure"
        ELSE NULL
    END Improvements
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    -- AND one of the following (OR) options must be true as well.
    AND ( well_pollution.results != 'Clean'
            OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
            OR ( water_source.type_of_water_source = 'shared_tap'AND visits.time_in_queue >= 30)
            );
            