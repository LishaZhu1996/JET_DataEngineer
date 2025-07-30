/*
##########################################################################
-- Name             : dwh.Load_factComicReview
-- Date             : 2025-07-30
-- Author           : LZ
-- Purpose          : Load data to dwh.FactComicReview
-- Usage            : To get fact table for comic review
##########################################################################
-- version	user	Date		Change  
-- 1.0		LZ		20250730	Initial version;
-- 1.1		LZ		20250731	Other change (Examle) -- log the change here
##########################################################################
*/
CREATE PROCEDURE [dwh].[Load_ComicBasic] 
-- Can set some parameter to save the running version in log table
@SnapshotDate DATETIME2(0),
@PipelineTriggerTime DATETIME2

AS
BEGIN
	
	DECLARE @SnapshotDate_id INT
	SET @SnapshotDate_id = CAST(CONVERT(CHAR(8), @SnapshotDate, 112) AS INT);

	BEGIN TRAN
	  	   	   	  	
	-- Delete the same SnapshotDate_id in case we need to execute the SP multiple times a day
	DELETE FROM TABLE dwh.FactComicReview where SnapshotDate_id = CAST(CONVERT(CHAR(8), @SnapshotDate, 112) AS INT)

	--insert 
	INSERT INTO dwh.FactComicReview
	(	
	 SnapshotDate_id              
	,Review_id
	,Comic_id
	,Reviewer_id
	,ReviewDate_id
	,Author_id
	,ComicTitle
	,ComicAlt
	,CostPerComic
	,ComicCreatedDate
	,Reviewer_Rate
	,Review_Comments 
	,ReviewDuration_second
	,IsReward 
	,RewardAmount 

) 
	SELECT @SnapshotDate_id      
	,DR.Review_id
	,DC.id AS Comic_id
	,DRR.id AS Reviewer_id
	,DRR.id AS ReviewDate_id
	,DA.id AS Author_id
	,CD.Title  AS ComicTitle
	,CD.Alt AS ComicAlt
	,CD.Cost AS CostPerComic
	,CAST(CONCAT([year],[month],[day]) AS date)  AS ComicCreatedDate
	,DR.Reviewer_Rate
	,DR.Review_Comments 
	,DR.ReviewDuration_second
	,DR.IsReward 
	,DR.RewardAmount 
	
    FROM dwh.DimReview DR

	LEFT JOIN dwh.DimComicDetail DC
	ON DR.Comic_num = DC.id

	LEFT JOIN dwh.DimReviewer DRR
	ON DR.Reviewer_id = DRR.id

	LEFT JOIN dwh.DimAuthor DA
	ON DR.Author_id = DA.id


END