-- GET COURSES
--
-- This query is used to retrieve a list of courses available for registration.
--
-- :student_id - The student's ID
--
-- The query returns a list of courses with their timeblocks and prerequisites. It also includes a column indicating whether the student meets the prerequisites for each course.
--
-- The "has_prerequisites" column will be 'Yes' if the student meets all prerequisites, and 'No' if any prerequisites are missing.
--
SELECT 
    c.course_id,
    c.title,
    c.course_code,
    c.info,
    c.credit_hours,
    c.department,
    c.room,
    c.term,
    c.year,
    tb.timeblock_id,
    tb.start_time,
    tb.end_time,
    tb.day,
    p.prereq_id AS prerequisite_course_id,
    CASE 
        WHEN p.prereq_id IS NULL THEN 'Yes'  -- No prerequisites required
        WHEN NOT EXISTS (
            SELECT 1 
            FROM prerequisites pr
            LEFT JOIN enrollments e ON pr.prereq_id = e.course_id 
                AND e.student_id = :student_id
                AND e.status = 'Passed'
            WHERE pr.course_id = c.course_id
            AND e.course_id IS NULL  -- If any prerequisite is missing, return 'No'
        ) THEN 'Yes'
        ELSE 'No'
    END AS has_prerequisites
FROM courses c
LEFT JOIN courseblock cb ON c.course_id = cb.course_id
LEFT JOIN timeblocks tb ON cb.timeblock_id = tb.timeblock_id
LEFT JOIN prerequisites p ON c.course_id = p.course_id
ORDER BY c.course_id, tb.timeblock_id, p.prereq_id;




-- REGISTER FOR COURSE
--
-- This query is used to register a student for a course. It checks for missing prerequisites and time conflicts with other "In Progress" courses.
--
-- :student_id - The student's ID
-- :course_id - The course's ID
--
-- If the student meets all requirements, a new row is inserted into the enrollments table.
--
-- If the student is missing prerequisites, the query returns no rows.
--
-- If there is a time conflict with another "In Progress" course, the query returns no rows.
--
INSERT INTO enrollments (student_id, course_id, status)
SELECT :student_id, :course_id, 'In Progress'
WHERE NOT EXISTS (
    -- Check for missing prerequisites
    SELECT 1 
    FROM prerequisites p
    LEFT JOIN enrollments e ON p.prereq_id = e.course_id 
        AND e.student_id = :student_id
        AND e.status = 'Passed'
    WHERE p.course_id = :course_id
      AND e.course_id IS NULL  -- If any prerequisite is missing, this returns rows
)
AND NOT EXISTS (
    -- Check for time conflicts with other "In Progress" courses
    SELECT 1
    FROM enrollments e
    JOIN courseblock cb1 ON e.course_id = cb1.course_id
    JOIN timeblocks tb1 ON cb1.timeblock_id = tb1.timeblock_id
    JOIN courseblock cb2 ON cb2.course_id = :course_id
    JOIN timeblocks tb2 ON cb2.timeblock_id = tb2.timeblock_id
    WHERE e.student_id = :student_id
      AND e.status = 'In Progress'
      AND tb1.day = tb2.day  -- Must be on the same day
      AND tb1.start_time < tb2.end_time  -- Ensures Course A starts before Course B ends
      AND tb1.end_time > tb2.start_time  -- Ensures Course A ends after Course B starts
)
AND (
    -- Ensure student has not registered for more than 10 courses in Fall + Winter
    SELECT COUNT(*) FROM enrollments e
    JOIN courses c ON e.course_id = c.course_id
    WHERE e.student_id = :student_id
      AND c.term IN ('Fall', 'Winter')
      AND e.status = 'In Progress'
) < 10
AND (
    -- Ensure the current date is before the registration deadline
    SELECT COUNT(*) FROM terms t
    JOIN courses c ON c.term = t.term
    WHERE c.course_id = :course_id
    AND t.year = :year
    AND t.registration_deadline >= CURRENT_DATE
) > 0
AND (
    -- Ensure the course is not full (current enrollment < capacity)
    SELECT COUNT(*) FROM enrollments
    WHERE course_id = :course_id
        AND status = 'In Progress'
) < (
    SELECT capacity FROM courses WHERE course_id = :course_id
);




-- DROP COURSE
--
-- This query is used to drop a course. It checks for time conflicts with other "In Progress" courses.
--
-- :student_id - The student's ID
-- :course_id - The course's ID
--
-- If the student is not registered for the course, the query returns no rows.
--
-- If there is a time conflict with another "In Progress" course, the query returns no rows.
--
UPDATE enrollments
SET status = 'Dropped'
WHERE student_id = :student_id
  AND course_id = :course_id
  AND status = 'In Progress';




-- GET CURRENT COURSE SCHEDULE
--
-- This query is used to retrieve a student's current course schedule.
--
-- :student_id - The student's ID
--
-- The query returns a list of courses with their timeblocks and grades.
--
WITH curr AS (
    SELECT * 
    FROM enrollments e
    JOIN courses c ON c.course_id = e.course_id
    WHERE e.student_id = 1
    AND e.status = 'In Progress'
)
SELECT
    curr.course_id,
    curr.title,
    curr.course_code,
    curr.info,
    curr.instructor_id,
    curr.credit_hours,
    curr.department,
    curr.room,
    curr.term,
    curr.year,
    tb.timeblock_id,
    tb.start_time,
    tb.end_time,
    tb.day
FROM curr
JOIN courseblocks cb ON cb.course_id = curr.course_id
JOIN timeblocks tb ON tb.timeblock_id = cb.timeblock_id
ORDER BY
    CASE
        WHEN curr.term = 'Fall' THEN 1
        WHEN curr.term = 'Winter' THEN 2
        ELSE 3
    END,
    CASE
        WHEN tb.day = 'Monday' THEN 1
        WHEN tb.day = 'Tuesday' THEN 2
        WHEN tb.day = 'Wednesday' THEN 3
        WHEN tb.day = 'Thursday' THEN 4
        WHEN tb.day = 'Friday' THEN 5
    END,
    tb.start_time;


-- TODO
-- receive notifications for important updates like registration deadlines




-- GET LIST OF DEPARTMENTS
SELECT department_id FROM departments;