--Construct a sample data entry.
-- 1. insert course
BEGIN TRANSACTION;
INSERT INTO courses (
    title, course_code, info, credit_hours, department, room, capacity, term, year, syllabus, faculty_id
) VALUES (
    'Introduction to AI', 'AI101', 'Basic concepts of AI',
    3, 'Computer Science', 'Room 101', 50, 'Fall', 2025, 'Initial syllabus content', 1
);

-- 2. get course_id
WITH new_course AS (
    SELECT course_id FROM courses WHERE course_code = 'AI101'
)
-- 3. record the action
INSERT INTO course_management (admin_id, course_id, action, date)
SELECT 1, course_id, 'create', DATETIME('now') FROM new_course;

-- 4. set prerequisites（assume CS101 is a prerequisite for AI）
INSERT INTO prerequisites (course_id, prereq_id)
VALUES (
    (SELECT course_id FROM courses WHERE course_code = 'AI101'),
    (SELECT course_id FROM courses WHERE course_code = 'CS101')
);

-- 5. set timeblock for AI
INSERT INTO timeblocks (start_time, end_time, day)
VALUES ('10:00:00', '11:30:00', 'Monday');

-- 6. set courseblock for AI
INSERT INTO courseblock (course_id, timeblock_id)
VALUES (
    (SELECT course_id FROM courses WHERE course_code = 'AI101'),
    (SELECT timeblock_id FROM timeblocks WHERE start_time = '10:00:00' AND end_time = '11:30:00' AND day = 'Monday')
);

-- 7. update room
UPDATE courses
SET room = 'Room 202'
WHERE course_code = 'AI101'
AND EXISTS (SELECT 1 FROM rooms WHERE room_number = 'Room 202');

COMMIT;



--Drop course
-- 1. delete related enrollments info
BEGIN TRANSACTION;
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

-- 5. record the action
INSERT INTO course_management (admin_id, course_id, action, date)
SELECT 1, course_id, 'delete', DATETIME('now')
FROM courses WHERE course_code = 'AI101';

-- 6. finally delete course after checking date
DELETE FROM courses
WHERE course_code = 'AI101'
AND (SELECT drop_deadline FROM terms WHERE term = courses.term AND year = courses.year) >= DATE('now');

COMMIT;



-- Update course details such as syllabus, class schedule
BEGIN TRANSACTION;
-- 1. update course
UPDATE courses
SET syllabus = 'Updated syllabus content for AI101.',
    term = 'Winter',
    year = 2025,
    credit_hours = 4
WHERE course_code = 'AI101';

-- 2. record the action
INSERT INTO course_management (admin_id, course_id, action, date)
SELECT 1, course_id, 'modify', DATETIME('now')
FROM courses WHERE course_code = 'AI101';

-- 3. recheck the timeblock
UPDATE courseblock
SET timeblock_id = (
    SELECT timeblock_id FROM timeblocks
    WHERE start_time = '14:00:00' AND end_time = '15:30:00' AND day = 'Wednesday'
)
WHERE course_id = (SELECT course_id FROM courses WHERE course_code = 'AI101');

-- 4. recheck the room whether is available
UPDATE courses
SET room = 'Room 202'
WHERE course_code = 'AI101'
AND EXISTS (SELECT 1 FROM rooms WHERE room_number = 'Room 202');

COMMIT;
