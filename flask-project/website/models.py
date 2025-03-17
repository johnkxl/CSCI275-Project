from . import db
from sqlalchemy import case, cast, String


class Student(db.Model):
    __tablename__ = 'students'
    
    student_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    middle_name = db.Column(db.String(50), nullable=True)
    last_name = db.Column(db.String(50), nullable=False)
    personal_email = db.Column(db.String(100), nullable=False, unique=True)
    student_email = db.Column(db.String(100), nullable=False, unique=True)
    major = db.Column(db.String(100), nullable=False)
    credit_hours = db.Column(db.Integer, default=0)

    enrollments = db.relationship('Enrollment', backref='student', lazy=True)

    def get_all_courses(self):
        courses = db.session.query(
            Course.course_id,
            Course.title,
            Course.course_code,
            Course.info,
            Course.credit_hours,
            Course.department,
            Course.room,
            Course.term,
            Course.year,
            Timeblock.timeblock_id,
            Timeblock.start_time,
            Timeblock.end_time,
            Timeblock.day
        ).outerjoin(
            Courseblock, Course.course_id == Courseblock.course_id
        ).outerjoin(
            Timeblock, Courseblock.timeblock_id == Timeblock.timeblock_id
        ).order_by(
            Course.course_id, Timeblock.timeblock_id
        ).all()

        # Format results
        result = []
        for c in courses:
            result.append({
                'course_id': c.course_id,
                'title': c.title,
                'course_code': c.course_code,
                'info': c.info,
                'day': c.day,
                'start_time': c.start_time.strftime('%H:%M:%S') if c.start_time is not None else "huh?",
                'end_time': c.end_time.strftime('%H:%M:%S') if c.start_time is not None else "huh?",  # Convert time to string,
                # 'prerequisite': c.prereq_id
            })
        return result

    def enroll(self, course_id):
        # Check if already enrolled
        course_enrollments = Enrollment.query.filter(
            Enrollment.student_id == self.student_id,
            Enrollment.course_id == course_id,
            (Enrollment.status == 'Passed') | (Enrollment.status == 'In Progress')
        ).all()

        if course_enrollments:
            statuses = list([ce.status for ce in course_enrollments])
            reason = 'completed' if 'Passed' in statuses else 'enrolled in'
            return {"error": f"❌ Already {reason} this course."}, 400

        # Check for missing prerequisites
        missing_prereqs = Prerequisite.query\
            .filter(Prerequisite.course_id == course_id)\
            .filter(~Enrollment.query
                    .filter(Enrollment.student_id == self.student_id)
                    .filter(Enrollment.course_id == Prerequisite.prereq_id)
                    .filter(Enrollment.status == 'Passed')
                    .exists())\
            .all()

        if missing_prereqs:
            return {"error": f"❌ Missing prerequisites: {missing_prereqs}"}, 400

        # Add enrollment
        new_enrollment = Enrollment(student_id=self.student_id, course_id=course_id, status='In Progress')
        db.session.add(new_enrollment)
        db.session.commit()

        return {"message": f"✅ Enrolled in course {course_id}"}, 200
    
    def drop(self, course_id) -> tuple[dict, int]:
        course = Enrollment.query.filter(Enrollment.student_id == self.student_id,
                                Enrollment.course_id == course_id,
                                Enrollment.status == 'In Progress').first()
        
        if not course:
            return {"error": "Not registered for course"}, 400
        
        db.session.delete(course)
        db.session.commit()

        return {"message": f"✅ Dropped course {course_id}"}, 200
    
    def get_schedule(self):
        # Query to fetch the courses in progress for student_id = 1
        curr_query = (
            db.session.query(Course)
            .join(Enrollment, Enrollment.course_id == Course.course_id)
            .filter(Enrollment.student_id == 1, Enrollment.status == 'In Progress')
            .subquery()
        )

        # Case statements for custom ordering
        term_order = case(
            (curr_query.c.term == 'Fall', 1),
            (curr_query.c.term == 'Winter', 2),
            else_=3
        )

        day_order = case(
            (Timeblock.day == 'Monday', 1),
            (Timeblock.day == 'Tuesday', 2),
            (Timeblock.day == 'Wednesday', 3),
            (Timeblock.day == 'Thursday', 4),
            (Timeblock.day == 'Friday', 5),
            else_=6
        )

        # Main query
        courses = db.session.query(
            curr_query.c.course_id,
            curr_query.c.title,
            curr_query.c.course_code,
            curr_query.c.info,
            curr_query.c.instructor_id,
            curr_query.c.credit_hours,
            curr_query.c.department,
            curr_query.c.room,
            curr_query.c.term,
            curr_query.c.year,
            Timeblock.timeblock_id,
            cast(Timeblock.start_time, String).label('start_time'),
            cast(Timeblock.end_time, String).label('end_time'),
            Timeblock.day
        ).join(
            Courseblock, Courseblock.course_id == curr_query.c.course_id
        ).join(
            Timeblock, Timeblock.timeblock_id == Courseblock.timeblock_id
        ).order_by(
            term_order, day_order, Timeblock.start_time
        ).all()

        return [dict(c._mapping) for c in courses]
        

class Course(db.Model):
    __tablename__ = 'courses'
    
    course_id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    course_code = db.Column(db.String(20), nullable=False, unique=True)
    info = db.Column(db.Text, nullable=True)
    instructor_id = db.Column(db.Integer, db.ForeignKey('faculty.faculty_id'), nullable=False)
    department = db.Column(db.String(4), db.ForeignKey('departments.department_id'), nullable=False)
    room = db.Column(db.String(10), db.ForeignKey('rooms.room_number'))
    credit_hours = db.Column(db.Integer, nullable=False)
    term = db.Column(db.String(20), nullable=False)
    year = db.Column(db.Integer, nullable=False)
    capacity = db.Column(db.Integer)

    enrollments = db.relationship('Enrollment', backref='course', lazy=True)
    courseblocks = db.relationship('Courseblock', backref='course', lazy=True)


class Department(db.Model):
    __tablename__ = 'departments'

    department_id = db.Column(db.Integer, primary_key=True)
    department_name = db.Column(db.String(30), nullable=False)
    department_chair = db.Column(db.String(30), db.ForeignKey('faculty.faculty_id'))
    department_email = db.Column(db.String(30), nullable=False)


class Enrollment(db.Model):
    __tablename__ = 'enrollments'

    # enrollment_id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey('students.student_id'), primary_key=True)
    course_id = db.Column(db.Integer, db.ForeignKey('courses.course_id'), primary_key=True)
    status = db.Column(db.String(20), nullable=False)


class Prerequisite(db.Model):
    __tablename__ = 'prerequisites'

    course_id = db.Column(db.Integer, db.ForeignKey('courses.course_id'), primary_key=True)
    prereq_id = db.Column(db.Integer, db.ForeignKey('courses.course_id'), primary_key=True)


class Timeblock(db.Model):
    __tablename__ = 'timeblocks'

    timeblock_id = db.Column(db.String(2), primary_key=True)
    day = db.Column(db.String(9))
    start_time = db.Column(db.Time)
    end_time = db.Column(db.Time)

    courseblocks = db.relationship('Courseblock', backref='timeblock', lazy=True)


class Courseblock(db.Model):
    __tablename__ = 'courseblocks'

    course_id = db.Column(db.Integer, db.ForeignKey('courses.course_id'), primary_key=True)
    timeblock_id = db.Column(db.String(2), db.ForeignKey('timeblocks.timeblock_id'), primary_key=True)


class Room(db.Model):
    __tablename__ = 'rooms'

    room_number = db.Column(db.String(10), primary_key=True)
    building = db.Column(db.String(20), nullable=False)


class Faculty(db.Model):
    __tablename__ = 'faculty'

    faculty_id = db.Column(db.Integer, primary_key=True)
    first_name = db.Column(db.String(50), nullable=False)
    middle_name = db.Column(db.String(50), nullable=True)
    last_name = db.Column(db.String(50), nullable=False)
    personal_email = db.Column(db.String(100), nullable=False, unique=True)
    student_email = db.Column(db.String(100), nullable=False, unique=True)

    
    
