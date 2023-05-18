DROP TABLE IF EXISTS sections;
DROP TABLE IF EXISTS forests;
DROP TABLE IF EXISTS managers;

CREATE TABLE managers(
  id serial PRIMARY KEY,
  user_name varchar(64) UNIQUE NOT NULL,
  password varchar(64) NOT NULL
);

INSERT INTO managers(user_name, password) 
  VALUES('admin', '$2a$12$GQCDJxayIvqdP1y7w7pcMOA1R1nEmZsT6NBIZQ7hlmEkpdz2lQRKe');

CREATE TABLE forests(
  id serial PRIMARY KEY,
  manager_id int REFERENCES managers(id) ON DELETE CASCADE,
  name varchar(200) NOT NULL,
  description text NOT NULL,
  unique(manager_id, name)
);

INSERT INTO forests(manager_id, name, description) VALUES
(1, 'AA burnt', 'sorting ex'),
(1, 'AA singed', 'sorting ex'),
(1, 'AA no impact', 'sorting ex'),

(1, 'Tiger forest', 'Mostly mountainous'),
(1, 'Issaquah National Forest', 'Largely developed'),
(1, 'Rocky Beach', 'Coastal OR'),
(1, 'Sleeping Bear', 'Northern MI, really nice actually'),
(1, 'BLM A2', 'Nevada'),
(1, 'BLM B7', 'Nevada'),
(1, 'BLM B8', 'Nevada'),
(1, 'BLM A3', 'Nevada'),
(1, 'BLM A6', 'Nevada'),
(1, 'Theiving Squirrel', 'they are everywhere');


CREATE TABLE sections(
  id SERIAL PRIMARY KEY,
  forest_id int REFERENCES forests(id) ON DELETE CASCADE,
  acerage decimal(10, 2) NOT NULL,
  name varchar(200) NOT NULL, 
  description text,
  impacted BOOLEAN NOT NULL,
  impact_date DATE, 
  UNIQUE(forest_id, name)
);

INSERT INTO sections(forest_id, acerage, name, description, impacted, impact_date)
VALUES
(1, 20, 'A1', 'lorem ipsum', true, '2022-07-04'),
(1, 15, 'A2', 'glacier valley lorem ipsum', true, '2022-07-04'),
(1, 7, 'A3', 'north ridge lorem ipsum', true, '2022-07-04'),
(1, 17, 'A4', 'glacier valley lorem ipsum', true, '2022-07-04'),
(1, 20, 'A5', 'lorem ipsum', true, '2022-07-04'),
(1, 17, 'A6', 'glacier valley lorem ipsum', true, '2022-07-04'),
(1, 20, 'A7', 'north ridge lorem ipsum', true, '2022-07-04'),
(1, 17, 'A8', 'glacier valley lorem ipsum', true, '2022-07-04'),
(1, 20, 'B1', 'lorem ipsum', true, '2022-07-04'),
(1, 17, 'B2', 'glacier valley lorem ipsum', true, '2022-07-04'),
(1, 20, 'B3', 'north ridge lorem ipsum', true, '2022-07-04'),
(1, 17, 'B5', 'glacier valley lorem ipsum', true, '2022-07-04'),

(2, 20, 'A1', 'north ridge lorem ipsum', true, '2022-07-04'),
(2, 17, 'A2', 'glacier valley lorem ipsum', true, '2022-07-04'),
(2, 20, 'A5', 'north ridge lorem ipsum', true, '2022-07-04'),
(2, 40, 'A8', 'glacier valley lorem ipsum', true, '2022-07-04'),
(2, 55, 'B3', NULL, false, NULL), 
(2, 20, 'B4', NULL, false, NULL), 
(2, 20, 'B5', NULL, false, NULL), 
(2, 20, 'B6', NULL, false, NULL),

(3, 20, 'C1', NULL, false, NULL),
(3, 20, 'C2', NULL, false, NULL),
(3, 20, 'C3', NULL, false, NULL),
(3, 20, 'C4', NULL, false, NULL),

(4, 20, 'B1', NULL, false, NULL), 
(4, 20, 'B2', NULL, true, '2022-07-04'),
(4, 20, 'B3', NULL, true, '2019-07-04'), 
(4, 20, 'B4', NULL, false, NULL), 
(4, 20, 'B5', NULL, false, NULL), 
(4, 20, 'B6', NULL, true, '2019-09-25'), 

(5, 20, 'C1', NULL, true, '2019-09-25'),
(5, 20, 'C2', NULL, false, NULL),
(5, 20, 'C3', NULL, false, NULL),
(5, 20, 'C4', NULL, true, '2022-09-25'),

(6, 20, 'B3', NULL, true, '2019-07-04'), 
(6, 20, 'B4', NULL, false, NULL), 
(6, 20, 'B5', NULL, false, NULL), 
(6, 20, 'B6', NULL, true, '2019-09-25'), 

(7, 20, 'C1', NULL, true, '2019-09-25'),
(7, 20, 'C2', NULL, false, NULL),
(7, 20, 'C3', NULL, false, NULL),
(7, 20, 'C4', NULL, true, '2022-09-25'),

(8, 20, 'B3', NULL, true, '2019-07-04'), 
(8, 20, 'B4', NULL, false, NULL), 
(8, 20, 'B5', NULL, false, NULL), 
(8, 20, 'B6', NULL, true, '2019-09-25'), 

(8, 20, 'C1', NULL, true, '2019-09-25'),
(8, 20, 'C2', NULL, false, NULL),
(8, 20, 'C3', NULL, false, NULL),
(8, 20, 'C4', NULL, true, '2022-09-25');
