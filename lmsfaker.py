import pyodbc
from faker import Faker
from datetime import datetime

# Database connection
server_name = "DESKTOP-MLD356I\\SQLEXPRESS"
database_name = "lmsTrail2"

connection = pyodbc.connect(f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server_name};DATABASE={database_name};Trusted_Connection=yes;")
cursor = connection.cursor()

faker = Faker()

#extracting the courseID form the course table in form of list
course_ids = [row[0] for row in cursor.execute("SELECT CourseID FROM Course").fetchall()]

course_data = cursor.execute("SELECT CourseID, CourseName FROM Course").fetchall()
course_ids = [row[0] for row in course_data]
course_names = {row[0]: row[1] for row in course_data}

course_ids_lesson = [row[0] for row in cursor.execute("SELECT CourseID FROM Course").fetchall()]

for _ in range(100):
    lesson_id = None
    while True:
        lesson_id = faker.random_int(min=1, max=300) #limiting the ids 
        cursor.execute("SELECT COUNT(*) FROM Lesson WHERE LessonID = ?", (lesson_id,))
        if cursor.fetchone()[0] == 0:
            break

    course_id = faker.random.choice(course_ids_lesson)
    title = course_names[course_id]
    video_link = faker.url()
    attachments = faker.random_element(elements=('attachment.docx', 'attachment.pdf', 'attachment.csv', 'https://github.com/ahmadnaeem313', 'https://github.com/ShamiGondal'))

    cursor.execute("EXEC InsertLesson ?, ?, ?, ?, ?", (lesson_id, course_id, title, video_link, attachments))

connection.commit()

for _ in range(100):
    enrollment_id = None
    while True:
        enrollment_id = faker.random_int(min=1, max=300)
        cursor.execute("SELECT COUNT(*) FROM Enrollment WHERE EnrollmentID = ?", (enrollment_id,))
        if cursor.fetchone()[0] == 0:
            break

    student_ids = [row[0] for row in cursor.execute("SELECT StudentID FROM Student").fetchall()]
    student_id = faker.random.choice(student_ids)

    course_id = faker.random.choice(course_ids)

    start_date = datetime(2023, 1, 1)
    end_date = datetime(2023, 12, 31)
    enrollment_date = (start_date + faker.time_delta(end_date - start_date)).strftime('%Y-%m-%d')

    existing_enrollment_query = "SELECT COUNT(*) FROM Enrollment WHERE StudentID = ? AND CourseID = ?"
    cursor.execute(existing_enrollment_query, (student_id, course_id))
    if cursor.fetchone()[0] == 0:
        cursor.execute("EXEC InsertEnrollment ?, ?, ?, ?", (enrollment_id, student_id, course_id, enrollment_date))

connection.commit()

for _ in range(100):
    fee_id = None
    while True:
        fee_id = faker.random_int(min=1, max=300)
        cursor.execute("SELECT COUNT(*) FROM CourseFeeDetail WHERE FeeID = ?", (fee_id,))
        if cursor.fetchone()[0] == 0:
            break

    fee_course_id = faker.random.choice(course_ids)
    fee = faker.pydecimal(left_digits=3, right_digits=1, positive=True)

    cursor.execute("EXEC InsertCourseFeeDetail ?, ?, ?", (fee_id, fee_course_id, fee))

connection.commit()

cursor.execute("SELECT EnrollmentID FROM Enrollment")
enrollment_ids = [row[0] for row in cursor.execute("SELECT EnrollmentID FROM Enrollment").fetchall()]

for _ in range(100):
    payment_id = None
    while True:
        payment_id = faker.random_int(min=1, max=300)
        cursor.execute("SELECT COUNT(*) FROM Payment WHERE PaymentID = ?", (payment_id,))
        if cursor.fetchone()[0] == 0:
            break

    enrollment_id = faker.random_element(elements=enrollment_ids)

    course_id_query = "SELECT CourseID FROM Enrollment WHERE EnrollmentID = ?"
    cursor.execute(course_id_query, (enrollment_id,))
    result = cursor.fetchone()

    if result is not None:
        course_id = result[0]

        fee_query = "SELECT Fee FROM CourseFeeDetail WHERE CourseID = ?"
        cursor.execute(fee_query, (course_id,))
        fee_amount_result = cursor.fetchone()

        if fee_amount_result is not None:
            fee_amount = fee_amount_result[0]
            
            payment_id = faker.random_int(min=1, max=300)
            payment_date = faker.date_this_decade()
            amount_paid = fee_amount
            payment_status = 'Completed'
            
            cursor.execute("EXEC InsertPaymentWithCheck ?, ?, ?, ?, ?", 
                           (payment_id, enrollment_id, payment_date, amount_paid, payment_status))
        else:
            print(f"No Fee found for CourseID: {course_id}")
    else:
        print(f"No CourseID found for EnrollmentID: {enrollment_id}")

connection.commit()

teacher_ids = [row[0] for row in cursor.execute("SELECT TeacherID FROM Teacher").fetchall()]

for _ in range(100):
    feedback_id = None
    while True:
        feedback_id = faker.random_int(min=1, max=300)
        cursor.execute("SELECT COUNT(*) FROM Feedback WHERE FeedbackID = ?", (feedback_id,))
        if cursor.fetchone()[0] == 0:
            break

    student_id = faker.random.choice(student_ids)
    course_id = faker.random.choice(course_ids)
    teacher_id = faker.random.choice(teacher_ids)

    comment = faker.text()
    comment_type = faker.random_element(elements=('Teacher', 'Course'))

    cursor.execute("EXEC InsertFeedback ?, ?, ?, ?, ?, ?", (feedback_id, student_id, course_id, teacher_id, comment, comment_type))

connection.commit()

course_data = cursor.execute("SELECT CourseID, CourseName FROM Course").fetchall()
course_ids = [row[0] for row in course_data]
course_names = {row[0]: row[1] for row in course_data}

cursor.execute("SELECT EnrollmentID FROM Enrollment")
enrollment_ids = cursor.fetchall()

enrollment_ids = [row[0] for row in enrollment_ids]

for _ in range(100):
    exam_id = None
    while True:
        exam_id = faker.random_int(min=1, max=300)
        cursor.execute("SELECT COUNT(*) FROM Exam WHERE ExamID = ?", (exam_id,))
        if cursor.fetchone()[0] == 0:
            break

    enrollment_id = faker.random_element(elements=enrollment_ids)

    cursor.execute("SELECT CourseID FROM Enrollment WHERE EnrollmentID = ?", (enrollment_id,))
    course_id_result = cursor.fetchone()

    if course_id_result:
        course_id = course_id_result[0]

        cursor.execute("SELECT CourseName FROM Course WHERE CourseID = ?", (course_id,))
        course_name_result = cursor.fetchone()

        if course_name_result:
            exam_title = course_name_result[0]
        else:
            print(f"No CourseName found for CourseID: {course_id}")
            continue
    else:
        print(f"No CourseID found for EnrollmentID: {enrollment_id}")
        continue

    total_marks = 10
    obtained_marks = faker.random_int(min=1, max=min(total_marks, 10))
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2023, 12, 31)
    Exam_Date = (start_date + faker.time_delta(end_date - start_date)).strftime('%Y-%m-%d')
    exam_type = faker.random_element(elements=('Assignment', 'Quiz'))

    cursor.execute("EXEC InsertExam ?, ?, ?, ?, ?, ?, ?", (exam_id, enrollment_id, exam_title, total_marks, obtained_marks, Exam_Date, exam_type))

connection.commit()
connection.close()

print("Data successfully generated and inserted into all tables!")
