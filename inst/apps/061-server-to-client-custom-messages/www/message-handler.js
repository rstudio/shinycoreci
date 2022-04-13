// This recieves messages of type "testmessage" from the server.
Shiny.addCustomMessageHandler("testmessage",
  function(message) {
    $("#custom-message").text(JSON.stringify(message))
  }
);
