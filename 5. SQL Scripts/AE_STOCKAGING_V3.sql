CREATE PROCEDURE "AE_STOCKAGING_V3" 
(	IN AgingDate TimeStamp,
	IN ItemCodeFrom varchar(20),
	IN ItemCodeTo varchar(20),
	IN WhsCodeFrom varchar(20),
	IN WhsCodeTo varchar(20)	
)
AS
AgeColumn1 INTEGER;
AgeColumn2 INTEGER;
AgeColumn3 INTEGER;
AgeColumn4 INTEGER;
AgeColumn5 INTEGER;
AgeColumn6 INTEGER;

ComName varchar(300);
CoRegNo nvarchar(40);
GSTRegNo nvarchar(40);


BEGIN
--IF WhsCode = '' THEN
--WhsCode := '';

AgeColumn1 := 30;
AgeColumn2 := 60;
AgeColumn3 := 90;
AgeColumn4 := 120;
AgeColumn5 := 365;
AgeColumn6 := AgeColumn5+1;

SELECT
	 (SELECT
	 TOP 1 ifnull("PrintHeadr",
	 "CompnyName") 
	FROM"OADM") 
INTO ComName 
FROM DUMMY;

SELECT (SELECT "TaxIdNum" FROM"OADM") INTO CoRegNo FROM DUMMY;
SELECT (SELECT "TaxIdNum2" FROM"OADM") INTO GSTRegNo FROM DUMMY;

CREATE COLUMN TABLE OnHand  ("X" INTEGER ,"ItemCode" NVARCHAR(20),"Description" NVARCHAR(100),"Warehouse" NVARCHAR(8)
							  ,"OnHand" DECIMAL(36,3),"TransValue" DECIMAL(36,9),"AvgPrice" DECIMAL(36,15));
							  
CREATE COLUMN TABLE TEMP_RunTotal ("InQty1" DECIMAL(21,6),"TtlQty"  DECIMAL(21,6)  ,"ItemCode" NVARCHAR(20)
							   ,"DocDate" Date,"Warehouse" NVARCHAR(8),"InQty" DECIMAL(21,6)
								 ,"BASE_REF" NVARCHAR(20),"TransNum" INTEGER,"TransValue" DECIMAL(36,9));
								 	
CREATE COLUMN TABLE RunTotal  ("InQty1" DECIMAL(21,6),"TtlQty"  DECIMAL(21,6)  ,"ItemCode" NVARCHAR(20)
								,"DocDate" Date,"Warehouse" NVARCHAR(8),"InQty" DECIMAL(21,6)
								 ,"BASE_REF" NVARCHAR(20),"TransValue" DECIMAL(36,9));	
								 
CREATE COLUMN TABLE Temp1  ("ItemCode" NVARCHAR(20),"Description" NVARCHAR(100),"OnHand" DECIMAL(36,3),"TransValue" DECIMAL(36,9)
							,"DocDate" Date,"Warehouse" NVARCHAR(8),"Quantity" DECIMAL(21,6),"AvgPrice" DECIMAL(36,15));
							
CREATE COLUMN TABLE Temp  ("ItemCode" NVARCHAR(20),"ItemName" NVARCHAR(100),"OnHand" DECIMAL(36,3),"TransValue" DECIMAL(36,9)
							,"Warehouse" NVARCHAR(8),"WhsName" NVARCHAR(100),"ItmsGrpNam" NVARCHAR(20),"AgeColumn1" DECIMAL(21,6)
							,"AgeColumn2" DECIMAL(21,6),"AgeColumn3" DECIMAL(21,6)
							,"AgeColumn4" DECIMAL(21,6),"AgeColumn5" DECIMAL(21,6),"AgeColumn6" DECIMAL(21,6)
							,"AvgPrice" DECIMAL(36,15));							
							
							
CREATE COLUMN TABLE Final  ("CompName" NVARCHAR(100),"CoRegNo" NVARCHAR(100),"GSTRegNo" NVARCHAR(100),"LogoImage" BLOB,
							"ItemCode" NVARCHAR(20),"ItemName" NVARCHAR(100),"OnHand" DECIMAL(36,3),"TransValue" DECIMAL(36,9)
						,"WhsCode" NVARCHAR(8),"WhsName" NVARCHAR(100),"ItmsGrpNam" NVARCHAR(20)
						,"AgeColumn1" DECIMAL(21,6),"AgeColumn2" DECIMAL(21,6),"AgeColumn3" DECIMAL(21,6)
							,"AgeColumn4" DECIMAL(21,6),"AgeColumn5" DECIMAL(21,6),"AgeColumn6" DECIMAL(21,6)
						,"AgeColumn1_Value" DECIMAL(36,15),"AgeColumn2_Value" DECIMAL(36,15),"AgeColumn3_Value" DECIMAL(36,15)
						,"AgeColumn4_Value" DECIMAL(36,15),"AgeColumn5_Value" DECIMAL(36,15),"AgeColumn6_Value" DECIMAL(36,15)
						,"Header1" NVARCHAR(100) ,"Header2" NVARCHAR(100),"Header3" NVARCHAR(100)
						,"Header4" NVARCHAR(100),"Header5" NVARCHAR(100),"Header6" NVARCHAR(100)
						,"AvgPrice" DECIMAL(36,15),"UOM" NVARCHAR(100)
);								 							 						  
							  
INSERT INTO OnHand
(
select 
SUM(A."TransValue") AS "X",
	A."ItemCode"
	, max(B."ItemName") as "Description"
	, A."Warehouse"
	, TO_DECIMAL(IFNULL(Sum(IFNull(A."InQty",0) - IFNULL(A."OutQty",0)),0.0),36,3) As "OnHand"
, TO_DECIMAL(IFNULL(Sum(A."TransValue"),0.0000000),36,9) As "TransValue"
, ROUND(ROUND(CASE WHEN IFNULL(Sum(IFNULL(A."InQty",0) - IFNULL(A."OutQty",0)),0)=0 THEN 0 ELSE 
	IFNULL(TO_DECIMAL(IFNULL(Sum(A."TransValue"),0.0000000),36,9)
	/TO_DECIMAL(IFNULL(Sum(IFNull(A."InQty",0) - IFNULL(A."OutQty",0)),0.0),36,3)
	,0) 
	END,16),4,ROUND_CEILING)  AS "AvgPrice"
From OINM A
	Join OITM B On A."ItemCode" = B."ItemCode"
	where A."DocDate" <= :AgingDate and 
	(A."ItemCode" >= :ItemCodeFrom or :ItemCodeFrom = '') and 
	(A."ItemCode" <= :ItemCodeTo or :ItemCodeTo = '') and 
	(A."Warehouse" >= :WhsCodeFrom or :WhsCodeFrom = '') and (A."Warehouse" <= :WhsCodeTO or :WhsCodeTo = '')
	Group By A."ItemCode", A."Warehouse"
		HAVING IFNULL(Sum(IFNULL(A."InQty",0) - IFNULL(A."OutQty",0)),0)<>0  OR  IFNULL(Sum(A."TransValue"),0)<>0
);							  

INSERT INTO TEMP_RunTotal(						  
Select 
	A."InQty" as "InQty1"
		, 0 As "TtlQty"
		, A."ItemCode"
		, A."DocDate"
		, A."Warehouse"
		, A."InQty"
		, A."BASE_REF"					
		, A."TransNum"
		, A."TransValue"

From OINM A INNER JOIN OITW ON
		A."ItemCode"=OITW."ItemCode" and A."Warehouse" = OITW."WhsCode"
	Where A."DocDate" <= :AgingDate and 
	(A."ItemCode" >= :ItemCodeFrom or :ItemCodeFrom = '') and 
	(A."ItemCode" <= :ItemCodeTo or :ItemCodeTo = '') and 
	(A."Warehouse" >= :WhsCodeFrom or :WhsCodeFrom = '') and 	(A."Warehouse" <= :WhsCodeTo or :WhsCodeTo = '')
--	And A."TransType" In(-2, 14, 16, 18, 20, 59, 67) 
	And (IFNULL(A."InQty",0) <> 0)
Order By A."TransNum" Desc) ;

INSERT INTO RunTotal(						  
Select 
	A."InQty" as "InQty1"
	, (Select Sum("InQty") 
		From "OINM" 
		Where "DocDate" <= :AgingDate And IFNULL("InQty",0) <> 0 
			And "ItemCode" = A."ItemCode"  and "Warehouse" = A."Warehouse"
			And "TransNum" > A."TransNum"
--			And "TransType" In(-2, 14, 16, 18, 20, 59, 67) 
		group by "ItemCode", "Warehouse" 
		) As "TtlQty"
	, A."ItemCode"
	, A."DocDate"
	, A."Warehouse"
	, A."InQty"
	, A."BASE_REF"					
	, A."TransValue"
From TEMP_RunTotal A 
Order By A."TransNum" Desc ) ;

INSERT INTO Temp1(						  
Select 
	 A."ItemCode"
	, A."Description"
	, A."OnHand"
	, A."TransValue"
	, B."DocDate"
	, B."Warehouse"
	, Case When B."InQty" + IFNULL(B."TtlQty",0) > A."OnHand"
			Then Case When A."OnHand" - IFNULL(B."TtlQty",0) < 0 
				Then 0 Else A."OnHand" - IFNULL(B."TtlQty",0) End 
		Else B."InQty" 
		End As "Quantity"
	, A."AvgPrice"

From OnHand A 
	Join RunTotal B On A."ItemCode" = B."ItemCode" AND A."Warehouse" = B."Warehouse"
order by A."ItemCode", A."Warehouse") ;

INSERT INTO Temp(						  
Select 
	A."ItemCode"
	, max(A."Description") As "ItemName"
	, A."OnHand"
	, A."TransValue"
	, A."Warehouse" AS "WhsCode"
	, max(D."WhsName") AS "Whsname"
	, Max(H."ItmsGrpNam") As "ItmsGrpNam"
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) between 0 And 30 Then "Quantity" Else 0 End) as "AgeColumn1"
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) between 31 And 60 Then "Quantity" Else 0 End) as "AgeColumn2"
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) between 61 And 90 Then "Quantity" Else 0 End) as "AgeColumn3"
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) between 91 And 120 Then "Quantity" Else 0 End) as "AgeColumn4"
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) between 121 And 365 Then "Quantity" Else 0 End) as "AgeColumn5"	
	, Sum (Case when DAYS_BETWEEN(A."DocDate",:AgingDate) >365 Then "Quantity" Else 0 End) as "AgeColumn6"
	, A."AvgPrice"

From Temp1 A
	left outer Join OWHS D On A."Warehouse"=D."WhsCode"
	left outer join OITM F on A."ItemCode" = F."ItemCode"
	Left outer Join OITB H on H."ItmsGrpCod"=F."ItmsGrpCod"
	Group by 
	A."ItemCode"
	, A."Warehouse"
	, A."OnHand"
	,A."DocDate"
--	, Convert(Varchar(10),A.DocDate,112)
	, A."TransValue"
	, A."AvgPrice"

Order by A."ItemCode" desc) ;

INSERT INTO Final(						  
select 
	:ComName as "CompName"
	,:CoRegNo as "CoRegNo"
	,:GSTRegNo as "GSTRegNo"
	,(select Top 1 "LogoImage" from OADP) as "LogoImage"
	,A."ItemCode"
	,A."ItemName"
	,A."OnHand"
	/*,A.TransValue as TransValue*/
--	 CAST(CAST(1.5 as DECIMAL(15,2)) as VARCHAR) 
	,CAST(CAST(MAX(A."AvgPrice")* (A."OnHand") as DECIMAL(19,2)) as VARCHAR) as "TransValue"  
--	,ROUND(MAX(A."AvgPrice")* (A."OnHand"),2) as "TransValue"  
--	,A."TransValue"  
	,A."Warehouse"
	,max(A."WhsName") as "WhsName"
	,A."ItmsGrpNam" 
	,sum(A."AgeColumn1") as "AgeColumn1"
	,sum(A."AgeColumn2") as "AgeColumn2" 
	,sum(A."AgeColumn3") as "AgeColumn3"
	,sum(A."AgeColumn4") as "AgeColumn4"
	,sum(A."AgeColumn5") as "AgeColumn5"
	,sum(A."AgeColumn6") as "AgeColumn6"
	, ROUND(SUM(A."AgeColumn1")* MAX(A."AvgPrice"),2) as "AgeColumn1_Value"
	, ROUND(SUM(A."AgeColumn2")* MAX(A."AvgPrice"),2) as "AgeColumn2_Value"
	, ROUND(SUM(A."AgeColumn3")* MAX(A."AvgPrice"),2) as "AgeColumn3_Value"
	, ROUND(SUM(A."AgeColumn4")* MAX(A."AvgPrice"),2) as "AgeColumn4_Value"
	, ROUND(SUM(A."AgeColumn5")* MAX(A."AvgPrice"),2) as "AgeColumn5_Value"
	, ROUND(SUM(A."AgeColumn6")* MAX(A."AvgPrice"),2) as "AgeColumn6_Value"
--	, SUM(A."AgeColumn5")* MAX(A."AvgPrice") as "AgeColumn5_Value"
--	, SUM(A."AgeColumn6")* MAX(A."AvgPrice") as "AgeColumn6_Value"
	,'<= 30 Days' as "Header1"
	,'31-60 Days'as "Header2"
	,'61-90 Days'as "Header3"
	,'91-120 Days'as "Header4"
	,'120-365 Days'as "Header5"
	,'Above 365 Days' as "Header6"
	/*,CAST(MAX(A.Avgprice) AS NUMERIC(36,6)) as AvgPrice */
--	,CAST(CAST(MAX(A."AvgPrice") as DECIMAL(19,2)) as VARCHAR) as "AvgPrice"
	,MAX(A."AvgPrice") as "AvgPrice"
	/*, CASE when  isnull(A.onhand, 0) > 0 then convert(numeric(19, 2), a.TransValue / A.onhand) else CAST(MAX(A.Avgprice) AS NUMERIC(36,6)) end as AvgPrice */
	,B."InvntryUom" as "UOM"

from Temp A
inner join OITM B on A."ItemCode" = B."ItemCode"
group by a."ItemCode",A."Warehouse",a."ItemName",a."OnHand",a."ItmsGrpNam",b."InvntryUom",A."TransValue"
order by a."ItemCode" asc
) ;

UPDATE Final
SET 
"AgeColumn1_Value"=CASE WHEN "AgeColumn1_Value"<>0 AND "AgeColumn6_Value"=0 AND "AgeColumn5_Value"=0 
					AND "AgeColumn4_Value"=0 AND "AgeColumn3_Value"=0 AND "AgeColumn2_Value"=0 THEN 
					"AgeColumn1_Value"+("TransValue"-("AgeColumn1_Value"+"AgeColumn2_Value"
			 +"AgeColumn3_Value"+"AgeColumn4_Value"+"AgeColumn5_Value"+"AgeColumn6_Value")) ELSE "AgeColumn1_Value" END ,
 
"AgeColumn2_Value"=CASE WHEN "AgeColumn2_Value"<>0 AND "AgeColumn6_Value"=0 AND "AgeColumn5_Value"=0 AND 
				"AgeColumn4_Value"=0 AND "AgeColumn3_Value"=0 THEN "AgeColumn2_Value"
				+("TransValue"-("AgeColumn1_Value"+"AgeColumn2_Value"+"AgeColumn3_Value"+"AgeColumn4_Value"
				+"AgeColumn5_Value" +"AgeColumn6_Value")) 
				ELSE "AgeColumn2_Value" END ,

"AgeColumn3_Value"=CASE WHEN "AgeColumn3_Value"<>0 AND "AgeColumn6_Value"=0 AND "AgeColumn5_Value"=0 
			AND "AgeColumn4_Value"=0 THEN "AgeColumn3_Value"+("TransValue"-("AgeColumn1_Value"+"AgeColumn2_Value"
			+"AgeColumn3_Value"+"AgeColumn4_Value"+"AgeColumn5_Value"+"AgeColumn6_Value")) ELSE "AgeColumn3_Value" END 
			,

"AgeColumn4_Value"=CASE WHEN "AgeColumn4_Value"<>0 AND "AgeColumn6_Value"=0 AND "AgeColumn5_Value"=0 
			THEN "AgeColumn4_Value"+("TransValue"-("AgeColumn1_Value"+"AgeColumn2_Value"+"AgeColumn3_Value"+
				"AgeColumn4_Value"+"AgeColumn5_Value"+"AgeColumn6_Value")) ELSE "AgeColumn4_Value" END ,
				
"AgeColumn5_Value"=CASE WHEN "AgeColumn5_Value"<>0 AND "AgeColumn6_Value"=0 THEN "AgeColumn5_Value"+("TransValue"-(
			"AgeColumn1_Value"+"AgeColumn2_Value"+"AgeColumn3_Value"+"AgeColumn4_Value"+"AgeColumn5_Value"+"AgeColumn6_Value")) ELSE
			 "AgeColumn5_Value" END ,
			 
"AgeColumn6_Value"=CASE WHEN "AgeColumn6_Value"<>0  THEN "AgeColumn6_Value"+("TransValue"-(
			"AgeColumn1_Value"+"AgeColumn2_Value"+"AgeColumn3_Value"+"AgeColumn4_Value"+"AgeColumn5_Value"+"AgeColumn6_Value")) ELSE
			 "AgeColumn6_Value" END 			 
where 
"TransValue"<>"AgeColumn1_Value"+"AgeColumn2_Value"+"AgeColumn3_Value"+"AgeColumn4_Value"+"AgeColumn5_Value";

SELECT *, :AgingDate as AgingDate FROM Final;
--SELECT * FROM RunTotal;
DROP TABLE OnHand;
DROP TABLE TEMP_RunTotal;
DROP TABLE RunTotal;
DROP TABLE Temp1;
DROP TABLE Temp;
DROP TABLE Final;
END