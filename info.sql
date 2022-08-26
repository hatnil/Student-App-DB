SELECT jsonb_build_object('student', BasicInformation.idnr, 'name',BasicInformation.name,'login',BasicInformation.login,'program', BasicInformation.program , 'branch', branch ,
'finished',(SELECT COALESCE(json_agg(jsonb_build_object( 'course',Courses.name,'code',FinishedCourses.course,'credits',FinishedCourses.credits,'grade',FinishedCourses.grade)),'[]') FROM FinishedCourses FULL OUTER JOIN Courses ON FinishedCourses.course = Courses.code WHERE student=?), 
'registered',(SELECT COALESCE(json_agg(jsonb_build_object('course',Courses.name,'code',Registrations.course ,'status', Registrations.status)),'[]')FROM Registrations FULL OUTER JOIN Courses ON Registrations.course = Courses.code WHERE student=?)
,'seminarCourses', seminarCourses, 'mathCredits',mathCredits,'researchCredits',researchCredits ,'totalCredits',totalcredits,'canGraduate',qualified) FROM BasicInformation FULL OUTER JOIN PathToGraduation 
ON BasicInformation.idnr = PathToGraduation.student WHERE idnr = ?;

