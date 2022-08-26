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




    


    