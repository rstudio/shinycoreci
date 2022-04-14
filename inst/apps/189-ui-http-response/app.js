function verifyPOST() {
  return $.ajax({
    url: "post_endpoint",
    method: "POST",
    dataType: "text"
  }).then(function(data) {
    if (data !== "All good!") {
      throw new Error("Unexpected response: \"" + data + "\"");
    }
  });
}
