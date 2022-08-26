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
