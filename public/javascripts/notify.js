var mySocket = new WebSocket(ws_url);

mySocket.onmessage = function (evt) {
  console.log( "Got message " + evt.data );
  Notification.requestPermission(function() {
    var n = new Notification('Kanku Desktop Notification', {
	body: evt.data,
	icon: './favicon.ico' // optional
    });
    n.onclick = function() {
        window.location.href = 'job_history';
        n.close();
    };
    setTimeout(n.close.bind(n), 20000);
  });
};

mySocket.onopen = function(evt) {
  console.log("opening");
  Notification.requestPermission(function() {
    var n = new Notification('Kanku Desktop Notification', {
	body: 'opening websocket',
	icon: './favicon.ico' // optional
    });
    n.onclick = function() {
        window.location.href = 'job_history';
        n.close();
    };
    setTimeout(n.close.bind(n), 20000);
  });
  setTimeout(
    function() {
      mySocket.send('hello');
    },
    2000
  );
};


if (! window.Notification ) {
  alert("Notifications not availible in your browser!");
} else if (Notification.permission !== "granted") {
   Notification.requestPermission(function() {});
} else {
  $('#trigger_notify').click(
    function(){

    Notification.requestPermission(function() {
      var n = new Notification('Kanku Desktop Notification', {
	body: 'test <a href="/kanku/job_history"> test test test test test test test test test test test test test test test test test test test test test test test test test test test ',
	icon: './favicon.ico' // optional
      });
      n.onclick = function() {
        window.location.href = 'job_history';
        n.close();
      };
      setTimeout(n.close.bind(n), 20000);
    });
  });
}
