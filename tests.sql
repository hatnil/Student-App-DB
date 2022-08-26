---------------------------------------------

-- TEST #1: Register the student who already has taken the course.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('4444444444', 'CCC222');

-- TEST #2: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('1111111111', 'CCC111');

-- TEST #3: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('1111111111', 'CCC555');

-- TEST #4: Register the student who already is in waiting list for course .
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('2222222222', 'CCC333');

-- TEST #5: Register for a Full limited course;
-- EXPECTED OUTCOME: Pass 
INSERT INTO Registrations VALUES ('5555555555', 'CCC222');

-- TEST #6: Register for a  limited course;
-- EXPECTED OUTCOME: Pass 
INSERT INTO Registrations VALUES ('2222222222', 'CCC777');


-- TEST #7: Register the student who  does not fulfill the prerequisites 
-- EXPECTED OUTCOME: fail
INSERT INTO Registrations VALUES ('3333333333', 'CCC666');

-- TEST #8: Unregister from an unlimited course. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC111';

-- TEST #9: unregistered from a limited course without a waiting list. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '3333333333' AND course = 'CCC777';

-- TEST #10: unregistered from a limited course with a waiting list, when the student is registered. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC222';


-- TEST #11: unregistered from a limited course with a waiting list, when the student is in the middle of the waiting list;
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '2222222222' AND course = 'CCC333';

-- TEST #12: unregistered from an overfull course with a waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC333';