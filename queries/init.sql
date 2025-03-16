CREATE TABLE IF NOT EXISTS students (
    student_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    student_email TEXT UNIQUE NOT NULL,
    personal_email TEXT UNIQUE NOT NULL,
    credit_hours INTEGER DEFAULT 0,
    major TEXT,
    FOREIGN KEY (major) REFERENCES departments(department_name)
);

CREATE TABLE IF NOT EXISTS faculty (
    faculty_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    faculty_email TEXT UNIQUE NOT NULL,
    personal_email TEXT UNIQUE NOT NULL,
    department TEXT NOT NULL,
    FOREIGN KEY (department) REFERENCES departments(department_name)
);

CREATE TABLE IF NOT EXISTS admin (
    admin_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    middle_name TEXT,
    last_name TEXT NOT NULL,
    admin_email TEXT UNIQUE NOT NULL,
    personal_email TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS departments (
    department_id TEXT PRIMARY KEY,
    department_name TEXT NOT NULL,
    department_chair INTEGER NOT NULL,
    department_email TEXT UNIQUE NOT NULL,
    FOREIGN KEY (department_chair) REFERENCES faculty(faculty_id)
);

CREATE TABLE IF NOT EXISTS terms (
    term TEXT NOT NULL,
    year INTEGER NOT NULL,
    registration_deadline DATE NOT NULL,
    drop_deadline DATE NOT NULL,
    PRIMARY KEY (term, year), -- Composite primary key
    CHECK (term IN ('Fall', 'Winter', 'Spring', 'Summer'))
);

CREATE TABLE IF NOT EXISTS courses (
    course_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    course_code TEXT NOT NULL,
    info TEXT NOT NULL,
    instructor_id INTEGER NOT NULL,
    credit_hours INTEGER NOT NULL,
    department TEXT NOT NULL,
    room TEXT NULL,
    capacity INTEGER DEFAULT 30,
    term TEXT NOT NULL,
    year INTEGER NOT NULL,
    FOREIGN KEY (instructor_id) REFERENCES faculty(faculty_id)
    FOREIGN KEY (term, year) REFERENCES terms(term, year), -- Composite foreign key
    FOREIGN KEY (department) REFERENCES departments(department_name),
    FOREIGN KEY (room) REFERENCES rooms(room_number)
);

CREATE TABLE IF NOT EXISTS prerequisites (
    course_id INTEGER,
    prereq_id INTEGER,
    PRIMARY KEY (course_id, prereq_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (prereq_id) REFERENCES courses(course_id)
);

CREATE TABLE IF NOT EXISTS timeblocks (
    timeblock_id TEXT PRIMARY KEY,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    day TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS days (
    day TEXT PRIMARY KEY,
    day_int INTEGER
);

CREATE TABLE IF NOT EXISTS courseblocks (
    course_id INTEGER,
    timeblock_id INTEGER,
    PRIMARY KEY (course_id, timeblock_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (timeblock_id) REFERENCES timeblocks(timeblock_id)
);

CREATE TABLE IF NOT EXISTS enrollments (
    student_id INTEGER,
    course_id INTEGER,
    grade INTEGER DEFAULT NULL,
    status TEXT DEFAULT 'In Progress',
    CHECK (status IN (
        'In Progress',
        'Passed',
        'Failed',
        'Dropped',
        'Completed' -- For courses that don't require a grade / audit
    )),
    PRIMARY KEY (student_id, course_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE IF NOT EXISTS rooms (
    room_number TEXT PRIMARY KEY,
    building TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS announcements (
    announcement_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    date DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS announce (
    announcement_id INTEGER,
    instructor_id INTEGER NULL,
    admin_id INTEGER NULL,
    FOREIGN KEY (announcement_id) REFERENCES announcements(announcement_id),
    FOREIGN KEY (instructor_id) REFERENCES faculty(faculty_id),
    FOREIGN KEY (admin_id) REFERENCES admin(admin_id),
    CHECK (
        (instructor_id IS NOT NULL AND admin_id IS NULL) OR
        (instructor_id IS NULL AND admin_id IS NOT NULL)
    )
);