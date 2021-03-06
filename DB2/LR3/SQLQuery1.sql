USE master
GO
DROP DATABASE LR3
GO
CREATE DATABASE LR3
GO
USE LR3
GO

CREATE TABLE Directors(
	ID int PRIMARY KEY,
	Name varchar(40)
)

CREATE TABLE Director_mentors(
	ID int PRIMARY KEY,
	mentor_id int FOREIGN KEY REFERENCES Directors(ID), -- ���������
	mentee_id int FOREIGN KEY REFERENCES Directors(ID), -- ������
)

-- task 1
INSERT INTO Directors VALUES
	(1, 'Gendalf'),
	(2, 'Sauron'),
	(3, 'R2D2'),
	(4, 'Leonardo Di Caprio'),
	(5, 'Luke Skywalker'),
	(6, 'Filipp J. Fry'),
	(7, 'Van Gogh'),
	(8, 'Obi Wan Kenobi'),
	(9, 'Mukha'),
	(10, 'Superman')

INSERT INTO Director_mentors VALUES
	(1, NULL, 3   ),
	(2, NULL, 5   ),
	(3, 1   , 6   ),
	(4, 1   , 9   ),
	(5, 2   , NULL),
	(6, 4   , NULL),
	(7, NULL, 8   ),
	(8, 7   , NULL),
	(9, 5   , NULL),
	(10, 2  , NULL)

-- task 2.1
-- ������� ������ ��� �������� ��������� �������.

GO

CREATE PROCEDURE listMentees
    @ID INT
AS 
   WITH subquery(mentee_ids) AS 
   (
		SELECT ID
		FROM Director_mentors
		WHERE mentor_id = @ID
		UNION ALL
		SELECT T.ID
		FROM subquery
		INNER JOIN Director_mentors AS T ON 
		T.mentor_id = subquery.mentee_ids
   )

   SELECT distinct mentee_ids, Directors.Name
   FROM subquery
   JOIN Directors ON Directors.ID = mentee_ids
GO

EXEC listMentees 1 
EXEC listMentees 2 
GO

-- task 2.2
-- ������� ������ ��� ������� ��������� ��������

CREATE PROCEDURE listMentors
    @ID INT
AS 
   WITH subquery(mentor_ids) AS 
   (
		SELECT mentor_id
		FROM Director_mentors
		WHERE ID = @ID
		UNION ALL
		SELECT T.mentor_id
		FROM subquery
		INNER JOIN Director_mentors AS T ON 
		T.ID = subquery.mentor_ids
		WHERE T.mentor_id IS NOT NULL
   )

   SELECT distinct mentor_ids, Directors.Name
   FROM subquery
   JOIN Directors ON Directors.ID = mentor_ids
GO

EXEC listMentors 6 
EXEC listMentors 9 
GO

-- task 2.3
-- ������� ������, ������ ����� ����� � ������� ( ������ ��������������� level � connect by)

CREATE PROCEDURE listMenteesWithLevel
    @ID INT
AS 
   WITH subquery(mentee_ids,lvl) AS 
   (
		SELECT ID, 1
		FROM Director_mentors
		WHERE mentor_id = @ID
		UNION ALL
		SELECT T.ID, lvl+1
		FROM subquery
		INNER JOIN Director_mentors AS T ON 
		T.mentor_id = subquery.mentee_ids
   )

   SELECT distinct mentee_ids, lvl, Directors.Name
   FROM subquery
   JOIN Directors ON Directors.ID = mentee_ids
GO

EXEC listMenteesWithLevel 1 
EXEC listMenteesWithLevel 2 
GO

-- task 2.4
-- ������ ���� � ������� ������� ���, ��� ��������� ����. 

UPDATE Director_mentors
SET mentor_id = 4
WHERE ID = 1

-- task 2.4.1
-- �������� �����, �� ���� ������� ��� ������������.

EXEC listMentees 1

-- task 2.4.2
-- ������ ��� ����� ���, ��� ������� �� ����

GO

CREATE PROCEDURE listMenteesWithCycles
    @ID INT
AS 
   WITH subquery(mentee_ids, lvl, iscycle) AS 
   (
		SELECT ID, 1, 0
		FROM Director_mentors
		WHERE mentor_id = @ID
		UNION ALL
		SELECT T.ID, lvl+1, (CASE WHEN T.mentor_id = subquery.mentee_ids THEN 1 ELSE 0 END)
		FROM subquery
		INNER JOIN Director_mentors AS T ON 
		T.mentor_id = subquery.mentee_ids
		WHERE iscycle = 0
   )

   SELECT distinct mentee_ids, lvl, Directors.Name
   FROM subquery
   JOIN Directors ON Directors.ID = mentee_ids
GO

EXEC listMenteesWithCycles 1

-- task 2.5
-- ��� ��� �������� (�� ����� ����: ������ ) ������� ������ ������� ����� �/�, 
-- �� �������� � ������� � ��� �������� ( �� ����� ����: ��������/���������/�������/������)


GO

CREATE PROCEDURE listMenteesWithHistory
    @ID INT
AS 
   WITH subquery(mentee_ids, history, iscycle) AS 
   (
		SELECT Director_mentors.ID, 
			CAST(CONCAT((SELECT Directors.Name FROM Directors WHERE ID = @ID),'\',CAST(Directors.Name AS nvarchar(256))) AS nvarchar(256)), 0
		FROM Director_mentors
		JOIN Directors ON Directors.ID = Director_mentors.ID
		WHERE mentor_id = @ID
		UNION ALL
		SELECT 
			T.ID,
			CAST(CONCAT(subquery.history,'\',CAST(Directors.Name AS nvarchar(256))) AS nvarchar(256)),
			(CASE WHEN T.mentor_id = subquery.mentee_ids THEN 1 ELSE 0 END)
		FROM subquery
		INNER JOIN Director_mentors AS T ON 
		T.mentor_id = subquery.mentee_ids
		JOIN Directors ON Directors.ID = T.ID
		WHERE iscycle = 0
   )

   SELECT mentee_ids, history, Directors.Name
   FROM subquery
   JOIN Directors ON Directors.ID = mentee_ids
GO

EXEC listMenteesWithHistory 1