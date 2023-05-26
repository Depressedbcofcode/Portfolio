--Extracting information about bus drivers in month 5,7,10,11 in 2020 and their transit time.

SELECT Name as Bus_Driver_Name,
		NRIC as Bus_Driver_NRIC,
		FORMAT(TDate,'yyyy-MM') as Month,
		DATEDIFF(MINUTE, StartTime, EndTime) as Transit_time
FROM driver
JOIN bustrip ON driver.DID = bustrip.DID
WHERE MONTH(TDate) IN (5,7,10,11) AND YEAR(TDate) = 2020
ORDER BY Transit_time ASC


--Extracting information about each bus service for each stop and if the weekday frequency for each service is high or not

SELECT stop.StopID,
		LocationDes,
		Address,
		service.SID,
		CASE
			WHEN Normal = 1 THEN 'Normal'
			ELSE 'Express'
		END AS Type,
		WeekdayFreq,
		CASE
			WHEN WeekdayFreq > 12 THEN 'High'
			WHEN 6< WeekdayFreq AND WeekdayFreq < 12 THEN 'Medium'
			ELSE 'Low'
		END AS Checking
FROM stop 
LEFT JOIN stoprank on stop.StopID = stoprank.StopID
LEFT JOIN service on stoprank.SID = service.SID
LEFT JOIN normal on service.SID = normal.SID
WHERE LocationDes LIKE '%bridge%' OR LocationDes LIKE '%Bridge%' OR LocationDes like '%changi%' OR LocationDes LIKE '%Changi%'
	OR Address LIKE '%bridge%' OR Address LIKE '%Bridge%' OR Address LIKE '%changi%' OR Address LIKE '%Changi%'
ORDER BY StopID, SID DESC



--Count the number of rides for each replaced card ID and old card ID

;
WITH CTE AS

	(SELECT c1.CardID as ReplacedCardID,
			c1.Expiry,
			c1.OldCardID,
			COUNT(r1.CardID) as NumberOfRide
	FROM citylink c1 
	JOIN citylink c2 on c1.OldCardID = c2.CardID
	LEFT JOIN ride r1 on c1.CardID = r1.CardID
	GROUP BY c1.CardID, c1.Expiry, c1.OldCardID)

SELECT ReplacedCardID,
		Expiry,
		NumberOfRide,
		OldCardID,
		COUNT(r2.CardID) as NumberOfRide_Old
FROM CTE
LEFT JOIN ride r2 on CTE.OldCardID = r2.CardID
GROUP BY ReplacedCardID, Expiry, OldCardID,NumberOfRide
ORDER BY NumberOfRide ASC


--Count the number of cards satisfying the condition: number of ride on replaced card greater than that of old cards.
;
WITH CTE AS

	(SELECT c1.CardID as ReplacedCardID,
			c1.Expiry,
			c1.OldCardID,
			COUNT(r1.CardID) as NumberOfRide
	FROM citylink C1 
	JOIN citylink c2 on c1.OldCardID = c2.CardID
	LEFT JOIN ride r1 on c1.CardID = r1.CardID
	GROUP BY c1.CardID, c1.Expiry, c1.OldCardID)

, A as
	(SELECT ReplacedCardID,
			Expiry,
			NumberOfRide,
			OldCardID,
			COUNT(r2.CardID) as NumberOfRide_Old
	FROM CTE
	LEFT JOIN ride r2 on CTE.OldCardID = r2.CardID
	GROUP BY ReplacedCardID, Expiry, OldCardID,NumberOfRide
	)
SELECT COUNT(*) AS NoOfCardSatisfied
FROM A
WHERE NumberOfRide > NumberOfRide_Old


--Count the number of cards satisfying the condition: the number of ride on old card is an even number.
;
WITH CTE AS

	(SELECT c1.CardID as ReplacedCardID,
			c1.Expiry,
			c1.OldCardID,
			COUNT(r1.CardID) as NumberOfRide
	FROM citylink C1 
	JOIN citylink c2 on c1.OldCardID = c2.CardID
	LEFT JOIN ride r1 on c1.CardID = r1.CardID
	GROUP BY c1.CardID, c1.Expiry, c1.OldCardID)

, A as 
	(SELECT ReplacedCardID,
			Expiry,
			NumberOfRide,
			OldCardID,
			COUNT(r2.CardID) as NumberOfRide_Old
	FROM CTE
	LEFT JOIN ride r2 on CTE.OldCardID = r2.CardID
	GROUP BY ReplacedCardID, Expiry, OldCardID,NumberOfRide
	)
SELECT COUNT(*) AS NoOfCardSatisfied
FROM A
WHERE NumberOfRide_Old % 2 = 0



--Extract top 4 bus stops having highest traffic count in 2029,2020,2021

;
WITH Boarded_cnt as
	(SELECT YEAR(RDate) as Year,
	BoardStop as Stop_ID,
	COUNT(*) as Traffic_cnt
	FROM ride
	GROUP BY YEAR(RDate), BoardStop
	)
, Alight_cnt as 
	(SELECT YEAR(RDate) as Year,
	AlightStop as Stop_ID,
	COUNT(*) as Traffic_cnt
	FROM ride
	WHERE AlightStop IS NOT NULL
	GROUP BY YEAR(RDate), AlightStop
	)
, Union_cnt as
	(SELECT * FROM Boarded_cnt 
	UNION ALL
	SELECT * FROM Alight_cnt
	)
, Traffic_cnt_by_rank as
	(SELECT Year,
			Stop_ID, 
			SUM(Traffic_cnt) as Traffic_cnt,
			Row_number() OVER (PARTITION BY Year ORDER BY SUM(Traffic_cnt) DESC) as Rank
	FROM Union_cnt
	GROUP BY Year, Stop_ID
	)
SELECT *
FROM Traffic_cnt_by_rank
WHERE Rank <=4
ORDER BY Stop_ID, Traffic_cnt ASC

