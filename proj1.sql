-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;
DROP VIEW IF EXISTS lslghelper;
DROP VIEW IF EXISTS helpermax;
DROP VIEW IF EXISTS binidHelper;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE namefirst like '% %'
  ORDER BY namefirst, namelast
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height) AS avgheight, COUNT(*)
    FROM people
    GROUP BY birthyear
    HAVING avgheight > 70
    ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, h.yearid
  FROM people AS p LEFT OUTER JOIN HallofFame AS h ON p.playerid = h.playerid
  WHERE h.inducted = "Y"
  ORDER BY h.yearid DESC, p.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT q2i.namefirst, q2i.namelast, q2i.playerid, cali.schoolid, q2i.yearid
    FROM q2i,
    (SELECT c.playerid, s.schoolid FROM Collegeplaying AS c, Schools AS s
    WHERE c.schoolid = s.schoolid AND s.schoolstate = 'CA') AS cali
    WHERE q2i.playerid = cali.playerid
    ORDER BY q2i.yearid DESC, cali.schoolid, q2i.playerid
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
  SELECT q2i.playerid, q2i.namefirst, q2i.namelast, school.schoolid
  FROM q2i LEFT OUTER JOIN
  (SELECT c.playerid, s.schoolid FROM Collegeplaying AS c, Schools AS s
  WHERE c.schoolid = s.schoolid) AS school
  ON q2i.playerid = school.playerid
  ORDER BY q2i.playerid DESC, school.schoolid ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid, CAST(CAST(1.0*((H-H2B-H3B-HR)+2*H2B+3*H3B+4*HR)/AB
  AS DECIMAL(5,2)) AS FLOAT) AS slg
  FROM people AS p, batting AS b
  WHERE b.AB > 50 AND p.playerid = b.playerid
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, lslg
  FROM people AS p,
  (SELECT b.playerid, CAST(CAST(1.0*((SUM(H)-SUM(H2B)-SUM(H3B)-SUM(HR))+2*SUM(H2B)+3*SUM(H3B)+4*SUM(HR))/SUM(AB)
  AS DECIMAL(5,2)) AS FLOAT) AS lslg FROM batting AS b,
  (SELECT b.playerid, SUM(b.AB) AS atbat FROM batting AS b
  GROUP BY b.playerid) AS lifeatbat
  WHERE lifeatbat.atbat > 50 and lifeatbat.playerid = b.playerid
  GROUP BY b.playerid
  ) AS lifetime
  WHERE lifetime.playerid = p.playerid
  ORDER BY lslg DESC, p.playerid ASC
  LIMIT 10
;

--helper function
CREATE VIEW lslghelper(playerid, lslg)
AS
  SELECT playerid, CAST(CAST(1.0*((SUM(H)-SUM(H2B)-SUM(H3B)-SUM(HR))+2*SUM(H2B)+3*SUM(H3B)+4*SUM(HR))/SUM(AB)
  AS DECIMAL(5,2)) AS FLOAT)
  FROM batting
  GROUP BY playerid
  HAVING SUM(AB) > 50
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast, l.lslg
  FROM people AS p INNER JOIN lslghelper AS l ON p.playerid = l.playerid
  WHERE l.lslg > (SELECT lslg FROM lslghelper WHERE playerid = 'mayswi01')
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
  SELECT binid, help.min+binid*((help.max - help.min)/10.0), help.min+(binid+1)*((help.max - help.min)/10.0), COUNT(*)
  FROM binidHelper AS help INNER JOIN binids AS bin
  ON bin.binid = CAST((help.salary - help.min)/((help.max - help.min)/10.0) AS INT)
  OR (bin.binid + 1 = CAST((help.salary - help.min)/((help.max - help.min)/10.0) AS INT)
  AND CAST((help.salary - help.min)/((help.max - help.min)/10.0) AS INT) = 10)
  GROUP BY bin.binid
;

--helper function
 CREATE VIEW binidHelper(min, max, avg, salary)
 AS
   SELECT info.min, info.max, info.avg, s.salary
   FROM (SELECT MIN(salary) AS min, MAX(salary) AS max, avg(salary) AS avg FROM salaries WHERE yearid LIKE '2016')
   AS info
   INNER JOIN (SELECT salary FROM salaries WHERE yearid LIKE '2016') AS s
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT later.yearid, later.min-start.min AS mindiff, later.max-start.max AS maxdiff, later.avg-start.avg
  AS avgdiff
  FROM q4i AS start, q4i AS later
  WHERE (later.yearid- start.yearid) = 1
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, h.salary, h.yearid
  FROM people AS p INNER JOIN helpermax AS h ON p.playerid = h.playerid
;

--helper function
CREATE VIEW helpermax(playerid, yearid, salary)
AS
  SELECT s.playerid, s.yearid, s.salary
  FROM salaries AS s
  WHERE (s.yearid = 2000 AND s.salary = (SELECT MAX(salary) FROM salaries where yearid = 2000))
  OR (s.yearid = 2001 AND s.salary = (SELECT MAX(salary) FROM salaries where yearid = 2001))
;

-- Question 4v
CREATE VIEW q4v(team, diffAvg)
AS
  SELECT a.teamid AS team, MAX(salary) - MIN(salary) AS diffAvg
  FROM allstarfull AS a, salaries AS s
  WHERE (s.yearid = 2016 AND a.yearid = 2016) AND (a.playerid = s.playerid)
  GROUP BY a.teamid
;

