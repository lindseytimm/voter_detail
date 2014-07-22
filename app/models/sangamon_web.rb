class SangamonWeb
  
  def self.address_count(street_number, pre_direction, street_name, city, zip)
    street_no = ""
    direction = ""
    cty = ""
    z = ""
    
    street_no = "AND a.street_number = TRIM('" + street_number + "') " if street_number > ""
    direction = "AND a.pre_direction = '" + pre_direction + "' " if pre_direction > ""
    cty = "AND c.code = '" + city + "' " if city > ""
    z = "AND a.zip = '" + zip + "' " if zip > ""

    
    sql = 
      "SELECT 
      	COUNT(DISTINCT CONCAT(cast(`a`.`district_group_id` as char(4)), CASE WHEN od.address_id IS NULL THEN '' ELSE CONCAT('_', CAST(od.old_district_id as char(4))) END)) as district_group_count,
      	COUNT(DISTINCT TRIM(CONCAT(IFNULL(a.pre_direction, ''), ' ', IFNULL(a.street_name, ''), ' ', IFNULL(a.street_suffix, '')))) as street_count
      FROM `voter`.`addresses` a
      LEFT OUTER JOIN `voter`.`cities` c
        ON a.city = c.name
      LEFT OUTER JOIN `voter`.`old_districts` od
		    ON a.id = od.address_id
      WHERE a.street_name LIKE CONCAT(TRIM('" + street_name.gsub("'", "''") + "'), '%')" +
      street_no +
      direction + 
      cty +
      z + ";"
      
    return DistrictGroup.find_by_sql sql

  end
  
  def self.results_1(street_number, pre_direction, street_name, city, zip)
    street_no = ""
    direction = ""
    cty = ""
    z = ""
    
    street_no = "AND a.street_number = TRIM('" + street_number + "') " if street_number > ""
    direction = "AND a.pre_direction = '" + pre_direction + "' " if pre_direction > ""
    cty = "AND c.code = '" + city + "' " if city > ""
    z = "AND a.zip = '" + zip + "' " if zip > ""
    
    sql = 
      "SELECT
          1 as results_code,
        	p.code as precinct_code, 
        	dg.code as geocode2, 
        	'' as geocode3,
        	vc.location_description as polling_place_name, 
        	'' as description, 
        	p.name as precinct_name,
        	CONCAT(vc.address_line_1, ', ', vc.city, ' ', vc.zip) as addr1, 
        	IFNULL(bs.ballot_style, '000') as ballot_type
      FROM voter.district_groups dg
      INNER JOIN
        	(SELECT 
          		`a`.`district_group_id`
        	FROM `voter`.`addresses` a
          LEFT OUTER JOIN `voter`.`cities` c
            ON a.city = c.name
            WHERE a.street_name LIKE CONCAT(TRIM('" + street_name.gsub("'", "''") + "'), '%')" +
            street_no +
            direction + 
            cty +
            z + "
        	GROUP BY 
          		`a`.`district_group_id`) dg1
        	ON dg.id = dg1.district_group_id
      INNER JOIN voter.district_groups_precincts dgp
        	ON dg.id = dgp.district_group_id
      INNER JOIN voter.precincts p
      	  ON dgp.precinct_id = p.id
      INNER JOIN voter.precinct_vote_centers pvc
      	  ON p.id = pvc.precinct_id
      INNER JOIN (SELECT * FROM voter.vote_centers WHERE election_day_center = 1) vc
      	  ON pvc.vote_center_id = vc.id
  	  LEFT OUTER JOIN
  		  (SELECT
  			  edgbs.district_group_id,
  			  ebs.name as ballot_style
  		  FROM (SELECT * FROM voter.elections WHERE election_date = (SELECT MAX(election_date) FROM voter.elections)) e
  		  INNER JOIN voter.election_ballot_styles ebs
  			  ON e.id = ebs.election_id
  		  INNER JOIN voter.election_district_group_ballot_styles edgbs
  			  ON ebs.id = edgbs.election_ballot_style_id
  		  WHERE ebs.federal <> 1
        AND ebs.jurisdiction_id = 38
  		  ) bs
  		  ON dg.id = bs.district_group_id;"
      
    return DistrictGroup.find_by_sql sql

  end
  
  def self.result_districts(street_number, pre_direction, street_name, city, zip)
    street_no = ""
    direction = ""
    cty = ""
    z = ""
    
    street_no = "AND a.street_number = TRIM('" + street_number + "') " if street_number > ""
    direction = "AND a.pre_direction = '" + pre_direction + "' " if pre_direction > ""
    cty = "AND c.code = '" + city + "' " if city > ""
    z = "AND a.zip = '" + zip + "' " if zip > ""
    
    sql = 
      "SELECT
          CASE WHEN dg1.old_district_id IS NOT NULL THEN 
        	  CASE WHEN dt.name = 'Ward' THEN 'Ward (New Effective 4/7/15)' ELSE dt.name END 
            ELSE dt.name
          END as district_type, 
          CASE WHEN dg1.old_district_id IS NOT NULL THEN 
        	  CASE WHEN dt.name = 'Ward' THEN CONCAT(d.report_name, ' (New)') ELSE d.report_name END 
            ELSE d.report_name
          END as district_name, 
          d.sequence
      FROM 
        	(SELECT 
          		`a`.`district_group_id`,
              `od`.`old_district_id`
        	FROM `voter`.`addresses` a
          LEFT OUTER JOIN `voter`.`old_districts` od
            ON a.id = od.address_id
          LEFT OUTER JOIN `voter`.`cities` c
            ON a.city = c.name
            WHERE a.street_name LIKE CONCAT(TRIM('" + street_name.gsub("'", "''") + "'), '%')" +
            street_no +
            direction + 
            cty +
            z + "
        	GROUP BY 
          		`a`.`district_group_id`,
              `od`.`old_district_id`) dg1
      INNER JOIN voter.district_groups_districts dgd
      	  ON dg1.district_group_id = dgd.district_group_id
      INNER JOIN voter.districts d
      	  ON dgd.district_id = d.id
      INNER JOIN voter.district_types dt
      	  ON d.district_type_id = dt.id
      WHERE d.county_wide = 0
      UNION SELECT DISTINCT 
          	'Ward (Current)' as district_type, 
          	CONCAT(d.report_name, ' (Current)') as district_name,
            dg.sequence - 5 as sequence
      FROM voter.addresses a
  	  INNER JOIN voter.old_districts od
  		  ON a.id = od.address_id
  	  INNER JOIN voter.districts d
  		  ON od.old_district_id = d.id
  	  LEFT OUTER JOIN `voter`.`cities` c
  		  ON a.city = c.name
      INNER JOIN voter.district_groups_districts dgd
        ON a.district_group_id = dgd.district_group_id
      INNER JOIN voter.districts dg
        ON dgd.district_id = dg.id
      WHERE dg.district_type_id = 67
      AND a.street_name LIKE CONCAT(TRIM('" + street_name.gsub("'", "''") + "'), '%')" +
      street_no +
      direction + 
      cty +
      z + "
      ORDER BY sequence;"
      
    return DistrictGroup.find_by_sql sql

  end  
  
  
  
  def self.results_16(street_number, pre_direction, street_name, city, zip)
    street_no = ""
    direction = ""
    cty = ""
    z = ""
    
    street_no = "AND a.street_number = TRIM('" + street_number + "') " if street_number > ""
    direction = "AND a.pre_direction = '" + pre_direction + "' " if pre_direction > ""
    cty = "AND c.code = '" + city + "' " if city > ""
    z = "AND a.zip = '" + zip + "' " if zip > ""
    
    sql = 
      "SELECT 
        16 as results_code,
      	IFNULL(`a`.`pre_direction`, '') as StreetPre,
      	TRIM(CONCAT(IFNULL(a.street_name, ''), ' ', IFNULL(a.street_suffix, ''))) as StreetName
      FROM `voter`.`addresses` a
      LEFT OUTER JOIN `voter`.`cities` c
        ON a.city = c.name
      WHERE a.street_name LIKE CONCAT(TRIM('" + street_name.gsub("'", "''") + "'), '%')" +
      street_no +
      direction + 
      cty +
      z + "
      GROUP BY 
      	`a`.`pre_direction`,
      	TRIM(CONCAT(IFNULL(a.street_name, ''), ' ', IFNULL(a.street_suffix, '')));"
      
    return DistrictGroup.find_by_sql sql

  end  
  
end

