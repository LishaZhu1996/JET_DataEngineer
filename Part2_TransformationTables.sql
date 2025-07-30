--Part2 Create all of the fact and dim tables

create table dwh.FactComicReview (
   SnapshotDate_id --To save difeerent snapshot data
  ,Review_id int NOT NULL
  ,Comic_id int NOT NULL
  ,Reviewer_id int NOT NULL
  ,ReviewDate_id int NOT NULL
  ,Author_id int NOT NULL
  ,ComicTitle nvarchar(1000)
  ,ComicAlt nvarchar (1000)
  ,CostPerComic decimal(8,2)
  ,ComicCreatedDate date
  ,Reviewer_Rate decimal(4,2) --Rate is between 1 and 10
  ,Review_Comments nvarchar(max)
  ,ReviewDuration_second decimal(8,2)
  ,IsReward bit
  ,RewardAmount decimal(8,2)
)
CREATE CLUSTERED INDEX IX_FactComicReview_Clustered
ON dwh.FactComicReview (Review_id); --Or set Review_id as primary Key
CREATE NONCLUSTERED INDEX IX_FactComicReview_ReviewLookup
ON dwh.FactComicReview (Review_id)
INCLUDE (Comic_id, Reviewer_id, Author_id);

create table dwh.DimReview (
   id int NOT NULL
  ,Reviewer_id int NOT NULL
  ,Author_id int NOT NULL
  ,Comic_num int NOT NULL
  ,Review_Date date NOT NULL
  ,Reviewer_Rate decimal(4,2) --Rate is between 1 and 10
  ,Review_Comments nvarchar(max)
  ,ReviewDuration_second decimal(8,2) --The number of time reviews is not enough, can create a measure using duration to see how long reviewers spend in each comic.
  ,IsReward bit
  ,RewardAmount decimal(8,2)
)
CREATE CLUSTERED INDEX IX_DimReview_Clustered
ON dwh.DimReview (id); --Or set id as primary Key

create table dwh.DimComicDetail (
   id int NOT NULL
  ,ComicDate_id INT
  ,Cost decimal(8,2)
  ,link nvarchar(1000)
  ,Img nvarchar(1000)
  ,news nvarchar(2500)
  ,safe_title nvarchar(1000)
  ,title nvarchar(1000)
  ,alt nvarchar(2500)
  ,[year] nvarchar(5)
  ,[month] nvarchar(5)
  ,[day] nvarchar(5)
  ,transcript nvarchar(max)
  ,extra_parts nvarchar(max)
  ,[checksum] BINARY (20) --For SCD type 2   
  ,[SCD_Start_Date] DATETIME2 (0) NOT NULL --For SCD type 2
  ,[SCD_End_Date] DATETIME2 (0) NOT NULL --For SCD type 2

)
CREATE CLUSTERED INDEX IX_DimComic_Clustered
ON dwh.DimComicDetail (id); --Or set id as primary Key

create table dwh.DimReviewer (
  id int NOT NULL
  ,ReviewerName nvarchar(100)
  ,Nationality nvarchar(100)
  ,Gender nvarchar(50)
  ,Birthday date
  ,AccountCreatedAt date
)
CREATE CLUSTERED INDEX IX_DimReviewer_Clustered
ON dwh.DimReviewer (id);--Or set id as primary Key

create table dwh.Author (
  id int NOT NULL
  ,AuthorName nvarchar(100)
  ,Nationality nvarchar(100)
  ,Gender nvarchar(50)
  ,Birthday date
  ,AccountCreatedAt date
)
CREATE CLUSTERED INDEX IX_DimAuthor_Clustered
ON dwh.Author (id);--Or set id as primary Key

create table dwh.DimDate(
   id int NOT NULL
  ,[Date] date
  ,[Year] int
  ,Month_num int
  ,Month_tx_long nvarchar(100)
  ,Month_tx_short nvarchar(100)
  ,[Day] int
  ,Year_Month_long nvarchar(100)
  ,Year_Month_short nvarchar(100)
  ,[WeekDay] nvarchar(100)
)
CREATE CLUSTERED INDEX IX_DimDate_Clustered
ON dwh.DimDate (id);--Or set id as primary Key


