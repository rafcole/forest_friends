// application.js

$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Deletion is permanent, would you like to continue?");
    if (ok) {
      this.submit();
    }
  });

});