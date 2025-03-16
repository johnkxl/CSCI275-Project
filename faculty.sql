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
BEGIN TRANSACTION;

UPDATE courses
SET syllabus = 'Updated syllabus content for AI101.',
    term = 'Winter',
    year = 2025,
    credit_hours = 4
WHERE course_code = 'AI101';

-- recheck the timeblock
UPDATE courseblock
SET timeblock_id = (
    SELECT timeblock_id FROM timeblocks
    WHERE start_time = '14:00:00' AND end_time = '15:30:00' AND day = 'Wednesday'
)
WHERE course_id = (SELECT course_id FROM courses WHERE course_code = 'AI101');

-- recheck the room whether is available
UPDATE courses
SET room = 'Room 202'
WHERE course_code = 'AI101'
AND EXISTS (SELECT 1 FROM rooms WHERE room_number = 'Room 202');

COMMIT;


-- post announcements for registered students
-- use transaction to post announcement
BEGIN TRANSACTION;
-- 1. insert announcement
INSERT INTO announcements (title, body, date)
VALUES ('Class canceled', 'Class canceled due to weather.', DATETIME('now'));

-- 2. get announcement_id
SELECT last_insert_rowid() INTO @announcement_id;

-- 3. get faculty_id
SELECT faculty_id INTO @faculty_id
FROM faculty
WHERE faculty_email = 'professor@example.com';

-- 4. insert announcement after checking
INSERT INTO announce (announcement_id, instructor_id)
VALUES (@announcement_id, @faculty_id);

COMMIT;



-- create trigger to update notifications table about announcement automatically
CREATE TRIGGER notify_students_on_announcement
AFTER INSERT ON announce
FOR EACH ROW
BEGIN
    INSERT INTO notifications (student_id, course_id, message)
    SELECT enrollments.student_id, courses.course_id, 'New announcement posted for your course!'
    FROM enrollments
    JOIN courses ON enrollments.course_id = courses.course_id
    WHERE courses.faculty_id = NEW.instructor_id;
END;
