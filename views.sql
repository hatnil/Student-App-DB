--VIEWS

--BasicInformation(idnr, name, login, program, branch)

CREATE VIEW BasicInformation AS
SELECT
  Students.idnr,
  Students.name,
  Students.login,
  Students.program,
  (
    SELECT
      branch
    FROM
      StudentBranches
    Where
      StudentBranches.student = Students.idnr
  )
FROM
  Students;

--FinishedCourses(student, course, grade, credits)  
CREATE VIEW FinishedCourses AS
SELECT
  Taken.student,
  Taken.course,
  Taken.grade,
  Courses.credits
FROM
  Taken,
  Courses
WHERE
  Courses.code = Taken.course;


--PassedCourses(student, course, credits)
CREATE VIEW PassedCourses AS
SELECT
  Taken.student,
  Taken.course,
  Courses.credits
FROM
  Taken,
  Courses
WHERE
  Courses.code = Taken.course
  AND Taken.grade != 'U';


--Registrations(student, course, status)
CREATE VIEW Registrations AS (
  SELECT
    Registered.student,
    Registered.course,
    'registered' AS status
  FROM
    Registered
)
UNION
(
  SELECT
    WaitingList.student,
    WaitingList.course,
    'waiting' AS status
  FROM
    WaitingList
);


--UnreadMandatory(student, course)
CREATE VIEW UnreadMandatory AS (
  SELECT
    StudentBranches.student,
    MandatoryBranch.course
  FROM
    StudentBranches,
    MandatoryBranch
  WHERE
    (StudentBranches.branch = MandatoryBranch.branch)
    AND (
      StudentBranches.program = MandatoryBranch.program
    )
    AND (
      MandatoryBranch.course NOT IN (
        SELECT
          PassedCourses.course
        FROM
          PassedCourses
        WHERE
          PassedCourses.student = StudentBranches.student
      )
    )
)
UNION
(
  SELECT
    Students.idnr AS student,
    MandatoryProgram.course
  FROM
    Students,
    MandatoryProgram
  WHERE
    (Students.program = MandatoryProgram.program)
    AND (
      MandatoryProgram.course NOT IN (
        SELECT
          PassedCourses.course
        FROM
          PassedCourses
        WHERE
          PassedCourses.student = Students.idnr
      )
    )
);




-- PathToGraduation(student, totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, qualified)

CREATE VIEW PathToGraduation AS 
    WITH

    TotalCredits AS (
     SELECT PassedCourses.student, SUM (PassedCourses.credits) AS totalCredits FROM PassedCourses
     GROUP BY PassedCourses.student
     ),


     MandatoryLeft AS (
     SELECT UnreadMandatory.student, COUNT (UnreadMandatory.course) AS mandatoryLeft FROM UnreadMandatory
     GROUP BY UnreadMandatory.student
     ),

     MathCredits AS (
     SELECT PassedCourses.student, SUM (PassedCourses.credits) AS mathCredits FROM PassedCourses, Classified
        WHERE (PassedCourses.course = Classified.course) AND (Classified.classification = 'math') 
        GROUP BY PassedCourses.student
     ),

    ResearchCredits AS (
     SELECT PassedCourses.student, SUM (PassedCourses.credits) AS researchCredits FROM PassedCourses, Classified
        WHERE (PassedCourses.course = Classified.course) AND (Classified.classification = 'research') 
        GROUP BY PassedCourses.student
     ),

    SeminarCourses AS (
     SELECT PassedCourses.student, COUNT (PassedCourses.course) AS seminarCourses FROM PassedCourses, Classified
        WHERE (PassedCourses.course = Classified.course) AND (Classified.classification = 'seminar') 
        GROUP BY PassedCourses.student
    ),
    
    RecommendedCredits AS(
      SELECT student, SUM (credits) AS recommendedCredits FROM PassedCourses
        WHERE (PassedCourses.student, PassedCourses.course) IN (
          SELECT StudentBranches.student, RecommendedBranch.course
          FROM StudentBranches, RecommendedBranch
            WHERE (StudentBranches.branch = RecommendedBranch.branch) AND (StudentBranches.program = RecommendedBranch.program)
      )
      GROUP BY PassedCourses.student
    ),


    HelpPathToGraduation AS (
      SELECT  idnr AS student, COALESCE (totalCredits, 0) AS totalCredits, COALESCE (mandatoryLeft, 0) AS mandatoryLeft,
      COALESCE (mathCredits, 0) AS mathCredits, COALESCE (researchCredits, 0) AS researchCredits,
      COALESCE (seminarCourses, 0) AS seminarCourses, COALESCE (recommendedCredits, 0) AS recommendedCredits
      FROM Students
      LEFT OUTER JOIN TotalCredits ON (idnr = TotalCredits.student)
      LEFT OUTER JOIN MandatoryLeft ON (idnr = MandatoryLeft.student)
      LEFT OUTER JOIN MathCredits ON (idnr = MathCredits.student)
      LEFT OUTER JOIN ResearchCredits ON (idnr = ResearchCredits.student)
      LEFT OUTER JOIN SeminarCourses ON (idnr = SeminarCourses.student)
      LEFT OUTER JOIN RecommendedCredits on (idnr = RecommendedCredits.student)) 

    SELECT student,
    COALESCE (totalCredits, 0) AS totalCredits,
    COALESCE (mandatoryLeft, 0) AS mandatoryLeft,
    COALESCE (mathCredits, 0) AS mathCredits,
    COALESCE (researchCredits, 0) AS researchCredits,
    COALESCE (seminarCourses, 0) AS seminarCourses,
    mathCredits >= 20
    AND researchCredits >= 10
    AND seminarCourses >= 1
    AND recommendedCredits >= 10
    AND mandatoryLeft = 0
    AND EXISTS( SELECT * FROM StudentBranches WHERE student = StudentBranches.student ) 
    AS qualified
    FROM HelpPathToGraduation ;