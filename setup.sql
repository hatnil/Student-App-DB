--Nilufar Hatamova

--TABLES
CREATE TABLE Department(
   name TEXT UNIQUE NOT NULL,
   abbreviation TEXT PRIMARY KEY
);

CREATE TABLE Program(
   name TEXT PRIMARY KEY,
   abbreviation TEXT NOT NULL
);

CREATE TABLE Students(
   idnr VARCHAR(10) PRIMARY KEY,
   name TEXT NOT NULL,
   login TEXT UNIQUE NOT NULL,
   program TEXT NOT NULL,
   FOREIGN KEY (program) REFERENCES Program(name),
   CONSTRAINT studentProgram UNIQUE(idnr,program)
);

CREATE TABLE Branches (
   name TEXT NOT NULL,
   program TEXT NOT NULL,
   PRIMARY KEY (name, program),
   FOREIGN KEY (program) REFERENCES Program(name)
);

CREATE TABLE Courses (
   code VARCHAR(6) PRIMARY KEY,
   name TEXT NOT NULL,
   credits FLOAT NOT NULL CHECK (credits >= 0),
   department TEXT NOT NULL ,
   FOREIGN KEY (department) REFERENCES Department(abbreviation)
);
 
CREATE TABLE Prerequisites(
	course CHAR(6) ,
	prerequisite CHAR(6) ,
	PRIMARY KEY (course,prerequisite),
  FOREIGN KEY  (course) REFERENCES Courses(code),
  FOREIGN KEY  (prerequisite) REFERENCES Courses(code)
);

CREATE TABLE LimitedCourses(
   code VARCHAR(6) PRIMARY KEY,
   capacity INTEGER NOT NULL CHECK (capacity >= 0),
   FOREIGN KEY (code) REFERENCES Courses (code)
);

CREATE TABLE StudentBranches(
   student VARCHAR(10) PRIMARY KEY,
   branch TEXT NOT NULL,
   program TEXT NOT NULL,
   FOREIGN KEY (student) REFERENCES Students(idnr),
   FOREIGN KEY (branch, program) REFERENCES Branches(name, program),
   CONSTRAINT checkStudentProgram  FOREIGN KEY (student, program) REFERENCES Students(idnr,program)
);

CREATE TABLE Classifications(name TEXT PRIMARY KEY);

CREATE TABLE Classified(
   course VARCHAR(6) NOT NULL,
   classification TEXT NOT NULL,
   PRIMARY KEY (course, classification),
   FOREIGN KEY (course) REFERENCES Courses(code),
   FOREIGN KEY (classification) REFERENCES Classifications(name)
);

CREATE TABLE MandatoryProgram(
   course VARCHAR(6) NOT NULL,
   program TEXT NOT NULL,
   PRIMARY KEY(course, program),
   FOREIGN KEY(course) REFERENCES Courses(code),
   FOREIGN KEY (program) REFERENCES Program(name)
);

CREATE TABLE MandatoryBranch(
   course VARCHAR(6) NOT NULL,
   branch TEXT NOT NULL,
   program TEXT NOT NULL,
   PRIMARY KEY(course, branch, program),
   FOREIGN KEY(course) REFERENCES Courses(code),
   FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch(
   course VARCHAR(6) NOT NULL,
   branch TEXT NOT NULL,
   program TEXT NOT NULL,
   PRIMARY KEY(course, branch, program),
   FOREIGN KEY(course) REFERENCES Courses(code),
   FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Registered(
   student VARCHAR(10) NOT NULL,
   course VARCHAR(6) NOT NULL,
   PRIMARY KEY(student, course),
   FOREIGN KEY (student) REFERENCES Students(idnr),
   FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE Taken(
   student VARCHAR(10) NOT NULL,
   course VARCHAR(6) NOT NULL,
   grade CHAR(1) NOT NULL CHECK (grade in ('U', '3', '4', '5')),
   PRIMARY KEY(student, course),
   FOREIGN KEY (student) REFERENCES Students(idnr),
   FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE WaitingList(
   student VARCHAR(10) NOT NULL,
   course VARCHAR(6) NOT NULL,
   position SERIAL,
   PRIMARY KEY (student, course),
   FOREIGN KEY (student) REFERENCES Students(idnr),
   FOREIGN KEY (course) REFERENCES LimitedCourses(code),
   CONSTRAINT waitingCoursePosition UNIQUE (course, position)
);
CREATE TABLE Hosts (
    department TEXT NOT NULL REFERENCES Department(abbreviation),
    program TEXT NOT NULL REFERENCES Program(name)
);

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




--INSERTS
INSERT INTO Department VALUES('Department1','Dep1');
INSERT INTO Department VALUES('Department2','Dep2');

INSERT INTO Program VALUES('Prog1','P1');
INSERT INTO Program VALUES('Prog2','P2');

INSERT INTO Hosts VALUES('Dep1','Prog1');
INSERT INTO Hosts VALUES('Dep2','Prog1');
INSERT INTO Hosts VALUES('Dep1','Prog2');

INSERT INTO Branches VALUES ('B1', 'Prog1');
INSERT INTO Branches VALUES ('B2', 'Prog1');
INSERT INTO Branches VALUES ('B1', 'Prog2');

INSERT INTO Students VALUES ('1111111111', 'N1', 'ls1', 'Prog1');
INSERT INTO Students VALUES ('2222222222', 'N2', 'ls2', 'Prog1');
INSERT INTO Students VALUES ('3333333333', 'N3', 'ls3', 'Prog2');
INSERT INTO Students VALUES ('4444444444', 'N4', 'ls4', 'Prog1');
INSERT INTO Students VALUES ('5555555555', 'Nx', 'ls5', 'Prog2');
INSERT INTO Students VALUES ('6666666666', 'Nx', 'ls6', 'Prog2');

INSERT INTO Courses VALUES ('CCC111', 'C1', 22.5, 'Dep1');
INSERT INTO Courses VALUES ('CCC222', 'C2', 20,   'Dep1');
INSERT INTO Courses VALUES ('CCC333', 'C3', 30,   'Dep1');
INSERT INTO Courses VALUES ('CCC444', 'C4', 40,   'Dep1');
INSERT INTO Courses VALUES ('CCC555', 'C5', 50,   'Dep1');
INSERT INTO Courses VALUES ('CCC666', 'C6', 20,   'Dep2');
INSERT INTO Courses VALUES ('CCC777', 'C7', 25,   'Dep2');

INSERT INTO Prerequisites VALUES ('CCC666', 'CCC111');

INSERT INTO LimitedCourses VALUES ('CCC222', 2);
INSERT INTO LimitedCourses VALUES ('CCC333', 2);
INSERT INTO LimitedCourses VALUES ('CCC666', 2);
INSERT INTO LimitedCourses VALUES ('CCC777', 2);

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333', 'math');
INSERT INTO Classified VALUES ('CCC444', 'research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranches VALUES ('2222222222', 'B1', 'Prog1');
INSERT INTO StudentBranches VALUES ('3333333333', 'B1', 'Prog2');
INSERT INTO StudentBranches VALUES ('4444444444', 'B1', 'Prog1');

INSERT INTO MandatoryProgram VALUES ('CCC111', 'Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC555', 'B1', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B2', 'Prog1');

INSERT INTO Registered VALUES ('1111111111', 'CCC111');
INSERT INTO Registered VALUES ('1111111111', 'CCC222');
INSERT INTO Registered VALUES ('2222222222', 'CCC222');
INSERT INTO Registered VALUES ('5555555555', 'CCC333');
INSERT INTO Registered VALUES ('1111111111', 'CCC333');
INSERT INTO Registered VALUES ('3333333333','CCC777');
-- Overfulling
INSERT INTO Registered VALUES ('6666666666', 'CCC333');

INSERT INTO WaitingList VALUES ('3333333333', 'CCC222');
INSERT INTO WaitingList VALUES ('3333333333', 'CCC333');
INSERT INTO WaitingList VALUES ('2222222222', 'CCC333');

INSERT INTO Taken VALUES('2222222222', 'CCC111', 'U');
INSERT INTO Taken VALUES('2222222222', 'CCC222', 'U');
INSERT INTO Taken VALUES('2222222222', 'CCC444', 'U');

INSERT INTO Taken VALUES('4444444444', 'CCC111', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC222', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC333', '5');
INSERT INTO Taken VALUES('4444444444', 'CCC444', '5');

INSERT INTO Taken VALUES('5555555555', 'CCC111', '5');
INSERT INTO Taken VALUES('5555555555', 'CCC333', '5');
INSERT INTO Taken VALUES('5555555555', 'CCC444', '5');




--TRIGGERS--
--CourseQueuePositions(course,student,place)
CREATE VIEW CourseQueuePositions AS 
SELECT course, student,rank() OVER (PARTITION BY course ORDER BY position)   AS place
FROM WaitingList;

-- Register Trigger
CREATE FUNCTION courseRegisteration() RETURNS trigger AS $register$
    -- the variable will be used in loop.
    DECLARE  numOfprerequisites INTEGER;
    DECLARE passedPrerequisites INTEGER;
    BEGIN
        -- Check if student has already taken the course.
        IF(EXISTS(SELECT student FROM Taken WHERE student = NEW.student AND course = NEW.course AND grade != 'U'))
	        THEN RAISE EXCEPTION 'The student has already completed this course ';
        END IF;

        -- Check if student has already registered for the course.
        IF(EXISTS(SELECT student FROM Registered WHERE student = NEW.student AND course = NEW.course))
	        THEN RAISE EXCEPTION 'The student has already registered for this course ';
        END IF;

        -- Check if student fulfill the prerequisites for the course.
        numOfprerequisites := (SELECT COUNT (prerequisite) FROM Prerequisites WHERE Prerequisites.course = NEW.course);
        passedPrerequisites := (SELECT COUNT (student) FROM Prerequisites JOIN PassedCourses ON prerequisite = PassedCourses.course
								WHERE student = NEW.student AND Prerequisites.course = NEW.course);

        IF(numOfprerequisites>passedPrerequisites)
		    THEN RAISE EXCEPTION 'The student do not fulfill the prerequisites for this course!!!';
        END IF;
            
        -- Check if  course is limited.
        IF(NEW.course IN (SELECT LimitedCourses.code FROM LimitedCourses) )
            THEN 
                -- Check if student is already in waitinglist for this course.
                IF(EXISTS (SELECT student FROM WaitingList WHERE student = NEW.student AND course = NEW.course))
                    THEN RAISE EXCEPTION 'The student is already in waitinglist for this course';
                -- Check if the course full then add student to the waiting list for course   
                ELSIF((SELECT COUNT(Registered.student) FROM Registered WHERE Registered.course = NEW.course) >= (SELECT LimitedCourses.capacity FROM LimitedCourses WHERE LimitedCourses.code = NEW.course))
                        THEN 
                            INSERT INTO WaitingList VALUES (NEW.student, NEW.course);
                            RETURN NEW;      

                --  if the course  is not full then add student to the registered              
                ELSE
                    INSERT INTO Registered VALUES (NEW.student, NEW.course);
                    RETURN NEW;
                END IF;
        -- if  course is not limited thne add student to register.
        ELSE
            INSERT INTO Registered VALUES (NEW.student, NEW.course);
                    RETURN NEW;
        END IF;
    END   
$register$ LANGUAGE plpgsql;

CREATE TRIGGER register INSTEAD OF INSERT  OR UPDATE ON Registrations

    FOR EACH ROW EXECUTE FUNCTION courseRegisteration();




-- Unregister Trigger
CREATE FUNCTION unregister() RETURNS trigger  AS $unregister$
    DECLARE maxseats INT;
    DECLARE numstudent INT;
    DECLARE waiter CHAR(10);
    BEGIN
    --Check if student in registered.
        IF OLD.student IN (SELECT student FROM Registered WHERE  course = OLD.course ) 
            THEN  
                --Check if the course is limited
                IF(EXISTS(SELECT code FROM LimitedCourses WHERE code = OLD.course) AND EXISTS(SELECT course FROM Registered WHERE student = OLD.student AND course = OLD.course))
                   THEN
                        -- Unregister student by deleting from Registered.
                        DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
                        numstudent := (SELECT COUNT(student) FROM Registered WHERE  course = OLD.course) ;
                        maxseats :=(SELECT capacity FROM LimitedCourses WHERE code = OLD.course);
                        --Check if course has empty seat
                        IF(maxseats>numstudent)
                            THEN
                                --Check if there are some student who waits for empty seat
                                IF(EXISTS(SELECT student FROM Waitinglist WHERE  course = OLD.course )) 
                                    THEN
                                        --Select the student with minimum position, means who waited longest.
                                         waiter :=(SELECT student  FROM CourseQueuePositions WHERE CourseQueuePositions.course=OLD.course AND CourseQueuePositions.place = 1);
                                        --Insert the student to Registered
                                        INSERT INTO Registered VALUES (waiter, OLD.course);
                                        -- Remove the student from Waiting list
                                        DELETE FROM WaitingList WHERE student = waiter AND course = OLD.course;
                                        
                                                                             
                                END IF;
                        END IF;
                --if the course is not limited then unregister the student by deleting from Registered
                ELSE 
                DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
                
                END IF; 
        RETURN OLD;
        END IF;

        --Check if the student is in waitinf list. If so, then remove student from waiting list.
        IF  OLD.student IN (SELECT WaitingList.student FROM WaitingList WHERE WaitingList.course = OLD.course)
        THEN   
            DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
            RETURN OLD;
        END IF;
    END   
$unregister$ LANGUAGE plpgsql;

CREATE TRIGGER unregister INSTEAD OF DELETE   ON Registrations

    FOR EACH ROW EXECUTE FUNCTION unregister();




    


    