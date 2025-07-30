/*
##########################################################################
-- Name             : dq.vw_DQI_Definition
-- Date             : 2025-07-30
-- Author           : Lisha Zhu
-- Purpose          : vw_DQI_Definition is the view that where the manual definition of DQIs is stored. This view is created mainly for versionin purposes.
-- Usage            : Creation of DQI_Definition records
##########################################################################
-- version	user	Date		Change  
-- 1.0		LZ		20250730	Initial version
##########################################################################
*/
CREATE VIEW [dq].[vw_DQI_Definition]
AS

SELECT 'DQ1'                                                                                                 [Id]
      ,'RewardIndicator not align with reward amount'                                                        [Name]
      ,'Identifies all the review records from where the Reward indicator is not align with Reward Amount.'  [Description]
      ,	 'SELECT Review_id AS ObjectId, '
	    + ' ''Review id '' + Review_id + '' for comic '' + Comic_id + '' has wrong reward info'' AS Message'
	    +'  FROM dwh.factComicReview'
	    +' WHERE (IsReward = 1 and RewardAmount is null) or (IsReward = 0 and RewardAmount is not null)' [QueryBadData]

	  ,	 'SELECT Review_id, Comic_id '
	    +'  FROM dwh.factComicReview'												[QueryAllData] 
      ,'Comic Review'                                                               [Dimension]
      ,'Active'                                                                     [Status]
      ,'2025-07-31'                                                                 [CreatedDate]
      ,'LishaZhu'																	[CreatedBy]
      ,NULL																	        [ModifiedDate]
      ,NULL																		    [ModifiedBy]

UNION ALL

SELECT 'DQ2'                                                                                                 [Id]
      ,'Comic which has cost less than 5 EUR'										                          [Name]
      ,'Identifies all the comics which has cost less then 5 EUR, since cost is based on title'				  [Description]
      ,	 'SELECT Comic_id AS ObjectId, '
	    +' '' Comic with num of '' + Comic_id + '' has a wrong Cost'' AS Message'
		+'  FROM dwh.DimComicDetail'
	    +' WHERE Cost < 5'															[QueryBadData]

	  ,	 'SELECT Comic_id '
	    +'  FROM dwh.DimComicDetail'												[QueryAllData]
      ,'Comic Review'                                                               [Dimension]
      ,'Active'                                                                     [Status]
      ,'2025-07-31'                                                                 [CreatedDate]
      ,'LishaZhu'																	[CreatedBy]
      ,NULL																	        [ModifiedDate]
      ,NULL																		    [ModifiedBy]