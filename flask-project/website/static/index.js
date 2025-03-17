const DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
const DAY_START_HOUR = 8;
const DAY_END_HOUR = 18;


let STUDENT_ID = 1;

// Get schedule grid elements
const fallScheduleGrid = document.getElementById("schedule-fall");
const winterScheduleGrid = document.getElementById("schedule-winter");

// Initialize both schedules
// createSchedule(fallScheduleGrid);
// createSchedule(winterScheduleGrid);
renderSchedule(STUDENT_ID);

const departments = [
  "ADED", "ANTH", "AQUA", "ART", "BIOL", "BSAD", "CATH", "CELT", "CHEM", "CLAS",
  "CLEN", "COOP", "CSCI", "DEVS", "EESC", "ECON", "EDUC", "ENGR", "ENGL", "FREN",
  "GERM", "HLTH", "HIST", "HKIN", "HNU", "IDS", "MATH", "MIKM", "MLAN", "MUSI",
  "NURS", "PHIL", "PHYS", "PSCI", "PSYC", "PGOV", "RELS", "SOCI", "SPAN", "SMGT", "STAT", "WMGS"
];

deptFilterContainer = document.getElementById("dept-filter-container");
departmentSelect = document.getElementById("departmentSelect");
departments.forEach( dept => {
    deptartmentOption = document.createElement("option");
    deptartmentOption.setAttribute("value", dept);
    deptartmentOption.innerHTML = dept;
    departmentSelect.appendChild(deptartmentOption);
})

// Load all courses initially
fetchCourses();

// Filter courses when department changes
departmentSelect.addEventListener('change', (e) => {
  const selectedDepartment = e.target.value;
  fetchCourses(selectedDepartment);
})


// Create schedule function
function createSchedule(gridElement) {
  gridElement.innerHTML = ""; // Clear before rendering
  for (let hour = DAY_START_HOUR; hour <= DAY_END_HOUR; hour++) {
    for (let i = 0; i < 4; i++) {
      const timeLabel = i === 0 ? `${hour}:00` : "";
      gridElement.innerHTML += `<div class="time-label">${timeLabel}</div>`;
      DAYS.forEach(() => {
        gridElement.innerHTML += '<div class="schedule-cell"></div>';
      });
    }
  }
}

// Add class to the correct schedule
function addClass(term, day, startHour, startMin, endHour, endMin, courseInfo) {
  const gridElement = term === "Fall" ? fallScheduleGrid : winterScheduleGrid;

  // Create class block
  const classBlock = document.createElement("div");
  classBlock.className = "class-block";
  classBlock.innerHTML = `
      <strong>${courseInfo.course_code}</strong><br>
      ${courseInfo.title}<br>`;
      // <small>Prof: ${courseInfo.instructor_id}</small><br>
      // <small>Room: ${courseInfo.room}</small><br>
      // <small>${courseInfo.start_time} - ${courseInfo.end_time}</small>
  // ;

  // Calculate grid positioning
  const dayOffset = 1 + DAYS.indexOf(day);
  const totalDays = 6;
  const targetStartHour = startHour - DAY_START_HOUR;
  const targetRow = targetStartHour * 4 + Math.floor(startMin / 15);
  const targetRowIndex = targetRow * totalDays;
  const targetCellIndex = targetRowIndex + dayOffset;

  const targetCell = gridElement.children[targetCellIndex];
  targetCell.style.position = "relative";
  targetCell.appendChild(classBlock);

  // Calculate height dynamically based on duration
  const durationInMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin);
  const blockHeight = (durationInMinutes / 15) * 30; // Each 15-min slot = 30px height
  classBlock.style.height = `${blockHeight}px`;
}

// Example: Adding classes (Replace with real data from backend)
// addClass("Fall", 9, 30, "Math 101");
// addClass("Winter", 10, 15, "CS 201");

function togglecaretAccordion(triangle) {
  const header = triangle.parentElement;
  const content = header.nextElementSibling;
  const isActive = content.classList.contains('active');

  // Close all accordion items
  document.querySelectorAll('.accordion-content').forEach(item => {
      item.classList.remove('active');
      item.previousElementSibling.classList.remove('active');
  });

  // Toggle current item
  if (!isActive) {
    content.classList.add('active');
    header.classList.add('active');
  } else {
    content.classList.remove('active');
    header.classList.remove('active');
  }
}

function fetchCourses(department = '') {
  const url = department
      ? `api/courses?department=${encodeURIComponent(department)}`
      : 'api/courses';

      fetch(url)
          .then(response => response.json())
          .then(data => {
            const courseList = document.getElementById("course-search-results");
            courseList.innerHTML = ''; // Clear existing list
            data.forEach(course => {
              const listItem = document.createElement("li");
              listItem.setAttribute("class", "list-group-item courseItem");
              listItem.setAttribute('id', `${course.course_id}`)
              listItem.innerHTML = `<div class="d-flex w-100 justify-content-between">
                      <h5 class="mb-1">${course.course_code} ${course.title}</h5>
                      <small>${course.term} ${course.year}</small>
                    </div>
                    <p class="mb-1">${course.prof}</p>
                    <div class="caretAccordion">
                      <div class="caretAccordion-item">
                        <div class="caretAccordion-header">
                            <div class="triangle"  onclick="togglecaretAccordion(this)"></div>
                            Timeblocks
                        </div>
                        <div class="caretAccordion-content">
                          <small class="mb-1">
                          <ul>
                          ${course.timeblocks.map(tb =>`
                            <li>${tb.day} | ${tb.start_time} - ${tb.end_time}</li>
                          `).join('')}
                          </ul>
                          </small>
                        </div>
                      </div>
                      <div class="caretAccordion-item">
                          <div class="caretAccordion-header">
                              <div class="triangle"  onclick="togglecaretAccordion(this)"></div>
                              Prerequisites
                          </div>
                          <div class="caretAccordion-content">
                              MATH 001, MATH 002
                          </div>
                      </div>
                    </div>`

                    courseList.appendChild(listItem);
                });
          })
          .catch(error => console.error('Error fetching courses:', error));
}

// Functions for registering for, or dropping a course. **********************
function updateCourseRegistrationStatus(studentId, courseId, type) {
  fetch(`api/${type}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ student_id: studentId, course_id: courseId })
  })
  .then(response => response.json().then(data => ({ status: response.status, body: data })))
  .then(({ status, body }) => {
    if (status === 200) {
      console.log(body.message);
      renderSchedule(studentId); // Refresh schedule on success
    }
    else if (status === 400) {
      console.log(body.error);
    }
  })
  .catch(error => console.error('Error:', error));
}

function enroll(studentId, courseId) {
  updateCourseRegistrationStatus(studentId, courseId, 'enroll');
}

function unenroll(studentId, courseId) {
  updateCourseRegistrationStatus(studentId, courseId, 'drop');
}

// Tests
// enroll(1, 40407);
// unenroll(1, 40407);

// ****************************************************************************



function courseSearch() {
  fetch('/api/courses')
    .then(response => response.json())
    .then(courses => {
      const courseList = document.getElementById("course-search-results");
      courses.forEach(course => {
        const listItem = document.createElement("li");
        listItem.setAttribute("class", "list-group-item");
        listItem.innerHTML = `<div class="d-flex w-100 justify-content-between">
                <h5 class="mb-1">${course.course_code} ${course.title}</h5>
                <small>${course.term} ${course.year}</small>
              </div>
              <p class="mb-1">${course.instructor}</p>
              <div class="caretAccordion">
                <div class="caretAccordion-item">
                  <div class="caretAccordion-header">
                      <div class="triangle"  onclick="togglecaretAccordion(this)"></div>
                      Timeblocks
                  </div>
                  <div class="caretAccordion-content">
                    <small class="mb-1"></small>
                  </div>
                </div>
                <div class="caretAccordion-item">
                    <div class="caretAccordion-header">
                        <div class="triangle"  onclick="togglecaretAccordion(this)"></div>
                        Prerequisites
                    </div>
                    <div class="caretAccordion-content">
                        MATH 001, MATH 002
                    </div>
                </div>
              </div>`

              courseList.appendChild(listItem);
      });
    })
}

function renderSchedule(studentId) {
  // Clear old schedules
  createSchedule(fallScheduleGrid);
  createSchedule(winterScheduleGrid);

  fetch(`api/student/${studentId}/schedule`)
    .then(response => response.json())
    .then(courses => {
      courses.forEach(course => {
        // Extract time details
        const [startHour, startMin] = course.start_time.split(":").map(Number);
        const [endHour, endMin] = course.end_time.split(":").map(Number);
  
        // Add class to the schedule
        addClass(course.term, course.day, startHour, startMin, endHour, endMin, course);
      })
  });
}