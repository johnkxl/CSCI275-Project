from flask import Blueprint, request, jsonify
from .models import Student, Faculty, Course, Timeblock, Courseblock

api = Blueprint('api', __name__, static_folder='static', template_folder='templates')


@api.route('/courses', methods=['GET'])
def get_all_courses():
    # Get the 'department' filter from the query parameters
    department_filter = request.args.get('department')

    query = Course.query \
        .outerjoin(Faculty, Course.instructor_id == Faculty.faculty_id) \
        .outerjoin(Courseblock, Courseblock.course_id == Course.course_id) \
        .outerjoin(Timeblock, Courseblock.timeblock_id == Timeblock.timeblock_id) \
        .add_columns(
            Course.course_id,
            Course.title,
            Course.course_code,
            Course.info,
            Faculty.first_name.label("prof"),
            Course.credit_hours,
            Course.department,
            Course.room,
            Course.term,
            Course.year,
            Timeblock.timeblock_id,
            Timeblock.start_time,
            Timeblock.end_time,
            Timeblock.day
        )
    
    # Apply department filter if provided
    if department_filter:
        query = query.filter(Course.department == department_filter)

    # Execute query
    data = query.order_by(Course.course_code, Timeblock.timeblock_id).all()

    # Grouping logic
    courses_dict = {}
    for course in data:
        course_id = course.course_id
        if course_id not in courses_dict:
            courses_dict[course_id] = {
                "course_id": course.course_id,
                "title": course.title,
                "course_code": course.course_code,
                "info": course.info,
                "prof": course.prof,
                "credit_hours": course.credit_hours,
                "department": course.department,
                "room": course.room,
                "term": course.term,
                "year": course.year,
                "timeblocks": []
            }

        # Append timeblock only if it exists (some courses may have no timeblock)
        if course.timeblock_id:
            courses_dict[course_id]["timeblocks"].append({
                "timeblock_id": course.timeblock_id,
                "day": course.day,
                "start_time": str(course.start_time) if course.start_time else None,
                "end_time": str(course.end_time) if course.end_time else None
            })

    # Convert grouped data back to list format
    result = list(courses_dict.values())
    return jsonify(result)


@api.route('/enroll', methods=['POST'])
def enroll_student():
    data = request.get_json()
    student_id = data.get('student_id')
    course_id = data.get('course_id')

    student = Student.query.get(student_id)
    course = Course.query.get(course_id)

    if not student or not course:
        return jsonify({"error": "Student or course not found"}), 404

    # if course in student.courses:
    #     return jsonify({"message": "Student already enrolled in this course"}), 400

    # student.courses.append(course)
    message = student.enroll(course_id)

    # return jsonify({"message": f"Student {student.first_name} enrolled in {course.title} successfully"}), 201
    return message

@api.route('/drop', methods=['POST'])
def drop_course():
    data = request.get_json()
    student_id = data.get('student_id')
    course_id = data.get('course_id')

    student = Student.query.get(student_id)
    course = Course.query.get(course_id)
    if not student or not course:
        return jsonify({"error": "Student or course not found"}), 404
    
    message = student.drop(course_id)
    return message

@api.route('/student/<int:student_id>/schedule', methods=['GET'])
def get_student_schedule(student_id):
    student = Student.query.get(student_id)
    if not student:
        return jsonify({"error": "Student not found"}), 404

    return jsonify(student.get_schedule())