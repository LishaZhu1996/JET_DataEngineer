/*
##########################################################################
-- Name             : dwh.Load_ComicBasic
-- Date             : 2025-07-30
-- Author           : LZ
-- Purpose          : Load data to dwh.DimComicDetail
-- Usage            : Get data from tmp.ComicBasic
##########################################################################
-- version	user	Date		Change  
-- 1.0		LZ		20250730	Initial version;
-- 1.1		LZ		20250731	Other change (Examle) -- log the change here
##########################################################################
*/
CREATE PROCEDURE [dwh].[Load_ComicBasic] 
-- Can set some parameter to save the running version in log table
@PipelineTriggerTime DATETIME2

AS
BEGIN
	
	DECLARE @SCD_End_Date DATETIME2(0) = '9999-12-31'

	MERGE INTO [dwh].[DimComicDetail]	AS TGT	--target
	USING (
		SELECT
		 [month]
		,[num]
		,[link]
		,[year]
		,[news]
		,[safe_title]
		,[transcript]
		,[alt]
		,[img]
		,[title]
		,[day]
		,[extra_parts]
		,CAST(CONCAT([year],[month],[day]) AS INT) AS ComicDate_id
		,LEN(REPLACE(title, ' ', '')) * 5 AS Cost --Calculate the cost based on letters in title, remove space
		,HASHBYTES('SHA1',concat_ws('|',
					ISNULL([month], '') ,
					ISNULL([link], '') ,
					ISNULL([year], '') ,
					ISNULL([news], '') ,
					ISNULL([safe_title], '') ,
					ISNULL([transcript], '') ,
					ISNULL([alt], '') ,
					ISNULL([img], '') ,
					ISNULL([title], '') ,
					ISNULL([day], '') ,
					ISNULL([extra_parts], '')
			   )) AS [Checksum]  -- Used for SCD type 2
		FROM [tmp].[ComicsBasic])			AS SRC	--source
	ON (TGT.[Checksum] = SRC.[Checksum] AND TGT.SCD_Start_Date <= @PipelineTriggerTime AND TGT.SCD_End_Date > @PipelineTriggerTime)

	  WHEN NOT MATCHED BY TARGET THEN 
		INSERT(
		[month]
		,[id]
		,[link]
		,[year]
		,[news]
		,[safe_title]
		,[transcript]
		,[alt]
		,[img]
		,[title]
		,[day]
		,[extra_parts]
		,[ComicDate_id]
		,[Cost]
		,[Checksum]
		,SCD_Start_Date
		,SCD_End_Date
		)
		VALUES(
		 SRC.[month]
		,SRC.[num]
		,SRC.[link]
		,SRC.[year]
		,SRC.[news]
		,SRC.[safe_title]
		,SRC.[transcript]
		,SRC.[alt]
		,SRC.[img]
		,SRC.[title]
		,SRC.[day]
		,SRC.[extra_parts]
		,SRC.[ComicDate_id]
		,SRC.[Cost]
		,SRC.[Checksum]
		,@PipelineTriggerTime
		,@SCD_End_Date
		);


	   	IF OBJECT_ID('tempdb..#scd_start_date') IS NOT NULL
		DROP TABLE #scd_start_date

		CREATE TABLE #scd_start_date(
			  [id]				INT	NULL
			, SCD_Start_Date	DATETIME2(0) NOT NULL
		)
	
		INSERT INTO #scd_start_date
		(
			  [id]
			, SCD_Start_Date
		)
		SELECT 
			  [id]
			, MAX(SCD_Start_Date)		AS SCD_Start_Date
		FROM		dwh.DimComicDetail
		GROUP BY 
			  [id]
		HAVING COUNT(*) > 1
	
		UPDATE t
			SET t.SCD_End_Date = s.SCD_Start_Date
		FROM		dwh.DimComicDetail t
		INNER JOIN	#scd_start_date s
		ON			t.Id				= s.Id
		AND			t.SCD_Start_Date		< s.SCD_Start_Date
		AND			t.SCD_End_Date			= '9999-12-31'
	
		UPDATE 
			a
		SET			scd_start_date			= '1900-01-01'
		FROM		dwh.DimComicDetail a
		INNER JOIN (
						SELECT 
							Id
							, MIN(SCD_Start_Date) scd_start_date 
						FROM dwh.DimComicDetail
						GROUP BY 
							  Id
					) m
		ON			a.Id				= m.Id
		AND			a.SCD_Start_Date		= m.scd_start_date
		AND			a.SCD_Start_Date		<> '1900-01-01'
END