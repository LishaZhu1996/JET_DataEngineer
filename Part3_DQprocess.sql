
/*
##########################################################################
-- Name             : dq.DQI_Process
-- Date             : 2025-07-30
-- Author           : Lisha Zhu
-- Purpose          : DQI_Process is the main procedure that loads the records which do not follow the correct business logic.                 
-- Usage            : Load data to DQI_Details
##########################################################################
-- version	user	Date		Change  
-- 1.0		LZ		20250730	Initial version

##########################################################################
*/
CREATE PROCEDURE [dq].[DQI_Process](@DQI_Id nvarchar(10))
AS

BEGIN

DECLARE 
	    @DQI_QueryBadData NVARCHAR(max)
	  , @SqlStmt NVARCHAR(max)
;
	

	SELECT @DQI_QueryBadData            = QueryBadData
	FROM dq.vw_DQI_Definition
	WHERE Id                            = @DQI_Id
	
	--Drop temp table if exists
	IF OBJECT_ID('tempdb..#DQI_Details') is not null
		DROP TABLE #DQI_Details

	--Create temp table to store the initial results of the query defined in DQI_Definition table per each DQI
	CREATE TABLE #DQI_Details (
	  DQI_Id          NVARCHAR(20)  NOT NULL,
      ObjectId        NVARCHAR(100)  NOT NULL,
      [Message]		  NVARCHAR(max) NULL,

	)

    --Create select query for bad records in the correct order of columns
	SET @SqlStmt = 'SELECT ''' + @DQI_Id + ''' as DQI_Id'
				  +'     , Message '
				  +'  FROM (' + @DQI_QueryBadData + ') t' 
	BEGIN
		INSERT INTO #DQI_Details
		EXEC sp_executesql  @SqlStmt
	END

BEGIN TRAN

	--Merge the data to DQI Details table. As the source contains the data filtered only for a specific DQI_Id, in the WHEN MATCHED/NOT MATCHED condition 
	--we add a filter on target based on the current DQI_Id in order to do the matching only on the records.
	--If the target is not filtered on DQI_Id then the details of other DQI_id would be updated in a wrong way.
	MERGE INTO dq.DQI_Detail as target
	USING
	(
		SELECT dd.DQI_Id
			 , dd.ObjectId
			 , dd.[Message]
		  FROM #DQI_Details dd
	)	as source
	 ON target.DQI_Id                  = source.DQI_Id
	AND target.ObjectId                = source.ObjectId

	
	--Update the attributes that might have changed in case the query logic is updated in the DQI Defition
	--Update the matched records to Active as they are re-open as issues or marked as corrected by mistake
	WHEN MATCHED AND target.DQI_ID = @DQI_Id
	THEN UPDATE
	SET target.[Message]				 = source.[Message]
      , target.[ExecutionTimestamp]		 = getdate()
	  , target.IsActive    = 1
	  , target.IsCorrected = 0
	  , target.CorrectedOn = NULL
	
	--Insert the newly identified cases
	WHEN NOT MATCHED BY TARGET AND source.DQI_Id = @DQI_Id 
	THEN INSERT
	(
	   [DQI_Id]
	  ,[ObjectId]
      ,[Message]
      ,[IsActive]
      ,[IsCorrected]
      ,[CorrectedOn]
	)
	VALUES
	(
	   source.[DQI_ID]
      ,source.[ObjectId]
      ,source.[Message]
      ,1         --IsActive
      ,0         --IsCorrected
      ,NULL
	)
	--Update the records which are active in the DQI_Detail table but are not identified from the query. Basically this means that the issues is fixed or potentially the records are inactivated or closed. 
	--The later is more difficult to be identified and in this version we will consider as corrected records also the ones deleted or inactivated.
	WHEN NOT MATCHED BY SOURCE AND target.DQI_Id = @DQI_Id
	THEN UPDATE
	SET target.IsActive    = 0
	  , target.IsCorrected = 1
	  , target.CorrectedOn = getdate()
	  ;

COMMIT TRAN

END
GO


