-- view lists of students enrolled in their courses

-- GET STUDENTS IN ALL COURSES
--
-- This query is used to retrieve a list of students enrolled in all courses taught by an instructor.
--
-- :instructor_id - The instructor's ID (from the instructors table)
--
-- The query returns a list of students with their student ID, first name, last name, and email.
--
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    s.student_email
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
JOIN courses c ON e.course_id = c.course_id
WHERE c.instructor_id = :instructor_id
  AND e.status = 'In Progress';

-- GET STUDENTS IN A SPECIFIC COURSE
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    s.student_emai;
FROM students s
JOIN enrollments e on s.student_id = e.student_id
WHERE c.instructor_id = :instructor_id
  AND e.course_id = :course_id
  AND e.status = "In Progress";




-- update course details such as syllabus, class schedule, and grading criteria






-- post announcements for registered students