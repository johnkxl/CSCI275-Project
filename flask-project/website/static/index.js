const days = ["Mon", "Tue", "Wed", "Thu", "Fri"];
const dayStartHour = 8;
const dayEndHour = 18;

// Get schedule grid elements
const fallScheduleGrid = document.getElementById("schedule-fall");
const winterScheduleGrid = document.getElementById("schedule-winter");

// Create schedule function
function createSchedule(gridElement) {
  gridElement.innerHTML = ""; // Clear before rendering
  for (let hour = dayStartHour; hour <= dayEndHour; hour++) {
    for (let i = 0; i < 4; i++) {
      const timeLabel = i === 0 ? `${hour}:00` : "";
      gridElement.innerHTML += `<div class="time-label">${timeLabel}</div>`;
      days.forEach(() => {
        gridElement.innerHTML += '<div class="schedule-cell"></div>';
      });
    }
  }
}

// Add class to the correct schedule
function addClass(term, startHour, startMin, courseName) {
  const gridElement = term === "Fall" ? fallScheduleGrid : winterScheduleGrid;
  
  const classBlock = document.createElement("div");
  classBlock.className = "class-block bg-info";
  classBlock.innerText = courseName;

  const dayOffset = 1;
  const totalDays = 6;
  const targetStartHour = startHour - dayStartHour;
  const targetRow = targetStartHour * 4 + Math.floor(startMin / 15);
  const targetRowIndex = targetRow * totalDays;
  const targetCellIndex = targetRowIndex + dayOffset;

  const targetCell = gridElement.children[targetCellIndex];
  targetCell.style.position = "relative";
  targetCell.appendChild(classBlock);
  classBlock.style.height = "100px"; // Adjust block height
}

// Initialize both schedules
createSchedule(fallScheduleGrid);
createSchedule(winterScheduleGrid);

// Example: Adding classes (Replace with real data from backend)
addClass("Fall", 9, 30, "Math 101");
addClass("Winter", 10, 15, "CS 201");



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


const departments = [
  "ADED", "ANTH", "AQUA", "ART", "BIOL", "BSAD", "CATH", "CELT", "CHEM", "CLAS",
  "CLEN", "COOP", "CSCI", "DEVS", "EESC", "ECON", "EDUC", "ENGR", "ENGL", "FREN",
  "GERM", "HLTH", "HIST", "HKIN", "HNU", "IDS", "MATH", "MIKM", "MLAN", "MUSI",
  "NURS", "PHIL", "PHYS", "PSCI", "PSYC", "PGOV", "RELS", "SOCI", "SPAN", "SMGT", "STAT", "WMGS"
];

deptFilterContainer = document.getElementById("dept-filter-container");
departmentSelect = document.getElementById("departmentSelect");
departments.forEach( dept => {
  deptartmentOption = document.createElement("option")
  deptartmentOption.setAttribute("value", dept)
  deptartmentOption.innerHTML = dept
  departmentSelect.appendChild(deptartmentOption)
})


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

function changeRegistration(student_id, course_id, type) {
  fetch(`api/${type}`, {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ student_id: student_id, course_id: course_id })
  })
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error('Error:', error));
}

function registerCourse(student_id, course_id) {
  changeRegistration(student_id, course_id, 'enroll');
}

function dropCourse(student_id, course_id) {
  changeRegistration(student_id, course_id, 'drop');
}

// Tests
// registerCourse(1, 40407);
// dropCourse(1, 40407);

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

// Load all courses initially
fetchCourses();

// Filter courses when department changes
departmentSelect.addEventListener('change', (e) => {
  const selectedDepartment = e.target.value;
  fetchCourses(selectedDepartment);
})
