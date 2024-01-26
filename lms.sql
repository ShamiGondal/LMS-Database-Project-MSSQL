Create database lmsTrail2
Drop database lmsTrail2

use lmsTrail2

use LMSTRAIL4


-- (Classifying Entity)
CREATE TABLE [User] ( 
    UserID INT PRIMARY KEY,
	FirstName NVARCHAR(60),
	LastName NVARCHAR(60),
    Email VARCHAR(100),
    Password VARCHAR(100),
    UserType VARCHAR(20) CHECK (UserType IN ('Student', 'Teacher', 'Admin'))
);

-- (Component Entity)
CREATE TABLE Admin (
    AdminID INT PRIMARY KEY,
    UserID INT UNIQUE FOREIGN KEY REFERENCES [User](UserID)
);

-- (Component Entity)
CREATE TABLE Teacher (
    TeacherID INT PRIMARY KEY,
    UserID INT UNIQUE FOREIGN KEY REFERENCES [User](UserID)
);

-- (Component Entity)
CREATE TABLE Student (
    StudentID INT PRIMARY KEY,
    UserID INT UNIQUE FOREIGN KEY REFERENCES [User](UserID)
);

-- (Transactional Entity)
CREATE TABLE Course (
    CourseID INT PRIMARY KEY,
    CourseName VARCHAR(100),
    CourseDescription TEXT,
    TeacherID INT,
    AdminID INT,
    CONSTRAINT FK_Teacher FOREIGN KEY (TeacherID) REFERENCES Teacher(TeacherID),
    CONSTRAINT FK_Admin FOREIGN KEY (AdminID) REFERENCES Admin(AdminID),
    CONSTRAINT CK_AdminTeacherCourse UNIQUE (AdminID, TeacherID, CourseID)
);

-- (Transactional Entity)
CREATE TABLE Enrollment (
    EnrollmentID INT PRIMARY KEY,
    StudentID INT,
    CourseID INT,
    EnrollmentDate DATE,
    CONSTRAINT FK_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT UQ_Enrollment UNIQUE (StudentID, CourseID),
);

-- (Transactional Entity)
CREATE TABLE CourseFeeDetail (
    FeeID INT PRIMARY KEY,
    CourseID INT,
    Fee DECIMAL(10, 2),
    CONSTRAINT FK_CourseFee_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- (Transactional Entity)
CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY,
	EnrollmentID INT FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID),
    PaymentDate DATE,
    AmountPaid DECIMAL(10, 2),
    PaymentStatus VARCHAR(20) CHECK (PaymentStatus IN ('Completed')),
	CONSTRAINT UNIQUE_PAYMENT UNIQUE (PaymentID, EnrollmentID),
);

-- (Transactional Entity)
CREATE TABLE Lesson (
    LessonID INT PRIMARY KEY,
    CourseID INT,
    Title VARCHAR(100),
	VideoLink NVARCHAR(255),
    Attachments TEXT,
    CONSTRAINT FK_Lesson_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);

-- (Transactional Entity)
CREATE TABLE Feedback (
    FeedbackID INT PRIMARY KEY,
    StudentID INT,
    CourseID INT,
    TeacherID INT,
    Comment TEXT,
    CommentType VARCHAR(10) CHECK (CommentType IN ('Teacher', 'Course')),
    CONSTRAINT FK_Feedback_Student FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    CONSTRAINT FK_Feedback_Course FOREIGN KEY (CourseID) REFERENCES Course(CourseID),
    CONSTRAINT FK_Feedback_Teacher FOREIGN KEY (TeacherID) REFERENCES Teacher(TeacherID)
);

-- (Transactional Entity)
CREATE TABLE Exam (
    ExamID INT PRIMARY KEY,
	EnrollmentID INT, --addition
    Title VARCHAR(100),
    TotalMarks INT,
    ObtainedMarks INT,
	ExamDate DATE,
    ExamType VARCHAR(10) CHECK (ExamType IN ('Assignment', 'Quiz')),
	CONSTRAINT FK_Exam_Enrollment FOREIGN KEY (EnrollmentID) REFERENCES Enrollment(EnrollmentID),
);


-- Trigger for inserting data into Teacher table of student Teacher and Admin 
----------------------------------------------------------------------------------------------------------------------------------------


CREATE TRIGGER trg_InsertTeacher
ON [User]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Teacher (TeacherID, UserID)
    SELECT i.UserID, i.UserID
    FROM inserted i
    WHERE i.UserType = 'Teacher';
END;
GO
CREATE TRIGGER trg_InsertStudent
ON [User]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Student (StudentID, UserID)
    SELECT i.UserID, i.UserID
    FROM inserted i
    WHERE i.UserType = 'Student';
END;
GO
CREATE TRIGGER trg_InsertAdmin
ON [User]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Admin (AdminID, UserID)
    SELECT i.UserID, i.UserID
    FROM inserted i
    WHERE i.UserType = 'Admin';
END;
GO




--Audit tables To Maintain Important History
----------------------------------------------------------------------------------------------------------------------------------------


CREATE TABLE CoursePaymentHistory (
    PaymentID INT PRIMARY KEY,
	EnrollmentID INT ,
    PaymentDate DATE,
    AmountPaid DECIMAL(10, 2),
    PaymentStatus VARCHAR(20) CHECK (PaymentStatus IN ('Completed')),
    ChangeType VARCHAR(20) CHECK (ChangeType IN ('CourseDeleted')),
);

select * from CoursePaymentHistory
select * from payment


-- change id before insertion
UPDATE Payment
SET PaymentStatus = 'Completed'
WHERE PaymentID = 20
  AND EnrollmentID = 65;

Delete Payment
WHERE PaymentID = 68
 AND EnrollmentID = 273


-- Create the new trigger for both DELETE and UPDATE operations
CREATE TRIGGER trg_InsertUpdateDeletePayment
ON Payment
AFTER DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

   
    IF (SELECT COUNT(*) FROM deleted) > 0 OR (SELECT COUNT(*) FROM inserted) > 0
    BEGIN
        -- Insert deleted or updated payment records into CoursePaymentHistory
        INSERT INTO CoursePaymentHistory (PaymentID, EnrollmentID, PaymentDate, AmountPaid, PaymentStatus, ChangeType)
        SELECT
            COALESCE(d.PaymentID, i.PaymentID), 
            COALESCE(d.EnrollmentID, i.EnrollmentID), 
            COALESCE(d.PaymentDate, i.PaymentDate),  
            COALESCE(d.AmountPaid, i.AmountPaid),    
            COALESCE(i.PaymentStatus, 'Completed'),  
            CASE 
                WHEN d.PaymentID IS NOT NULL THEN 'CourseDeleted'
                WHEN i.PaymentID IS NOT NULL THEN 'CourseUpdated'
            END
        FROM deleted d
        FULL OUTER JOIN inserted i ON d.PaymentID = i.PaymentID;
    END;
END;

------------------------------------------------------------------------------------

CREATE TABLE EnrollmentHistory (
    EnrollmentID INT PRIMARY KEY,
    StudentID INT,
    CourseID INT,
    EnrollmentDate DATE,
    ChangeType VARCHAR(20) CHECK (ChangeType IN ('PassedOut', 'Updated', 'Added', 'Deleted')),
    ChangeDate DATETIME
);

UPDATE Enrollment
SET EnrollmentDate = '2023-01-19'
WHERE EnrollmentID = 6;



DELETE FROM Enrollment
WHERE EnrollmentID = 2;
--will give the error because of payment

select * from Enrollment
select * from EnrollmentHistory


DROP TRIGGER trg_InsertUpdateDeleteEnrollment;

CREATE TRIGGER trg_InsertUpdateDeleteEnrollment
ON Enrollment
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF (SELECT COUNT(*) FROM inserted) > 0
    BEGIN
        -- Insert/Update records into EnrollmentHistory
        INSERT INTO EnrollmentHistory (EnrollmentID, StudentID, CourseID, EnrollmentDate, ChangeType, ChangeDate)
        SELECT
            i.EnrollmentID,
            i.StudentID,
            i.CourseID,
            i.EnrollmentDate,
            CASE 
                WHEN EXISTS(SELECT 1 FROM deleted d WHERE d.EnrollmentID = i.EnrollmentID) THEN 'Updated'
                ELSE 'Added'
            END,
            GETDATE()
        FROM inserted i;
    END
    ELSE IF (SELECT COUNT(*) FROM deleted) > 0  
    BEGIN
        INSERT INTO EnrollmentHistory (EnrollmentID, StudentID, CourseID, EnrollmentDate, ChangeType, ChangeDate)
        SELECT
            d.EnrollmentID,
            d.StudentID,
            d.CourseID,
            d.EnrollmentDate,
            'Deleted',
            GETDATE()
        FROM deleted d;
    END;
END;


--Procedures for the insertions 
----------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE InsertUser
    @UserID INT,
    @FirstName NVARCHAR(60),
    @LastName NVARCHAR(60),
    @Email VARCHAR(100),
    @Password VARCHAR(100),
    @UserType VARCHAR(20)
AS
BEGIN
    -- Check if the UserID or Email already exists in the User table
    IF NOT EXISTS (
        SELECT 1
        FROM [User]
        WHERE UserID = @UserID OR Email = @Email
    )
    BEGIN
        INSERT INTO [User] (UserID, FirstName, LastName, Email, Password, UserType)
        VALUES (@UserID, @FirstName, @LastName, @Email, @Password, @UserType);

        PRINT 'User record inserted successfully';
    END
    ELSE
    BEGIN
        PRINT 'UserID or Email already exists. User record not inserted.';
    END
END;




EXEC InsertUser
    @UserID = 111,
    @FirstName = 'John',
    @LastName = 'Doe',
    @Email = 'john.doe@example.com',
    @Password = 'password123',
    @UserType = 'Student';



CREATE PROCEDURE InsertCourse
    @CourseID INT,
    @CourseName VARCHAR(100),
    @CourseDescription TEXT,
    @TeacherID INT,
    @AdminID INT
AS
BEGIN
    
    IF EXISTS (
        SELECT 1
        FROM Teacher
        WHERE TeacherID = @TeacherID
    ) AND EXISTS (
        SELECT 1
        FROM Admin
        WHERE AdminID = @AdminID
    )
    BEGIN
        
        IF NOT EXISTS (
            SELECT 1
            FROM Course
            WHERE AdminID = @AdminID AND TeacherID = @TeacherID AND CourseID = @CourseID
        )
        BEGIN
            INSERT INTO Course (CourseID, CourseName, CourseDescription, TeacherID, AdminID)
            VALUES (@CourseID, @CourseName, @CourseDescription, @TeacherID, @AdminID);

            PRINT 'Course record inserted successfully';
        END
        ELSE
        BEGIN
            PRINT 'Combination of AdminID, TeacherID, and CourseID already exists. Course record not inserted.';
        END
    END
    ELSE
    BEGIN
        PRINT 'Invalid TeacherID or AdminID. Course record not inserted.';
    END
END;


EXEC InsertCourse
    @CourseID = 31,
    @CourseName = 'Introduction to SQL',
    @CourseDescription = 'A beginner-friendly course on SQL',
    @TeacherID = 212,
    @AdminID = 61;

-- Lessons insertions procedure

CREATE PROCEDURE InsertLesson
    @LessonID INT,
    @CourseID INT,
    @Title VARCHAR(100),
    @VideoLink NVARCHAR(255),
    @Attachments TEXT
AS
BEGIN
  
    IF EXISTS (
        SELECT 1
        FROM Course
        WHERE CourseID = @CourseID
    )
    BEGIN
        INSERT INTO Lesson (LessonID, CourseID, Title, VideoLink, Attachments)
        VALUES (@LessonID, @CourseID, @Title, @VideoLink, @Attachments);
        
        PRINT 'Lesson record inserted successfully';
    END
    ELSE
    BEGIN
        PRINT 'CourseID does not exist in the Course table. Lesson record not inserted.';
    END
END;



-- Example for InsertLesson procedure
EXEC InsertLesson
    @LessonID = 1991,
    @CourseID = 2,
    @Title = 'Introduction to SQL',
    @VideoLink = 'https://example.com/sql_intro',
    @Attachments = 'Lesson materials';

-- course Fee procedure

drop procedure InsertCourseFeeDetail
CREATE PROCEDURE InsertCourseFeeDetail
    @FeeID INT,
    @CourseID INT,
    @Fee DECIMAL(10, 2)
AS
BEGIN
    -- Check if the CourseID exists in the Course table
    IF EXISTS (
        SELECT 1
        FROM Course
        WHERE CourseID = @CourseID
    )
    BEGIN
        INSERT INTO CourseFeeDetail (FeeID, CourseID, Fee)
	    VALUES (@FeeID, @CourseID, @Fee);
	   
        PRINT 'CourseFee record inserted successfully';
    END
    ELSE
    BEGIN
        PRINT 'CourseID does not exist in the Course table. CourseFee record not inserted.';
    END
END;

-- Example for InsertCourseFeeDetail procedure
EXEC InsertCourseFeeDetail
    @FeeID = 901,
    @CourseID = 6,
    @Fee = 500.00;

-- feedback insertion procedure

CREATE PROCEDURE InsertFeedback
    @FeedbackID INT,
    @StudentID INT,
    @CourseID INT,
    @TeacherID INT,
    @Comment TEXT,
    @CommentType VARCHAR(10)
AS
BEGIN
   
    IF EXISTS (
        SELECT 1
        FROM Student
        WHERE StudentID = @StudentID
    ) AND EXISTS (
        SELECT 1
        FROM Course
        WHERE CourseID = @CourseID
    ) AND EXISTS (
        SELECT 1
        FROM Teacher
        WHERE TeacherID = @TeacherID
    )
    BEGIN
        INSERT INTO Feedback (FeedbackID, StudentID, CourseID, TeacherID, Comment, CommentType)
        VALUES (@FeedbackID, @StudentID, @CourseID, @TeacherID, @Comment, @CommentType);
        
        PRINT 'Feedback record inserted successfully';
    END
    ELSE
    BEGIN
        PRINT 'Invalid StudentID, CourseID, or TeacherID. Feedback record not inserted.';
    END
END;



-- Example for InsertFeedback procedure
EXEC InsertFeedback
    @FeedbackID = 798,
    @StudentID = 111,
    @CourseID = 3,
    @TeacherID = 211,
    @Comment = 'Great course!',
    @CommentType = 'Teacher';

--Enrollment Insertion

CREATE PROCEDURE InsertEnrollment
    @EnrollmentID INT,
    @StudentID INT,
    @CourseID INT,
    @EnrollmentDate DATE
AS
BEGIN
    
    IF NOT EXISTS (
        SELECT 1
        FROM Enrollment
        WHERE StudentID = @StudentID AND CourseID = @CourseID
    )
    BEGIN
        INSERT INTO Enrollment (EnrollmentID, StudentID, CourseID, EnrollmentDate)
        VALUES (@EnrollmentID, @StudentID, @CourseID, @EnrollmentDate);
        
        PRINT 'Enrollment record inserted successfully';
    END
    ELSE
    BEGIN
        PRINT 'Combination of StudentID and CourseID already exists. Enrollment record not inserted.';
    END
END;


-- Example for InsertEnrollment procedure
EXEC InsertEnrollment
    @EnrollmentID = 301,
    @StudentID = 113,
    @CourseID = 3,
    @EnrollmentDate = '2023-01-01';

	select * from Enrollment

-- payment insertion 
drop procedure InsertPaymentWithCheck
CREATE PROCEDURE InsertPaymentWithCheck
    @PaymentID INT,
    @EnrollmentID INT,
    @PaymentDate DATE,
    @AmountPaid DECIMAL(10, 2),
    @PaymentStatus VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        -- Check if the combination of EnrollmentID and PaymentID already exists in the Payment table
        IF NOT EXISTS (
            SELECT 1
            FROM Payment
            WHERE EnrollmentID = @EnrollmentID AND PaymentID = @PaymentID
        )
        BEGIN
            -- Check if the student has already paid for the specified course
            IF EXISTS (
                SELECT 1
                FROM Payment P
                INNER JOIN Enrollment E ON P.EnrollmentID = E.EnrollmentID
                WHERE E.EnrollmentID = @EnrollmentID
            )
            BEGIN
                -- If the student has already paid, return failure
                RETURN 0;
            END

            -- If the combination doesn't exist and the student has not already paid, perform the insert
            INSERT INTO Payment (PaymentID, EnrollmentID, PaymentDate, AmountPaid, PaymentStatus)
            VALUES (@PaymentID, @EnrollmentID, @PaymentDate, @AmountPaid, @PaymentStatus);
            
            -- Return success
            RETURN 1;
        END
        ELSE
        BEGIN
            -- If the combination already exists, return failure
            RETURN 0;
        END
    END TRY
    BEGIN CATCH
        -- Return failure if an error occurs
        RETURN 0;
    END CATCH
END;


-- Example for InsertPaymentWithCheck procedure
EXEC InsertPaymentWithCheck
    @PaymentID = 332,
    @EnrollmentID = 123,
    @PaymentDate = '2023-01-01',
    @AmountPaid = 100.00,
    @PaymentStatus = 'Paid';


--Exam Insertion Procedure

CREATE PROCEDURE InsertExam
    @ExamID INT,
    @EnrollmentID INT,
    @Title VARCHAR(100),
    @TotalMarks INT,
    @ObtainedMarks INT,
    @ExamDate DATE,
    @ExamType VARCHAR(10)
AS
BEGIN
    
    IF EXISTS (
        SELECT 1
        FROM Enrollment e
        JOIN Course c ON e.CourseID = c.CourseID
        WHERE e.EnrollmentID = @EnrollmentID
    )
    BEGIN
      
        DECLARE @AssignmentCount INT, @QuizCount INT;

        SELECT
            @AssignmentCount = COUNT(*)
        FROM
            Exam
        WHERE
            EnrollmentID = @EnrollmentID AND ExamType = 'Assignment';

        SELECT
            @QuizCount = COUNT(*)
        FROM
            Exam
        WHERE
            EnrollmentID = @EnrollmentID AND ExamType = 'Quiz';

        PRINT 'Existing Assignment Count: ' + CAST(@AssignmentCount AS VARCHAR(10));
        PRINT 'Existing Quiz Count: ' + CAST(@QuizCount AS VARCHAR(10));

        IF (@ExamType = 'Assignment' AND @AssignmentCount < 5) OR
           (@ExamType = 'Quiz' AND @QuizCount < 4)
        BEGIN
            INSERT INTO Exam (ExamID, EnrollmentID, Title, TotalMarks, ObtainedMarks, ExamDate, ExamType)
            VALUES (@ExamID, @EnrollmentID, @Title, @TotalMarks, @ObtainedMarks, @ExamDate, @ExamType);

            PRINT 'Exam record inserted successfully';
        END
        ELSE
        BEGIN
            PRINT 'The maximum limit for exams of type ' + @ExamType + ' has been reached for this course.';
        END
    END
    ELSE
    BEGIN
        PRINT 'EnrollmentID does not exist or is not associated with a valid course. Exam record not inserted.';
    END
END;




-- Example for InsertExam procedure
EXEC InsertExam
    @ExamID = 981,
    @EnrollmentID = 1,
    @Title = 'Midterm Exam',
    @TotalMarks = 100,
    @ObtainedMarks = 85,
    @ExamDate = '2023-02-01',
    @ExamType = 'Assignment';







-- Denormalized Table for Reporting Purpose
----------------------------------------------------------------------------------------------------------------------------------------

SELECT
    E.EnrollmentID,
    E.StudentID,
    E.CourseID,
    C.CourseName,
    C.CourseDescription,
    E.EnrollmentDate,
    P.PaymentID,
    P.PaymentDate,
    P.AmountPaid,
    P.PaymentStatus,
    Ex.ExamID,
    Ex.Title,
    Ex.TotalMarks,
    Ex.ObtainedMarks,
    Ex.ExamDate,
    Ex.ExamType
FROM Enrollment E
JOIN Course C ON E.CourseID = C.CourseID
LEFT JOIN Payment P ON E.EnrollmentID = P.EnrollmentID
LEFT JOIN Exam Ex ON E.EnrollmentID = Ex.EnrollmentID
WHERE P.PaymentStatus = 'Completed' AND EX.ExamID IS NOT NULL ;


-- Create a new table for the analytical report
CREATE TABLE AnalyticalReport (
    EnrollmentID INT,
    StudentID INT,
    CourseID INT,
    CourseName VARCHAR(100),
    CourseDescription TEXT,
    EnrollmentDate DATE,
    PaymentID INT NULL,	
    PaymentDate DATE,
    AmountPaid DECIMAL(10, 2),
    PaymentStatus VARCHAR(20),
    ExamID INT,
    Title VARCHAR(100),
    TotalMarks INT,
    ObtainedMarks INT,
    ExamDate DATE,
    ExamType VARCHAR(10)
);
CREATE NONCLUSTERED INDEX IX_EnrollmentID
ON AnalyticalReport (EnrollmentID);

select * from AnalyticalReport

-- Bulk Insertion from CSV File
BULK INSERT AnalyticalReport
FROM 'C:\Users\Hp\Desktop\newDeNorTable.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);


--Reporting From Denormalized Table
----------------------------------------------------------------------------------------------------------------------------------------
--Retrieve average amount paid per course:

SELECT
    CourseID,
    AVG(AmountPaid) AS AverageAmountPaid
FROM AnalyticalReport
GROUP BY CourseID;

--Retrieve the count of enrollments per course:

SELECT
    CourseID, CourseName,
    COUNT(EnrollmentID) AS EnrollmentCount
FROM AnalyticalReport
GROUP BY CourseID , CourseName;

--Average obtained marks 
SELECT
    CourseID ,CourseName,
    AVG(ObtainedMarks) AS ObtainedMarks
FROM AnalyticalReport
WHERE ExamID IS NOT NULL
GROUP BY CourseID, CourseName;

--Retrieve the maximum amount paid for a course:

SELECT TOP 3
    CourseID,
    MAX(AmountPaid) AS MaxAmountPaid
FROM AnalyticalReport
WHERE PaymentStatus = 'Completed'
GROUP BY CourseID;


-- Most enrolled course

SELECT TOP 1
    CourseID,
    CourseName,
    COUNT(EnrollmentID) AS EnrollmentCount
FROM AnalyticalReport
GROUP BY CourseID, CourseName
ORDER BY EnrollmentCount DESC

--Most generated Revenue 

SELECT Top 1
    CourseID,
    CourseName,
    SUM(AmountPaid) AS TotalRevenue
FROM AnalyticalReport
WHERE PaymentStatus = 'Completed'
GROUP BY CourseID, CourseName
ORDER BY TotalRevenue DESC

-- Create stored procedure to get complete exam details for a student
CREATE PROCEDURE GetStudentExamDetails
    @StudentID INT
AS
BEGIN
    SELECT
        AR.EnrollmentID,
        AR.CourseID,
        AR.CourseName,
        AR.CourseDescription,
        AR.EnrollmentDate,
        AR.ExamID,
        AR.Title AS ExamTitle,
        AR.TotalMarks,
        AR.ObtainedMarks,
        AR.ExamDate,
        AR.ExamType
    FROM
        AnalyticalReport AR
    WHERE
        AR.StudentID = @StudentID
        AND AR.ExamID IS NOT NULL; 
END;

EXEC GetStudentExamDetails @StudentID = 127

CREATE PROCEDURE GetStudentPerformanceSummaryFromDenormalized
    @StudentID INT
AS
BEGIN
    SELECT
        AR.EnrollmentID,
        AR.CourseID,
        AR.CourseName,
        ISNULL(SUM(AR.ObtainedMarks), 0) AS TotalObtainedMarks,
        100 AS TotalPossibleMarks, -- Constant total possible marks
        ISNULL(SUM(CASE WHEN AR.ExamType = 'Assignment' THEN 1 ELSE 0 END), 0) AS AssignmentCount,
        ISNULL(SUM(CASE WHEN AR.ExamType = 'Quiz' THEN 1 ELSE 0 END), 0) AS QuizCount,
        CASE
            WHEN ISNULL(SUM(AR.ObtainedMarks), 0) > 0 
                 THEN (ISNULL(SUM(AR.ObtainedMarks), 0) * 100) / 100
            ELSE 0
        END AS Percentage,
        CASE
            WHEN ISNULL(SUM(AR.ObtainedMarks), 0) * 100 / 100 >= 50 THEN 'Pass'
            ELSE 'Fail'
        END AS Result
    FROM
        AnalyticalReport AR
    WHERE
        AR.StudentID = @StudentID
    GROUP BY
        AR.EnrollmentID, AR.CourseID, AR.CourseName;
END;

EXEC GetStudentPerformanceSummaryFromDenormalized @StudentID = 127
--General Reporting
----------------------------------------------------------------------------------------------------------------------------------------


--7.

CREATE PROCEDURE GetEnrollmentsCountForCourse
    @CourseID INT
AS
BEGIN
    -- Query to count enrollments for a specific course
    SELECT
        C.CourseID,
        C.CourseName,
        COUNT(E.EnrollmentID) AS EnrollmentsCount
    FROM
        Course C
    LEFT JOIN
        Enrollment E ON C.CourseID = E.CourseID
    WHERE
        C.CourseID = @CourseID
    GROUP BY
        C.CourseID, C.CourseName;
END;


--get no of students enrolled in the particular course
EXEC GetEnrollmentsCountForCourse @CourseID = 30



--8.
-- This procedure will provide assignment and quizz against one enrollment

DROP PROCEDURE GetExamsByEnrollmentID

CREATE PROCEDURE GetExamsWithCountsByEnrollmentID
    @EnrollmentID INT
AS
BEGIN
    SELECT
        E.EnrollmentID,
        S.StudentID,
        U.FirstName + ' ' + U.LastName AS StudentName,
        C.CourseID,
        C.CourseName,
        EX.ExamID,
        EX.Title,
        EX.TotalMarks,
        EX.ObtainedMarks,
        EX.ExamDate,
        EX.ExamType,
        (SELECT COUNT(*) FROM Exam WHERE EnrollmentID = @EnrollmentID AND ExamType = 'Assignment') AS AssignmentCount,
        (SELECT COUNT(*) FROM Exam WHERE EnrollmentID = @EnrollmentID AND ExamType = 'Quiz') AS QuizCount
    FROM
        Enrollment E
    JOIN
        Student S ON E.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    JOIN
        Course C ON E.CourseID = C.CourseID
    LEFT JOIN
        Exam EX ON E.EnrollmentID = EX.EnrollmentID
    WHERE
        E.EnrollmentID = @EnrollmentID
    ORDER BY
        EX.ExamID;
END;
--get the exam for sepecific course witht the cout
EXEC GetExamsWithCountsByEnrollmentID @EnrollmentID = 127; 


--8.

--This procedure will provide all the exams by student against all enrollments


CREATE PROCEDURE GetExamsByStudentID
    @StudentID INT
AS
BEGIN
    SELECT
        E.EnrollmentID,
        S.StudentID,
        U.FirstName + ' ' + U.LastName AS StudentName,
        C.CourseID,
        C.CourseName,
        ISNULL(CONVERT(VARCHAR, EX.ExamID), 'No Exam') AS ExamID,
        EX.Title,
        ISNULL(CONVERT(VARCHAR, EX.TotalMarks), 'No Exam') AS TotalMarks,
        ISNULL(CONVERT(VARCHAR, EX.ObtainedMarks), 'No Exam') AS ObtainedMarks,
        ISNULL(CONVERT(VARCHAR, EX.ExamDate, 120), 'No Exam') AS ExamDate,
        EX.ExamType
    FROM
        Enrollment E
    JOIN
        Student S ON E.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    JOIN
        Course C ON E.CourseID = C.CourseID
    LEFT JOIN
        Exam EX ON E.EnrollmentID = EX.EnrollmentID
    WHERE
        S.StudentID = @StudentID
    ORDER BY
        EX.ExamID;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'No exam details found for the specified student.';
    END
END;




--get the exam of student with id for all courses
EXEC GetExamsByStudentID @StudentID = 111; -- Replace with the desired StudentID



--9.

--Enrollments querry form date to date



CREATE PROCEDURE GetEnrollmentsByDateRange
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
        E.EnrollmentID,
        S.StudentID,
        U.FirstName + ' ' + U.LastName AS StudentName,
        E.CourseID,
        E.EnrollmentDate
    FROM
        Enrollment E
    JOIN
        Student S ON E.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    WHERE
        E.EnrollmentDate BETWEEN @StartDate AND @EndDate;
END;



--Get the enrollments based on date
EXEC GetEnrollmentsByDateRange '2023-01-01', '2023-12-31';

--10.

--Report of student against all the course 

CREATE PROCEDURE GetStudentPerformanceSummary
    @StudentID INT
AS
BEGIN
    SELECT
        E.EnrollmentID,
        C.CourseID,
        C.CourseName,
        ISNULL(SUM(EX.ObtainedMarks), 0) AS TotalObtainedMarks,
        100 AS TotalPossibleMarks, -- Constant total possible marks
        ISNULL(SUM(CASE WHEN EX.ExamType = 'Assignment' THEN 1 ELSE 0 END), 0) AS AssignmentCount,
        ISNULL(SUM(CASE WHEN EX.ExamType = 'Quiz' THEN 1 ELSE 0 END), 0) AS QuizCount,
        CASE
            WHEN ISNULL(SUM(EX.ObtainedMarks), 0) > 0 
                 THEN (ISNULL(SUM(EX.ObtainedMarks), 0) * 100) / 100
            ELSE 0
        END AS Percentage,
        CASE
            WHEN ISNULL(SUM(EX.ObtainedMarks), 0) * 100 / 100 >= 50 THEN 'Pass'
            ELSE 'Fail'
        END AS Result
    FROM
        Enrollment E
    JOIN
        Course C ON E.CourseID = C.CourseID
    LEFT JOIN
        Exam EX ON E.EnrollmentID = EX.EnrollmentID
    WHERE
        E.StudentID = @StudentID
    GROUP BY
        E.EnrollmentID, C.CourseID, C.CourseName;
END;

--Get the all course assignment and quiz related to one student 
EXEC GetStudentPerformanceSummary @StudentID = 127



--11.

--Report on student agianst one course

CREATE PROCEDURE GetStudentCoursePerformance
    @EnrollmentID INT
AS
BEGIN
    SELECT
        E.EnrollmentID,
        S.StudentID,
        U.FirstName + ' ' + U.LastName AS StudentName,
        C.CourseID,
        C.CourseName,
        ISNULL(SUM(EX.ObtainedMarks), 0) AS TotalObtainedMarks,
        100 AS TotalPossibleMarks, -- Constant total possible marks
        ISNULL(SUM(CASE WHEN EX.ExamType = 'Assignment' THEN 1 ELSE 0 END), 0) AS AssignmentCount,
        ISNULL(SUM(CASE WHEN EX.ExamType = 'Quiz' THEN 1 ELSE 0 END), 0) AS QuizCount,
        CASE
            WHEN ISNULL(SUM(EX.ObtainedMarks), 0) > 0 
                 THEN (ISNULL(SUM(EX.ObtainedMarks), 0) * 100) / 100
            ELSE 0
        END AS Percentage,
        CASE
            WHEN ISNULL(SUM(EX.ObtainedMarks), 0) * 100 / 100 >= 50 THEN 'Pass'
            ELSE 'Fail'
        END AS Result
    FROM
        Enrollment E
    JOIN
        Student S ON E.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    JOIN
        Course C ON E.CourseID = C.CourseID
    LEFT JOIN
        Exam EX ON E.EnrollmentID = EX.EnrollmentID
    WHERE
        E.EnrollmentID = @EnrollmentID
    GROUP BY
        E.EnrollmentID, S.StudentID, U.FirstName, U.LastName, C.CourseID, C.CourseName;
END;



--Get Student marks in one course based on assignmnet and quizz 
EXEC GetStudentCoursePerformance @EnrollmentID = 111

--12. to get the heightest marks in course

CREATE PROCEDURE GetHighestMarksForCourse
    @CourseID INT
AS
BEGIN
    SELECT TOP 3
        E.CourseID,
        MAX(EX.ObtainedMarks) AS HighestMarks,
        C.CourseName,
        S.StudentID,
        U.FirstName + ' ' + U.LastName AS StudentName
    FROM
        Enrollment E
    JOIN
        Student S ON E.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    JOIN
        Course C ON E.CourseID = C.CourseID
    LEFT JOIN
        Exam EX ON E.EnrollmentID = EX.EnrollmentID
    WHERE
        E.CourseID = @CourseID
        AND EX.ObtainedMarks IS NOT NULL
    GROUP BY
        E.CourseID, C.CourseName, S.StudentID, U.FirstName, U.LastName
    ORDER BY
        MAX(EX.ObtainedMarks) DESC;
END;

--Get the highest marks of the course 
EXEC GetHighestMarksForCourse @CourseID =30



--13. to get the teacher feedback 

CREATE PROCEDURE GetTeacherFeedbackComments
    @TeacherUserID INT
AS
BEGIN
    SELECT
        F.FeedbackID,
        U.FirstName + ' ' + U.LastName AS StudentName,
        F.Comment
    FROM
        Feedback F
    JOIN
        Student S ON F.StudentID = S.StudentID
    JOIN
        [User] U ON S.UserID = U.UserID
    WHERE
        F.TeacherID = (SELECT T.TeacherID FROM Teacher T JOIN [User] UTeacher ON T.UserID = UTeacher.UserID WHERE UTeacher.UserID = @TeacherUserID)
        AND F.CommentType = 'Teacher';
END;


--Get all the feedback of one teacher
EXEC GetTeacherFeedbackComments @TeacherUserID = 211
--14.  get the teacher course details

CREATE PROCEDURE GetCoursesByTeacherID
    @TeacherUserID INT
AS
BEGIN
    SELECT
        C.*
    FROM
        Course C
    JOIN
        Teacher T ON C.TeacherID = T.TeacherID
    WHERE
        T.UserID = @TeacherUserID;
END;



--get the teacher with its corresponding course 
EXEC GetCoursesByTeacherID @TeacherUserID = 211
--

--15.
-- Create stored procedure to get course assignments
CREATE PROCEDURE GetAdminCourseAssignments
AS
BEGIN
    SELECT
        A.AdminID,
        U.FirstName + ' ' + U.LastName AS AdminName,
        C.CourseID,
        C.CourseName,
        C.CourseDescription,
        T.TeacherID,
        U_Teacher.FirstName + ' ' + U_Teacher.LastName AS TeacherName
    FROM
        [User] U
    JOIN
        Admin A ON U.UserID = A.UserID
    JOIN
        Course C ON A.AdminID = C.AdminID
    JOIN
        Teacher T ON C.TeacherID = T.TeacherID
    JOIN
        [User] U_Teacher ON T.UserID = U_Teacher.UserID;
END;



-- query to find  which admin has assigned which course to which teacher
EXEC GetAdminCourseAssignments


--17. VIEWS 
----------------------------------------------------------------------------------------------------------------------------------------
-- Create a view representing Admin-Teacher-Course relationships

-- How many courses admin has assigned Admin-Teacher-Course relationships
-- This view helped to retrive the teacher details regarding course 

CREATE VIEW TeacherDetails AS
SELECT
    U.UserID,
    U.FirstName,
    U.LastName,
    U.Email,
    T.TeacherID,
    C.CourseID,
    C.CourseName,
    C.CourseDescription,
    F.FeedbackID,
    F.Comment,
    F.CommentType
FROM
    [User] U
JOIN
    Teacher T ON U.UserID = T.UserID
LEFT JOIN
    Course C ON T.TeacherID = C.TeacherID
LEFT JOIN
    Feedback F ON T.TeacherID = F.TeacherID;

select * from TeacherDetails

--Retrive the teacher comments

CREATE PROCEDURE TeacherComment 
	@TeacherID INT
AS
BEGIN
	SELECT
		TeacherID,
		FeedbackID,
		Comment,
		CommentType
	FROM TeacherDetails
	WHERE TeacherID = @TeacherID AND FeedbackID IS NOT NULL AND CommentType = 'Teacher';
END

EXEC TeacherComment @TeacherID = 211

--get teacher courses and comment for courses and teacher also 
SELECT
		TeacherID,
		CourseID,
		CourseName,
		CourseDescription,
		FeedbackID,
		Comment,
		CommentType
FROM TeacherDetails
WHERE TeacherID = 211;















