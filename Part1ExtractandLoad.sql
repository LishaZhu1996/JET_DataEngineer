--Lisha Zhu assignment for Data Engineer role
-- SQL part

-- This part is to create a control table for the first part of Extract and loading
CREATE TABLE tmp.EntityControlTable 
-- this control table is created for the entity management

-- for now, from API, I can only get a part of the data containing some basic comic data. My assumption is that in real usage/future, the whole project will contain more than one aspect
-- in that case, I mocked some other entities, for example, title related table

-- also, for now, the record is manually inserted into the table. The ideal situation for the management point of view as well as scalability side, 
-- better to get another API which contain the JSON schema for the table strucure, including the entityname, columns name and column type in each entity
-- so that, we can create the automatic script that generate this control table and real table based on those meta data to aviod any potential issue
(
Id INT NOT NULL, --Indicate the id for each entity
EntityName NVARCHAR(100) NOT NULL, -- Indicate the name of the entity
Num_Max_DB INT NULL, --Used as a watermark, based on the strucure of the API, so we can decide to have a full load or increamental load from APIs
LastAttemptDatetime DATETIME2 NULL, -- Indicate the last time/attempt we try to get the data through APIs
BasicEndpointurl NVARCHAR(1000) NOT NULL, --Indicate different endpoint url used to load data for different entity
Fullload INT NOT NULL --This value will be passed from the pipeline when it is triggered, 1 = fullload and 0 = deltaload
)

-- manually insert the value in 
-- iitial Num_Max_DB and the LastAttemptDatetime is null
INSERT INTO tmp.EntityControlTable (Id, EntityName, Num_Max_DB, LastAttemptDatetime,BasicEndpointurl,Fullload)
VALUES 
(1, 'Comics_basic', NULL, NULL,'https://xkcd.com/info.0.json',1),
(2, 'Title', NULL, NULL, 'Other URL example',1)


-- Create the ComicsBasic table for data loading from APIS
CREATE TABLE tmp.ComicsBasic(
[month] NVARCHAR(50) NOT NULL,
[num] INT NOT NULL,
[link] NVARCHAR(1000) NULL,
[year] NVARCHAR(5) NOT NULL,
[news] NVARCHAR(2500) NULL,
[safe_title] NVARCHAR(500) NOT NULL,
[transcript] NVARCHAR(max) NULL,
[alt] NVARCHAR(500) NULL,
[img] NVARCHAR(500) NOT NULL,
[title] NVARCHAR(500) NOT NULL,
[day] NVARCHAR(5) NOT NULL,
[extra_parts] NVARCHAR(2500) NULL)

CREATE UNIQUE CLUSTERED INDEX CX_ComicsBasic_Num
ON tmp.ComicsBasic (num); -- based on my understanding, num is the unique indetifier

CREATE NONCLUSTERED INDEX IX_ComicsBasic_YearMonthDay
ON tmp.ComicsBasic ([year], [month], [day])
INCLUDE (num);  -- based on my understanding, year, month, day as well as num will be used quite often in where/join/group by etc, thus created this index to improve the performance
