--Construct a sample data entry.
-- 1. insert course
INSERT INTO courses (
    title, course_code, info, credit_hours, department, room, capacity, term, year, syllabus, faculty_id
) VALUES (
    'Introduction to AI', 'AI101', 'Basic concepts of AI',
    3, 'Computer Science', 'Room 101', 50, 'Fall', 2025, 'Initial syllabus content', 1
);

-- 2. set prerequisites（assume CS101 is a prerequisite for AI）
INSERT INTO prerequisites (course_id, prereq_id)
VALUES (
    (SELECT course_id FROM courses WHERE course_code = 'AI101'),
    (SELECT course_id FROM courses WHERE course_code = 'CS101')
);

-- 3. set timeblock for AI
INSERT INTO timeblocks (start_time, end_time, day)
VALUES ('10:00:00', '11:30:00', 'Monday');

-- 4. set courseblock for AI
INSERT INTO courseblock (course_id, timeblock_id)
VALUES (
    (SELECT course_id FROM courses WHERE course_code = 'AI101'),
    (SELECT timeblock_id FROM timeblocks WHERE start_time = '10:00:00' AND end_time = '11:30:00' AND day = 'Monday')
);



--Drop course
-- 1. delete related enrollments info
DELETE FROM enrollments
WHERE
course_id = (SELECT course_id FROM courses WHERE course_code = 'AI101');

-- 2. delete related schedule
DELETE FROM courseblock
WHERE
course_id = (SELECT course_id FROM courses WHERE course_code = 'AI101');

-- 3. delete related prerequisites
DELETE FROM prerequisites
WHERE
course_id = (SELECT course_id FROM courses WHERE course_code = 'AI101');

-- 4. delete related faculty_id
UPDATE courses
SET faculty_id = NULL
WHERE course_code = 'AI101';

-- 5. finally delete course after checking date
DELETE FROM courses
WHERE course_code = 'AI101'
AND (SELECT drop_deadline FROM terms WHERE term = courses.term AND year = courses.year) >= DATE('now');