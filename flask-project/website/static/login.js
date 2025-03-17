document.getElementById("login-form").addEventListener("submit", function (e) {
    e.preventDefault();
  
    var formData = new FormData(e.target);
    // output as an object
    console.log(Object.fromEntries(formData));
  
    // ...or iterate through the name-value pairs
    for (var pair of formData.entries()) {
      console.log(pair[0] + ": " + pair[1]);
    }
});