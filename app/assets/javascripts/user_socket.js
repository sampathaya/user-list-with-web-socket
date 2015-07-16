var UserSocket = function(user_id){
  this.user_id = user_id;

  this.socket = new WebSocket("ws://wsulist.herokuapp.com/users/" + this.user_id.toString());
  console.log(this.socket);
  this.initIt();
};

UserSocket.prototype.initIt = function() {
  var that = this;

  this.socket.onmessage = function(e) {
  	console.log(e);
  	var tokens = e.data.split(" ");
  	switch(tokens[0]) {
  		case "users":
  		  _total_users = tokens[1];
  		  _active_sessions = tokens[2];
        user_id = tokens[3];
        user_name = tokens[4];
        user_email = tokens[5];
  		  $(".user_count").html(_total_users);
        handle_user_list(user_id, user_name, user_email);
  		  break;
  		case "status":
  		  user_status = tokens[1]
  		  user_id = tokens[2]
        set_user_status(user_id, user_status);
  		  break;
  	}
  }

  this.socket.onopen = function() {
  	that.socket.send('new_session '+ that.user_id.toString());
  }

  this.socket.onclose = function(e) {
  	// alert('going awayyyyyyy');
  	console.log(e);
  	that.socket.close(e.code, e.reason);
  }
};

function set_user_status(_id, user_status) {
  $("#users").find("#user_"+_id).removeClass("online ofline away").addClass(user_status);
}

function handle_user_list(_id, _name, _email) {
  if($("#users").find("#user_"+_id).length > 0) {

  }else {
    new_html = "<div class=\"col-md-3 col-sm-6 full-border margin-10 online\" id=\"user_" + _id + "\">";
    new_html += "<h3>"+ _name +"</h3>";
    new_html += "<h5>"+ _email + "</h5>";
    new_html += "</div>";
    $("#users").append(new_html);
  }
}